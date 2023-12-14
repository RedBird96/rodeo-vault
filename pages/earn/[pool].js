import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import {
  ONE,
  ONE6,
  YEAR,
  ZERO,
  bnMin,
  formatDate,
  formatChartDate,
  formatError,
  formatNumber,
  formatUnits,
  parseUnits,
  assets,
  pools,
  useGlobalState,
  useWeb3,
  call,
  runTransaction,
  contracts as addresses,
} from "../../utils";
import Layout from "../../components/layout";
import Tooltip from "../../components/tooltip";
import ChartPool from "../../components/charts/pool";
import ChartInterestRateModel from "../../components/charts/interestRateModel";
import ModalPoolDeposit from "../../components/modals/poolDeposit";
import ModalPoolWithdraw from "../../components/modals/poolWithdraw";
import ModalLmDeposit from "../../components/modals/lmDeposit";
import ModalLmWithdraw from "../../components/modals/lmWithdraw";
import ModalLmDepositLp from "../../components/modals/lmDepositLp";
import ModalLmWithdrawLp from "../../components/modals/lmWithdrawLp";
import ModalLmHarvestOrdo from "../../components/modals/lmHarvestOrdo";
import ModalLmWithdraw0 from "../../components/modals/lmWithdraw0";

export default function EarnPool() {
  const router = useRouter();
  const { state } = useGlobalState();
  const { provider, signer, address, networkName, contracts, chainId } =
    useWeb3();
  const pool = state.pools.find((p) => p.slug == router.query.pool);
  const asset = state.assets[pool?.asset] || { symbol: "?" };
  const [modal, setModal] = useState("");
  const [data, setData] = useState({
    value: parseUnits("0"),
    valueInLm: parseUnits("0"),
    balance: parseUnits("0"),
    balanceLp: parseUnits("0"),
    balanceInLm: parseUnits("0"),
    assetBalance: parseUnits("0"),
    allowance: parseUnits("0"),
    allowanceLp: parseUnits("0"),
    allowanceHelper: parseUnits("0"),
    assetAllowance: parseUnits("0"),
    rewardsBalance: parseUnits("0"),
    tvl: parseUnits("0"),
    lmAmount: ZERO,
    lmLp: ZERO,
    lmLock: ZERO,
    lmBoostLp: ZERO,
    lmBoostLock: ZERO,
    lmOwed: ZERO,
    lmValue: ZERO,
    lmLpValue: ZERO,
    lmApr: ZERO,
    ordoBalances: [],
  });
  const enableLm =
    typeof window !== "undefined" && window.location.hash === "#lm";

  async function fetchData() {
    if (!pool || !contracts) return;
    const poolContract = contracts.asset(pool.address);
    const assetContract = contracts.asset(pool.asset);
    const lmValues = await contracts.liquidityMining.users(address);

    const lmData = await call(
      signer,
      addresses.liquidityMining,
      "getUser-uint256,address-uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256",
      0,
      address
    );

    const ordoBalancesData = await call(
      signer,
      addresses.liquidityMiningPluginOrdo,
      "getBalances-address,uint256,uint256-address[],uint256[],uint256[]",
      address,
      10000,
      50
    );
    const ordoBalances = [];
    for (let i in ordoBalancesData[0]) {
      if (ordoBalancesData[2][i].gt(0)) {
        ordoBalances.push({
          token: ordoBalancesData[0][i],
          strike: ordoBalancesData[1][i],
          balance: ordoBalancesData[2][i],
        });
      }
    }

    const data = {
      tvl: parseUnits("0"),
      value: parseUnits("0"),
      valueInLm: parseUnits("0"),
      balance: await poolContract.balanceOf(address),
      balanceLp: await call(
        signer,
        addresses.lpToken,
        "balanceOf-address-uint256",
        address
      ),
      balanceInLm: lmValues[0],
      assetBalance: await assetContract.balanceOf(address),
      allowance: await poolContract.allowance(
        address,
        addresses.liquidityMining
      ),
      allowanceLp: await call(
        signer,
        addresses.lpToken,
        "allowance-address,address-uint256",
        address,
        addresses.liquidityMining
      ),
      allowanceHelper: await call(
        signer,
        pool.asset,
        "allowance-address,address-uint256",
        address,
        addresses.liquidityMiningHelper
      ),
      assetAllowance: await assetContract.allowance(address, pool.address),
      rewardsBalance: await contracts.liquidityMining.getPending(address),
      lmAmount: lmData[0],
      lmLp: lmData[1],
      lmLock: lmData[2],
      lmBoostLp: lmData[3],
      lmBoostLock: lmData[4],
      lmOwed: lmData[5],
      lmValue: lmData[6],
      lmLpValue: lmData[7],
      lmApr: pool.lmApr,
      ordoBalances,
    };

    if (pool.shares.gt(0)) {
      data.value = data.balance.mul(pool.supply).div(pool.shares);
      data.valueInLm = data.balanceInLm.mul(pool.supply).div(pool.shares);
    }
    const priceAdjusted = pool.price
      .mul(ONE)
      .div(parseUnits("1", asset.decimals));
    data.tvl = pool.supply.mul(priceAdjusted).div(ONE);
    setData(data);
  }

  useEffect(() => {
    fetchData().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [pool, networkName, address]);

  async function onClaim() {
    runTransaction(
      call(
        signer,
        addresses.liquidityMining,
        "+harvest-uint256,address,address-",
        0,
        address,
        addresses.liquidityMiningPluginXrdo
      ),
      "Claiming...",
      "Claimed!",
      true,
      "arbitrum"
    );
  }

  async function onExercise(option) {
    const teller = "0xF507733f260a42bB2c8108dE87B7B0Ce5826A9cD";
    const cost = option.balance.mul(option.strike).div(ONE);
    const allowance = await call(
      signer,
      pool.asset,
      "allowance-address,address-uint256",
      address,
      teller
    );
    if (allowance.lt(cost)) {
      await runTransaction(
        call(signer, pool.asset, "+approve-address,uint256", teller, cost),
        "Setting allowance...",
        "Set",
        true,
        "arbitrum"
      );
    }
    runTransaction(
      call(
        signer,
        teller,
        "+exercise-address,uint256-",
        option.token,
        option.balance
      ),
      "Exercising...",
      "Exercised!",
      true,
      "arbitrum"
    );
  }

  return (
    <Layout title={`Earn ${asset.symbol}`} backLink="/earn">
      <div className="grid-4 gap-6 mb-6">
        <div className="card text-center">
          <div className="label">
            Supply APR
            <Tooltip
              tip={`APR from borrowing ${formatNumber(
                pool?.apr || 0,
                16
              )}%. APR from liquidity mining ${formatNumber(
                data.lmApr || 0,
                16
              )}%.`}
            />
          </div>
          <div className="font-xl font-bold">
            {formatNumber(pool ? pool.apr.add(data.lmApr) : 0, 16)}%
          </div>
        </div>
        <div className="card text-center">
          <div className="label">Borrow APR</div>
          <div className="font-xl font-bold">
            {formatNumber(pool ? pool.rate.mul(YEAR) : 0, 16)}%
          </div>
        </div>
        <div className="card text-center">
          <div className="label">Utilization</div>
          <div className="font-xl font-bold">
            {formatNumber(pool ? pool.utilization : 0, 16)}%
          </div>
        </div>
        <div className="card text-center">
          <div className="label">Oracle Price</div>
          <div className="font-xl font-bold">
            $ {formatNumber(pool ? pool.price : 0)}
          </div>
        </div>
      </div>

      <div className="grid-2 gap-6">
        <div>
          <div className="mb-6">
            <div className="grid-2">
              <div className="card text-center">
                <div className="label">Lent</div>
                <div className="font-xl font-bold">
                  {formatNumber(pool ? pool.supply : 0, asset.decimals, 0)}
                </div>
              </div>
              <div className="card text-center">
                <div className="label">Borrowed</div>
                <div className="font-xl font-bold">
                  {formatNumber(pool ? pool.borrow : 0, asset.decimals, 0)}
                </div>
              </div>
            </div>
          </div>

          <div className="font-lg mb-2">Interest Rate Curve</div>
          <div className="border rounded mb-6">
            {pool ? <ChartInterestRateModel pool={pool} /> : null}
          </div>

          <ChartPool
            decimals={asset.decimals}
            chainId={chainId}
            pool={pool?.address}
            apr={pool?.apr}
            tvl={data.tvl}
          />
        </div>

        <div>
          <div className="card mb-6">
            <div className="label">Your {asset.symbol} lent</div>
            <div className="font-xxl font-bold mb-2">
              {formatNumber(
                data.value
                  .add(data.valueInLm)
                  .mul(ONE)
                  .div(parseUnits("1", asset.decimals))
                  .add(data.lmValue)
              )}
            </div>

            <div className="flex">
              <div className="flex-1 label">Wallet</div>
              <div>
                {formatNumber(data.value, asset.decimals)} {asset.symbol}
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">Rodeo Booster</div>
              <div>
                {formatNumber(data.lmValue)} {asset.symbol}
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">Liquidity mining V0</div>
              <div>
                {formatNumber(data.valueInLm, asset.decimals)} {asset.symbol}
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">1 ribUSDC = ? USDC</div>
              <div>{formatNumber(pool?.conversionRate || 0, 18, 4)}</div>
            </div>

            <div className="grid-2 mt-2">
              <button className="button" onClick={() => setModal("deposit")}>
                Deposit
              </button>
              <button
                className="button button-link"
                onClick={() => setModal("withdraw")}
              >
                Withdraw
              </button>
            </div>
          </div>

          <div className="card mb-6">
            <h2 className="title">Rodeo Booster rbLP</h2>

            <div className="flex">
              <div className="flex-1 label">wallet</div>
              <div>
                {formatNumber(data.balance, asset.decimals)} rib{asset.symbol}
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">rib{asset.symbol} staked</div>
              <div>
                {formatNumber(data.lmAmount, asset.decimals)} (${" "}
                {formatNumber(data.lmValue)})
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">RDO/ETH LP staked</div>
              <div>
                {formatNumber(data.lmLp)} ($ {formatNumber(data.lmLpValue)} /{" "}
                {formatNumber(data.lmValue.mul(5).div(100))})
              </div>
            </div>
            <div className="flex mb-4">
              <div className="flex-1 label">Locked until</div>
              <div>{formatDate(data.lmLock)}</div>
            </div>
            <div className="flex">
              <div className="flex-1 label">APR</div>
              <div>{formatNumber(data.lmApr, 16, 1)}%</div>
            </div>
            <div className="flex">
              <div className="flex-1 label">+ lock boost</div>
              <div>
                ({formatNumber(data.lmBoostLock, 16, 1)}%){" "}
                {formatNumber(data.lmApr.mul(data.lmBoostLock).div(ONE), 16, 1)}
                %
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">+ rbLP boost</div>
              <div>
                ({formatNumber(data.lmBoostLp, 16, 1)}%){" "}
                {formatNumber(data.lmApr.mul(data.lmBoostLp).div(ONE), 16, 1)}%
              </div>
            </div>
            <div className="flex mb-4">
              <div className="flex-1 label">Your APR</div>
              <div>
                {formatNumber(
                  data.lmApr
                    .mul(ONE.add(data.lmBoostLock).add(data.lmBoostLp))
                    .div(ONE),
                  16,
                  1
                )}
                %
              </div>
            </div>

            <div className="grid-2 mb-2">
              <button className="button" onClick={() => setModal("depositLm")}>
                Deposit rib{asset.symbol}
              </button>
              <button
                className="button button-link"
                onClick={() => setModal("withdrawLm")}
              >
                Withdraw rib{asset.symbol}
              </button>
            </div>

            <div className="grid-2 mb-4">
              <button
                className="button button-small"
                onClick={() => setModal("depositLmLp")}
              >
                Deposit RDO/ETH LP
              </button>
              <button
                className="button button-small button-link"
                onClick={() => setModal("withdrawLmLp")}
              >
                Withdraw RDO/ETH LP
              </button>
            </div>

            <h2 className="title mb-2">Rewards</h2>

            <div className="card text-center mb-4">
              <div className="label">Owed</div>
              <div className="font-xl font-bold">
                {formatNumber(data.lmOwed)} RDO
              </div>
            </div>

            <div className="grid-2">
              <button
                className="button button-link w-full"
                onClick={() => onClaim()}
              >
                Claim as xRDO
              </button>
              {enableLm ? (
                <button
                  className="button button-link w-full"
                  onClick={() => setModal("harvestOrdo")}
                >
                  Claim as oRDO
                </button>
              ) : (
                <button
                  disabled
                  className="button button-link w-full"
                  onClick={() => {}}
                >
                  Claim as oRDO (soon™)
                </button>
              )}
            </div>

            {data.ordoBalances.map((o) => (
              <div className="card flex items-center mt-4" key={o.token}>
                <div className="flex-1">
                  oRDO <b>{formatNumber(o.balance, 18, 1)}</b> @{" "}
                  <b>${formatNumber(o.strike, 6, 2)}</b>
                </div>
                <div>
                  <button
                    className="button button-small button-link"
                    onClick={() => onExercise(o)}
                  >
                    Exercise for{" "}
                    {formatNumber(o.balance.mul(o.strike).div(ONE), 6, 2)} USDC
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="card mb-6">
            <h2 className="title">Liquidity Mining V0</h2>

            <div className="flex mb-2">
              <div className="flex-1 label">rib{asset.symbol} staked</div>
              <div>{formatNumber(data.balanceInLm, asset.decimals)}</div>
            </div>

            <div className="mb-4">
              <button
                className="button w-full"
                onClick={() => setModal("withdrawLm0")}
              >
                Withdraw
              </button>
            </div>

            <h2 className="title mb-2">Rewards</h2>

            <div className="mb-4">
              <div className="card text-center">
                <div className="label">Earned</div>
                <div className="font-xl font-bold">
                  {formatNumber(data.rewardsBalance)} RDO
                </div>
              </div>
            </div>

            <div className="mb-4">
              Earned tokens will be claimable soon and subject to vesting. The
              ratio will be 80% xRDO, 20% RDO.
            </div>

            <button
              disabled
              className="button button-link w-full"
              onClick={() => {}}
            >
              Claim (soon™)
            </button>
          </div>
        </div>
      </div>
      {modal == "deposit" ? (
        <ModalPoolDeposit
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdraw" ? (
        <ModalPoolWithdraw
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "depositLm" ? (
        <ModalLmDeposit
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLm" ? (
        <ModalLmWithdraw
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "depositLmLp" ? (
        <ModalLmDepositLp
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLmLp" ? (
        <ModalLmWithdrawLp
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "harvestOrdo" ? (
        <ModalLmHarvestOrdo
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLm0" ? (
        <ModalLmWithdraw0
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
    </Layout>
  );
}
