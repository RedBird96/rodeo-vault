import { useState } from "react";
import {
  ONE,
  call,
  formatNumber,
  parseUnits,
  useWeb3,
  contracts as addresses,
} from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmDeposit({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { address, signer, contracts } = useWeb3();
  const [zap, setZap] = useState(true);
  const [lock, setLock] = useState("30");
  const [amount, setAmount] = useState("");
  let allowanceOk;
  try {
    if (!amount) allowanceOk = true;
    const parsedAmount = parseUnits(amount, asset.decimals);
    allowanceOk = (zap ? data.allowanceHelper : data.allowance).gte(
      parsedAmount
    );
  } catch (e) {}

  async function onSubmit(amount) {
    if (!allowanceOk) {
      return call(
        signer,
        zap ? pool.asset : pool.address,
        "+approve-address,uint256",
        zap ? addresses.liquidityMiningHelper : addresses.liquidityMining,
        ethers.constants.MaxUint256
      );
    }
    let lockArg = parseInt(lock) * 86400;
    if (data.lmLock.gt(0)) lockArg = 0;
    if (zap) {
      if (lockArg < 30 * 86400) lockArg = 30 * 86400;
      return call(
        signer,
        addresses.liquidityMiningHelper,
        "+depositWithZap-uint256,uint256,address,uint256,uint256,uint256-",
        0,
        amount,
        address,
        lockArg,
        parseUnits("0.06", 18),
        250
      );
    } else {
      return call(
        signer,
        addresses.liquidityMining,
        "+deposit-uint256,uint256,address,uint256-",
        0,
        amount,
        address,
        lockArg
      );
    }
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    if (allowanceOk) setModal("");
  }

  const lmAprWithDlp = data.lmApr.add(
    data.lmApr.mul(zap ? ONE : data.lmBoostLp).div(ONE)
  );
  const extraFields = data.lmLock.eq(0) ? (
    <div className="mb-4">
      <label className="label">Lock Duration ({lock} days)</label>
      <input
        className="w-full"
        type="range"
        value={lock}
        onChange={(e) => setLock(e.target.value)}
        min={zap ? "30" : "0"}
        max="365"
        step="1"
      />
      <div className="mt-2">
        <div className="flex">
          <div className="label mb-0 flex-1">Base APR</div>
          <div>{formatNumber(data.lmApr, 16, 1)}%</div>
        </div>
        <div className="flex">
          <div className="label mb-0 flex-1">Base APR + dLP boost</div>
          <div>{formatNumber(lmAprWithDlp, 16, 1)}%</div>
        </div>
        <div className="flex">
          <div className="label mb-0 flex-1">Your APR + dLP + lock boost</div>
          <div className="font-bold">
            {formatNumber(
              lmAprWithDlp.add(data.lmApr.mul(parseInt(lock)).div(365)),
              16,
              1
            )}
            %
          </div>
        </div>
      </div>
    </div>
  ) : null;

  return (
    <ActionModal
      title="Deposit into liquidity mining"
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
              Deposit rib{asset.symbol}
            </a>
          </div>
          {zap ? (
            <div>
              Use {asset.symbol} to mint rib{asset.symbol}, stake it, and use 6%
              of the total to mint RDO/ETH LP tokens in order to gain 100% more
              APR from the rbLP boost.
            </div>
          ) : (
            <div>
              Deposit rib{asset.symbol} in the liquidity mining contract to earn
              RDO incentives over time. RDO will be claimable either as xRDO or
              as oRDO.
            </div>
          )}
        </>
      }
      action={
        allowanceOk
          ? zap
            ? `Zap to rib${asset.symbol} + RDO/ETH LP`
            : "Deposit"
          : "Approve " + (zap ? "" : "rib") + asset.symbol
      }
      extraFields={extraFields}
      labelSymbol={zap ? asset.symbol : "rib" + asset.symbol}
      balance={zap ? data.assetBalance : data.balance}
      decimals={asset.decimals}
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
