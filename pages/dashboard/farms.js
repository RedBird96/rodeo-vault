import { useState, useEffect } from "react";
import { ethers } from "ethers";
import {
  rpcUrls,
  formatNumber,
  formatAddress,
  useWeb3,
  useGlobalState,
} from "../../utils";

export default function DashboardFarms() {
  const chainId = 42161;
  const { state } = useGlobalState();
  const { contracts } = useWeb3();
  const [data, setData] = useState({});
  const farms = Object.values(data).sort((a, b) =>
    a.value.lt(b.value) ? 1 : -1
  );

  useEffect(() => {
    state.strategies.forEach(async (strategy) => {
      try {
        const s = {
          name: `${strategy.name} (${strategy.protocol})`,
          slug: strategy.slug,
          index: strategy.index,
          address: strategy.address,
        };
        const provider = new ethers.providers.JsonRpcProvider(
          rpcUrls[chainId].http
        );
        const contract = new ethers.Contract(
          s.address,
          [
            "function totalShares() view returns (uint)",
            "function rate(uint) view returns (uint)",
            "function pool() view returns (address)",
            "function minTick() view returns (int24)",
            "function maxTick() view returns (int24)",
          ],
          provider
        );
        s.totalShares = await contract.totalShares();
        s.value = await contract.rate(s.totalShares);
        if (strategy.protocol === "KyberSwap") {
          const minTick = await contract.minTick();
          const maxTick = await contract.maxTick();
          s.minPrice = 1.0001 ** minTick;
          s.maxPrice = 1.0001 ** maxTick;
        }
        if (strategy.apy.type === "uniswapv3") {
          const minTick = await contract.minTick();
          const maxTick = await contract.maxTick();
          s.minPrice = 1.0001 ** minTick * 1e18;
          s.maxPrice = 1.0001 ** maxTick * 1e18;
          const pid = ethers.utils.solidityKeccak256(
            ["address", "int24", "int24"],
            [s.address, minTick, maxTick]
          );
          const pool = new ethers.Contract(
            await contract.pool(),
            [
              "function positions(bytes32) view returns (uint128, uint256, uint256, uint128, uint128)",
            ],
            provider
          );
          s.liquidity = (await pool.positions(pid))[0];
        }
        setData((d) => ({ ...d, [s.index]: s }));
      } catch (e) {
        console.error("farm fetch", e);
      }
    });
  }, [state]);

  return (
    <div className="container">
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Farms</h2>
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
            {farms.map((s) => {
              return (
                <>
                  <tr key={s.index}>
                    <td>{s.index}</td>
                    <td>
                      <a
                        href={`/farm/${s.slug}`}
                        target="_blank"
                        rel="noreferrer"
                      >
                        {s.name}
                      </a>
                    </td>
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
                  {s.liquidity ? (
                    <tr>
                      <td colSpan="4">
                        Shares: {formatNumber(s.totalShares, 9, 1)} Liquidity:{" "}
                        {formatNumber(s.liquidity, 9, 1)} Min:{" "}
                        {formatNumber(s.minPrice, 0, 2)} Max:{" "}
                        {formatNumber(s.maxPrice, 0, 2)}{" "}
                      </td>
                    </tr>
                  ) : s.minPrice ? (
                    <tr>
                      <td colSpan="4">
                        Min: {formatNumber(s.minPrice, 0, 5)} Max:{" "}
                        {formatNumber(s.maxPrice, 0, 5)}{" "}
                      </td>
                    </tr>
                  ) : null}
                </>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
