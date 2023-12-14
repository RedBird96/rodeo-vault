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

  //test Data
  const tempData = {
    gross_apy: 0,
    net_apy: 0,
    tvl: 8.6,
    cap: 10,
    address: '0xE946...5F5C'
  }

  // if (state.vault.length === 0) {
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
        {/* {
          tempData.map((vault, index) => {
            return (
              <OverviewVault
                index = {0}
                vault={tempData}
              />
            )
          })  
        } */}
        
        <OverviewVault
          index = {0}
          vault={tempData}
        />
      </div>
      <h1 className="title" style={{ marginTop: 24 }}>Positions</h1>
      <div className="position-loading">Loading...</div>
      
    </Layout>
  );
}

function OverviewVault({index, vault}) {

  return (
    <div className="card mb-6">
      <h2 className="title">ETH/WETH/stETH/wstETH</h2>
      <div className="overview-flex">
        <div className="flex-1 label">Gross APY</div>
        <div>
          {formatNumber(vault.gross_apy)}%
        </div>
      </div>
      <div className="overview-flex">
        <div className="flex-1 label">Net APY</div>
        <div>
          {formatNumber(vault.net_apy)}%
        </div>
      </div>
      <div className="overview-flex">
        <div className="flex-1 label">TVL (stETH)</div>
        <div>
          {formatNumber(vault.tvl)}K
        </div>
      </div>

      <div className="progressbar">
        <div className="progressbar-data">

        </div>
      </div>

      <div className="overview-flex">
        <div className="flex-1 label">Cap (stETH)</div>
        <div>
          {formatNumber(vault.cap)}K
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
        <div className="flex-1 label">{`Contract: ${vault.address}`}</div>
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
  );
}