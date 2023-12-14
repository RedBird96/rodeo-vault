import { useState, useEffect } from "react";
import { ethers } from "ethers";
import {
  parseUnits,
  formatDate,
  formatNumber,
  useWeb3,
  useGlobalState,
  apiServerHost,
} from "../../utils";

export default function DashboardLiquidations() {
  const { state } = useGlobalState();
  const [data, setData] = useState([]);

  useEffect(() => {
    (async () => {
      setData(await (await fetch(apiServerHost + "/liquidations")).json());
    })();
  }, []);

  if (state.pools.length === 0) return <div>Loading...</div>;
  return (
    <div className="container">
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Liquidations</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Index</th>
              <th>Strategy</th>
              <th>Pool</th>
              <th>Value</th>
              <th>Borrow</th>
              <th>Fee</th>
              <th>Created</th>
              <th>Liquidated</th>
            </tr>
          </thead>
          <tbody>
            {data.map((p) => {
              const networkName = "arbitrum";
              const strategy = state.strategies.find(
                (s) => s.index.toString() === p.strategy
              );
              const pool = state.pools.find((po) => po.address === p.pool);
              const asset = state.assets[pool.asset];
              return (
                <tr key={p.id}>
                  <td>{p.index}</td>
                  <td>{strategy?.name || "?"}</td>
                  <td>{asset.symbol}</td>
                  <td>{p.data.amount}</td>
                  <td>
                    {formatNumber(parseUnits(p.data.borrow, 0), asset.decimals)}
                  </td>
                  <td>
                    {formatNumber(parseUnits(p.data.fee, 0), asset.decimals)}
                  </td>
                  <td>{formatDate(p.created)}</td>
                  <td>{formatDate(p.time)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
