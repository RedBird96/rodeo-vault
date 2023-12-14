import { useState } from "react";
import {
  call,
  parseUnits,
  useWeb3,
  contracts as addresses,
  ONE,
} from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmDepositLp({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { signer, address, contracts } = useWeb3();
  const [zap, setZap] = useState(true);
  const [amount, setAmount] = useState("");
  let allowanceOk;
  try {
    if (!amount) allowanceOk = true;
    const parsedAmount = parseUnits(amount, asset.decimals);
    allowanceOk = (zap ? data.allowanceHelper : data.allowanceLp).gte(
      parsedAmount
    );
  } catch (e) {}

  async function onSubmit(amount) {
    if (!allowanceOk) {
      return call(
        signer,
        zap ? pool.asset : addresses.lpToken,
        "+approve-address,uint256",
        zap ? addresses.liquidityMiningHelper : addresses.liquidityMining,
        ethers.constants.MaxUint256
      );
    }
    if (zap) {
      return call(
        signer,
        addresses.liquidityMiningHelper,
        "+depositWithZap-uint256,uint256,address,uint256,uint256,uint256-",
        0,
        amount,
        address,
        0,
        ONE,
        250
      );
    }
    return call(
      signer,
      addresses.liquidityMining,
      "+depositLp-uint256,address,uint256-",
      0,
      address,
      amount
    );
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    if (allowanceOk) setModal("");
  }

  return (
    <ActionModal
      title="Deposit RDO/ETH LP for boost"
      description={
        <>
          <div className="tabs mb-2">
            <a
              className={`tabs-tab ${zap ? "active" : ""}`}
              onClick={() => setZap(true)}
            >
              Zap from {asset.symbol}
            </a>
            <a
              className={`tabs-tab ${zap ? "" : "active"}`}
              onClick={() => setZap(false)}
            >
              Deposit RDO/ETH LP
            </a>
          </div>
          {zap ? (
            <div>
              Zap some {asset.symbol} into RDO/ETH LP and deposit it in order to
              receive the rbLP 100% APR boost (when above 5% of your deposits
              value)
            </div>
          ) : (
            <div>
              Deposit more than 5% of the value of your staked rib$
              {asset.symbol} as RDO/ETH LP in order to receive a 100% boost to
              your APR.
            </div>
          )}
        </>
      }
      action={
        allowanceOk
          ? zap
            ? "Zap USDC to RDO/ETH LP"
            : "Deposit"
          : `Approve ${zap ? "USDC" : "RDO/ETH LP"}`
      }
      labelSymbol={zap ? asset.symbol : "RDO/ETH LP"}
      balance={zap ? data.assetBalance : data.balanceLp}
      decimals={zap ? asset.decimals : 18}
      hasAmount
      onSubmit={onSubmit}
      onReload={onReload}
      onError={fetchData}
      onHide={() => setModal("")}
      amount={amount}
      setAmount={setAmount}
    />
  );
}
