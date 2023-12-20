import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import {
  formatNumber,
  formatUnits,
  formatKNumber,
  useGlobalState,
  useWeb3,
  call,
  runTransaction,
  Mode,
  onError,
  formatError,
  contracts as addresses,
  ZERO,
} from "../../../utils";
import Layout from "../../../components/layout";

export default function VaultPool() {
  const router = useRouter();
  const { state } = useGlobalState();
  const { provider, signer, address, networkName, contracts, chainId } =
    useWeb3();
  
  const pool = state.vault_pools.find((p) => p.address == router.query.vault);

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [balance, setBalance] = useState(0);
  const [mode, setMode] = useState(Mode.Deposit);
  const [amount, setAmount] = useState(0);
  const [symbol, setSymbol] = useState("wstETH");
  const [vaultSymbol, setVaultSymbol] = useState("rowstETH");
  const [data, setData] = useState({
    wstLockedAmount: 0.0,
    wstLockedUSDAmount: 0,
    ethDepositedAmount: 0.0,
    totalDepositedAmount: 0.0,
    depositedGrossAPY: 0.0,
    annualFee: 0.0,
    performanceFee: 0.0,
    exitFee: 0.0,
    myNetValue: 0,
    myNetEarning: 0,
    myNetLP: 0
  });
  const [wstPrice, setWstPrice] = useState(2544);
  const [assetAllowance, setAssetAllowance] = useState(false);
  const [allowanceAmount, setAllowanceAmount] = useState(0);
  const [annualManageFee, setAnnualManageFee] = useState(0);
  const [performanceFee, setPerformanceFee] = useState(0);
  const [exitFee, setExitFee] = useState(0);
  const [estExitFee, setEstExitFee] = useState(0);
  const [estLoss, setEstLoss] = useState(0);
  const [estWithdrawl, setEstWithdrawl] = useState(0);
  const [estMinWithdrawl, setEstMinWithdrawl] = useState(0);

  async function fetchDetails() {
    if (!pool || !contracts) return;

    const assetContract = contracts.asset(pool.asset);
    const vaultContract = contracts.vault(pool.address);
    const stContract = await vaultContract.strategy();
    const ta = await vaultContract.totalAssets();
    const strategyContract = contracts.vaultStrategy(stContract);
    const lendingAddress = await strategyContract.lendingLogic();
    const lendingContract = contracts.lendingLogic(lendingAddress);

    //todo test
    // const [_totalAssest, debtAsset, netAsset, _ratio] = 
    //   await lendingContract.getNetAssetsInfo(address);
    const _totalAssest = ZERO;
    const debtAsset = ZERO;
    const netAsset = ZERO;
    const _ratio = 0;

    const lpBalance = await vaultContract.balanceOf(address);
    const currency = await assetContract.symbol();
    const avBalance = await assetContract.balanceOf(address);
    const vaultCurrency = await vaultContract.symbol();

    const Aamount = await assetContract.allowance(address, pool.address);
    setAllowanceAmount(Number(formatUnits(Aamount)));
    if (Number(formatUnits(Aamount)) > amount) {
      setAssetAllowance(true);
    }
    const data = {
      wstLockedAmount: Number(formatUnits(ta)),
      wstLockedUSDAmount: Number(formatUnits(ta)) * wstPrice,
      ethDepositedAmount: 0,
      totalDepositedAmount: 0,
      depositedGrossAPY: Number(pool.gross_apy),
      annualFee: Number(pool.management_fee),
      performanceFee: Number(pool.performance_fee),
      exitFee: Number(pool.exit_fee),
      myNetValue: Number(formatUnits(netAsset)),
      myNetEarning: Number(formatUnits(debtAsset)),
      myNetLP: Number(formatUnits(lpBalance))
    } 
    setVaultSymbol(vaultCurrency);
    setSymbol(currency);
    setData(data);
    setBalance(Number(formatUnits(avBalance)));
    setLoading(false);
  }

  useEffect(() => {

    fetchDetails().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [pool, networkName, address, state]);

  useEffect(() => {

    if (mode == Mode.Deposit) {
      setAnnualManageFee(amount * data.annualFee / 100);
      setPerformanceFee(amount * data.performanceFee / 100);
      setExitFee(amount * data.exitFee / 100);
    } else {
      const lossAmount = amount * data.exitFee / 100 + 
        amount * data.performanceFee / 100;
      setEstExitFee(amount * data.exitFee / 100);
      setEstLoss(amount);
      setEstWithdrawl(amount - lossAmount);
      setEstMinWithdrawl(amount - lossAmount);
    }

    if (allowanceAmount > amount) {
      setAssetAllowance(true);
    }
  }, [amount]);

  function onMax() {
    setAmount(formatUnits(balance, 2).replaceAll(",", ""));
  }

  function onAmount(val) {

    if (val == "")
    {
      setAmount(val);
      return; 
    }
    var pattern = /^[1-9]\d*(?:\.\d{0,8})?$/;
    if (!pattern.test(val))
      return;

    setAmount(val);

  }

  async function onDeposit() {

    if (balance < amount) {
      setError("Not enough balance");
      setLoading(false);
      return;
    }

    const cost = ethers.utils.parseUnits(amount.toString());
    try {
      await runTransaction(
        call(signer, pool.address, "+deposit-uint256,address-", cost , address),
        "Depositing to vault...",
        "Deposit",
        true,
        networkName
      );
      fetchDetails();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    } finally {
      setLoading(false);
    }

  }
  
  async function onWithdraw() {

    if (data.myNetLP < amount) {
      setError("Not enough amount");
      setLoading(false);
      return;
    }

    const cost = ethers.utils.parseUnits(amount.toString());
    try {
      await runTransaction(
        call(signer, pool.address, "+withdraw-uint256,address, address-", cost , address, address),
        "Withdrawing from vault...",
        "Withdraw",
        true,
        networkName
      );

      fetchDetails();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    } finally {
      setLoading(false);
    }
  }

  async function onAllow() {

    const cost = ethers.utils.parseUnits(amount.toString());
    try {
      await runTransaction(
        call(signer, pool.asset, "+approve-address,uint256", pool.address, cost),
        "Setting allowance...",
        "Approve",
        true,
        networkName
      );
      fetchDetails();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    } finally {
      setLoading(false);
    }
  }

  function handleAction() {
    setLoading(true);
    setError("");
    if (mode == Mode.Deposit) {
      if (!assetAllowance) {
        onAllow();
        return;
      }
      onDeposit();
    } else {
      onWithdraw();
    }
  }

  return (
    <Layout title="Vault stETH" backLink="/vault">
      <h1 className="title">Details</h1>
      <div className="grid-2--custom gap-6">
        <div>
          <div className="card mb-6">
            <h3>Vault Configuration</h3>
            {error ? <div className="error mb-4">{error}</div> : null}
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#F3A526"}}></div>
                <h4>Vault Volume</h4>
              </div>
              <div className="flex" style={{alignItems:"center"}}>
                <img src="/assets/wsteth.png" width={30} height={30}/>
                <div>{`${symbol} locked: ${formatNumber(data.wstLockedAmount)} = $${formatKNumber(data.wstLockedUSDAmount, 2)}`}</div>
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
                  <div>{`${formatNumber(data.ethDepositedAmount)}K / ${formatNumber(data.totalDepositedAmount)}K`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit Token</div>
                  <div>ETH/WETH/wstETH</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Gross APY</div>
                  <div>{`${data.depositedGrossAPY - data.annualFee}%`}</div>
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
                  <div>{`${data.annualFee}%`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Performance Fee</div>
                  <div>{`${data.performanceFee}% (${data.depositedGrossAPY}% of Gross APY)`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Exit Fee</div>
                  <div>{`${data.exitFee}%`}</div>
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
          <MyInfo
            netValue = {data.myNetValue}
            earning = {data.myNetEarning}
            lpValue = {data.myNetLP}
            price = {wstPrice}
            symbol = {symbol}
            vaultSymbol = {vaultSymbol}
          />
          <div className="card mb-6">
            <div className="flex">
              <p 
                className={mode == Mode.Deposit ? "vault-tab selected" : "vault-tab"}
                onClick={() => setMode(Mode.Deposit)}
              >
                Deposit
              </p>
              <p 
                className={mode == Mode.Withdraw ? "vault-tab selected" : "vault-tab"}
                onClick={() => setMode(Mode.Withdraw)}
              >
                Withdraw
              </p>
            </div>
            <div className="frame-border" style={{marginTop:"0px", marginBottom:"20px"}}/>
            <div>

              <label className="label flex">
                <div className="flex-1">Amount</div >
                <div>
                  {formatNumber(balance, 2)} {symbol} {" "}
                  <a onClick={onMax}>Max</a>
                </div>
              </label>
              <input
                className="input mb-4"
                placeholder="0.0"
                value={amount}
                onChange={(e) => onAmount(e.target.value)}
              />
            </div>
            <FeeList 
              mode = {mode}
              balance = {
                mode == Mode.Deposit ? 
                balance < amount ? 0 : balance - amount :
                data.myNetLP < amount ? 0 : data.myNetLP - amount
              }
              symbol = {symbol}
              params = {[
                mode == Mode.Deposit ? annualManageFee : estExitFee,
                mode == Mode.Deposit ? performanceFee : estLoss,
                mode == Mode.Deposit ? exitFee : estWithdrawl,
                mode == Mode.Deposit ? 0 : estMinWithdrawl
              ]}
            />
            <button 
              className="button w-full"
              disabled = {loading}
              onClick={() => handleAction()}
            >
              {
                mode == Mode.Deposit ?
                assetAllowance ? `Approve ${symbol}` :
                `Deposit ${symbol}` : `Withdraw ${symbol}`
              }
            </button>
          </div>
        </div>
      </div>
      <h1 className="title">Activity</h1>
      <div className="position-loading">Loading...</div>
    </Layout>
  );
}

function MyInfo(
  value,
  ...params
) {
  
  //todo test
  return (
    <div className="card mb-6">
      <h3>My Info</h3>
      <div className="grid-3">
        <div>
          <div className="flex-1 label">Net Value</div>
          <div className="flex-1 label">({value.symbol})</div>
          <div> {formatKNumber(value.lpValue)} </div>   
          <div> = ${formatKNumber(value.lpValue * value.price)}</div>
        </div>
        <div>
          <div className="flex-1 label">Earnings</div>
          <div className="flex-1 label">({value.symbol})</div>
          <div> {formatKNumber(value.earning)} </div>
          <div> = ${formatKNumber(value.earning * value.price)}</div>
        </div>
        <div>
          <div className="flex-1 label">LP</div>
          <div className="flex-1 label">({value.vaultSymbol})</div>
          <div> {formatKNumber(value.lpValue)} </div>
        </div>
      </div>
    </div>
  );
}

function FeeList(
  value,
  ...params
) {
  return (
    <div>
      <div className="flex">
        <div className="flex-1 label">Available {value.symbol}</div>
        <div>
          {value.balance < 1 ? 
          Number(value.balance).toFixed(2) : 
          formatKNumber(value.balance, 2)} {value.symbol}
        </div>
      </div>
      <div className="flex">
        <div className="flex-1 label">
          {
            value.mode == Mode.Deposit ? "Annual Management Fee" : "Est. exit fee(s)"
          }
        </div>
        <div> {
          value.params[0] < 1 ? 
          Number(value.params[0]).toFixed(2) :
          formatKNumber(value.params[0], 2)
        } {value.symbol} </div>
      </div>
      <div className="flex">
        <div className="flex-1 label">
          {
            value.mode == Mode.Deposit ? "Performance Fee" : "Est. loss"
          }
        </div>
        <div> {
          value.params[1] < 1 ? 
          Number(value.params[1]).toFixed(2) : 
          formatKNumber(value.params[1], 2)
        } {value.symbol} </div>
      </div>
      <div className="flex">
        <div className="flex-1 label">
          {
            value.mode == Mode.Deposit ? "Exit Fee" : "Est. withdrawal"
          }
        </div>
        <div> {
          value.params[2] < 1 ? 
          Number(value.params[2]).toFixed(2) : 
          formatKNumber(value.params[2], 2)
        } {value.symbol} </div>
      </div>
      {
        value.mode == Mode.Withdraw && 
        <div className="flex">
          <div className="flex-1 label">
            Est. min withdrawal
          </div>
          <div> {
            value.params[3] < 1 ? 
            Number(value.params[3]).toFixed(2) : 
            formatKNumber(value.params[3], 2)
          } {value.symbol} </div>
        </div>
      }
    </div>
  );  
}