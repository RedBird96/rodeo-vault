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

export default function Vault() {

  const { state } = useGlobalState();

  // if (state.pools.length === 0) {
  //   return (
  //     <Layout title="Vault">
  //       <h1 className="title">Overview</h1>
  //       <div className="loading">Loading...</div>
  //       <h1 className="title" style={{ marginTop: 24 }}>Positions</h1>
  //       <div className="position-loading">Loading...</div>
  //     </Layout>
  //   );
  // }
  return (
    <Layout title="Vault">
      <h1 className="title">Overview</h1>
      <div className="grid-2 gap-6">
        <div className="card mb-6">
            <h2 className="title">ETH/WETH/stETH/wstETH</h2>
            <div className="overview-flex">
              <div className="flex-1 label">Gross APY</div>
              <div>
                {formatNumber(0)}%
              </div>
            </div>
            <div className="overview-flex">
              <div className="flex-1 label">Net APY</div>
              <div>
                {formatNumber(0)}%
              </div>
            </div>
            <div className="overview-flex">
              <div className="flex-1 label">TVL (stETH)</div>
              <div>
                {formatNumber(8.6)}K
              </div>
            </div>

            <div className="progressbar">
              <div className="progressbar-data">

              </div>
            </div>

            <div className="overview-flex">
              <div className="flex-1 label">Cap (stETH)</div>
              <div>
                {formatNumber(10)}K
              </div>
            </div>
            <div className="overview-flex">
              <div className="flex-1 label">Safety</div>
              <div className="flex">
                <img src="/assets/color-shield.svg" width={20} height={20}/>
                <img src="/assets/color-shield.svg" width={20} height={20}/>
                <img src="/assets/color-shield.svg" width={20} height={20}/>
                <img src="/assets/color-shield.svg" width={20} height={20}/>
                <img src="/assets/shield.svg" width={20} height={20}/>
              </div>
            </div>
            <div className="overview-flex">
              <div className="flex-1 label">My Net Value</div>
              <div>
                -- ETH
              </div>
            </div>
            <div className="frame-border"></div>

            <div className="overview-flex">
              <div className="flex-1 label">Contract: 0xE946...5F5C</div>
              <a style={{cursor:"pointer"}} href="https://arbiscan.io/address/0xE946Dd7d03F6F5C440F68c84808Ca88d26475FC5" target="_blank">
                <img src="/assets/external-link.svg" width={20} height={20} />
              </a>
            </div>
            <div className="mb-4" style={{marginTop: "20px"}}>
              <Link href={`/vault/detail/0x000`}>
                <a className="button button-small w-full">Details</a>
              </Link>
            </div>            
        </div>
      </div>
      <h1 className="title" style={{ marginTop: 24 }}>Positions</h1>
      <div className="position-loading">Loading...</div>
      
      {/* <div className="farm">
        <div className="grid-4">
          <div>
            <div className="label hide show-phone">#</div>
            
          </div>

          <div>
            <div className="label hide show-phone">Time</div>
          </div>

          <div>
            <div className="label hide show-phone">Amount</div>
          </div>

          <div>
          <div className="label hide show-phone">Status</div>
          </div>
        </div>
      </div> */}
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
