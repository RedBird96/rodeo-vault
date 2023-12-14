import Image from "next/image";
import { useRouter } from "next/router";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useState, useEffect, useMemo } from "react";
import { ethers } from "ethers";
import {
  ZERO,
  ONE,
  YEAR,
  formatNumber,
  useWeb3,
  usePositions,
  useGlobalState,
} from "../../utils";
import Layout from "../../components/layout";
import Tooltip from "../../components/tooltip";
import Dropdown from "../../components/dropdown";
import SortCaret from "../../components/sortCaret";

const filterOptions = {
  name: "Name",
  position: "Position Value",
  apy: "APY",
  tvlTotal: "TVL",
};

export default function Farms() {
  const { state } = useGlobalState();
  const [protocol, setProtocol] = useState([]);
  const [asset, setAsset] = useState([]);
  const [sortBy, setSortBy] = useState([]);
  const [sortOrder, setSortOrder] = useState(0);
  const [search, setSearch] = useState("");
  const { data: positions } = usePositions();
  const showHidden = useMemo(
    () =>
      typeof window !== "undefined"
        ? window.location.hash === "#hidden"
        : false,
    []
  );

  const protocols = state.strategies.reduce((a, s) => {
    a[s.protocol] = s.protocol;
    return a;
  }, {});
  const assets = state.strategies.reduce((a, s) => {
    s.name.split("/").forEach((t) => (a[t] = t));
    return a;
  }, {});

  const activePositions = positions.filter((p) => p.shares.gt(0));
  const shares = activePositions.reduce((t, p) => t.add(p.sharesUsd), ZERO);
  const borrow = activePositions.reduce((t, p) => t.add(p.borrowUsd), ZERO);
  const profit = activePositions.reduce((t, p) => t.add(p.profitUsd), ZERO);
  const averageApy = shares.gt(0)
    ? activePositions
        .reduce(
          (t, p) =>
            t.add(
              p.sharesUsd.mul(
                state.strategies.find((s) => s.index === p.strategy)?.apy || 0
              )
            ),
          ZERO
        )
        .div(shares)
    : ZERO;
  const monthlyYield = shares
    .mul(averageApy.sub((state.pools[0]?.rate || ZERO).mul(YEAR)))
    .div(ONE.mul(12));

  let filteredStrategies = state.strategies.filter(
    (s) => !s.hidden || showHidden
  );
  filteredStrategies.forEach((s) => {
    s.position = positions.reduce((a, p) => {
      if (p.strategy === s.index) return a.add(p.sharesUsd);
      return a;
    }, ZERO);
  });
  if (protocol.length > 0) {
    filteredStrategies = filteredStrategies.filter((s) =>
      protocol.includes(s.protocol)
    );
  }
  if (asset.length > 0) {
    filteredStrategies = filteredStrategies.filter((s) => {
      return s.name.split("/").some((t) => asset.includes(t));
    });
  }
  if (sortBy.length > 0) {
    // 0: nothing, 1: ascending, 2: descending
    console.log(sortBy[0]);
    if (sortOrder == 0 || sortOrder == 1) {
      filteredStrategies = filteredStrategies.sort((a, b) => {
        if (sortBy[0] === "name") {
          return (a.protocol + a.name).localeCompare(b.protocol + b.name);
        }
        return parseInt(a[sortBy[0]].sub(b[sortBy[0]]).toString());
      });
    } else {
      filteredStrategies = filteredStrategies.sort((a, b) => {
        if (sortBy[0] === "name") {
          return (b.protocol + b.name).localeCompare(a.protocol + a.name);
        }
        return parseInt(b[sortBy[0]].sub(a[sortBy[0]]).toString());
      });
    }
  }
  if (search.length > 0) {
    filteredStrategies = filteredStrategies.filter(
      (s) =>
        s.protocol.toUpperCase().includes(search.toUpperCase()) ||
        s.name.toUpperCase().includes(search.toUpperCase())
    );
  }

  if (state.pools.length <= 0) {
    return (
      <Layout title="Farms">
        <div className="title">Farms</div>
        <div className="loading">Loading...</div>
      </Layout>
    );
  }

  return (
    <Layout title="Farms">
      <div className="grid-2 mb-6" style={{ gridTemplateColumns: "3fr 1fr" }}>
        <div>
          <div className="title">Portfolio</div>
          <div
            className="card grid-5"
            style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr" }}
          >
            <div>
              <div className="label">
                Value
                <Tooltip tip="The total value (in USD) of all your Farm positions in Rodeo. Including collateral + borrowed leverage" />
              </div>
              <div className="font-lg">$ {formatNumber(shares)}</div>
            </div>
            <div>
              <div className="label">
                Borrow
                <Tooltip tip="The total value (in USD) you have borrowed, as leverage, in all Farm positions" />
              </div>
              <div className="font-lg">$ {formatNumber(borrow)}</div>
            </div>
            <div>
              <div className="label">
                Profit
                <Tooltip tip="The total profit or losses (in USD) compared to the original collateral deposited. Slippage fees to exit positions are not included" />
              </div>
              <div className="font-lg">$ {formatNumber(profit)}</div>
            </div>
            <div>
              <div className="label">Monthly Yield</div>
              <div className="font-lg">$ {formatNumber(monthlyYield)}</div>
            </div>
            <div>
              <div className="label">
                Avg. APY
                <Tooltip tip="The APY of all open farm positions a user has averaged together. This is based on net APYs after the borrow fees have been subtracted" />
              </div>
              <div className="font-lg">{formatNumber(averageApy, 16, 1)}%</div>
            </div>
          </div>
        </div>
        <div>
          <div className="title">Protocol</div>
          <div className="card">
            <div>
              <div className="label">
                TVL
                <Tooltip tip="The Total Value (in USD) locked in Rodeo farm positions and lending pools" />
              </div>
              <div className="font-lg">$ {formatNumber(state.tvl, 24, 1)}M</div>
            </div>
          </div>
        </div>
      </div>

      <div
        className="grid-4 mb-6"
        style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr" }}
      >
        <div>
          <div style={{ position: "relative" }}>
            <Dropdown
              tokenList={protocols}
              setSelected={setProtocol}
              selected={protocol}
              header="Platform"
              multiSelect
            />
          </div>
        </div>
        <div>
          <div style={{ position: "relative" }}>
            <Dropdown
              tokenList={assets}
              setSelected={setAsset}
              selected={asset}
              header="Asset"
              multiSelect
            />
          </div>
        </div>
        <div>
          <div style={{ position: "relative" }}>
            <Dropdown
              tokenList={filterOptions}
              setSelected={setSortBy}
              selected={sortBy}
              header="Sort by"
            />
          </div>
        </div>
        <div>
          <input
            className="input"
            placeholder="Search..."
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="farms card">
        <div className="farms-labels mb-4">
          <div className="grid-6 label hide-phone">
            <div className="flex">
              <span
                onClick={() => {
                  setSortOrder(sortBy[0] !== "name" ? 1 : (sortOrder + 1) % 3);
                  setSortBy(["name"]);
                }}
                style={{ cursor: "pointer" }}
              >
                Name
              </span>
              <SortCaret
                style={{ marginLeft: 5 }}
                order={sortBy[0] === "name" ? sortOrder : 0}
              />
            </div>
            <div className="flex">
              <span
                onClick={() => {
                  setSortOrder(
                    sortBy[0] !== "position" ? 1 : (sortOrder + 1) % 3
                  );
                  setSortBy(["position"]);
                }}
                style={{ cursor: "pointer" }}
              >
                Position Value
              </span>
              <SortCaret
                style={{ marginLeft: 5 }}
                order={sortBy[0] === "position" ? sortOrder : 0}
              />
              <Tooltip tip="The total value (in USD) of your specific Farm position in Rodeo. This includes collateral + borrowed leverage" />
            </div>
            <div className="flex">
              <span
                style={{ cursor: "pointer" }}
                onClick={() => {
                  setSortOrder(
                    sortBy[0] !== "leverage" ? 1 : (sortOrder + 1) % 3
                  );
                  setSortBy(["leverage"]);
                }}
              >
                Leverage
              </span>
              <SortCaret
                style={{ marginLeft: 5 }}
                order={sortBy[0] === "leverage" ? sortOrder : 0}
              />
              <Tooltip tip="Assumed leverage for the APY number displayed. You can use from 1x leverage up to 10x leverage." />
            </div>
            <div className="flex">
              <span
                onClick={() => {
                  setSortOrder(sortBy[0] !== "apy" ? 1 : (sortOrder + 1) % 3);
                  setSortBy(["apy"]);
                }}
                style={{ cursor: "pointer" }}
              >
                APY
              </span>
              <SortCaret
                style={{ marginLeft: 5 }}
                order={sortBy[0] === "apy" ? sortOrder : 0}
              />
              <Tooltip tip="APY for this farm when using leverage in previous column, after subtracting borrowing fees" />
            </div>
            <div className="flex">
              <span
                onClick={() => {
                  setSortOrder(sortBy[0] !== "tvl" ? 1 : (sortOrder + 1) % 3);
                  setSortBy(["tvl"]);
                }}
                style={{ cursor: "pointer" }}
              >
                TVL
              </span>
              <SortCaret
                style={{ marginLeft: 5 }}
                order={sortBy[0] === "tvl" ? sortOrder : 0}
              />
              <Tooltip tip="Total Value Locked (TVL) of this farm's target farm/vault/pool. A higher TVL usually means less risky (Under: TVL in Rodeo's contract)" />
            </div>
            <div></div>
          </div>
        </div>
        {filteredStrategies.map((s, i) => (
          <Farm key={`farm-${i}`} strategy={s} positions={activePositions} />
        ))}
      </div>
    </Layout>
  );
}

export function Farm({ homepage = false, strategy, positions }) {
  const router = useRouter();
  const { walletStatus } = useWeb3();
  const { openConnectModal } = useConnectModal();

  function onOpen() {
    if (walletStatus === "disconnected") {
      openConnectModal();
      return;
    }
    router.push(`/farm/${strategy.slug}`);
  }

  return (
    <div className="farm" onClick={onOpen}>
      <div className={`${homepage ? "grid-5" : "grid-6"}`}>
        <div>
          <div className="label hide show-phone">Name</div>
          <div className="flex">
            <div className="farm-icon hide-phone">
              <Image
                src={strategy.icon}
                width={24}
                height={24}
                alt={strategy.protocol}
              />
            </div>
            <div>
              <b className="font-xl" style={{ lineHeight: 1 }}>
                {strategy.name}
                {strategy.isNew ? (
                  <span className="farm-note tooltip">
                    Wild West
                    <span className="tooltip-box">
                      Danger! New and un-audited farm
                    </span>
                  </span>
                ) : null}
              </b>
              <div className="text-faded hide-phone">{strategy.protocol}</div>
            </div>
          </div>
        </div>
        {!homepage ? (
          <div>
            <div className="label hide show-phone">Position Value</div>
            <div>$ {formatNumber(strategy.position)}</div>
          </div>
        ) : null}
        <div>
          <div className="label hide show-phone">Leverage</div>
          {formatNumber(strategy.leverage || 0, 18, 0)}x
          {homepage ? (
            <div className="text-faded hide-phone">Leverage</div>
          ) : null}
        </div>
        <div>
          <div className="label hide show-phone">APY</div>
          <div style={{ color: "var(--primary)" }}>
            {formatNumber(strategy.apyWithLeverage || 0, 16, 2) + "%"}
          </div>
          <div style={{ textDecoration: "line-through" }}>
            {formatNumber(strategy.apy, 16, 2) + "%"}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">TVL</div>
          <div>{formatNumber(strategy.tvlTotal, 24, 1)}M</div>
          <div className="text-faded hide-phone">
            {homepage ? "TVL" : formatNumber(strategy.tvl, 21, 1) + "K"}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">&nbsp;</div>
          <div>
            <a className="button button-small w-full" onClick={onOpen}>
              Farm
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
