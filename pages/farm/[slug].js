import Link from "next/link";
import Image from "next/image";
import Icon from "../../components/icon";
import { useRouter } from "next/router";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useEffect, useMemo, useState } from "react";
import {
  capitalize,
  DONUT_COLORS,
  bnToFloat,
  parseUnits,
  formatChartDate,
  formatHealthClassName,
  formatNumber,
  useGlobalState,
  usePositions,
  useWeb3,
  apiServerHost,
} from "../../utils";
import {
  Area,
  AreaChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
} from "recharts";
import Layout from "../../components/layout";

export default function Farm() {
  const router = useRouter();
  const { openConnectModal } = useConnectModal();
  const { signer, address, networkName, chainId } = useWeb3();
  const { state } = useGlobalState();
  const { data: positions, refetch: positionsRefetch } = usePositions();
  const strategy = state.strategies.find((s) => s.slug == router.query.slug);
  const positionsFiltered = positions.filter(
    (p) => p.strategy === strategy?.index && p.sharesUsd.gt("0")
  );
  const expChartData = strategy?.assets.map((a) => ({
    name: state.assets[a.address]?.symbol,
    value: a.ratio,
  }));

  const [chartInterval, setChartInterval] = useState(7);
  const [historicType, setHistoricType] = useState("tvl");
  const [histories, setHistories] = useState([]);
  const histChartData = useMemo(
    () => calcChartData(),
    [historicType, histories]
  );

  function onHistoricType(newTab) {
    setHistoricType(newTab);
    setChartInterval(7);
  }

  async function fetchHistories() {
    if (!strategy) return;
    const histories = await (
      await fetch(
        apiServerHost +
          `/apys/history?chain=${chainId}&address=${strategy.address.toLowerCase()}&interval=day&length=${chartInterval}`
      )
    ).json();
    if (histories[histories.length - 1].apy === "0") {
      histories[histories.length - 1].apy = histories[histories.length - 2].apy;
    }
    if (histories[histories.length - 1].tvl === "0") {
      histories[histories.length - 1].tvl = histories[histories.length - 2].tvl;
    }
    setHistories(histories);
  }

  function calcChartData() {
    if (!histories) return [];

    if (historicType == "apy") {
      return histories.map((h) => {
        return {
          date: new Date(h.t),
          apy: bnToFloat(parseUnits(h.apy, 0)),
        };
      });
    }

    if (historicType == "tvl") {
      return histories.map((h) => {
        return {
          date: new Date(h.t),
          tvl: bnToFloat(parseUnits(h.tvl, 0)) / 1e6,
        };
      });
    }
  }

  useEffect(() => {
    positionsRefetch().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [networkName, address]);

  useEffect(() => {
    fetchHistories().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [chartInterval]);

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="chart-tooltip">
          {historicType == "apy" ? (
            <div>APY - {`${formatNumber(payload[0].value * 100)}%`}</div>
          ) : (
            <div>TVL - {`$${formatNumber(payload[0].value, 0, 1) + "M"}`}</div>
          )}
          <div className="text-faded">
            {formatChartDate(payload[0].payload.date)}
          </div>
        </div>
      );
    }

    return null;
  };

  if (!strategy) {
    return (
      <Layout title="Farm: ...">
        <h1 className="title">...</h1>
        <div className="loading">Loading...</div>
      </Layout>
    );
  }
  return (
    <Layout title={strategy.name + " Farm"} backLink="/farm">
      <h2 className="title">Farm Information</h2>
      <div className="mb-4">
        <div className="grid-2" style={{ gridTemplateColumns: "1fr 1fr" }}>
          <div className="card grid-2">
            <div>
              <div className="label">APY</div>
              <span>{formatNumber(strategy.apy, 16, 1) + "%"}</span>
            </div>
            <div>
              <div className="label">TVL</div>
              <span>{"$" + formatNumber(strategy.tvlTotal, 24, 1) + " M"}</span>
            </div>
          </div>
          <div className="card grid-2">
            <div>
              <div className="label">Chain</div>
              <span>{capitalize(networkName)}</span>
            </div>
            <div>
              <div className="label">Protocol</div>
              <span>{strategy.protocol}</span>
            </div>
          </div>
        </div>
      </div>

      <h2 className="title flex items-center">
        <div className="flex-1">Your Positions</div>
        <Link href={`/farm/${strategy?.slug}/new`}>
          <a className="button button-small">New Position</a>
        </Link>
      </h2>

      <div className="mb-6">
        <div className="farms">
          <div className="mb-4">
            <div
              className="grid-7 label hide-phone"
              style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr 1fr 1fr" }}
            >
              <div>#</div>
              <div>Value</div>
              <div>Borrow</div>
              <div>ROI</div>
              <div>Leverage</div>
              <div>Health</div>
              <div></div>
            </div>
          </div>
          {positionsFiltered.map((p, i) => (
            <Position key={i} state={state} position={p} />
          ))}
          {positionsFiltered.length === 0 ? (
            <div
              className="farm text-center font-lg"
              style={{ padding: "60px 0" }}
            >
              No position yet
            </div>
          ) : null}
        </div>
      </div>

      <div className="mb-6">
        <div className="flex items-center">
          <h3 className="title flex-1">Historical Rate</h3>
          <div className="tabs" style={{ position: "relative", top: "-4px" }}>
            <a
              className={`tabs-tab ${historicType === "tvl" ? "active" : ""}`}
              onClick={onHistoricType.bind(null, "tvl")}
            >
              TVL
            </a>
            <a
              className={`tabs-tab ${historicType === "apy" ? "active" : ""}`}
              onClick={onHistoricType.bind(null, "apy")}
            >
              APY
            </a>
          </div>
        </div>
        <div className="card farm-info-card">
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={histChartData}>
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey={historicType}
                stroke="#e89028"
                fill="#e89028"
                strokeWidth={2}
                dot={false}
                isAnimationActive={false}
              />
            </AreaChart>
          </ResponsiveContainer>

          <div className="hist-toggle">
            <a
              className={`mr-4 ${chartInterval === 7 ? "active" : ""}`}
              onClick={() => setChartInterval(7)}
            >
              1W
            </a>
            <a
              className={`mr-4 ${chartInterval === 30 ? "active" : ""}`}
              onClick={() => setChartInterval(30)}
            >
              1M
            </a>
            <a
              className={`mr-4 ${chartInterval === 365 ? "active" : ""}`}
              onClick={() => setChartInterval(365)}
            >
              1Y
            </a>
          </div>
        </div>
      </div>

      <h3 className="title flex items-center">
        <div className="flex-1">Strategy</div>
        <a
          className="button button-link button-small"
          href={`https://arbiscan.io/address/${strategy.address}`}
          target="_blank"
          rel="noreferrer"
        >
          Strategy Contract <Icon name="external-link" small />
        </a>
      </h3>
      <div className="card p-6 mn-6">
        <div>{strategy.description}</div>
      </div>

      <h3 className="title mt-6">Fees</h3>
      <div className="card p-6 mb-6">
        {strategy.fees ? (
          <div className="mb-2">Strategy: {strategy.fees}</div>
        ) : null}
        <div>Rodeo: 10% performance fee on profits</div>
      </div>

      <h3 className="title">Assets</h3>
      <div className="grid-4">
        {strategy.assets.map((a, i) => (
          <div className="card mb-4 flex items-center" key={i}>
            {state.assets[a.address].icon ? (
              <div className="mr-2">
                <Image
                  src={state.assets[a.address].icon}
                  width={24}
                  height={24}
                />
              </div>
            ) : null}
            <div className="flex-1">
              <div className="font-lg font-bold">
                {state.assets[a.address].symbol}
              </div>
              <div className="font-sm text-faded">
                {state.assets[a.address].name}
              </div>
            </div>
            <a
              className="button button-link button-small"
              href={`https://arbiscan.io/address/${a.address}`}
              target="_blank"
              rel="noreferrer"
            >
              <Icon name="external-link" small />
            </a>
          </div>
        ))}
      </div>

      <div className="flex flex-column mb-6">
        <h3 className="title">Exposure</h3>
        <div className="card flex-1">
          <ResponsiveContainer width="100%" height={250}>
            <PieChart width={400} height={400}>
              <Pie
                data={expChartData}
                innerRadius={65}
                outerRadius={90}
                paddingAngle={1}
                dataKey="value"
                startAngle={90}
                endAngle={-270}
                isAnimationActive={false}
              >
                {expChartData.map((entry, index) => (
                  <Cell key={index} fill={DONUT_COLORS[index]} />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>

          <div className="text-center">
            {strategy.assets.map((a, index) => (
              <span key={index} className="mr-2">
                <b>{state.assets[a.address].symbol}</b> {a.ratio}%
              </span>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}

function Position({ state, position }) {
  const { networkName } = useWeb3();
  const pool = state.pools.find((p) => p.address === position.pool);
  const asset = state.assets[pool?.asset];
  const strategy = state.strategies.find((s) => s.index === position.strategy);
  if (!strategy) return null;

  return (
    <div className="farm">
      <div
        className="grid-7"
        style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr 1fr 1fr" }}
      >
        <div>#{position.id}</div>
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
          <div className="label hide show-phone">ROI</div>
          <div>
            $ {formatNumber(position.profitUsd)}
            <div style={{ opacity: "0.5" }}>
              {formatNumber(position.profitPercent, 16)}%
            </div>
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Leverage</div>
          {formatNumber(position?.leverage || 1, 18, 1)}x
        </div>
        <div>
          <div className="label hide show-phone">Health</div>
          <div className={formatHealthClassName(position.health)}>
            {formatNumber(position.health)}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">&nbsp;</div>
          <div>
            <Link href={`/farm/${strategy?.slug}/${position.id}`}>
              <a className="button button-small w-full">Details</a>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
