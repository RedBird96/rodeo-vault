import { Area, AreaChart, ResponsiveContainer, Tooltip } from "recharts";
import { formatNumber, formatChartDate } from "../utils";

export default function Chart({ data, onHover, height = 300 }) {
  function onMouseMove(data) {
    if (!data || !data.activePayload) return;
    if (onHover) onHover(data.activePayload[0].payload);
  }

  function onMouseOut() {
    if (onHover) onHover(null);
  }

  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={data} onMouseMove={onMouseMove} onMouseOut={onMouseOut}>
        <Tooltip content={<CustomTooltip />} />
        <Area
          dataKey="value"
          type="monotone"
          stroke="#e89028"
          fill="#e89028"
          strokeWidth={2}
          dot={false}
          isAnimationActive={false}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="chart-tooltip">
        <div>{formatNumber(parseFloat(payload[0].value))}</div>
        <div className="text-faded">
          {formatChartDate(payload[0].payload.date)}
        </div>
      </div>
    );
  }

  return null;
};
