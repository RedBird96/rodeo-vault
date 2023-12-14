import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import {
  ONE,
  ONE6,
  YEAR,
  ZERO,
  bnMin,
  formatDate,
  formatChartDate,
  formatError,
  formatNumber,
  formatUnits,
  parseUnits,
  assets,
  pools,
  useGlobalState,
  useWeb3,
  call,
  runTransaction,
  contracts as addresses,
} from "../../../utils";
import Layout from "../../../components/layout";
import ModalPoolDeposit from "../../../components/modals/poolDeposit";
import ModalPoolWithdraw from "../../../components/modals/poolWithdraw";
import ModalLmDeposit from "../../../components/modals/lmDeposit";
import ModalLmWithdraw from "../../../components/modals/lmWithdraw";
import ModalLmDepositLp from "../../../components/modals/lmDepositLp";
import ModalLmWithdrawLp from "../../../components/modals/lmWithdrawLp";
import ModalLmHarvestOrdo from "../../../components/modals/lmHarvestOrdo";
import ModalLmWithdraw0 from "../../../components/modals/lmWithdraw0";

export default function VaultPool() {
  const router = useRouter();
  const { state } = useGlobalState();
  const { provider, signer, address, networkName, contracts, chainId } =
    useWeb3();

  // const pool = state.pools.find((p) => p.slug == router.query.pool);
  // const asset = state.assets[pool?.asset] || { symbol: "?" };
  const [modal, setModal] = useState("");
  const [data, setData] = useState({
    wstLockedAmount: 8601.71717429,
    wstLockedUSDAmount: 22.03,
    ethDepositedAmount: 1.58,
    totalDepositedAmount: 1.82,
    depositedGrossAPY: 8,
    platformFee: 0.77,
    annualFee: 0,
    performanceFee: 0.58,
    exitFee: 0.02,
    myNetValue: 0,
    myNetEarning: 0,
    myNetLP: 0
  });

  return (
    <Layout title="Vault stETH" backLink="/vault">
      <h1 className="title">Details</h1>
      <div className="grid-2--custom gap-6">
        <div>
          <div className="card mb-6">
            <h3>Vault Configuration</h3>
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#F3A526"}}></div>
                <h4>Vault Volume</h4>
              </div>
              <div className="flex" style={{alignItems:"center"}}>
                <img src="/assets/wsteth.png" width={30} height={30}/>
                <div>{`wstETH locked: ${data.wstLockedAmount} = $${data.wstLockedUSDAmount}M`}</div>
              </div>
            </div>
            
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#4A4AF9"}}></div>
                <h4>Deposit Info</h4>
              </div>
              <div className="flex" style={{justifyContent:"space-between"}}>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit (ETH)</div>
                  <div>{`${data.ethDepositedAmount}K / ${data.totalDepositedAmount}K`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit Token</div>
                  <div>ETH/WETH/wstETH</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Gross APY</div>
                  <div>{`${data.depositedGrossAPY - data.platformFee}%`}</div>
                </div>
              </div>
            </div>
            <div className="frame-border"></div>
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#F3A526"}}></div>
                <h4>Fee Info</h4>
              </div>
              
              <div className="flex" style={{justifyContent:"space-between"}}>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Annual Management Fee</div>
                  <div>{`${data.annualFee}`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Performance Fee</div>
                  <div>{`${data.performanceFee}% (${data.depositedGrossAPY}% of Gross APY)`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Exit Fee</div>
                  <div>0.02%</div>
                </div>
              </div>
            </div>
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#4A4AF9"}}></div>
                <h4>Utililzed Protocols</h4>
              </div>
              <div className="flex">
                <a className="protocollink" href="https://aave.com/" target="_blank">
                  <img src="/protocols/aave.svg" width={20} height={20}/>
                  <div style={{margin:"0px 2px 0px 2px"}}>aave</div>
                  <img src="/assets/external-link.svg" width={20} height={20} />
                </a>
                <a className="protocollink" href="https://lido.fi/" target="_blank">
                  <img src="/protocols/lido.svg" width={20} height={20} />
                  <p style={{margin:"0px 2px 0px 2px"}}>lido</p>
                  <img src="/assets/external-link.svg" width={20} height={20} />
                </a>
                <a className="protocollink" href="https://balancer.fi/" target="_blank" >
                  <img src="/protocols/balancer.svg" width={20} height={20} />
                  <p style={{margin:"0px 2px 0px 2px"}}>balancer</p>
                  <img src="/assets/external-link.svg" width={20} height={20} />
                </a>
                <a className="protocollink" href="https://1inch.io/" target="_blank">
                  <img src="/protocols/1inch.svg" width={20} height={20} />
                  <p style={{margin:"0px 2px 0px 2px"}}>1inch</p>
                  <img src="/assets/external-link.svg" width={20} height={20} />
                </a>
              </div>
            </div>
            
          </div>
        </div>
        <div>
          <div className="card mb-6">
            <h3>My Info</h3>
            <div className="grid-3">
              <div>
                <div className="flex-1 label">Net Value (ETH)</div>
                <div> {data.myNetValue} </div>
                <div> = $0</div>
              </div>
              <div>
                <div className="flex-1 label">Earnings (ETH)</div>
                <div> {data.myNetEarning} </div>
                <div> = $0</div>
              </div>
              <div>
                <div className="flex-1 label">LP (wstETH)</div>
                <div> {data.myNetLP} </div>
                <div> = $0</div>
              </div>
            </div>
          </div>
          <div className="card mb-6">
            <div className="label">Your ETH</div>
            <div className="font-xxl font-bold mb-2">
              {0.0}
            </div>
            <div className="flex">
              <div className="flex-1 label">Wallet</div>
              <div>
                00
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">Annual Management Fee</div>
              <div>
                00
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">Performance Fee</div>
              <div>
                00
              </div>
            </div>
            <div className="flex">
              <div className="flex-1 label">Exit Fee</div>
              <div>
                00
              </div>
            </div>
            <div className="grid-2 mt-2">
              <button className="button" onClick={() => setModal("deposit")}>
                Deposit
              </button>
              <button
                className="button button-link"
                onClick={() => setModal("withdraw")}
              >
                Withdraw
              </button>
            </div>
          </div>
        </div>
      </div>
      <h1 className="title">Activity</h1>
      <div className="position-loading">Loading...</div>
      {/* {modal == "deposit" ? (
        <ModalPoolDeposit
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdraw" ? (
        <ModalPoolWithdraw
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "depositLm" ? (
        <ModalLmDeposit
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLm" ? (
        <ModalLmWithdraw
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "depositLmLp" ? (
        <ModalLmDepositLp
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLmLp" ? (
        <ModalLmWithdrawLp
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "harvestOrdo" ? (
        <ModalLmHarvestOrdo
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdrawLm0" ? (
        <ModalLmWithdraw0
          pool={pool}
          asset={asset}
          data={data}
          fetchData={fetchData}
          setModal={setModal}
        />
      ) : null} */}
    </Layout>
  );
}
