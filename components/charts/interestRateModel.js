import { useMemo } from "react";
import {
  Tooltip,
  LineChart,
  Line,
  XAxis,
  ReferenceLine,
  ResponsiveContainer,
} from "recharts";
import { formatNumber, parseUnits, ONE, YEAR } from "../../utils";

export default function ChartInterestRateModel({ pool, height = 140 }) {
  const kink = parseUnits(pool.rateModelKink, 0);
  const base = parseUnits(pool.rateModelBase, 0);
  const low = parseUnits(pool.rateModelLow, 0);
  const high = parseUnits(pool.rateModelHigh, 0);

  const data = useMemo(() => {
    const data = [];
    for (let i = 0; i <= 100; i += 5) {
      const utilization = parseUnits(String(i), 16);
      const rate = base
        .add(
          utilization.lt(kink)
            ? low.mul(utilization).div(ONE)
            : low
                .mul(kink)
                .div(ONE)
                .add(high.mul(utilization.sub(kink)).div(ONE))
        )
        .mul(YEAR);
      data.push({
        utilization: i,
        rate: rate.mul(10000).div(ONE).toNumber() / 100,
      });
    }
    return data;
  }, [kink, low, high, base]);

  return (
    <ResponsiveContainer width="100%" height={height}>
      <LineChart data={data}>
        <XAxis dataKey="utilization" type="number" hide tickCount={11} />
        <Tooltip content={<CustomTooltip />} />
        <ReferenceLine
          x={pool.utilization.mul(10000).div(ONE).toNumber() / 100}
          stroke="rgba(243,156,15,0.4)"
          strokeWidth="2"
        />
        <Line
          xAxisId={0}
          type="monotone"
          dataKey="rate"
          stroke="#e89028"
          strokeWidth={2}
          dot={false}
          isAnimationActive={false}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

function CustomTooltip({ active, payload, label }) {
  if (active && payload && payload.length) {
    return (
      <div className="chart-tooltip">
        <div>{formatNumber(payload[0].payload.rate, 0, 2)}% APR</div>
        <div className="text-faded">
          {payload[0].payload.utilization}% utilization
        </div>
      </div>
    );
  }

  return null;
}
