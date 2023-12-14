import { useState, useEffect } from "react";
import {
  ONE,
  ZERO,
  call,
  formatNumber,
  parseUnits,
  useWeb3,
  contracts as addresses,
} from "../../utils";
import ActionModal from "../actionModal";

export default function ModalLmHarvestOrdo({
  pool,
  asset,
  data,
  setModal,
  fetchData,
}) {
  const { signer, address, contracts } = useWeb3();
  const [modalData, setModalData] = useState({
    price: ZERO,
    bonus: ZERO,
    discount: ZERO,
    available: ZERO,
  });

  async function fetchModalData() {
    setModalData({
      price: await call(signer, addresses.tokenOracle, "latestAnswer--int256"),
      bonus: await call(
        signer,
        addresses.liquidityMiningPluginOrdo,
        "bonus--uint256"
      ),
      discount: await call(
        signer,
        addresses.liquidityMiningPluginOrdo,
        "discount--uint256"
      ),
      available: await call(
        signer,
        addresses.token,
        "balanceOf-address-uint256",
        addresses.liquidityMiningPluginOrdo
      ),
    });
  }

  useEffect(() => {
    fetchModalData();
  }, [address]);

  async function onSubmit(amount) {
    return call(
      signer,
      addresses.liquidityMining,
      "+harvest-uint256,address,address-",
      0,
      address,
      addresses.liquidityMiningPluginOrdo
    );
  }

  function onReload() {
    fetchData();
    setTimeout(() => fetchData(), 5000);
    setModal("");
  }

  const cent = parseUnits("0.01", 18);
  const strike = modalData.price.div(2).div(cent).mul(cent);
  const targetTokens = modalData.discount.gt(0)
    ? data.lmOwed.mul(ONE.add(modalData.bonus)).div(modalData.discount)
    : ZERO;
  const extraFields = (
    <div className="mb-4">
      <div className="flex">
        <div className="label mb-0 flex-1">RDO Available for rewards</div>
        <div>{formatNumber(modalData.available, 18, 0)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">Current price</div>
        <div>$ {formatNumber(modalData.price, 18, 3)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">
          Discounted option strike price (-
          {formatNumber(modalData.discount, 16, 0)}%)
        </div>
        <div>$ {formatNumber(strike, 18, 3)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">Your earned RDO</div>
        <div>{formatNumber(data.lmOwed, 18, 0)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">Tokens you would receive</div>
        <div>{formatNumber(targetTokens, 18, 0)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">Cost of exercising</div>
        <div>$ {formatNumber(targetTokens.mul(strike).div(ONE), 18, 2)}</div>
      </div>
      <div className="flex">
        <div className="label mb-0 flex-1">Value of underlying</div>
        <div>
          $ {formatNumber(targetTokens.mul(modalData.price).div(ONE), 18, 2)}
        </div>
      </div>
    </div>
  );

  return (
    <ActionModal
      title="Claim rewards as oRDO"
      description="When there is RDO available, you can claim your rewards as oRDO option token. They are option tokens with a discounted strike price. In order to make up for the fact that you need to pay USDC to excercise them, Rodeo will provide you with extra tokens on top of the amount you are owed."
      action="Claim"
      extraFields={extraFields}
      onSubmit={onSubmit}
      onReload={onReload}
      onHide={() => setModal()}
    />
  );
}
