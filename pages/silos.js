import { useState, useEffect } from "react";
import Layout from "../components/layout";
import {
  ONE,
  ZERO,
  parseUnits,
  formatNumber,
  useWeb3,
  runTransaction,
} from "../utils";
import ModalSilosMint from "../components/modals/silosMint";
import ModalSilosBurn from "../components/modals/silosBurn";
import ModalSilosAllocate from "../components/modals/silosAllocate";
import ModalSilosDeallocate from "../components/modals/silosDeallocate";

export default function Silos() {
  const { contracts, address, networkName } = useWeb3();
  const [data, setData] = useState({
    totalSupply: ZERO,
    allocations: [ZERO, ZERO, ZERO],
    userTotal: ZERO,
    userAllocated: ZERO,
    userAllocations: [ZERO, ZERO, ZERO],
    tokenBalance: ZERO,
    tokenAllowance: ZERO,
    claimableRdo: ZERO,
    claimableUsdc: ZERO,
  });
  const [modal, setModal] = useState(null);

  async function fetchData() {
    const totalSupply = await contracts.tokenStaking.totalSupply();
    const allocations = [
      (await contracts.tokenStaking.plugins(0))[0],
      (await contracts.tokenStaking.plugins(1))[0],
      (await contracts.tokenStaking.plugins(2))[0],
    ];
    const user = await contracts.tokenStaking.getUser(address, 3);
    const [claimableRdo] = await contracts.tokenStakingDividends.claimable(
      address,
      0
    );
    const [claimableUsdc] = await contracts.tokenStakingDividends.claimable(
      address,
      1
    );
    setData({
      totalSupply,
      allocations,
      userTotal: user[0],
      userAllocated: user[1],
      userAllocations: user[2],
      tokenBalance: await contracts.token.balanceOf(address),
      tokenAllowance: await contracts.token.allowance(
        address,
        contracts.tokenStaking.address
      ),
      claimableRdo,
      claimableUsdc,
    });
  }

  useEffect(() => {
    fetchData();
  }, [address, networkName]);

  async function onDividendsClaim() {
    const call = contracts.tokenStakingDividends.claim();
    await runTransaction(
      call,
      "Claiming dividends...",
      "Dividends claimed",
      true,
      "arbitrum"
    );
  }

  return (
    <Layout title="Silos">
      <div className="card grid-4 mb-4">
        <div>
          <div className="label">Total xRDO</div>
          <div className="font-lg">{formatNumber(data.userTotal, 18, 1)}</div>
        </div>
        <div>
          <div className="label">Available xRDO</div>
          <div className="font-lg">
            {formatNumber(data.userTotal.sub(data.userAllocated), 18, 1)}
          </div>
        </div>
        <div>
          <div className="label">Allocated xRDO</div>
          <div className="font-lg">
            {formatNumber(data.userAllocated, 18, 1)}
          </div>
        </div>
        <div className="grid-2">
          <button className="button" onClick={() => setModal({ type: "mint" })}>
            Convert
          </button>
          <button
            className="button button-link"
            onClick={() => setModal({ type: "burn" })}
          >
            Redeem
          </button>
        </div>
      </div>
      <div className="grid-3">
        <div className="card">
          <h2 className="title mt-0 font-bold">Dividends</h2>
          <div className="label">Your allocation</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.userAllocations[0], 18, 1)}
          </div>
          <div className="label">Total allocations</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.allocations[0], 18, 1)}
          </div>
          <div className="label">Deallocation fee</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(1, 0, 1)} %
          </div>
          <div className="label">APY</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(
              data.allocations[0].gt(0)
                ? parseUnits("239824", 18).mul(ONE).div(data.allocations[0])
                : ZERO,
              16,
              1
            )}{" "}
            %
          </div>

          <div className="grid-2 mb-4">
            <button
              className="button"
              onClick={() => setModal({ type: "allocate", index: 0 })}
            >
              Allocate
            </button>
            <button
              className="button button-link"
              onClick={() => setModal({ type: "deallocate", index: 0 })}
            >
              De-allocate
            </button>
          </div>

          <h3 className="subtitle">Earned dividends</h3>

          <div className="grid-2 mb-4">
            <div className="card">
              <div className="label">Earned xRDO</div>
              <div className="font-lg font-bold">
                {formatNumber(data.claimableRdo, 18, 2)}
              </div>
            </div>
            <div className="card">
              <div className="label">Earned USDC</div>
              <div className="font-lg font-bold">
                {formatNumber(data.claimableUsdc, 6, 2)}
              </div>
            </div>
          </div>

          <button
            className="button button-link w-full"
            onClick={onDividendsClaim}
          >
            Collect
          </button>

          <div className="font-sm mt-4">
            Allocate xRDO here to earn real yield in the form a share of
            protocol revenue. All non RDO revenue (performance fees, liquidation
            fees, etc) are converted to USDC. All RDO revenue (early exit fees,
            deallocation fees, etc) are converted to xRDO.
          </div>
        </div>

        <div className="card">
          <h2 className="title mt-0 font-bold">Fence</h2>
          <div className="label">Your allocation</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.userAllocations[1], 18, 1)}
          </div>
          <div className="label">Total allocations</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.allocations[1], 18, 1)}
          </div>
          <div className="label">Deallocation fee</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(0, 0, 1)} %
          </div>

          <div className="grid-2 mb-4">
            <button
              className="button"
              onClick={() => setModal({ type: "allocate", index: 1 })}
            >
              Allocate
            </button>
            <button
              className="button button-link"
              onClick={() => setModal({ type: "deallocate", index: 1 })}
            >
              De-allocate
            </button>
          </div>

          <div className="font-sm mt-4">
            Allocate xRDO here to gain access to increased leverage on your farm
            positions and even access to exclusive farms. Most farms with a
            `Fence` allocation requirement will scale with your position size.
          </div>
        </div>

        <div className="card">
          <h2 className="title mt-0 font-bold">???</h2>
          <div className="label">Your allocation</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.userAllocations[2], 18, 1)}
          </div>
          <div className="label">Total allocations</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(data.allocations[2], 18, 1)}
          </div>
          <div className="label">Deallocation fee</div>
          <div className="font-xl font-bold mb-4">
            {formatNumber(0, 0, 1)} %
          </div>

          <div className="grid-2 mb-4">
            <button
              className="button"
              onClick={() => setModal({ type: "allocate", index: 2 })}
            >
              Allocate
            </button>
            <button
              className="button button-link"
              onClick={() => setModal({ type: "deallocate", index: 2 })}
            >
              De-allocate
            </button>
          </div>

          <div className="font-sm mt-4">
            Allocate xRDO here to be really early to the mystery silo that is
            soon<sup>tm</sup> to be unveiled.
          </div>
        </div>
      </div>

      {modal && modal.type == "mint" ? (
        <ModalSilosMint
          data={data}
          onClose={() => setModal()}
          onReload={fetchData}
        />
      ) : null}
      {modal && modal.type == "burn" ? (
        <ModalSilosBurn
          data={data}
          onClose={() => setModal()}
          onReload={fetchData}
        />
      ) : null}
      {modal && modal.type == "allocate" ? (
        <ModalSilosAllocate
          data={data}
          index={modal.index}
          onClose={() => setModal()}
          onReload={fetchData}
        />
      ) : null}
      {modal && modal.type == "deallocate" ? (
        <ModalSilosDeallocate
          data={data}
          index={modal.index}
          onClose={() => setModal()}
          onReload={fetchData}
        />
      ) : null}
    </Layout>
  );
}
