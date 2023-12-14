import { useState, useEffect } from "react";
import Image from "next/image";
import {
  ONE,
  ONE6,
  ZERO,
  useGlobalState,
  useWeb3,
  parseUnits,
  formatNumber,
  formatDate,
  apiServerHost,
} from "../utils";

import Tooltip from "../components/tooltip";
import Layout from "../components/layout";

export default function Stats() {
  const { state } = useGlobalState();
  const { contracts, networkName } = useWeb3();
  const [data, setData] = useState({
    largest: [],
    danger: [],
    profit: [],
    earns: [],
    liquidations: [],
  });

  async function fetchData() {
    const data = await (await fetch(apiServerHost + "/analytics")).json();
    data.earns = await (await fetch(apiServerHost + "/earns")).json();
    data.liquidations = await (
      await fetch(apiServerHost + "/liquidations")
    ).json();
    setData(data);
  }

  useEffect(() => {
    fetchData();
  }, [networkName]);

  function renderPositions(positions) {
    return (
      <div className="card mb-8">
        <div className="grid-7 label">
          <div># - Strategy</div>
          <div className="text-right">Value</div>
          <div className="text-right">Borrow</div>
          <div className="text-right">Basis</div>
          <div className="text-right">Profit</div>
          <div className="text-right">Profit %</div>
          <div className="text-right">Life</div>
        </div>
        {positions.map((p) => {
          const s = state.strategies.find((s) => s.index == p.strategy) || {
            name: "?",
            protocol: "",
          };
          const price = parseUnits(p.price, 0);
          const borrow = parseUnits(p.borrow_value, 0).mul(price).div(ONE6);
          const amount = parseUnits(p.amount, 0).mul(price).div(ONE6);
          const profit = parseUnits(p.shares_value, 0).sub(borrow).sub(amount);
          let profitPercent = ZERO;
          if (amount.gt(0)) profitPercent = profit.mul(ONE).div(amount);
          return (
            <div className="grid-7 mt-2" key={p.index}>
              <div className="truncate">
                <b>#{p.index}</b> {s.name} {s.protocol}
              </div>
              <div className="text-right">
                {formatNumber(p.shares_value, 18, 0)}
              </div>
              <div className="text-right">{formatNumber(borrow, 18, 0)}</div>
              <div className="text-right">{formatNumber(amount, 18, 0)}</div>
              <div className="text-right">{formatNumber(profit, 18, 0)}</div>
              <div className="text-right">
                {formatNumber(profitPercent, 16, 1)}%
              </div>
              <div className="text-right">{formatNumber(p.life, 18, 2)}</div>
            </div>
          );
        })}
      </div>
    );
  }

  if (state.pools.length === 0) {
    return (
      <Layout title="Analytics">
        <h1 className="title">Analytics</h1>
        <div className="loading">Loading...</div>
      </Layout>
    );
  }
  return (
    <Layout title="Analytics">
      <div className="title mb-4">Tokenomics</div>
      <div className="grid-2 mb-4">
        <div className="card">
          <div className="label">Price</div>
          <div className="font-xxl font-bold">
            $ {formatNumber(state.tokenomics.tokenPrice, 18, 4)}
          </div>
          <div className="flex mt-2">
            <div className="label m-0 flex-1">Market Cap</div>
            <div className="">
              $ {formatNumber(state.tokenomics.marketCap, 18, 0)}
            </div>
          </div>
          <div className="flex mt-2">
            <div className="label m-0 flex-1">Fully Diluted</div>
            <div className="">
              $ {formatNumber(state.tokenomics.marketCapFullyDilluted, 18, 0)}
            </div>
          </div>
        </div>
        <div className="card">
          <div className="label">Circulating Supply</div>
          <div className="font-xxl font-bold">
            {formatNumber(state.tokenomics.supplyCirculating, 18, 0)}
          </div>
          <div className="flex mt-2">
            <div className="label m-0 flex-1">Max Supply</div>
            <div className="">
              {formatNumber(state.tokenomics.supplyMax, 18, 0)}
            </div>
          </div>
          <div className="flex mt-2">
            <div className="label m-0 flex-1">Total Supply</div>
            <div className="">
              {formatNumber(state.tokenomics.supplyTotal, 18, 0)}
            </div>
          </div>
        </div>
      </div>
      <div className="card mb-8">
        <div className="grid-4">
          <div>
            <div className="label">POL</div>
            <div>{formatNumber(state.tokenomics.supplyPOL, 18, 0)}</div>
          </div>
          <div>
            <div className="label">xRDO</div>
            <div>{formatNumber(state.tokenomics.supplyXRDO, 18, 0)}</div>
          </div>
          <div>
            <div className="label">Ecosystem</div>
            <div>{formatNumber(state.tokenomics.supplyEcosystem, 18, 0)}</div>
          </div>
          <div>
            <div className="label">Partners</div>
            <div>{formatNumber(state.tokenomics.supplyPartners, 18, 0)}</div>
          </div>
          <div>
            <div className="label">Team</div>
            <div>{formatNumber(state.tokenomics.supplyTeam, 18, 0)}</div>
          </div>
          <div>
            <div className="label">Multisig</div>
            <div>{formatNumber(state.tokenomics.supplyMultisig, 18, 0)}</div>
          </div>
          <div>
            <div className="label">Deployer</div>
            <div>{formatNumber(state.tokenomics.supplyDeployer, 18, 0)}</div>
          </div>
        </div>
      </div>

      <div className="title mb-4">Large Positions</div>
      {renderPositions(data.largest)}

      <div className="title mb-4">Profitable Positions</div>
      {renderPositions(data.profit)}

      <div className="title mb-4">Positions Close To Liquidation</div>
      {renderPositions(data.danger)}

      <div className="title mb-4">Recent Liquidations</div>
      <div className="card mb-8">
        <div
          className="grid-5 label"
          style={{ gridTemplateColumns: "1.5fr 1fr 1fr 1fr 1fr" }}
        >
          <div># - Strategy</div>
          <div className="text-right">Basis</div>
          <div className="text-right">Borrow</div>
          <div className="text-right">Fee</div>
          <div className="text-right">Time</div>
        </div>
        {data.liquidations.slice(0, 10).map((p) => {
          const s = state.strategies.find((s) => s.index == p.strategy) || {
            name: "?",
            protocol: "",
          };
          return (
            <div
              className="grid-5 mt-2"
              style={{ gridTemplateColumns: "1.5fr 1fr 1fr 1fr 1fr" }}
              key={p.index}
            >
              <div>
                #{p.index} {s.name} {s.protocol}
              </div>
              <div className="text-right">{formatNumber(p.amount, 18, 0)}</div>
              <div className="text-right">
                {formatNumber(p.data.borrow, 6, 0)}
              </div>
              <div className="text-right">{formatNumber(p.data.fee, 6, 0)}</div>
              <div className="text-right">{formatDate(p.time)}</div>
            </div>
          );
        })}
      </div>

      <div className="title mb-4">Recent Strategy Profit</div>
      <div className="card mb-8">
        <div className="grid-4 label">
          <div>Time</div>
          <div>Strategy</div>
          <div className="text-right">TVL</div>
          <div className="text-right">Profit</div>
        </div>
        {data.earns.slice(0, 10).map((e) => {
          const s = state.strategies.find((s) => s.address == e.strategy) || {
            name: "?",
            protocol: "",
          };
          return (
            <div className="grid-4 mt-2" key={e.time + e.strategy}>
              <div>{formatDate(e.time)}</div>
              <div>
                {s.name} {s.protocol}
              </div>
              <div className="text-right">{formatNumber(e.tvl, 18, 0)}</div>
              <div className="text-right">{formatNumber(e.earn)}</div>
            </div>
          );
        })}
      </div>
    </Layout>
  );
}
