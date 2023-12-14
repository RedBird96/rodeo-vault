import { useState } from "react";
import {
  ONE,
  ZERO,
  parseUnits,
  useWeb3,
  formatNumber,
  formatDate,
} from "../../utils";
import ActionModal from "../actionModal";

export default function ModalSilosBurn({ data, onClose, onReload }) {
  const { address, contracts } = useWeb3();
  const [amount, setAmount] = useState("");
  const [time, setTime] = useState(6 * 30);
  let parsedAmount = ZERO;
  let amountOut = ZERO;
  try {
    parsedAmount = parseUnits(amount || "0", 18);
    amountOut = parsedAmount
      .mul(
        parseUnits("0.5", 18).add(
          parseUnits("0.5", 18)
            .mul(parseInt(time) - 15)
            .div(165)
        )
      )
      .div(ONE);
  } catch (e) {
    console.log(e);
  }

  async function onSubmit(amount) {
    return contracts.tokenStaking.burn(amount, parseInt(time) * 86400);
  }

  function onDone() {
    onReload();
    setTimeout(() => onReload(), 5000);
    onClose();
  }

  const extraFields = (
    <>
      <label className="label">
        Vesting time ({time} days, {formatNumber(time / 30, 0, 1)} months)
      </label>
      <input
        className="block w-full mb-4"
        type="range"
        step="1"
        min="15"
        max="180"
        value={time}
        onChange={(e) => setTime(e.target.value)}
      />
      <div className="flex mb-2">
        <div className="flex-1 font-bold">RDO tokens you will get</div>
        <div>{formatNumber(amountOut)} RDO</div>
      </div>
      <div className="flex mb-4">
        <div className="flex-1 font-bold">Vesting ends</div>
        <div>
          {formatDate(Date.now() + parseInt(time) * 86400 * 1000).split(" ")[0]}
        </div>
      </div>
    </>
  );

  return (
    <ActionModal
      title={`Redeem xRDO for RDO`}
      description="If you redeem xRDO for RDO over 6 months, you will get 1 RDO for every xRDO. The minimum redemption time is 15 days, where you will get 0.5 RDO for each xRDO."
      action="Redeem"
      labelSymbol="xRDO"
      balance={data.userTotal.sub(data.userAllocated)}
      decimals={18}
      hasAmount
      onSubmit={onSubmit}
      onReload={onDone}
      onHide={onClose}
      extraFields={extraFields}
      amount={amount}
      setAmount={setAmount}
    />
  );
}
