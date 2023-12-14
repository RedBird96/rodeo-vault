import { useState, useEffect } from "react";
import { ethers } from "ethers";
import {
  ONE,
  YEAR,
  rpcUrls,
  ADDRESSES,
  parseUnits,
  formatDate,
  formatNumber,
  useWeb3,
  useGlobalState,
  apiServerHost,
} from "../../utils";

const chainIdToNetworkName = { 1337: "localhost", 42161: "arbitrum" };

export default function DashboardPositions() {
  const { contracts } = useWeb3();
  const { state } = useGlobalState();
  const [data, setData] = useState([]);

  useEffect(() => {
    (async () => {
      // testing
      let positions = JSON.parse(
        `[{"id":"1728612018737168","chain":"42161","index":"822","pool":"0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE","strategy":"30","shares":"4319211078692265538412","borrow":"3858893386","shares_value":"4915293131880568168504","borrow_value":"4000539908","life":"1167313286147161140","amount":"879558784","price":"999924000000000000","created":"2023-05-17T13:00:18.637Z","updated":"2023-05-18T00:00:21.659Z"},{"id":"1728597271138320","chain":"42161","index":"821","pool":"0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE","strategy":"12","shares":"671873492375214298480","borrow":"636726613","shares_value":"720065065215890516643","borrow_value":"660098629","life":"1036381192660495539","amount":"55047946","price":"999924000000000000","created":"2023-05-17T12:00:18.149Z","updated":"2023-05-18T00:00:21.895Z"},{"id":"1728538288115728","chain":"42161","index":"820","pool":"0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE","strategy":"30","shares":"217342830828444671536","borrow":"162082548","shares_value":"247337697595919841613","borrow_value":"168032033","life":"1398475436806165696","amount":"78111668","price":"999924000000000000","created":"2023-05-17T08:00:17.997Z","updated":"2023-05-18T00:00:22.125Z"}]`
      );
      // production
      positions = await (await fetch(apiServerHost + "/positions/all")).json();
      for (let p of positions) {
        const networkName = chainIdToNetworkName[p.chain];
        const strategy = state.strategies.find(
          (s) => s.index.toString() === p.strategy
        );
        const pool = state.pools.find((po) => po.address === p.pool);
        const asset = state.assets[pool.asset];
        const price = parseUnits(p.price, 0)
          .mul(ONE)
          .div(parseUnits("1", asset.decimals));
        p.sharesUsd = parseUnits(p.shares_value, 0);
        p.borrowUsd = parseUnits(p.borrow_value, 0).mul(price).div(ONE);
        p.amount = parseUnits(p.amount, 0).mul(price).div(ONE);
        p.profit = p.sharesUsd.sub(p.borrowUsd).sub(p.amount);
        p.profitPercent = parseUnits("0", 0);
        if (p.amount.gt(0)) p.profitPercent = p.profit.mul(ONE).div(p.amount);
        const elapsed = Date.now() - new Date(p.created).getTime();
        p.profitApy = parseUnits("0", 0);
        if (elapsed > 0) {
          p.profitApy = p.profitPercent.mul(YEAR * 1000).div(elapsed);
        }
        p.leverage = ONE;
        if (p.sharesUsd.gt(0) && p.borrowUsd.gt(0)) {
          p.leverage = p.borrowUsd
            .mul(ONE)
            .div(p.sharesUsd.sub(p.borrowUsd))
            .add(ONE);
        }
        p.strategyName =
          (strategy?.protocol || "?") + " " + (strategy?.name || "");
        p.life = parseUnits(p.life, 0);
      }
      setData(positions);
    })();
  }, []);

  async function onOwnerOf(p) {
    try {
      const networkName = chainIdToNetworkName[p.chain];
      const provider = new ethers.providers.JsonRpcProvider(
        rpcUrls[p.chain].http
      );
      const contract = new ethers.Contract(
        ADDRESSES[networkName].positionManager,
        ["function ownerOf(uint) view returns (address)"],
        provider
      );
      window.open(
        "https://arbiscan.io/address/" + (await contract.ownerOf(p.index)),
        "_blank"
      );
    } catch (e) {
      alert("Error fetching owner: ", e);
    }
  }

  function onSort(key) {
    setData(data.slice(0).sort((a, b) => (a[key].lt(b[key]) ? 1 : -1)));
  }

  return (
    <div className="container" style={{ maxWidth: "100%" }}>
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Positions</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Index</th>
              <th>Owner</th>
              <th>Strategy</th>
              <th>
                <a onClick={onSort.bind(null, "sharesUsd")}>Value</a>
              </th>
              <th>
                <a onClick={onSort.bind(null, "borrowUsd")}>Borrow</a>
              </th>
              <th>Basis</th>
              <th>
                <a onClick={onSort.bind(null, "profit")}>Profit</a>
              </th>
              <th>Profit %</th>
              <th>
                <a onClick={onSort.bind(null, "profitApy")}>Profit APY</a>
              </th>
              <th>
                <a onClick={onSort.bind(null, "leverage")}>Leverage</a>
              </th>
              <th>
                <a onClick={onSort.bind(null, "life")}>Health</a>
              </th>
              <th>Created</th>
            </tr>
          </thead>
          <tbody>
            {data.map((p) => {
              return (
                <tr key={p.id}>
                  <td>
                    <a
                      href={`/dashboard/positions/${p.chain}-${p.index}`}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {p.index}
                    </a>
                  </td>
                  <td>
                    <a onClick={() => onOwnerOf(p)}>Owner</a>
                  </td>
                  <td>{p.strategyName}</td>
                  <td>${formatNumber(p.sharesUsd)}</td>
                  <td>${formatNumber(p.borrowUsd)}</td>
                  <td>${formatNumber(p.amount)}</td>
                  <td>${formatNumber(p.profit)}</td>
                  <td>{formatNumber(p.profitPercent, 16, 1)}%</td>
                  <td>{formatNumber(p.profitApy, 16, 1)}%</td>
                  <td>{formatNumber(p.leverage, 18, 1)}x</td>
                  <td>{formatNumber(p.life)}</td>
                  <td>{formatDate(p.created)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
