import { useState } from "react";
import { formatNumber, parseUnits, useWeb3, ONE, ZERO } from "../../utils";
import ActionModal from "../actionModal";

export default function ModalPoolWithdraw({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { address, contracts } = useWeb3();
  const [amount, setAmount] = useState("");
  let parsedAmount = ZERO;
  try {
    parsedAmount = parseUnits(amount, asset.decimals);
  } catch (e) {}

  async function onSubmit(amount) {
    let shares = amount.mul(pool.shares).div(pool.supply);
    if (amount.eq(data.value)) {
      shares = data.balance;
    }
    const poolContract = contracts.pool(pool.address);
    return poolContract.burn(shares, address);
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  return (
    <ActionModal
      title={"Withdraw " + asset.symbol}
      action="Withdraw"
      labelSymbol={asset.symbol}
      balance={data.value}
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
