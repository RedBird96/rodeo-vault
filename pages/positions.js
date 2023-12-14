import Link from "next/link";
import Image from "next/image";
import { useEffect, useState } from "react";
import Layout from "../components/layout";
import {
  ONE,
  YEAR,
  assets,
  formatNumber,
  getContracts,
  parseUnits,
  pools,
  runTransaction,
  strategies,
  useGlobalState,
  usePositions,
  useWeb3,
} from "../utils";

export default function Positions() {
  const { state } = useGlobalState();
  const { contracts, networkName, address } = useWeb3();
  const [tab, setTab] = useState("active");
  const [lending, setLending] = useState();
  let { data: positions, refetch } = usePositions();
  positions.sort((a, b) => {
    const aActive = a.shares.gt(0);
    const bActive = b.shares.gt(0);
    if (aActive && !bActive) return -1;
    if (bActive && !aActive) return 1;
    return b.id - a.id;
  });
  const activePositions = positions.filter((p) => p.shares.gt(0));

  const shares = activePositions.reduce(
    (t, p) => t.add(p.sharesUsd),
    parseUnits("0")
  );
  const borrow = activePositions.reduce(
    (t, p) => t.add(p.borrowUsd),
    parseUnits("0")
  );
  const profit = activePositions.reduce(
    (t, p) => t.add(p.profitUsd),
    parseUnits("0")
  );
  positions = positions.filter((p) =>
    tab === "active" ? p.shares.gt(0) : p.shares.eq(0)
  );

  useEffect(() => {
    (async () => {
      const pool = state.pools[0];
      if (!pool) return;
      const asset = state.assets[pool?.asset];
      const poolContract = contracts.asset(pool.address);
      const lmValues = await contracts.liquidityMining.users(address);
      let balance = await poolContract.balanceOf(address);
      balance = balance.add(lmValues[0]);
      const value = balance.mul(pool.conversionRate).div(ONE);
      const valueUsd = value
        .mul(pool.price)
        .div(parseUnits("1", asset.decimals));
      setLending({ apr: pool.apr.add(pool.lmApr), valueUsd });
    })();
  }, [networkName, address, state.pools[0]]);

  return (
    <Layout title="Positions">
      <div className="title">Overview</div>
      <div className="grid-4 mb-4">
        <div className="card text-center">
          <div className="label">Your Value</div>
          <div className="font-lg">$ {formatNumber(shares)}</div>
        </div>
        <div className="card text-center">
          <div className="label">Your Borrow</div>
          <div className="font-lg">$ {formatNumber(borrow)}</div>
        </div>
        <div className="card text-center">
          <div className="label">Your Net</div>
          <div className="font-lg">$ {formatNumber(shares.sub(borrow))}</div>
        </div>
        <div className="card text-center">
          <div className="label">Your ROI</div>
          <div className="font-lg">$ {formatNumber(profit)}</div>
        </div>
      </div>
      <div className="title">Lending</div>
      <div className="grid-2 mb-4 w-half">
        <div className="card text-center">
          <div className="label">Value</div>
          <div className="font-lg">
            $ {lending ? formatNumber(lending.valueUsd) : "..."}
          </div>
        </div>
        <div className="card text-center">
          <div className="label">APR</div>
          <div className="font-lg">
            {lending ? formatNumber(lending.apr, 16, 1) : "..."}%
          </div>
        </div>
      </div>
      <div className="flex items-center">
        <div className="title flex-1">Your Positions</div>
        <div className="tabs mb-4" style={{ maxWidth: 210 }}>
          <a
            className={`tabs-tab ${tab === "active" ? " active" : ""}`}
            onClick={() => setTab("active")}
          >
            Active
          </a>
          <a
            className={`tabs-tab ${tab === "closed" ? " active" : ""}`}
            onClick={() => setTab("closed")}
          >
            Closed
          </a>
        </div>
      </div>
      <div className="farms">
        <div className="mb-4">
          <div className="grid-6 label hide-phone">
            <div>Strategy</div>
            <div>Value</div>
            <div>Borrow</div>
            <div>ROI / APY</div>
            <div>Health</div>
            <div></div>
          </div>
        </div>
        {positions.map((p, i) => (
          <Position key={i} state={state} position={p} refetch={refetch} />
        ))}
        {positions.length === 0 ? (
          <div
            className="farm text-center font-lg"
            style={{ padding: "60px 0" }}
          >
            No position yet
          </div>
        ) : null}
      </div>
    </Layout>
  );
}

function Position({ state, position, refetch }) {
  const { networkName, signer } = useWeb3();
  const pool = state.pools.find((p) => p.address === position.pool);
  const asset = state.assets[pool?.asset];
  const strategy = state.strategies.find((s) => s.index === position.strategy);
  const [loading, setLoading] = useState(false);

  let apy = parseUnits("0");
  try {
    apy = strategy.apy
      .mul(position.leverage)
      .div(ONE)
      .sub(pool.apr.mul(position.leverage.sub(ONE)).div(ONE));
  } catch (e) {
    console.error("calc apy", e);
  }

  async function onRemove(id) {
    try {
      setLoading(true);
      const contracts = getContracts(signer, networkName);
      const call = contracts.positionManager.burn(id);
      await runTransaction(
        call,
        "Burning your closed position NFT...",
        "Position NFT burned",
        false,
        networkName
      );
      refetch();
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }
  if (!strategy) return null;

  return (
    <div className="farm">
      <div className="grid-6">
        <div>
          <div className="label hide show-phone">Strategy</div>
          <div className="flex">
            <div className="farm-icon">
              <Image
                src={strategy.icon}
                width={24}
                height={24}
                alt={strategy.protocol}
              />
            </div>
            <div>
              <b className="font-xl" style={{ lineHeight: 1 }}>
                {strategy.name} #{position.id}
              </b>
              <div style={{ opacity: "0.5" }}>{strategy.protocol}</div>
            </div>
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Value</div>${" "}
          {formatNumber(position.sharesUsd)}
          <div style={{ opacity: "0.5" }}>
            {formatNumber(position.sharesAst, asset.decimals)}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Borrow</div>${" "}
          {formatNumber(position.borrowUsd)}
          <div style={{ opacity: "0.5" }}>
            {formatNumber(position.borrowAst, asset.decimals)}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">ROI / APY</div>
          <div>
            $ {formatNumber(position.profitUsd)}
            <div style={{ opacity: "0.5" }}>{formatNumber(apy, 16)}%</div>
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Health</div>
          <div>{formatNumber(position.health)}</div>
        </div>
        <div>
          <div className="label hide show-phone">&nbsp;</div>
          <div>
            {position.shares.gt(0) ? (
              <Link href={`/farm/${strategy?.slug}/${position?.id}`}>
                <a className="button button-small w-full">Details</a>
              </Link>
            ) : (
              <button
                className="button button-link button-small w-full mb-2"
                onClick={() => onRemove(position?.id)}
                disabled={loading}
              >
                {loading ? "Loading..." : "Remove"}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
