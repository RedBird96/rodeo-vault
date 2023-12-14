import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/router";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useState, useEffect } from "react";
import {
  YEAR,
  pools,
  assets,
  useGlobalState,
  useWeb3,
  formatNumber,
  parseUnits,
  formatUnits,
} from "../../utils";
import Layout from "../../components/layout";
import Tooltip from "../../components/tooltip";

export default function Earn() {
  const { state } = useGlobalState();

  if (state.pools.length === 0) {
    return (
      <Layout title="Earn">
        <h1 className="title">Earn</h1>
        <div className="loading">Loading...</div>
      </Layout>
    );
  }
  return (
    <Layout title="Earn">
      <div className="farms">
        <div className="mb-4">
          <div className="grid-5 label hide-phone">
            <div>Asset</div>
            <div>
              APR
              <Tooltip tip="Annual rate of return when lending funds. Rate is variable depending on pool utilization. Under: base organic rate + liquidity mining rate" />
            </div>
            <div>
              Supply
              <Tooltip tip="Supply: The total value (in USD) which has been deposited into the lending pool\n\nBorrow: The total value (in USD) of the lending pool which has been utilized by Farmers as leverage" />
            </div>
            <div>Cap</div>
            <div></div>
          </div>
        </div>
        {state.pools.map((p, i) => (
          <Pool index={i} state={state} pool={p} key={p.address} />
        ))}
      </div>
    </Layout>
  );
}

function Pool({ index, state, pool }) {
  const router = useRouter();
  const { address, walletStatus, networkName, contracts } = useWeb3();
  const { openConnectModal } = useConnectModal();
  const asset = state.assets[pool.asset];

  return (
    <div className="farm" onClick={() => router.push(`/earn/${pool.slug}`)}>
      <div className="grid-5">
        <div>
          <div className="label hide show-phone">Asset</div>
          <div className="flex">
            <div className="farm-icon hide-phone">
              <Image
                src={asset.icon}
                width={24}
                height={24}
                alt={asset.symbol}
              />
            </div>
            <div>
              <b className="font-xl" style={{ lineHeight: 1 }}>
                {asset.symbol}
              </b>
              <div className="text-faded hide-phone">{asset.name}</div>
            </div>
          </div>
        </div>
        <div>
          <div className="label hide show-phone">APR</div>
          {formatNumber(pool.apr.add(pool.lmApr), 16, 2)}%
          <div className="text-faded font-xs">
            {formatNumber(pool.apr, 16, 2)}% + {formatNumber(pool.lmApr, 16)}%
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Total Supply</div>
          <div>$ {formatNumber(pool.supply, asset.decimals, 0)}</div>
          <div className="text-faded font-xs">
            $ {formatNumber(pool.borrow, asset.decimals, 0)}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Cap</div>
          <div>{formatNumber(pool.cap, asset.decimals, 0)}</div>
          <div className="text-faded font-xs">{asset.symbol}</div>
        </div>
        <div>
          <div className="label hide show-phone">&nbsp;</div>
          <div>
            <Link href={`/earn/${pool.slug}`}>
              <a className="button button-small w-full">Lend</a>
            </Link>
          </div>
        </div>
      </div>
      {pool.apr.gt(parseUnits("0.1")) ? (
        <div className="pool-highapy">
          This pool has a high APY because of high utilization. It could use
          more lenders.
        </div>
      ) : null}
    </div>
  );
}
