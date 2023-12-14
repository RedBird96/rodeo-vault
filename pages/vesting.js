import { useState, useEffect } from "react";
import Image from "next/image";
import {
  ZERO_ADDRESS,
  useGlobalState,
  useWeb3,
  formatNumber,
  runTransaction,
  formatDate,
  atom,
  useAtom,
} from "../utils";

import SortCaret from "../components/sortCaret";
import Tooltip from "../components/tooltip";
import Layout from "../components/layout";

const vestingStatus = [
  {
    label: "Active",
    value: 0,
  },
  {
    label: "Completed",
    value: 1,
  },
];

const vestingAtom = atom([]);

export default function Vesting() {
  const { state } = useGlobalState();
  const [activeTab, setActiveTab] = useState(0);
  const [sortBy, setSortBy] = useState([]);
  const [sortOrder, setSortOrder] = useState(0);
  const { contracts, address, networkName } = useWeb3();
  const [vests, setVests] = useAtom(vestingAtom);

  async function fetchData() {
    const count = await contracts.vester.schedulesCount(address);
    const schedules = await contracts.vester.getSchedules(
      address,
      0,
      count.toNumber()
    );
    const infos = await contracts.vester.getSchedulesInfo(
      address,
      0,
      count.toNumber()
    );

    setVests(
      schedules[0].map((_, i) => ({
        id: i,
        amount: schedules[0][i],
        claimed: schedules[1][i],
        available: schedules[2][i],
        source: infos[0][i],
        token: infos[1][i],
        initial: infos[2][i],
        time: infos[3][i],
        start: infos[4][i],
      }))
    );
  }

  useEffect(() => {
    fetchData();
  }, [networkName]);

  let filteredVests = vests?.filter((vest) => {
    const done = vest?.amount.eq(vest?.claimed);
    return activeTab === 1 ? done : !done;
  });

  if (sortBy.length > 0) {
    if (sortOrder == 0 || sortOrder == 1) {
      filteredVests = filteredVests.sort((a, b) => {
        if (sortBy[0] === "token") {
          return a[sortBy[0]].localeCompare(b[sortBy[0]]);
        } else {
          return parseInt(a[sortBy[0]].sub(b[sortBy[0]]).toString());
        }
      });
    } else {
      filteredVests = filteredVests.sort((a, b) => {
        if (sortBy[0] === "token") {
          return b[sortBy[0]].localeCompare(a[sortBy[0]]);
        } else {
          return parseInt(b[sortBy[0]].sub(a[sortBy[0]]).toString());
        }
      });
    }
  }

  async function onClaim(index) {
    const call = await contracts.vester.claim(index, ZERO_ADDRESS);
    await runTransaction(
      call,
      "Claim is started...",
      "Claim completed.",
      true,
      networkName
    );
    fetchData();
    setTimeout(fetchData, 5000);
  }

  return (
    <Layout title="Vesting">
      <div className="flex justify-between">
        <div
          className="tabs"
          style={{
            width: "200px",
          }}
        >
          {vestingStatus.map((vesting, key) => {
            return (
              <a
                key={key}
                className={`tabs-tab ${
                  activeTab === vesting.value ? "active" : ""
                }`}
                onClick={() => setActiveTab(vesting.value)}
              >
                {vesting.label}
              </a>
            );
          })}
        </div>
      </div>

      <div className="mt-4">
        <div className="farms">
          <div className="mb-4">
            <div className="grid-6 label hide-phone">
              <div className="flex">
                <span
                  onClick={() => {
                    setSortOrder(
                      sortBy[0] !== "token" ? 1 : (sortOrder + 1) % 3
                    );
                    setSortBy(["token"]);
                  }}
                  style={{ cursor: "pointer" }}
                >
                  Token
                </span>
                <SortCaret
                  style={{ marginLeft: 5 }}
                  order={sortBy[0] === "token" ? sortOrder : 0}
                />
              </div>
              <div className="flex">
                <span
                  onClick={() => {
                    setSortOrder(
                      sortBy[0] !== "amount" ? 1 : (sortOrder + 1) % 3
                    );
                    setSortBy(["amount"]);
                  }}
                  style={{ cursor: "pointer" }}
                >
                  Claimed / Total
                </span>
                <SortCaret
                  style={{ marginLeft: 5 }}
                  order={sortBy[0] === "amount" ? sortOrder : 0}
                />
              </div>
              <div className="flex">
                <span
                  onClick={() => {
                    setSortOrder(
                      sortBy[0] !== "available" ? 1 : (sortOrder + 1) % 3
                    );
                    setSortBy(["available"]);
                  }}
                  style={{ cursor: "pointer" }}
                >
                  Claimable
                </span>
                <SortCaret
                  style={{ marginLeft: 5 }}
                  order={sortBy[0] === "available" ? sortOrder : 0}
                />
              </div>
              <div className="flex">
                <span
                  onClick={() => {
                    setSortOrder(
                      sortBy[0] !== "start" ? 1 : (sortOrder + 1) % 3
                    );
                    setSortBy(["start"]);
                  }}
                  style={{ cursor: "pointer" }}
                >
                  Start
                </span>
                <SortCaret
                  style={{ marginLeft: 5 }}
                  order={sortBy[0] === "start" ? sortOrder : 0}
                />
              </div>
              <div className="flex">
                <span
                  style={{ cursor: "pointer" }}
                  onClick={() => {
                    setSortOrder(
                      sortBy[0] !== "time" ? 1 : (sortOrder + 1) % 3
                    );
                    setSortBy(["time"]);
                  }}
                >
                  End
                </span>
                <SortCaret
                  style={{ marginLeft: 5 }}
                  order={sortBy[0] === "end" ? sortOrder : 0}
                />
              </div>
              <div></div>
            </div>
          </div>
          {filteredVests?.length === 0 ? (
            <div className="farm text-center py-16">
              No tokens vesting to your address yet
            </div>
          ) : (
            filteredVests?.map((vest, index) => (
              <Vest
                key={index}
                state={state}
                vest={vest}
                index={vest.id}
                onClaim={onClaim}
                networkName={networkName}
              />
            ))
          )}
        </div>
      </div>
    </Layout>
  );
}

function Vest({ state, vest, index, onClaim, networkName }) {
  const asset = state.assets[vest?.token];
  const start = formatDate(vest?.start);
  const end = formatDate(vest?.start.add(vest?.time));

  return (
    <div className="farm">
      <div className="grid-6">
        <div>
          <div className="label hide show-phone">Asset</div>
          <div className="flex">
            {asset?.icon ? (
              <div className="farm-icon hide-phone">
                <Image
                  src={asset?.icon}
                  width={24}
                  height={24}
                  alt={asset?.symbol}
                />
              </div>
            ) : null}
            <div>
              <b className="font-xl" style={{ lineHeight: 1 }}>
                {asset?.symbol}
              </b>
              <div className="hide-phone" style={{ opacity: "0.5" }}>
                {[
                  "",
                  "xRDO Redeem",
                  "Public Sale",
                  "Private Round",
                  "Private Rewards from xRDO exits",
                  "KOL",
                ][vest?.source] || "-"}
              </div>
            </div>
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Claimed / Total</div>
          <div>
            {formatNumber(vest?.claimed, asset?.decimals)} /{" "}
            {formatNumber(vest?.amount, asset?.decimals)}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Claimable</div>
          <div>
            {formatNumber(
              vest?.available.sub(vest?.claimed),
              asset?.decimals,
              4
            )}
          </div>
        </div>
        <div>
          <div className="label hide show-phone">Start</div>
          {start.split(" ")[0]}
        </div>
        <div>
          <div className="label hide show-phone">End</div>
          {end.split(" ")[0]}
        </div>
        <div>
          <div className="label hide show-phone">&nbsp;</div>
          <div>
            <button
              className="button button-small w-full"
              onClick={() => onClaim(index)}
            >
              Claim
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
