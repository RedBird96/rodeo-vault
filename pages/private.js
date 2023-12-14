import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/router";
import { useState, useEffect } from "react";
import {
  Area,
  AreaChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
} from "recharts";
import Layout from "../components/layout";
import Tooltip from "../components/tooltip";
import {
  ONE,
  ZERO,
  DONUT_COLORS,
  formatNumber,
  parseUnits,
  useWeb3,
  runTransaction,
} from "../utils";
import Input from "../components/input";

export default function PrivateSale() {
  const { contracts, address, networkName } = useWeb3();
  const zero = parseUnits("0");
  const [data, setData] = useState({
    allocation: zero,
    deposited: zero,
    balance: zero,
    rewardsTotal: zero,
    rewardsClaimed: zero,
    rewardsUserTotal: zero,
    rewardsUserClaimed: zero,
    rewardsUserAvailable: zero,
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [amount, setAmount] = useState("");
  const price = parseUnits("0.055266435306041666", 18);
  const owed = data.deposited.mul(parseUnits("1", 30)).div(price);
  let allowanceOk = true;
  try {
    const parsedAmount = parseUnits(amount, 6);
    allowanceOk = parsedAmount.lte(data.allowance);
  } catch (e) {}

  async function fetchData() {
    const info = await contracts.privateInvestors.getUser(address);
    const rewards = await contracts.privateInvestorsRewarder.getInfo(address);
    setData({
      deposited: info[0],
      allocation: info[1],
      rewardsTotal: rewards[0],
      rewardsClaimed: rewards[2],
      rewardsUserTotal: rewards[1],
      rewardsUserClaimed: rewards[3],
      rewardsUserAvailable: rewards[1].sub(rewards[3]),
    });
  }

  useEffect(() => {
    fetchData();
  }, [address]);

  async function onClaimRewards() {
    const call = await contracts.privateInvestorsRewarder.claim();
    await runTransaction(call, "Claiming...", "Claimed!", true, networkName);
    fetchData();
    setTimeout(fetchData, 5000);
  }

  const chartData = [
    { value: 960 },
    { value: 12000 },
    { value: 4500 },
    { value: 2790 },
    { value: 100000 - 960 - 12000 - 4500 - 2790 },
  ];

  return (
    <Layout title="Private Investors" hideWarning>
      <div className="flex" style={{ gap: 24 }}>
        <div className="flex-1 flex flex-column">
          <div className="card p-0" style={{ border: 0 }}>
            <div
              className="p-6"
              style={{ borderBottom: "1px solid rgba(0, 0, 0, 0.15)" }}
            >
              <h2 className="title mt-0">Vesting</h2>
              <div className="mb-2 flex">
                <div className="flex flex-2 justify-between">
                  <div className="title--item-sub">Your tokens</div>
                </div>
                <div className="flex flex-3 justify-end title--item">
                  {formatNumber(owed, 18, 2)} RDO
                </div>
              </div>
            </div>
            <div className="p-6">
              <div className="claim-btn-group">
                <button
                  onClick={() => (window.location.href = "/vesting")}
                  className="button w-full"
                >
                  Claim to wallet
                </button>
                <button
                  onClick={() => alert("Coming soon...")}
                  className="button w-full mt-2"
                >
                  Claim all as xRDO (+20% apy dividends 💸)
                </button>
                <button
                  onClick={() => alert("Coming soon...")}
                  className="button w-full mt-2"
                >
                  Claim and zap to LP (+50% apy rewards 🔥)
                </button>
              </div>
            </div>
          </div>

          <div className="card p-0 mt-6" style={{ border: 0 }}>
            <div
              className="p-6"
              style={{ borderBottom: "1px solid rgba(0, 0, 0, 0.15)" }}
            >
              <h2 className="title mt-0">Rewards from xRDO exits</h2>

              <div className="flex mb-2 text-faded">
                <div className="flex-1">Total Rewarded</div>
                <div>{formatNumber(data.rewardsTotal)} RDO</div>
              </div>
              <div className="flex mb-4 text-faded">
                <div className="flex-1">Total Claimed</div>
                <div>{formatNumber(data.rewardsClaimed)} RDO</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Your Share</div>
                <div>
                  {formatNumber(
                    data.rewardsTotal.gt(0)
                      ? data.rewardsUserTotal.mul(ONE).div(data.rewardsTotal)
                      : ZERO,
                    16,
                    3
                  )}
                  %
                </div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Your Rewards</div>
                <div>{formatNumber(data.rewardsUserTotal)} RDO</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Claimed</div>
                <div>{formatNumber(data.rewardsUserClaimed)} RDO</div>
              </div>
              <div className="flex mb-4 text-faded">
                <div className="flex-1">Available</div>
                <div>{formatNumber(data.rewardsUserAvailable)} RDO</div>
              </div>

              <button onClick={onClaimRewards} className="button w-full">
                Claim and start vesting
              </button>
            </div>
          </div>
        </div>

        <div className="flex-1 flex flex-column">
          <div className="card p-0 mb-6">
            <div
              className="p-6"
              style={{ borderBottom: "1px solid rgba(0, 0, 0, 0.15)" }}
            >
              <h2 className="title mt-0">Results</h2>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Private Raised</div>
                <div>$ 735,411.62</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Private Price</div>
                <div>$ 0.05527</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Private Tokens</div>
                <div>13,306,659.16</div>
              </div>
            </div>
            <div
              className="p-6"
              style={{ borderBottom: "1px solid rgba(0, 0, 0, 0.15)" }}
            >
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Public Sold</div>
                <div>$ 1,061,115.56</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Public Price</div>
                <div>$ 0.08843</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Public Tokens</div>
                <div>12,000,000.00</div>
              </div>
            </div>
            <div className="p-6">
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Market Cap</div>
                <div>$ 1,790,632.50</div>
              </div>
              <div className="flex mb-2 text-faded">
                <div className="flex-1">Fully Diluted Value</div>
                <div>$ 8,842,629.65</div>
              </div>
            </div>
          </div>

          <div className="card p-6 w-full flex flex-column justify-between mb-6">
            <div className="flex justify-between">
              <label className="heading--sub">Circulating Supply</label>
              <div className="heading--sub">
                {formatNumber(20250000, 18, 0)}
              </div>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <PieChart width={200} height={200}>
                <Pie
                  data={chartData}
                  innerRadius={85}
                  outerRadius={95}
                  dataKey="value"
                  startAngle={90}
                  endAngle={-270}
                  isAnimationActive={false}
                  stroke="none"
                >
                  {[2, 0, 3, 2, 1].map((entry, index) => (
                    <Cell key={index} fill={DONUT_COLORS[entry]} />
                  ))}
                </Pie>
                <Pie
                  data={chartData}
                  innerRadius={45}
                  outerRadius={75}
                  startAngle={90}
                  endAngle={-270}
                  isAnimationActive={false}
                  stroke="none"
                  dataKey="value"
                >
                  {[2, 0, 3, 2, 1].map((entry, index) => (
                    <Cell key={index} fill={DONUT_COLORS[entry]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>

            <div className="flex mb-2 text-faded">
              <div className="flex-1">Circulating Private</div>
              <div>960,000</div>
            </div>
            <div className="flex mb-2 text-faded">
              <div className="flex-1">Circulating Public</div>
              <div>12,000,000</div>
            </div>
            <div className="flex mb-2 text-faded">
              <div className="flex-1">POL</div>
              <div>4,500,000</div>
            </div>
            <div className="flex mb-4 text-faded">
              <div className="flex-1">Other</div>
              <div>2,790,000</div>
            </div>
            <div className="flex text-faded">
              <div className="flex-1">Max Supply</div>
              <div>100,000,000</div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
