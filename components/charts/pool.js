import { useRef, useEffect, useState, useMemo } from "react";
import {
  parseUnits,
  formatNumber,
  formatChartDate,
  ONE,
  YEAR,
  apiServerHost,
} from "../../utils";
import Chart from "../chart";

export default function ChartPool({ decimals, chainId, pool, apr, tvl }) {
  const [tab, setTab] = useState("tvl");
  const [interval, setInterval] = useState("month");
  const [data, setData] = useState([]);

  const dataApr = useMemo(() => {
    return data.slice(0, -1).map((h) => {
      const utilization = parseUnits(h.supply, 0).gt(0)
        ? parseUnits(h.borrow, 0)
            .mul(parseUnits("1"))
            .div(parseUnits(h.supply, 0))
        : 0;
      const apr = parseUnits(h.rate, 0)
        .mul(YEAR)
        .mul(utilization)
        .div(parseUnits("1"));

      return {
        date: new Date(h.t),
        value: parseFloat(ethers.utils.formatUnits(apr, 16)),
      };
    });
  }, [data]);

  const dataTvl = useMemo(() => {
    return data.slice(0, -1).map((h) => {
      const priceAdjusted = parseUnits(h.price, 0)
        .mul(ONE)
        .div(parseUnits("1", decimals));
      const tvl = parseUnits(h.supply, 0).mul(priceAdjusted).div(ONE);
      return {
        date: new Date(h.t),
        value: parseFloat(ethers.utils.formatUnits(tvl, 18)),
      };
    });
  }, [data]);

  async function fetchData() {
    if (!pool) return;
    let intervalParams;
    if (interval == "day") intervalParams = "interval=hour&length=24";
    if (interval == "week") intervalParams = "interval=hour&length=168";
    if (interval == "month") intervalParams = "interval=day&length=30";
    if (interval == "year") intervalParams = "interval=week&length=52";
    const res = await fetch(
      apiServerHost +
        `/pools/history?chain=${chainId}&address=${pool.toLowerCase()}&${intervalParams}`
    );
    if (!res.ok) return;
    setData(await res.json());
  }

  useEffect(() => {
    fetchData().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [pool, interval]);

  return (
    <>
      <div className="font-lg mb-2">
        {tab == "tvl" ? "Total Value Locked" : "Annual Percentage Rate"}
      </div>
      <div className="tabs mb-4">
        <a
          className={`tabs-tab ${tab === "tvl" ? "active" : ""}`}
          onClick={setTab.bind(null, "tvl")}
        >
          TVL
        </a>
        <a
          className={`tabs-tab ${tab === "apr" ? "active" : ""}`}
          onClick={setTab.bind(null, "apr")}
        >
          APR
        </a>
      </div>

      {tab === "tvl" ? (
        <div className="border rounded mb-4">
          <Chart data={dataTvl} />
        </div>
      ) : (
        <div className="border rounded mb-4">
          <Chart data={dataApr} />
        </div>
      )}

      <div className="mb-4">
        <div className="tabs">
          <a
            className={`tabs-tab ${interval === "day" ? "active" : ""}`}
            onClick={() => setInterval("day")}
          >
            Day
          </a>
          <a
            className={`tabs-tab ${interval === "week" ? "active" : ""}`}
            onClick={() => setInterval("week")}
          >
            Week
          </a>
          <a
            className={`tabs-tab ${interval === "month" ? "active" : ""}`}
            onClick={() => setInterval("month")}
          >
            Month
          </a>
          <a
            className={`tabs-tab ${interval === "year" ? "active" : ""}`}
            onClick={() => setInterval("year")}
          >
            Year
          </a>
        </div>
      </div>
    </>
  );
}
