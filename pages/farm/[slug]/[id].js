import Icon from "../../../components/icon";
import Link from "next/link";
import { useRouter } from "next/router";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useEffect, useRef, useState } from "react";
import { ethers } from "ethers";
import {
  ONE,
  YEAR,
  bnMax,
  formatChartDate,
  formatError,
  formatNumber,
  formatUnits,
  formatDate,
  parseUnits,
  runTransaction,
  tokensOfOwner,
  useWeb3,
  usePositions,
  useGlobalState,
  apiServerHost,
} from "../../../utils";
import Layout from "../../../components/layout";
import Tooltip from "../../../components/tooltip";
import DiscreteSliders from "../../../components/discreteSliders";
import PositionTrack from "../../../components/positionTrack";
import Input from "../../../components/input";

export default function FarmPosition() {
  const router = useRouter();
  const { state } = useGlobalState();
  const { openConnectModal } = useConnectModal();
  const { signer, address, walletStatus, networkName, contracts, chainId } =
    useWeb3();
  const { data: positions, refetch: positionsRefetch } = usePositions();
  const [action, setAction] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState();
  const [amount, setAmount] = useState("");
  const [amountBorrow, setAmountBorrow] = useState("");
  const strategy = state.strategies.find((s) => s.slug == router.query.slug);
  const strategySlippage = strategy?.slippage || 100;
  const [slippage, setSlippage] = useState(0);
  const [leverage, setLeverage] = useState(1);
  let [selectedPool, setSelectedPool] = useState(0);
  const chartPosRef = useRef();
  const chartBorRef = useRef();
  const chartDateRef = useRef();
  let chartPos = "";
  let chartBor = "";
  const [chartData, setChartData] = useState([]);
  const [posEvents, setPosEvents] = useState([]);
  const hasChartData = chartData.find((d) => d.pos != 0);

  const latestPosId = positions.length > 0 ? positions[0].id : null;
  const position = positions.find(
    (p) =>
      p.strategy === strategy?.index &&
      p.id == router.query.id &&
      p.sharesUsd.gt("0")
  );
  if (position) {
    selectedPool = state.pools.findIndex((p) => p.address === position.pool);
    chartPos = `$${formatNumber(position.sharesUsd)}`;
    chartBor = `$${formatNumber(position.borrowUsd)}`;
  }
  const pool = state.pools[selectedPool];
  const asset = state.assets[pool?.asset];
  const chartDate =
    chartData.length > 0
      ? formatChartDate(chartData[chartData.length - 1].date)
      : null;

  let title = "Adjust position";
  if (!position) title = "New Position";
  if (action === "borrow") title = "Borrow more";
  if (action === "repay") title = "Decrease debt";
  if (action === "deposit") title = "Add collateral";
  if (action === "withdraw") title = "Close position";

  const ASTONE = parseUnits("1", asset?.decimals || 18);
  let parsedAmount = parseUnits("0");
  let positionChanged = false;
  let updatedLeverage = 1;
  let leverageOrCurrent = leverage;
  let editShares = parseUnits("0");
  let editBorrow = parseUnits("0");

  let newSharesUsd = parseUnits("0");
  let newBorrowUsd = parseUnits("0");
  let newHealth = ONE;
  let newLiquidationUsd = parseUnits("0");
  let newLiquidationPercent = parseUnits("0");
  let newLeverage = parseUnits("1");
  let newApy = parseUnits("0");
  let borrowApr = parseUnits("0");
  let dailyApr = parseUnits("0");

  try {
    if (!pool || !asset) throw new Error("Missing pool or asset");
    parsedAmount = parseUnits(amount || "0", asset.decimals);
    const adjustedPrice = pool.price
      .mul(ONE)
      .div(parseUnits("1", asset.decimals));
    const parsedAmountUsd = parsedAmount.mul(adjustedPrice).div(ONE);
    if (parsedAmount.gt("0")) {
      positionChanged = true;
    }

    // Calculate the values to pass to `edit()`
    if (position) {
      if (action === "borrow") {
        editBorrow = parsedAmount;
      }
      if (action === "repay") {
        editBorrow = parsedAmount.mul(ONE).div(pool.index).mul(-1);
        if (parsedAmount.eq(position.borrowAst)) {
          editBorrow = position.borrow.mul(-1);
        }
        editShares = position.shares
          .mul(editBorrow.mul(pool.index).div(ONE))
          .div(position.sharesAst)
          .mul(101)
          .div(100);
      }
      if (action === "deposit") {
        editShares = parsedAmount;
      }
      if (action === "withdraw") {
        editShares = position.shares
          .mul(parsedAmount)
          .div(position.sharesAst)
          .mul(-1);
        const max = position.sharesAst.sub(position.borrowAst);
        if (parsedAmount.eq(max)) {
          editShares = position.shares.mul(-1);
          editBorrow = position.borrow.mul(-1);
        }
      }

      let newBorrowAst = position.borrowAst;
      let newSharesAst = position.sharesAst;
      if (editShares.gt(0)) {
        newSharesAst = newSharesAst.add(editShares);
      }
      if (editShares.lt(0)) {
        newSharesAst = position.shares
          .add(editShares)
          .mul(position.sharesAst)
          .div(position.shares);
      }
      if (editBorrow.gt(0)) {
        newSharesAst = newSharesAst.add(editBorrow);
        newBorrowAst = newBorrowAst.add(editBorrow);
      }
      if (editBorrow.lt(0)) {
        newBorrowAst = newBorrowAst.add(editBorrow.mul(pool.index).div(ONE));
      }
      if (editShares.eq(position.shares.mul(-1))) {
        newSharesAst = parseUnits("0");
      }
      newSharesUsd = newSharesAst.mul(pool.price).div(ASTONE);
      newBorrowUsd = newBorrowAst.mul(pool.price).div(ASTONE);

      if (newBorrowUsd.gt(0) && newSharesUsd.sub(newBorrowUsd).gt(0)) {
        updatedLeverage =
          newBorrowUsd
            .mul(1000)
            .div(newSharesUsd.sub(newBorrowUsd))
            .toNumber() /
            1000 +
          1;
        if (updatedLeverage < 1) updatedLeverage = 1;
        if (leverage === 1) leverageOrCurrent = updatedLeverage;
      }
    } else {
      // Calculate the values to pass to `earn()` for a new "deposit"
      editShares = parsedAmount;
      editBorrow = parseUnits(amountBorrow || "0", asset.decimals);
      newSharesUsd = parsedAmount.add(editBorrow).mul(adjustedPrice).div(ONE);
      newBorrowUsd = editBorrow.mul(adjustedPrice).div(ONE);
    }

    if (newBorrowUsd.eq("0") || newSharesUsd.eq("0")) {
      newHealth = ONE;
    } else {
      newHealth = newSharesUsd.mul(95).div(100).mul(ONE).div(newBorrowUsd);
      newLiquidationUsd = newBorrowUsd.mul(100).div(95);
      newLiquidationPercent = ONE.sub(
        newLiquidationUsd.mul(ONE).div(newSharesUsd)
      );
      newLeverage = newBorrowUsd
        .mul(ONE)
        .div(newSharesUsd.sub(newBorrowUsd))
        .add(ONE);
      borrowApr = pool.rate.mul(YEAR).mul(newLeverage.sub(ONE)).div(ONE);
    }

    newApy = strategy.apy;
    newApy = newApy.mul(newLeverage).div(ONE).sub(borrowApr);
    dailyApr =
      (Math.pow(newApy.mul(1000).div(ONE).toNumber() / 1000 + 1, 1 / 365) - 1) *
      100;
  } catch (e) {
    console.error("calc", e);
  }
  const leverageCap = updatedLeverage;
  const leverageMin = position && action == "deposit" ? leverageCap : "1";
  const leverageMax = position && action == "withdraw" ? leverageCap : "10";
  const assetAllowanceOk = !data
    ? false
    : action === "borrow" || action == "withdraw"
    ? true
    : parsedAmount.gt(0)
    ? data.assetAllowance.gte(parsedAmount)
    : data.assetAllowance.gt(0);

  function cMouseMove(data) {
    if (!data || !data.activePayload) return;
    chartPosRef.current.innerText = `$${formatNumber(
      parseFloat(data.activePayload[0].payload.pos) +
        parseFloat(data.activePayload[0].payload.bor)
    )}`;
    chartBorRef.current.innerText = `$${formatNumber(
      parseFloat(data.activePayload[0].payload.bor)
    )}`;
    chartDateRef.current.innerText = formatChartDate(
      data.activePayload[0].payload.date
    );
  }

  function cMouseOut() {
    chartDateRef.current.innerText = chartDate;
    chartPosRef.current.innerText = chartPos;
    chartBorRef.current.innerText = chartBor;
  }

  async function fetchData() {
    if (!contracts || !address || !pool || !strategy) return;
    const poolContract = contracts.pool(pool.address);
    const assetContract = contracts.asset(pool.asset);
    const positionValues =
      router.query.id && router.query.id !== "new"
        ? await contracts.investor.positions(router.query.id)
        : [0, 0, 0, parseUnits("0")];
    const strategyContract = contracts.strategy(strategy.address);
    const data = {
      borrowRate: pool.rate,
      borrowMin: pool.borrowMin,
      borrowAvailable: pool.supply.sub(pool.borrow),
      assetBalance: await assetContract.balanceOf(address),
      assetAllowance: await assetContract.allowance(
        address,
        contracts.positionManager.address
      ),
      positionOutset: new Date(positionValues[3].toNumber() * 1000),
      positionLifetime: parseInt(
        Date.now() / 1000 - positionValues[3].toNumber()
      ),
    };
    setData(data);
  }

  async function fetchChartData() {
    if (!position) return;

    const histories = await (
      await fetch(
        apiServerHost +
          `/positions/history?chain=${chainId}&index=${position.id}&interval=hour&length=168`
      )
    ).json();

    setChartData(
      histories.map((h, index) => {
        const pos = parseFloat(formatUnits(h.shares_value, 18));
        const priceAdjusted = parseUnits(h.price, 0)
          .mul(ONE)
          .div(parseUnits("1", asset.decimals));
        const bor = parseFloat(
          formatUnits(parseUnits(h.borrow_value, 0).mul(priceAdjusted).div(ONE))
        );

        return {
          date: new Date(h.t),
          pos: pos - bor,
          bor: bor,
        };
      })
    );
  }

  async function fetchEvents() {
    if (!position) {
      return;
    }

    setPosEvents(
      (
        await (
          await fetch(
            apiServerHost +
              `/positions/events?chain=${chainId}&index=${position.id}`
          )
        ).json()
      ).slice(0, 50)
    );
  }

  async function updatePosUrl() {
    if (!position) {
      const ids = await tokensOfOwner(
        signer,
        contracts.positionManager.address,
        address
      );
      ids.sort((a, b) => parseInt(b) - parseInt(a));

      if (ids.length > 0 && parseInt(ids[0]) !== latestPosId) {
        router.push(`/farm/${strategy?.slug}/${ids[0]}`, undefined, {
          shallow: true,
        });
      }
    }
  }

  useEffect(() => {
    if (!slippage && strategy) {
      setSlippage(strategy.slippage || 50);
    }
  }, [slippage, strategy]);

  useEffect(() => {
    fetchData().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [networkName, address, pool]);

  useEffect(() => {
    fetchChartData().then(
      () => {},
      (e) => console.error("fetch chart data", e)
    );
    fetchEvents().then(
      () => {},
      (e) => console.error("fetch events", e)
    );
  }, [strategy, address, position]);

  function adjustLeverage(value) {
    value = parseFloat(value);
    if (Number.isNaN(value)) return;
    value = Math.min(Math.max(value, leverageMin), leverageMax);
    setLeverage(value);
  }

  async function onApprove() {
    if (walletStatus === "disconnected") {
      openConnectModal();
      return;
    }
    setError("");
    try {
      setLoading(true);
      const assetContract = contracts.asset(pool.asset);

      const call = await assetContract.approve(
        contracts.positionManager.address,
        ethers.constants.MaxUint256
      );
      await runTransaction(
        call,
        "Transaction is pending approval...",
        "Approval completed.",
        false,
        networkName
      );
      setTimeout(fetchData, 1000);
    } catch (e) {
      console.error(e);
      setError(formatError(e.message));
    } finally {
      setLoading(false);
    }
  }

  async function onSubmit() {
    if (walletStatus === "disconnected") {
      openConnectModal();
      return;
    }
    setError("");
    try {
      setLoading(true);
      if (!position && !editBorrow.eq("0") && editBorrow.lt(data.borrowMin)) {
        throw new Error(
          `Borrow below minimum (${formatNumber(
            data.borrowMin,
            asset.decimals
          )})`
        );
      }
      if (!position && editBorrow.gt(data.borrowAvailable)) {
        throw new Error("Borrow larger than available for lending");
      }
      if (newHealth.lt(ONE)) {
        throw new Error("Health needs to stay above 1");
      }
      if (
        (!action || action === "deposit") &&
        parsedAmount.gt(data.assetBalance)
      ) {
        throw new Error("Error not enough funds in wallet");
      }

      const actualSlippage = slippage > 0 ? slippage : strategy.slippage;
      if (actualSlippage <= 0) {
        throw new Error("Slippage must be greater than 0%");
      }
      if (actualSlippage > 500) {
        throw new Error("Slippage must be less than or equal to 5%");
      }

      const callData = actualSlippage
        ? ethers.utils.defaultAbiCoder.encode(["uint256"], [actualSlippage])
        : "0x";
      let call;
      if (!position) {
        call = contracts.positionManager.mint(
          address,
          pool.address,
          strategy.index,
          parsedAmount,
          editBorrow,
          callData
        );
        const index = (await contracts.investor.nextPosition()).toNumber();
        await runTransaction(
          call,
          "New position deposit is awaiting confirmation on chain...",
          "Deposit completed.",
          true,
          networkName
        );
        router.push(`/farm/${strategy.slug}/${index}`);
      } else {
        call = contracts.positionManager.edit(
          position.id,
          editShares,
          editBorrow,
          callData
        );
        await runTransaction(
          call,
          "Position update is awaiting confirmation on chain...",
          "Position update completed.",
          true,
          networkName
        );
        if (editShares.eq(position.shares.mul(-1))) {
          router.push(`/farm/${strategy.slug}`);
        }
      }
      setAction("");
      setAmount("");
      setTimeout(async () => {
        //updatePosUrl();
        fetchData();
        positionsRefetch();
      }, 2000);
      setTimeout(() => {
        //updatePosUrl();
        fetchData();
        positionsRefetch();
      }, 10000);
    } catch (e) {
      console.error(e);
      setError(formatError(e));
    } finally {
      setLoading(false);
    }
  }

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="chart-tooltip wide">
          <div>
            <b>Position </b>{" "}
            {`$${formatNumber(
              parseFloat(payload[1].value) + parseFloat(payload[0].value)
            )}`}
          </div>
          <div>
            <b>Borrowed </b> {`$${formatNumber(parseFloat(payload[0].value))}`}
          </div>
          <div className="text-faded">
            {formatChartDate(payload[0].payload.date)}
          </div>
        </div>
      );
    }

    return null;
  };

  function renderActions() {
    const actions = [
      {
        id: "borrow",
        icon: "dollars-in",
        name: "Borrow more",
        description:
          "Take out more leverage against your collateral if your health factor is good",
      },
      {
        id: "repay",
        icon: "dollars-out",
        name: "Decrease debt",
        description:
          "Pay back a portion of borrowed funds to improve your position health",
      },
      {
        id: "deposit",
        icon: "dollars-bills",
        name: "Add collateral",
        description: "Deposit more collateral to improve your position health",
      },
      {
        id: "withdraw",
        icon: "dollars-wallet",
        name: "Close position",
        description:
          "Withdraw collateral and yield, and pay back borrowed funds and fees",
      },
    ];
    return (
      <>
        {actions.map((a) => (
          <a
            key={a.id}
            className="position-action"
            onClick={() => setAction(a.id)}
          >
            <span className="position-action-icon">
              <Icon name={a.icon} />
            </span>
            <span className="position-action-info">
              <span className="position-action-title">{a.name}</span>
              <span className="position-action-desc">{a.description}</span>
            </span>
            <span className="position-action-arrow">
              <Icon name="chevron-right" />
            </span>
          </a>
        ))}
      </>
    );
  }

  function renderForm() {
    switch (action) {
      case "borrow":
        return renderFormBorrow();
      case "repay":
        return renderFormRepay();
      case "deposit":
        return renderFormDeposit();
      case "withdraw":
        return renderFormWithdraw();
      default:
        return renderFormNew();
    }
  }

  function renderFormNew() {
    function setLeverage(value) {
      setAmountBorrow(
        formatNumber(
          parsedAmount.mul(parseUnits(value, 18).sub(ONE)).div(ONE),
          asset.decimals,
          0
        ).replaceAll(",", "")
      );
    }
    return (
      <>
        <div className="font-bold mb-4">Amount to deposit</div>
        <InputAmount
          amount={amount}
          setAmount={setAmount}
          max={data.assetBalance}
          asset={asset}
          buy
        />
        <div className="font-bold mb-4 mt-6">Amount to borrow</div>
        <InputAmount
          amount={amountBorrow}
          setAmount={setAmountBorrow}
          max={data.borrowAvailable}
          asset={asset}
        />
        <div className="font-bold mb-4 mt-6">Leverage</div>
        <InputLeverage
          value={formatNumber(newLeverage)}
          setValue={setLeverage}
        />
      </>
    );
  }

  function renderFormBorrow() {
    function setLeverage(value) {
      let amount = position.sharesAst
        .sub(position.borrowAst)
        .mul(parseUnits(value, 18).sub(ONE))
        .div(ONE)
        .sub(position.borrowAst);
      amount = bnMax(parseUnits("0"), amount);
      setAmount(formatNumber(amount, asset.decimals).replaceAll(",", ""));
    }
    return (
      <>
        <div className="title">Amount to borrow</div>
        <InputAmount
          amount={amount}
          setAmount={setAmount}
          max={data.borrowAvailable}
          asset={asset}
        />
        <div className="title mt-6">Leverage</div>
        <InputLeverage
          value={formatNumber(newLeverage)}
          setValue={setLeverage}
        />
      </>
    );
  }

  function renderFormRepay() {
    function setLeverage(value) {
      let amount = position.borrowAst.sub(
        position.sharesAst
          .sub(position.borrowAst)
          .mul(parseUnits(value, 18).sub(ONE))
          .div(ONE)
      );
      amount = bnMax(parseUnits("0"), amount);
      setAmount(formatNumber(amount, asset.decimals).replaceAll(",", ""));
    }
    return (
      <>
        <div className="title">Amount to repay</div>
        <InputAmount
          amount={amount}
          setAmount={setAmount}
          max={position.borrowAst}
          asset={asset}
        />
        <div className="title mt-6">Leverage</div>
        <InputLeverage
          value={formatNumber(newLeverage)}
          setValue={setLeverage}
        />
      </>
    );
  }

  function renderFormDeposit() {
    return (
      <>
        <div className="title">Amount to deposit</div>
        <InputAmount
          amount={amount}
          setAmount={setAmount}
          max={data.assetBalance}
          asset={asset}
          buy
        />
      </>
    );
  }

  function renderFormWithdraw() {
    return (
      <>
        <div className="title">Amount to withdraw</div>
        <InputAmount
          amount={amount}
          setAmount={setAmount}
          max={position.sharesAst.sub(position.borrowAst)}
          asset={asset}
        />
      </>
    );
  }

  if (!data || !strategy || !pool || !asset) {
    return (
      <Layout title="Position">
        <div className="loading">Loading...</div>
      </Layout>
    );
  }
  return (
    <Layout
      title={strategy.name + (position ? ` #${position.id}` : " New Position")}
      backLink={`/farm/${strategy?.slug}`}
    >
      <div className="warning mb-6">
        <b>Warning:</b> Farm performance depend on several factors. The
        fees/yield it collects will increase it&apos;s value. The underlying
        asset it uses (e.g. ETH, DPX, GMX) can go up or down in value. The
        borrowing interest rate can also fluctuate. Please read our{" "}
        <a
          href="https://docs.rodeofinance.xyz/"
          target="_blank"
          rel="noreferrer"
        >
          Docs
        </a>{" "}
        and{" "}
        <a
          href="https://docs.rodeofinance.xyz/other/faq"
          target="_blank"
          rel="noreferrer"
        >
          FAQ
        </a>{" "}
        to understand how the farms work before using them.
      </div>

      <div className="title">Position Information</div>
      <div className="grid-4 mb-6">
        <div className="card text-center">
          <div className="label">
            Position value
            <Tooltip tip="The total value (in USD) of your specific Farm position in Rodeo. This includes collateral + borrowed leverage" />
          </div>
          <div className="font-lg">
            $ {position ? formatNumber(position.sharesUsd) : "0.00"}
            <div className="text-faded">
              {positionChanged ? " → $ " + formatNumber(newSharesUsd) : null}
            </div>
          </div>
        </div>
        <div className="card text-center">
          <div className="label">
            Debt value
            <Tooltip tip="The total value (in USD) you have borrowed as leverage. This includes borrowed amount + borrow interest owed" />
          </div>
          <div className="font-lg">
            $ {position ? formatNumber(position.borrowUsd) : "0.00"}
            <div className="text-faded">
              {positionChanged ? " → $ " + formatNumber(newBorrowUsd) : null}
            </div>
          </div>
        </div>
        <div className="card text-center">
          <div className="label">
            Health
            <Tooltip
              tip={
                <>
                  A numeric representation of your position health. If your
                  health factor drops below 1 your position will be liquidated
                  <br />
                  <br />
                  0.99 to 0.95 = gentle liquidation
                  <br />
                  &lt;0.95 = full position liquidation
                  <br />
                  <br />
                  Health factor = Position Value * 0.95 / Debt Value (including
                  interest)
                </>
              }
            />
          </div>
          <div className="font-lg">
            {position
              ? position.health.eq(ONE)
                ? "∞"
                : formatNumber(position.health)
              : "0.00"}
            {positionChanged ? (
              <div className="text-faded">
                {" → "}
                {newHealth.eq(ONE) ? "∞" : formatNumber(newHealth)}
              </div>
            ) : null}
          </div>
        </div>
        <div className="card text-center">
          <div className="label">
            Liquidation
            <Tooltip tip="The position value at which your health factor will drop below 1 and enter liquidation. (this is the percentage in value your position must drop to enter liquidation)" />
          </div>
          <div className="font-lg">
            $ {formatNumber(position?.liquidationUsd || 0, 18, 1)} (
            {formatNumber(position?.liquidationPercent || 0, 16, 0)}%)
            {positionChanged ? (
              <div className="text-faded">
                → {formatNumber(newLiquidationUsd, 18, 1)} (
                {formatNumber(newLiquidationPercent, 16, 0)}%)
              </div>
            ) : null}
          </div>
        </div>
      </div>

      <div className="grid-2" style={{ gridTemplateColumns: "2fr 1fr" }}>
        <div>
          <div>
            <div className="flex items-center">
              <div className="flex-1 title">{title}</div>
              <SlipModal
                strategySlippage={strategySlippage}
                slippage={slippage}
                setSlippage={setSlippage}
              />
            </div>
            {position && !action ? (
              renderActions()
            ) : (
              <div>
                <div className="card mb-4">
                  {[23, 28, 32, 35, 39].includes(strategy.index) ? (
                    <div className="error mb-4 text-center">
                      Strategy wound down, withdraw your share of it&rsquo;s
                      value
                    </div>
                  ) : null}
                  {strategy && strategy.status !== 4 ? (
                    <div className="error mb-4 text-center">
                      Strategy paused
                    </div>
                  ) : null}
                  {error ? <div className="error mb-2">{error}</div> : null}
                  {renderForm()}
                </div>
                <div className="flex">
                  <button
                    className="button button-link button-primary"
                    onClick={() => setAction("")}
                  >
                    Back
                  </button>
                  <div className="flex-1"></div>
                  <button
                    className="button"
                    onClick={!assetAllowanceOk ? onApprove : onSubmit}
                    disabled={loading}
                  >
                    {loading
                      ? "Loading..."
                      : !assetAllowanceOk
                      ? "Approve " + asset.symbol
                      : position
                      ? "Adjust position"
                      : "Open position"}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
        <div>
          <div className="title">Farm Information</div>
          <div className="card mb-4">
            <div className="mb-4">
              <div className="label">Protocol</div>
              {strategy.protocol}
            </div>
            <div className="mb-4">
              <div className="label">
                TVL
                <Tooltip tip="Total Value Locked in this farm's underlying protocol farm/vault/pool. A higher TVL usually means less risky" />
              </div>
              {formatNumber(strategy?.tvlTotal || 0, 24, 1)} M
            </div>
            <div className="mb-4">
              <div className="label">
                Rodeo TVL
                <Tooltip tip="Total Value Locked in this farm on Rodeo, including borrowed funds" />
              </div>
              {formatNumber(strategy?.tvl, 18, 2)}{" "}
              {strategy?.cap.gt(0)
                ? " / " + formatNumber(strategy?.cap, 18, 2)
                : null}
            </div>
            <div className="mb-4">
              <div className="label">Position Health</div>
              <div className="w-full">
                <PositionTrack
                  value={formatNumber(newHealth)}
                  className="mb-2"
                />
                <div className="position-health flex">
                  <div>
                    <span className="position-health__text">
                      Current value:{" "}
                    </span>
                    <span className="position-health__current">
                      ${" "}
                      {positionChanged
                        ? formatNumber(newSharesUsd)
                        : position
                        ? formatNumber(position.sharesUsd)
                        : "0.00"}
                    </span>
                  </div>
                  <div>
                    <span className="position-health__text">Liquidation: </span>
                    <span className="position-health__liquidation">
                      ${" "}
                      {positionChanged
                        ? formatNumber(newLiquidationUsd, 18, 1)
                        : formatNumber(position?.liquidationUsd || 0, 18, 1)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div className="mb-4">
              <div className="label">
                Farm APR
                <Tooltip tip="The base yield of the underlying farm multiplied by the leverage factor. This does not include auto compounding" />
              </div>
              {formatNumber(newApy.add(borrowApr), 16)}%
            </div>
            <div className="mb-4">
              <div className="label">
                Borrow APR
                <Tooltip tip="The current borrow APR * (leverage -1)" />
              </div>
              {formatNumber(borrowApr.mul(-1), 16, 1)}%
            </div>
            <div className="mb-4">
              <div className="label">
                Net APR
                <Tooltip tip="The actual APR being earned after borrowing costs are subtracted. Net APR = Farm APR - Borrow APR. This does not include auto compounding" />
              </div>
              <span className={newApy.lt(0) ? "text-red" : ""}>
                {formatNumber(newApy, 16)}%
              </span>
            </div>
            <div className="mb-4">
              <div className="label">
                Daily APR
                <Tooltip tip="The APR earned on a daily basis. Daily APR = (NetAPY+1 ^ 1/365) - 1" />
              </div>
              {formatNumber(dailyApr, 16, 4)}%
            </div>

            {position && position.glpPrice ? (
              <>
                <div className="mb-4">
                  <div className="label">
                    GLP Price
                    <Tooltip tip="The current value of GLP" />
                  </div>
                  $ {formatNumber(position.glpPrice, 18, 4)}
                </div>
                {position.liquidationPercent.lt(ONE) ? (
                  <div className="mb-4">
                    <div className="label">
                      GLP Price for liquidation
                      <Tooltip tip="The price of GLP at which liquidation will be triggered on your position" />
                    </div>
                    ${" "}
                    {formatNumber(
                      position.glpPrice
                        .mul(ONE.sub(position.liquidationPercent))
                        .div(ONE),
                      18,
                      4
                    )}
                  </div>
                ) : null}
              </>
            ) : null}

            {position ? (
              <div className="mb-4">
                <div className="label">
                  ROI
                  <Tooltip tip="Profit or Loss compared to the original collateral deposited. This includes the Rodeo performance fee and estimated swap/mint costs to revert back to USDC" />
                </div>
                $ {formatNumber(position.profitUsd)} (
                {formatNumber(
                  position.profitUsd
                    .mul(ONE)
                    .div(position.sharesUsd.sub(position.borrowUsd)),
                  16
                )}
                %)
              </div>
            ) : null}
            {data && data.positionLifetime > 0 && position ? (
              <div className="mb-4">
                <div className="label">
                  Actual APR
                  <Tooltip tip="An estimation of what your APR would be if your current ROI since you opened the position continues. This includes fluctuations in price of the underlying" />
                </div>
                {formatNumber(
                  position.profitUsd
                    .mul(ONE)
                    .div(position.sharesUsd.sub(position.borrowUsd))
                    .mul(YEAR)
                    .div(data.positionLifetime),
                  16,
                  4
                )}
                %
              </div>
            ) : null}
            {position && data?.positionOutset ? (
              <div>
                <div className="label">
                  Created
                  <Tooltip tip="Date and time when the position was opened" />
                </div>
                {formatDate(data.positionOutset)}
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </Layout>
  );
}

function InputAmount({
  amount,
  setAmount,
  max,
  asset,
  decimals,
  buy,
  tokenSelectable,
}) {
  decimals = decimals || asset.decimals;
  function onSet(percent) {
    setAmount(formatUnits(max.mul(percent).div(100), decimals));
  }
  return (
    <div>
      <div className="flex">
        <div className="flex-1 mb-2">
          Available: {formatNumber(max, decimals)} {asset.symbol}
        </div>
        {buy ? (
          <a
            href={`https://app.1inch.io/#/42161/simple/swap/eth/${asset.symbol.toLowerCase()}`}
            target="_blank"
            rel="noreferrer"
          >
            Purchase {asset.symbol} <Icon name="external-link" small />
          </a>
        ) : null}
      </div>
      <div className="mb-2 flex">
        <Input
          className="flex-1"
          value={amount}
          onInput={(e) => setAmount(e.target.value)}
          placeholder="0.00"
          icon={asset.icon}
          onMax={onSet.bind(null, 100)}
          tokenSelectable={tokenSelectable}
        />
        <button
          className="button button-link button-small mr-2 ml-2"
          onClick={onSet.bind(null, 25)}
        >
          25%
        </button>
        <button
          className="button button-link button-small mr-2"
          onClick={onSet.bind(null, 50)}
        >
          50%
        </button>
        <button
          className="button button-link button-small mr-2"
          onClick={onSet.bind(null, 75)}
        >
          75%
        </button>
        <button
          className="button button-link button-small"
          onClick={onSet.bind(null, 100)}
        >
          100%
        </button>
      </div>
    </div>
  );
}

function InputLeverage({ value, setValue }) {
  const [inputValue, setInputValue] = useState("");

  useEffect(() => {
    setInputValue(parseFloat(value) > 10 ? "10.00" : value);
    // setInputValue(value);
  }, [value]);

  return (
    <div>
      <div className="grid-2" style={{ gridTemplateColumns: "1fr 90px" }}>
        <div className="flex mb-4">
          <DiscreteSliders
            className="w-full"
            min={1}
            max={10}
            value={value}
            range={10}
            onInput={setValue}
          />
        </div>
        <input
          className="input mb-2"
          type="number"
          max={10}
          style={{ width: 90, textAlign: "right" }}
          value={inputValue}
          onInput={(e) =>
            setInputValue(e.target.value > 10 ? "10.00" : e.target.value)
          }
          onBlur={() => setValue(inputValue)}
          placeholder="0.00"
          align="right"
        />
      </div>
    </div>
  );
}

function SlipModal({ strategySlippage, slippage, setSlippage }) {
  const [open, setOpen] = useState(false);
  const [custom, setCustom] = useState((slippage / 100).toFixed(1));

  function adjustSlippage(value) {
    setSlippage(value);
    setCustom((value / 100).toFixed(1));
  }

  function adjustCustomSlippage(value) {
    setSlippage(parseFloat(value) * 100);
    setCustom(value);
  }

  useEffect(() => {
    const close = () => {
      if (open) setOpen(false);
    };
    window.addEventListener("click", close);
    return () => window.removeEventListener("click", close);
  }, [open]);

  return (
    <div className="slip-modal-container" onClick={(e) => e.stopPropagation()}>
      <a className="slip-modal-icon" onClick={() => setOpen(!open)}>
        <Icon name="gear" small /> Slippage ({(slippage / 100).toFixed(1)}%)
      </a>

      {open ? (
        <div className="slip-modal">
          <div className="inner">
            <div className="label mb-2">Slippage Settings</div>

            <button
              className={
                "button button-small flex-1 mr-2 " +
                (slippage === strategySlippage ? "" : "button-link")
              }
              onClick={() => adjustSlippage(strategySlippage)}
            >
              Default ({`${(strategySlippage / 100).toFixed(1)}`}%)
            </button>
            <button
              className={
                "button button-small flex-1 mr-2 " +
                (slippage === 250 ? "" : "button-link")
              }
              onClick={() => adjustSlippage(250)}
            >
              2.5%
            </button>
            <button
              className={
                "button button-small flex-1 " +
                (slippage === 500 ? "" : "button-link")
              }
              onClick={() => adjustSlippage(500)}
            >
              5.0%
            </button>

            <div className="label mt-4">Custom</div>
            <input
              className="input mb-2"
              value={custom}
              onInput={(e) => adjustCustomSlippage(e.target.value)}
              placeholder="0.00"
            />
          </div>
        </div>
      ) : null}
    </div>
  );
}
