import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { formatNumber, formatAddress, useWeb3 } from "../../utils";

export default function DashboardOracles() {
  const { contracts, provider, signer } = useWeb3();
  const [data, setData] = useState([]);

  useEffect(() => {
    (async () => {
      const logs = await provider.getLogs({
        fromBlock: 55923155,
        address: "0x72f7101371201CeFd43Af026eEf1403652F115EE",
        topics: [
          "0xb7261e9c33aa7c56209c3bf60b424a8f9551ce28876c0ab3d0c487695e943487",
        ],
      });
      console.log(logs);
      const oracles = {};
      for (let log of logs) {
        const token = log.topics[1].slice(26);
        const oracle = log.topics[2].slice(26);
        oracles[token] = {
          token,
          oracle,
          tokenName: "?",
          decimals: 0,
          answer: 0,
        };
      }
      for (let o of Object.values(oracles)) {
        let tokenName = "?";
        let decimals = 0;
        let answer = 0;
        try {
          const oracle = new ethers.Contract(
            o.oracle,
            [
              "function latestAnswer() view returns (int256)",
              "function decimals() view returns (uint8)",
            ],
            provider
          );
          const t = contracts.asset(o.token);
          tokenName = await t.symbol();
          answer = await oracle.latestAnswer();
          decimals = await oracle.decimals();
        } catch (e) {
          answer = e.message.includes("stale price") ? "stale" : "error";
          console.error(e);
        }
        oracles[o.token].tokenName = tokenName;
        oracles[o.token].decimals = decimals;
        oracles[o.token].answer = answer;
        if (o.oracle.endsWith("4f2d")) {
          oracles[o.token].oracle = "0x00000000";
          oracles[o.token].answer = "dead";
        }
        setData(Object.values(oracles));
      }
    })();
  }, []);

  return (
    <div className="container">
      <div className="card mt-4 mb-4">
        <h2 className="title mt-0">Oracles</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Token</th>
              <th>Oracle</th>
              <th>Answer</th>
            </tr>
          </thead>
          <tbody>
            {data.map((o) => (
              <tr key={o.token}>
                <td>
                  <a
                    href={`https://arbiscan.io/address/${o.token}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    {o.tokenName} {formatAddress(o.token)}
                  </a>
                </td>
                <td>
                  <a
                    href={`https://arbiscan.io/address/${o.oracle}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    {formatAddress(o.oracle)}
                  </a>
                </td>
                <td>
                  {typeof o.answer == "string"
                    ? o.answer
                    : formatNumber(o.answer, o.decimals)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
