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
import Tooltip from "../../../components/tooltip";
import ChartPool from "../../../components/charts/pool";
import ChartInterestRateModel from "../../../components/charts/interestRateModel";
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
  // const [data, setData] = useState({
  //   value: parseUnits("0"),
  //   valueInLm: parseUnits("0"),
  //   balance: parseUnits("0"),
  //   balanceLp: parseUnits("0"),
  //   balanceInLm: parseUnits("0"),
  //   assetBalance: parseUnits("0"),
  //   allowance: parseUnits("0"),
  //   allowanceLp: parseUnits("0"),
  //   allowanceHelper: parseUnits("0"),
  //   assetAllowance: parseUnits("0"),
  //   rewardsBalance: parseUnits("0"),
  //   tvl: parseUnits("0"),
  //   lmAmount: ZERO,
  //   lmLp: ZERO,
  //   lmLock: ZERO,
  //   lmBoostLp: ZERO,
  //   lmBoostLock: ZERO,
  //   lmOwed: ZERO,
  //   lmValue: ZERO,
  //   lmLpValue: ZERO,
  //   lmApr: ZERO,
  //   ordoBalances: [],
  // });
  // const enableLm =
  //   typeof window !== "undefined" && window.location.hash === "#lm";

  // async function fetchData() {
  //   if (!pool || !contracts) return;
  //   const poolContract = contracts.asset(pool.address);
  //   const assetContract = contracts.asset(pool.asset);
  //   const lmValues = await contracts.liquidityMining.users(address);

  //   const lmData = await call(
  //     signer,
  //     addresses.liquidityMining,
  //     "getUser-uint256,address-uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256",
  //     0,
  //     address
  //   );

  //   const ordoBalancesData = await call(
  //     signer,
  //     addresses.liquidityMiningPluginOrdo,
  //     "getBalances-address,uint256,uint256-address[],uint256[],uint256[]",
  //     address,
  //     10000,
  //     50
  //   );
  //   const ordoBalances = [];
  //   for (let i in ordoBalancesData[0]) {
  //     if (ordoBalancesData[2][i].gt(0)) {
  //       ordoBalances.push({
  //         token: ordoBalancesData[0][i],
  //         strike: ordoBalancesData[1][i],
  //         balance: ordoBalancesData[2][i],
  //       });
  //     }
  //   }

  //   const data = {
  //     tvl: parseUnits("0"),
  //     value: parseUnits("0"),
  //     valueInLm: parseUnits("0"),
  //     balance: await poolContract.balanceOf(address),
  //     balanceLp: await call(
  //       signer,
  //       addresses.lpToken,
  //       "balanceOf-address-uint256",
  //       address
  //     ),
  //     balanceInLm: lmValues[0],
  //     assetBalance: await assetContract.balanceOf(address),
  //     allowance: await poolContract.allowance(
  //       address,
  //       addresses.liquidityMining
  //     ),
  //     allowanceLp: await call(
  //       signer,
  //       addresses.lpToken,
  //       "allowance-address,address-uint256",
  //       address,
  //       addresses.liquidityMining
  //     ),
  //     allowanceHelper: await call(
  //       signer,
  //       pool.asset,
  //       "allowance-address,address-uint256",
  //       address,
  //       addresses.liquidityMiningHelper
  //     ),
  //     assetAllowance: await assetContract.allowance(address, pool.address),
  //     rewardsBalance: await contracts.liquidityMining.getPending(address),
  //     lmAmount: lmData[0],
  //     lmLp: lmData[1],
  //     lmLock: lmData[2],
  //     lmBoostLp: lmData[3],
  //     lmBoostLock: lmData[4],
  //     lmOwed: lmData[5],
  //     lmValue: lmData[6],
  //     lmLpValue: lmData[7],
  //     lmApr: pool.lmApr,
  //     ordoBalances,
  //   };

  //   if (pool.shares.gt(0)) {
  //     data.value = data.balance.mul(pool.supply).div(pool.shares);
  //     data.valueInLm = data.balanceInLm.mul(pool.supply).div(pool.shares);
  //   }
  //   const priceAdjusted = pool.price
  //     .mul(ONE)
  //     .div(parseUnits("1", asset.decimals));
  //   data.tvl = pool.supply.mul(priceAdjusted).div(ONE);
  //   setData(data);
  // }

  // useEffect(() => {
  //   fetchData().then(
  //     () => {},
  //     (e) => console.error("fetch", e)
  //   );
  // }, [pool, networkName, address]);

  // async function onClaim() {
  //   runTransaction(
  //     call(
  //       signer,
  //       addresses.liquidityMining,
  //       "+harvest-uint256,address,address-",
  //       0,
  //       address,
  //       addresses.liquidityMiningPluginXrdo
  //     ),
  //     "Claiming...",
  //     "Claimed!",
  //     true,
  //     "arbitrum"
  //   );
  // }

  // async function onExercise(option) {
  //   const teller = "0xF507733f260a42bB2c8108dE87B7B0Ce5826A9cD";
  //   const cost = option.balance.mul(option.strike).div(ONE);
  //   const allowance = await call(
  //     signer,
  //     pool.asset,
  //     "allowance-address,address-uint256",
  //     address,
  //     teller
  //   );
  //   if (allowance.lt(cost)) {
  //     await runTransaction(
  //       call(signer, pool.asset, "+approve-address,uint256", teller, cost),
  //       "Setting allowance...",
  //       "Set",
  //       true,
  //       "arbitrum"
  //     );
  //   }
  //   runTransaction(
  //     call(
  //       signer,
  //       teller,
  //       "+exercise-address,uint256-",
  //       option.token,
  //       option.balance
  //     ),
  //     "Exercising...",
  //     "Exercised!",
  //     true,
  //     "arbitrum"
  //   );
  // }

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
                <div>wstETH locked: 8601.7171717 = $22.03M</div>
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
                  <div>1.58K / 1.82K</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit Token</div>
                  <div>ETH/WETH/wstETH</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Gross APY</div>
                  <div>7.23%</div>
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
                  <div>0</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Performance Fee</div>
                  <div>0.58% (8% of Gross APY)</div>
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
                <div> 0 </div>
                <div> = $0</div>
              </div>
              <div>
                <div className="flex-1 label">Earnings (ETH)</div>
                <div> 0 </div>
                <div> = $0</div>
              </div>
              <div>
                <div className="flex-1 label">LP (wstETH)</div>
                <div> 0 </div>
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
          pool={}
          asset={}
          data={}
          fetchData={}
          setModal={setModal}
        />
      ) : null}
      {modal == "withdraw" ? (
        <ModalPoolWithdraw
          pool={}
          asset={}
          data={}
          fetchData={}
          setModal={setModal}
        />
      ) : null} */}
    </Layout>
  );
}
