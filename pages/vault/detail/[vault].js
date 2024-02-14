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
  ServiceMode,
  apiServerHost,
  paddingTwoletters,
  convertStringToExactNumber
} from "../../../utils";
import Layout from "../../../components/layout";

export default function VaultPool() {
  const router = useRouter();
  const { signer, address, networkName, contracts } =
    useWeb3();
    
  const { state } = useGlobalState();

  const pool = state.vaults.find((p) => p.address == router.query.vault);

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [disabled, setDisabled] = useState(true);
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
  const [myPositions, setMyPositions] = useState([]);
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

    const res = await (
      await fetch(
        apiServerHost +
          `/fetch/vaultstrategy/positions/history?wallet=${address}`
      )
    ).json()
      
    setMyPositions(res);

    //test
    const assetContract = contracts.asset(pool.asset);
    const vaultContract = contracts.vault(pool.address);
    const stContract = await vaultContract.strategy();
    const ta = await vaultContract.totalLockedAmount();
    const strategyContract = contracts.vaultStrategy(stContract);
    const price = await strategyContract.getAssestPrice(pool.asset);

    //todo test
    // const [_totalAssest, debtAsset, netAsset, _ratio] = 
    //   await lendingContract.getNetAssetsInfo(address);
    const _totalAssest = ZERO;
    const netAsset = ZERO;

    const depositedAmt = await vaultContract.userDepositdAmount(address);
    const lpBalance = await vaultContract.balanceOf(address);
    const debtAsset = await vaultContract.convertToAssets(lpBalance);
    const currency = await assetContract.symbol();
    const avBalance = await assetContract.balanceOf(address);
    const vaultCurrency = await vaultContract.symbol();
    const assetPrice = Number(formatUnits(price, 8, 2));
    const Amount = await assetContract.allowance(address, pool.address);
    setAllowanceAmount(Number(formatUnits(Amount)));
    if (Number(formatUnits(Amount)) >= amount) {
      setAssetAllowance(true);
    }
    const data = {
      wstLockedAmount: Number(formatUnits(ta)),
      wstLockedUSDAmount: Number(formatUnits(ta)) * assetPrice,
      ethDepositedAmount: 0,
      totalDepositedAmount: 0,
      depositedGrossAPY: Number(pool.grossApy),
      annualFee: Number(pool.managementFee),
      performanceFee: Number(pool.performanceFee),
      exitFee: Number(pool.exitFee),
      myNetValue: Number(formatUnits(debtAsset)),
      myNetEarning: Number(formatUnits(debtAsset)) - Number(formatUnits(depositedAmt)),
      myNetLP: Number(formatUnits(lpBalance))
    } 
    setWstPrice(assetPrice);
    setVaultSymbol(vaultCurrency);
    setSymbol(currency);
    setData(data);
    setBalance(convertStringToExactNumber(formatUnits(avBalance)));
    setDisabled(false);
    setLoading(false);
  }

  useEffect(() => {

    fetchDetails().then(
      () => {},
      (e) => console.error("fetch", e)
    );
  }, [state]);

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

    if (allowanceAmount < amount) {
      setAssetAllowance(false);
    } else {
      setAssetAllowance(true);
    }
  }, [amount]);

  function onMax() {
    if (mode == Mode.Deposit)
      setAmount(balance);
    else
      setAmount(data.myNetValue); 
  }

  function onAmount(val) {

    if (val == "")
    {
      setAmount(val);
      return; 
    }
    var pattern = /^[0-9]\d*(?:\.\d{0,8})?$/;
    if (!pattern.test(val))
      return;

    setAmount(val);
  }

  async function onDeposit() {

    if (balance < amount) {
      setError("Not enough balance");
      setDisabled(false);
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
      
      const param = {
        time: (Date.now()/1000).toString(),
        action: "1",
        amount: amount.toString(),
        status:"Completed",
        wallet:address
      }
      await fetch(
        apiServerHost +
          `/register/vaultstrategy/positions/history`, {
            method: "POST",
            body: JSON.stringify(param)
          }
      )
      fetchDetails();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    }
    setDisabled(false);

  }
  
  async function onWithdraw() {

    if (data.myNetLP < amount) {
      setError("Not enough amount");
      setDisabled(false);
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

      const param = {
        time: (Date.now()/1000).toString(),
        action: "0",
        amount: amount.toString(),
        status:"Completed",
        wallet:address
      }
      await fetch(
        apiServerHost +
          `/register/vaultstrategy/positions/history`, {
            method: "POST",
            body: JSON.stringify(param)
          }
      )
      fetchDetails();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    }
    setDisabled(false);
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
      console.log("call ended");
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    }
    setDisabled(false);
    console.log("call ended2");
  }

  function handleAction() {
    if (amount == 0)
      return;
    setDisabled(true);
    setError("");
    if (mode == Mode.Deposit) {
      if (!assetAllowance) {
        onAllow();
      } else {
        onDeposit();
      }
    } else {
      onWithdraw();
    }
  }

  return (
    <Layout title={"Vault " + symbol} backLink="/vault" service = {ServiceMode.Vault}>
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
                <div>{`${symbol} locked: ${
                    data.wstLockedAmount < 0.01 ? formatNumber(data.wstLockedAmount, 18, 7) : formatNumber(data.wstLockedAmount)
                  } = $${
                    data.wstLockedUSDAmount < 1 ? 
                    formatNumber(data.wstLockedUSDAmount, 18, 7)
                    : formatKNumber(data.wstLockedUSDAmount, 2)
                  }`}</div>
              </div>
            </div>
            
            <div className="flex" style={{flexDirection:"column"}}>
              <div className="flex" style={{alignItems: "baseline"}}>
                <div className="config" style={{background:"#4A4AF9"}}></div>
                <h4>Deposit Info</h4>
              </div>
              <div className="flex" style={{justifyContent:"space-between"}}>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit (wstETH)</div>
                  <div>{`${
                    data.wstLockedAmount < 0.01 ? formatNumber(data.wstLockedAmount, 18, 7) : formatNumber(data.wstLockedAmount)
                  }`}</div>
                </div>
                <div className="flex" style={{flexDirection:"column"}}>
                  <div className="flex-1 label">Deposit Token</div>
                  <div>wstETH</div>
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
                  {formatNumber(mode == Mode.Deposit ? balance : data.myNetLP, 2)} {symbol} {" "}
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
              disabled = {disabled}
              onClick={() => handleAction()}
            >
              {
                mode == Mode.Deposit ?
                !assetAllowance ? `Approve ${symbol}` :
                `Deposit ${symbol}` : `Withdraw ${symbol}`
              }
            </button>
          </div>
        </div>
      </div>
      <h1 className="title">Activity</h1>
      <MyActivity
        list = {myPositions}
        symbol = {symbol}
      />
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
          <div> {value.netValue < 1 ? formatNumber(value.netValue, 18, 6) : formatKNumber(value.netValue)} </div>   
          <div> = ${value.netValue * value.price < 1 ? formatNumber(value.netValue * value.price, 18, 6) : formatKNumber(value.netValue * value.price)}</div>
        </div>
        <div>
          <div className="flex-1 label">Earnings</div>
          <div className="flex-1 label">({value.symbol})</div>
          <div> {value.earning < 1 ? formatNumber(value.earning, 18, 6) : formatKNumber(value.earning)} </div>
          <div> = ${value.earning * value.price < 1 ? formatNumber(value.earning * value.price, 18, 6) : formatKNumber(value.earning * value.price)}</div>
        </div>
        <div>
          <div className="flex-1 label">LP</div>
          <div className="flex-1 label">({value.vaultSymbol})</div>
          <div> {value.lpValue < 1 ? formatNumber(value.lpValue, 18, 6) :formatKNumber(value.lpValue)} </div>
        </div>
      </div>
    </div>
  );
}

function MyActivity(
  value,
  symbol,
  ...parmas
) {

  return (
    <>
    {
      value.list.length == 0 
      ? <div className="position-loading">Loading...</div> :
      <div className="farms">
        <div className="mb-4">
          <div className="grid-5--custom label">
            <div>#</div>
            <div>Time</div>
            <div>Action</div>
            <div>Amount</div>
            <div>Status</div>
            <div></div>
          </div>
        </div>
        {/* {value.length != 0 && value.list.map((p, i) => (
          <Position key={i} index={i} position={p} symbol={value.symbol}/>
        ))} */}
      </div>
    }
    </>
  )
  
}

function Position({ index, position, symbol }) {

  const dt = new Date(position.time * 1000);
  const showDT = `${dt.getFullYear()}-${paddingTwoletters(dt.getMonth() + 1)}-${paddingTwoletters(dt.getDate())} ${paddingTwoletters(dt.getHours())}:${paddingTwoletters(dt.getMinutes())}:${paddingTwoletters(dt.getSeconds())}`;
  return (
    <div className="farm">
      <div className="grid-5--custom">
        <div>
          <div className="label hide show-phone">id</div>
          <div className="flex">
            {index + 1}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Time</div>
          {showDT}
        </div>
        <div>
          <div className="label hide show-phone">Action</div>
          {position.action == 1 ? "Deposit" : "Withdraw"}
        </div>
        <div>
          <div className="label hide show-phone">Amount</div>
          <div>
            {position.amount < 1 ? formatNumber(position.amount, 18, 6) : formatKNumber(position.amount)} {symbol}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Status</div>
          <div>{position.status}</div>
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