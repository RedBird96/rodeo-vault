import { useState, useEffect } from "react";
import { ethers } from "ethers";
import {
  ONE,
  rpcUrls,
  ADDRESSES,
  strategies,
  parseUnits,
  formatDate,
  formatNumber,
  formatAddress,
  apiServerHost,
} from "../../utils";

export default function DashboardLiquidations() {
  const [data, setData] = useState([]);

  useEffect(() => {
    (async () => {
      //setData([
      //  {
      //    time: "2023-05-10T08:03:12.000Z",
      //    strategy: "0x2B858a16aa9F7B5D0Bc2326259125A390f9400db",
      //    block: "89192851",
      //    earn: "7089824000000000000",
      //    tvl: "98344981179756338866786",
      //  },
      //]);
      setData(await (await fetch(apiServerHost + "/earns")).json());
    })();
  }, []);

  return (
    <div className="container">
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Earns</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Strategy</th>
              <th>Block</th>
              <th>Profit</th>
              <th>TVL</th>
            </tr>
          </thead>
          <tbody>
            {data.map((e) => {
              const networkName = "arbitrum";
              const s = strategies[networkName].find(
                (s) => s.address === e.strategy
              ) || { protocol: "?", name: "" };
              return (
                <tr key={e.time}>
                  <td>{formatDate(e.time)}</td>
                  <td>
                    {s.protocol} {s.name}
                  </td>
                  <td>{e.block}</td>
                  <td>{formatNumber(parseUnits(e.earn, 0))}</td>
                  <td>{formatNumber(parseUnits(e.tvl, 0))}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
