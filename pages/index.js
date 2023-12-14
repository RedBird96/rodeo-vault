import { useState, useEffect } from "react";
import Link from "next/link";
import Icon from "../components/icon";
import Layout from "../components/layoutWebsite";
import { Farm } from "./farm/index";
import { ZERO, useGlobalState, formatNumber } from "../utils";

export default function Home() {
  const { state } = useGlobalState();
  const highestApy = state.strategies
    .filter((s) => !s.hidden)
    .sort((a, b) => {
      return parseInt(b.apy.sub(a.apy).toString());
    })[0];

  return (
    <Layout>
      <div className="splash flex">
        <div className="flex-1 mb-4">
          <h1>Leveraged Yield Farming</h1>
          <p className="text-faded">
            Farms with easy, automated and secure leverage on all the top farms
            Arbitrum has to offer. Earn yield on majors in our lending pools
            with better APY that most other lending markets.
          </p>
          <Link href="/farm">
            <a className="button">Launch App</a>
          </Link>
        </div>
        <div className="splash-right">
          <div className="card flex mb-4">
            <div className="flex-1">
              $ {formatNumber(state.tvl || 2000000, 24, 1)}M
            </div>
            <div className="text-faded">TVL</div>
          </div>
          <div className="card">
            <div className="flex">
              <div className="flex-1">
                {highestApy
                  ? formatNumber(highestApy.apyWithLeverage, 16, 1)
                  : "126.0"}
                %
              </div>
              <div className="text-faded">APY</div>
            </div>
            <div
              className="flex items-center border-t"
              style={{ padding: "16px 16px 0", margin: "16px -16px 0" }}
            >
              <div className="flex-1">
                {highestApy?.name || "ETH/USDT"}
                <div className="text-faded">
                  {highestApy?.protocol || "SushiSwap"}
                </div>
              </div>
              <Link href={`/farm/${highestApy?.slug || "sushiswap-eth-usdt"}`}>
                <a>
                  <Icon name="go-button" />
                </a>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="overview" id="overview">
        <h2>Farms</h2>
        <div className="farms">
          {state.strategies
            .filter((s) => !s.hidden)
            .map((s, i) => (
              <Farm homepage key={`farm-${i}`} state={state} strategy={s} />
            ))}
        </div>
      </div>

      <div className="content-why" id="why">
        <h2>Why Rodeo?</h2>

        <p>
          Composable Yield Protocol: Rodeo is a DeFi protocol that allows users
          to earn yield on a diverse range of managed and passive investment
          strategies, though a simple user experience
        </p>

        <div className="cards">
          <div className="card content-card">
            <h4>
              Leverage
              <span>Undercollateralized loans</span>
            </h4>
            <img src="/website/why-leverage.png" />
            <div>
              Rodeo is one of the very few places in DeFi where you can borrow
              more capital than your collateral enabling high yield from
              leverage as high as 10x.
            </div>
          </div>
          <div className="card content-card">
            <h4>
              Lend
              <span>High interest on stables</span>
            </h4>
            <img src="/website/why-lend.png" />
            <div>
              Rodeo lends stables to farmers getting high yield, enabling
              stables holders to safely collect higher yields than offered by
              competing money markets.
            </div>
          </div>
          <div className="card content-card">
            <h4>
              Composable Yield
              <span>Variety of integrated protocols</span>
            </h4>
            <img src="/website/why-decentralized.png" />
            <div>
              Rodeo&rsquo;s core leverage structure allows the secure and
              efficient integration of any sufficiently liquid and profitable
              yield strategy. Covering areas such as: GLP, Concentrated
              Liquidity, LSDs, Managed LP, Yield speculation and more
            </div>
          </div>
        </div>
      </div>

      <div className="home-icons" id="integrations">
        <h2>Integrations</h2>
        <div className="home-icons-row">
          <div className="home-icon">
            <img src="/protocols/gmx.png" />
          </div>
          <div className="home-icon">
            <img src="/protocols/uniswap.svg" />
          </div>
          <div className="home-icon">
            <img src="/protocols/sushiswap.png" />
          </div>
          <div className="home-icon">
            <img src="/protocols/traderjoe.png" />
          </div>
          <div className="home-icon">
            <img src="/protocols/kyberswap.png" />
          </div>
          <div className="home-icon">
            <img src="/protocols/curve.svg" />
          </div>
          <div className="home-icon">
            <img src="/protocols/balancer.svg" />
          </div>
          <div className="home-icon">
            <img src="/protocols/plutusdao.png" />
          </div>
          <div className="home-icon">
            <img src="/protocols/jonesdao.png" />
          </div>
        </div>
      </div>
    </Layout>
  );
}
