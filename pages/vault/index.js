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
  formatAddress,
  formatKNumber,
  parseUnits,
  formatUnits,
} from "../../utils";
import Layout from "../../components/layout";

export default function Vault() {

  const { state } = useGlobalState();

  // test Data
  // const tempData = {
  //   gross_apy: 8,
  //   performance_fee: 0.62,
  //   exit_fee: 0.02,
  //   management_fee: 0.77,
  //   net_apy: 0.2,
  //   tvl: 0,
  //   cap: 0,
  //   locked_amount: 0,
  //   volume: 0,
  //   asset: '0xeA9302eecFAd89cc757AD1c17c241D4e07a16D1d',
  //   address: '0x08eccD9A9A8845Adc96A4e9a8c5f925698d5D532'
  // }

  // state.vault_pools = [];
  // state.vault_pools.push(tempData);

  if (state.vault_pools.length === 0) {
    return (
      <Layout title="Vault">
        <h1 className="title">Overview</h1>
        <div className="loading">Loading...</div>
        <h1 className="title" style={{ marginTop: 24 }}>Positions</h1>
        <div className="position-loading">Loading...</div>
      </Layout>
    );
  }
  
  return (
    <Layout title="Vault">
      <h1 className="title">Overview</h1>
      <div className="grid-2 gap-6">
        {
          state.vault_pools.map((v, i) => {
            return (
              <OverviewVault
                index = {i}
                vault={v}
              />
            )
          })  
        }
        
        {/* <OverviewVault
          index = {0}
          vault={tempData}
        /> */}
      </div>
      {/* <h1 className="title" style={{ marginTop: 24 }}>Positions</h1>
      <div className="position-loading">Loading...</div> */}
      
    </Layout>
  );
}

function OverviewVault({index, vault}) {

  const { provider, signer, address, networkName, contracts, chainId } =
    useWeb3();
  const router = useRouter();
  const assetContract = contracts.asset(vault.asset);
  const vaultContract = contracts.vault(vault.address);
  const [balance, setBalance] = useState(0);
  const [symbol, setSymbol] = useState("");
  const [tvl, setTVL] = useState(0);
  const [capacity, setCapacity] = useState(0);
  const [percentage, setPercentage] = useState(0);

  async function fetchData() {
    if (!assetContract)  return;
    const assetBalance = await assetContract.balanceOf(address);
    const sy = await assetContract.symbol();
    const su = await vaultContract.totalAssets();
    const ca = await vaultContract.marketCapacity();
    setBalance(assetBalance);
    setSymbol(sy);
    setTVL(Number(formatUnits(su)));
    setCapacity(Number(formatUnits(ca)));
    setPercentage(su / ca * 100); 
  }
  useEffect(() => {
    fetchData().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [vault, address, networkName, contracts]);

  const url = "https://arbiscan.io/address/" + vault.address;
  return (
    <div className="card mb-6">
      <h2 className="title">ETH/WETH/wstETH</h2>
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
        <div className="flex-1 label">TVL ({symbol})</div>
        <div>
          {formatNumber(tvl, 2)}
        </div>
      </div>

      <div className="progressbar">
        <div className="progressbar-data" style={{width: percentage}}/>
      </div>

      <div className="overview-flex">
        <div className="flex-1 label">Cap ({symbol})</div>
        <div>
          {formatNumber(capacity, 0)}
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
        <div className="flex-1 label">My Balance</div>
        <div>
          {formatNumber(balance)} {symbol}
        </div>
      </div>
      <div className="frame-border"></div>

      <div className="overview-flex">
        <div className="flex-1 label">{`Contract: ${formatAddress(vault.address)}`}</div>
        <a style={{cursor:"pointer"}} href={url} target="_blank">
          <img src="/assets/external-link.svg" width={20} height={20} />
        </a>
      </div>
      <div className="mb-4" style={{marginTop: "20px"}}>
          <a 
            className="button button-small w-full"
            onClick={() => router.push(`/vault/detail/${vault.address}`)}
          >
            Details
          </a>
      </div>            
    </div>
  );
}