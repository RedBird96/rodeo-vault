import { useState } from "react";
import {
  ONE,
  YEAR,
  call,
  useWeb3,
  parseUnits,
  formatDate,
  formatNumber,
  contracts as addresses,
} from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmWithdraw({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { signer, address, contracts } = useWeb3();

  async function onSubmit(amount) {
    return call(
      signer,
      addresses.liquidityMining,
      "+withdraw-uint256,uint256,address-",
      0,
      amount,
      address
    );
  }

  async function onSubmitEarly(amount) {
    return call(
      signer,
      addresses.liquidityMining,
      "+withdrawEarly-uint256,address-",
      0,
      address
    );
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  if (data.lmLock.toNumber() > Date.now() / 1000) {
    const feeRate = parseUnits("75", 16)
      .mul(data.lmLock.sub((Date.now() / 1000) | 0))
      .div(YEAR);
    const fee = data.lmValue.mul(feeRate).div(ONE);
    return (
      <ActionModal
        title="Withdraw early from liquidity mining"
        description={
          <>
            Your{" "}
            <b>
              {formatNumber(data.lmAmount, asset.decimals)} rib
              {asset.symbol}
            </b>{" "}
            (${formatNumber(data.lmValue)}) are locked until{" "}
            <b>{formatDate(data.lmLock)}</b>. You can withdraw it early by
            paying a penality fee of{" "}
            <b className="text-red">
              {formatNumber(feeRate, 16, 1)}% (${formatNumber(fee)})
            </b>
            . You will receive <b>${formatNumber(data.lmValue.sub(fee))}</b>.
            You will keep you rewards accumulated up until now.
          </>
        }
        action={`Withdraw early loosing ${formatNumber(feeRate, 16, 1)}%`}
        onSubmit={onSubmitEarly}
        onReload={onReload}
        onHide={() => setModal()}
      />
    );
  }

  return (
    <ActionModal
      title="Withdraw from liquidity mining"
      action="Withdraw"
      labelSymbol={"rib" + asset.symbol}
      balance={data.lmAmount}
      decimals={asset.decimals}
      hasAmount
      onSubmit={onSubmit}
      onReload={onReload}
      onHide={() => setModal()}
    />
  );
}
