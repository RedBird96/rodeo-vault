import { useState } from "react";
import { call, contracts as addresses, parseUnits, useWeb3 } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmWithdrawLp({
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
      "+withdrawLp-uint256,uint256,address-",
      0,
      amount,
      address
    );
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  return (
    <ActionModal
      title="Withdraw RDO/ETH LP"
      action="Withdraw"
      labelSymbol={"RDO/ETH LP"}
      balance={data.lmLp}
      hasAmount
      onSubmit={onSubmit}
      onReload={onReload}
      onHide={() => setModal()}
    />
  );
}
