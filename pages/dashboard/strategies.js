import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { formatNumber, formatAddress, useWeb3 } from "../../utils";

export default function DashboardStrategies() {
  const { contracts, signer } = useWeb3();
  const [data, setData] = useState([]);

  useEffect(() => {
    (async () => {
      const strategies = [];
      const nextStrategy = await contracts.investor.nextStrategy();
      for (let i = 0; i < nextStrategy; i++) {
        const address = await contracts.investor.strategies(i);
        const strategyContract = new ethers.Contract(
          address,
          [
            "function name() view returns (string)",
            "function totalShares() view returns (uint)",
            "function rate(uint) view returns (uint)",
          ],
          signer
        );
        let name = "?";
        let value = 0;
        try {
          name = await strategyContract.name();
          value = await strategyContract.rate(
            await strategyContract.totalShares()
          );
        } catch (e) {
          console.error(i, e);
        }
        strategies.push({
          index: i,
          address: address,
          name: name,
          value: value,
        });
        setData([...strategies]);
      }
      setData([...strategies]);
    })();
  }, []);

  return (
    <div className="container">
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Strategies</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Index</th>
              <th>Name</th>
              <th>Contract</th>
              <th>Value</th>
            </tr>
          </thead>
          <tbody>
            {data.map((s) => (
              <tr key={s.index}>
                <td>{s.index}</td>
                <td> {s.name} </td>
                <td>
                  <a
                    href={`https://arbiscan.io/address/${s.address}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    {formatAddress(s.address)}
                  </a>
                </td>
                <td>${formatNumber(s.value || 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
