import { useState } from "react";
import { parseUnits, useWeb3 } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalPoolDeposit({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { address, contracts } = useWeb3();
  const [amount, setAmount] = useState("");
  let allowanceOk;
  try {
    const parsedAmount = parseUnits(amount, asset.decimals);
    allowanceOk = data.assetAllowance.gte(parsedAmount);
  } catch (e) {}

  async function onSubmit(amount) {
    if (!allowanceOk) {
      const assetContract = contracts.asset(asset.address);
      return assetContract.approve(pool.address, ethers.constants.MaxUint256);
    }
    const poolContract = contracts.pool(pool.address);
    return poolContract.mint(amount, address);
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  return (
    <ActionModal
      title={"Deposit " + asset.symbol}
      description={`Deposit ${asset.symbol} in the lending pool in order to earn yield. You will receive an interest bearing deposit token named rib${asset.symbol} in return.`}
      action={allowanceOk ? "Deposit" : "Approve " + asset.symbol}
      labelSymbol={asset.symbol}
      balance={data.assetBalance}
      decimals={asset.decimals}
      hasAmount
      onSubmit={onSubmit}
      onReload={onReload}
      onHide={() => setModal()}
      amount={amount}
      setAmount={setAmount}
    />
  );
}
