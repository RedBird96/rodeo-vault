import { useState } from "react";
import { parseUnits, useWeb3 } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmWithdraw0({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { address, contracts } = useWeb3();

  async function onSubmit(amount) {
    return contracts.liquidityMining.withdraw(amount, address);
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  return (
    <ActionModal
      title="Withdraw from liquidity mining"
      action="Withdraw"
      labelSymbol={"rib" + asset.symbol}
      balance={data.balanceInLm}
      decimals={asset.decimals}
      hasAmount
      onSubmit={onSubmit}
      onReload={onReload}
      onHide={() => setModal()}
    />
  );
}
