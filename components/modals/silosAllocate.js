import { useState } from "react";
import { parseUnits, useWeb3, SILO_NAMES } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalSilosAllocate({ data, index, onClose, onReload }) {
  const { address, contracts } = useWeb3();

  async function onSubmit(amount) {
    return contracts.tokenStaking.allocate(index, amount);
  }

  function onDone() {
    onReload();
    setTimeout(() => onReload(), 5000);
    onClose();
  }

  return (
    <ActionModal
      title={`Allocate to the ${SILO_NAMES[index]} silo`}
      action="Allocate"
      labelSymbol="xRDO"
      balance={data.userTotal.sub(data.userAllocated)}
      decimals={18}
      hasAmount
      onSubmit={onSubmit}
      onReload={onDone}
      onHide={onClose}
    />
  );
}
