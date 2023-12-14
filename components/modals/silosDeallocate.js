import { useState } from "react";
import { parseUnits, useWeb3, SILO_NAMES } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalSilosDeallocate({
  data,
  index,
  onClose,
  onReload,
}) {
  const { address, contracts } = useWeb3();

  async function onSubmit(amount) {
    return contracts.tokenStaking.deallocate(index, amount);
  }

  function onDone() {
    onReload();
    setTimeout(() => onReload(), 5000);
    onClose();
  }

  return (
    <ActionModal
      title={`Deallocate from the ${SILO_NAMES[index]} silo`}
      action="Deallocate"
      labelSymbol="xRDO"
      balance={data.userAllocations[index]}
      decimals={18}
      hasAmount
      onSubmit={onSubmit}
      onReload={onDone}
      onHide={onClose}
    />
  );
}
