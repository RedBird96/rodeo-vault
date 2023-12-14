import { useState } from "react";
import { parseUnits, useWeb3 } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalSilosMint({ data, onClose, onReload }) {
  const { contracts, address } = useWeb3();
  const [amount, setAmount] = useState("");
  let allowanceOk;
  try {
    const parsedAmount = parseUnits(amount || "1", 18);
    allowanceOk = data.tokenAllowance.gte(parsedAmount);
  } catch (e) {}

  async function onSubmit(amount) {
    if (!allowanceOk) {
      return contracts.token.approve(
        contracts.tokenStaking.address,
        ethers.constants.MaxUint256
      );
    }
    return contracts.tokenStaking.mint(amount, address);
  }

  function onDone() {
    onReload();
    setTimeout(() => onReload(), 5000);
    onClose();
  }

  const footer = (
    <div className="text-red mb-4">
      To redeem your xRDO as RDO you will have to wait at least 15 days. In
      order to get RDO back at a 1:1 ratio you will have to wait for them to
      vest linearily over 6 months.
    </div>
  );

  return (
    <ActionModal
      title="Convert RDO to xRDO"
      description="Convert RDO into xRDO at a 1:1 ratio in order to start allocating to Silos. Silos are the gateway to many advantages and features of the Rodeo protocol."
      extraFields={footer}
      action={allowanceOk ? "Convert" : "Approve RDO"}
      labelSymbol="RDO"
      balance={data.tokenBalance}
      decimals={18}
      hasAmount
      onSubmit={onSubmit}
      onReload={onDone}
      onHide={onClose}
      amount={amount}
      setAmount={setAmount}
    />
  );
}
