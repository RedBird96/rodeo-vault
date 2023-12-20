import { useRef, useState, useEffect } from "react";
import { toast } from "react-toastify";
import { ethers } from "ethers";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";
import { publicProvider } from "wagmi/providers/public";
import {
  configureChains,
  createClient,
  useSigner as wagmiUseSigner,
  useProvider as wagmiUseProvider,
  useAccount,
  useNetwork,
} from "wagmi";
import * as wagmiChains from "wagmi/chains";
import { getDefaultWallets } from "@rainbow-me/rainbowkit";
import Icon from "./components/icon";

const isLocal = true;
  // typeof window !== "undefined"
  //   ? window.location.hostname === "localhost"
  //   : false;

const isStaging = process.env.NEXT_PUBLIC_RODEO_ENV == "staging";

export const apiServerHost = isLocal
  ? "http://localhost:4000"
  : isStaging
  ? " https://api-testing.rodeofinance.xyz"
  : "https://api.rodeofinance.xyz";

export const ZERO = ethers.utils.parseUnits("0");
export const ONE = ethers.utils.parseUnits("1");
export const ONE6 = ethers.utils.parseUnits("1", 6);
export const ONE12 = ethers.utils.parseUnits("1", 12);
export const MAX_UINT256 = ethers.constants.MaxUint256;
export const YEAR = 365 * 24 * 60 * 60;
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
export const DEAD_ADDRESS = "0x00000000000000000000000000000000DeaDBeef";
export const DEFAULT_CHAIN_ID = 42161;
export const DEFAULT_NETWORK_NAME = "arbitrum";
export const DONUT_COLORS = {
  0: "#df8418",
  1: "#D9D9D9",
  2: "#f5cea0",
  3: "#fcf3e7",
  4: "#fcf3e7",
  5: "#fcf3e7",
};
export const SILO_NAMES = {
  0: "Dividends",
  1: "Fence",
  2: "???",
};

export const Mode = {
  Deposit: 0,
  Withdraw: 1
}
export const contracts = {
  investor: "0x8accf43Dd31DfCd4919cc7d65912A475BfA60369",
  investorHelper: "0x6f456005A7CfBF0228Ca98358f60E6AE1d347E18",
  positionManager: "0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6",
  liquidityMiningOld: "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1",
  liquidityMining: "0x3aEe6cA602C060883201B89c64cb5F782F964879",
  liquidityMiningHelper: "0xDb08658e207C68FaB77af69d76388f06C5Bb5351",
  liquidityMiningPluginXrdo: "0xbEed577c773ac2610C018e0c444dA4F7Adc93df2",
  liquidityMiningPluginOrdo: "0xF6908dc494914338b14ade3b743F5f50168c752d",
  privateInvestors: "0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463",
  privateInvestorsRewarder: "0xE38581a771B5A0bdf13D61fbf1E5efB3BbbFbFc3",
  vester: "0xbb5032d20b689d9eE69A7C490Bd02Fc9efC734c2",
  tokenStaking: "0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D",
  tokenStakingDividends: "0x40aDa8CE51aD45a0211a7f495A526E26e4b3b5Ea",
  token: "0x033f193b3Fceb22a440e89A2867E8FEE181594D9",
  lpToken: "0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39",
  tokenOracle: "0x309349d5D02C6f8b50b5040e9128E1A8375042D7",
};
if (process.env.NEXT_PUBLIC_RODEO_ENV === "staging") {
  contracts.investor = "0x3A806d2D7DbdbeE3aA5cD75BA9d737fc682ce367";
  contracts.investorHelper = "0x9d35CBC1F2FE7464E503ac447775668eB2832C28";
  contracts.positionManager = "0xbb2c59E4ea21f15cD43F915ed470C78E647F55eb";
}

export function call(signer, address, fn, ...args) {
  let [name, params, returns] = fn.split("-");
  const rname = name[0] === "+" ? name.slice(1) : name;
  let efn = `function ${rname}(${params}) external`;
  if (name[0] !== "+") efn += " view";
  if (returns) efn += ` returns (${returns})`;

  const contract = new ethers.Contract(address, [efn], signer);
  return contract[rname](...args);
}

const globalStateAtom = atom({
  tvl: ZERO,
  tokenomics: {},
  assets: [],
  pools: [],
  strategies: [],
  vault_pools: []
});

export function useGlobalState() {
  const provider = wagmiUseProvider();
  const signerData = wagmiUseSigner();
  const signer =
    signerData.isSuccess && !signerData.isFetching && signerData.data
      ? signerData.data
      : provider;
  const [state, setState] = useAtom(globalStateAtom);

  async function fetchData() {
    const res = await fetch(apiServerHost, { mode: "cors" });
    const state = await res.json();

    ////////test data//////////////////
    const tempData = {
      gross_apy: 8,
      performance_fee: 0.62,
      exit_fee: 0.02,
      management_fee: 0.77,
      net_apy: 0.2,
      tvl: 0,
      cap: 0,
      locked_amount: 0,
      volume: 0,
      asset: '0xCa13ea158e11DE30FF5FBb37d231C9B93849B2BA',
      address: '0x08eccD9A9A8845Adc96A4e9a8c5f925698d5D532'
    }
    state.vault_pools.push(tempData);
    ////////////////////////////////////

    for (let p of state.pools) {
      p.borrowMin = parseUnits(p.borrowMin || "0", 0);
      p.cap = parseUnits(p.cap || "0", 0);
      p.index = parseUnits(p.index || "0", 0);
      p.shares = parseUnits(p.shares || "0", 0);
      p.supply = parseUnits(p.supply || "0", 0);
      p.borrow = parseUnits(p.borrow || "0", 0);
      p.rate = parseUnits(p.rate || "0", 0);
      p.price = parseUnits(p.price || "0", 0);
      p.lmRate = await call(
        signer,
        contracts.liquidityMining,
        "rewardPerDay--uint256"
      );
      p.lmBalance = await call(
        signer,
        contracts.liquidityMining,
        "poolInfo-uint256-uint256",
        0
      );
      p.utilization = p.supply.gt(0) ? p.borrow.mul(ONE).div(p.supply) : ZERO;
      p.apr = p.rate.mul(YEAR).mul(p.utilization).div(ONE);
      p.conversionRate = p.supply.mul(ONE).div(p.shares);
      const tokenPrice = await call(
        signer,
        contracts.tokenOracle,
        "latestAnswer--int256"
      );
      p.lmApr = p.lmBalance.gt(0)
        ? p.lmRate
            .mul(365)
            .mul(tokenPrice)
            .div(p.lmBalance.mul(p.conversionRate).div(ONE6))
        : ZERO;
    }

    for (let v of state.vault_pools) {
      v.tvl = parseUnits(/*v.tvl || */"0", 0);
      v.cap = parseUnits(/*v.cap || */"0", 0);
      v.locked_amount = parseUnits(/*v.locked_amount || */"0", 0);
      v.volume = parseUnits(/*v.volume || */"0", 0);
      v.net_apy = v.gross_apy * (1 - v.performance_fee);
    }

    for (let s of state.strategies) {
      s.cap = parseUnits(s.cap || "0", 0);
      s.apy = parseUnits(s.apy || "0", 0);
      s.tvl = parseUnits(s.tvl || "0", 0);
      s.tvlTotal = parseUnits(s.tvlTotal || "0", 0);

      const defaultLeverage = s.apyType === "traderjoe" ? "1" : "5";
      s.leverage = parseUnits(defaultLeverage, 18);
      s.apyWithLeverage = s.apy;
      try {
        const pool = state.pools[0]; // TODO pick better
        s.apyWithLeverage = s.apy
          .mul(s.leverage)
          .div(ONE)
          .sub(pool.rate.mul(YEAR).mul(s.leverage.sub(ONE)).div(ONE));
        if (s.apyWithLeverage.lt(0)) {
          s.leverage = ONE;
          s.apyWithLeverage = s.apy;
        }
      } catch (e) {}
    }
    state.strategies.push({
      index: 22,
      slug: "traderjoe-eth-usdc",
      name: "USDC/ETH",
      protocol: "TraderJoe",
      icon: "/protocols/traderjoe.png",
      address: "0x5f06285DCeB3B19e77F49B64Eb2A78BBF423A863",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });
    state.strategies.push({
      index: 31,
      slug: "traderjoe-arb-eth",
      name: "ARB/ETH",
      protocol: "TraderJoe",
      icon: "/protocols/traderjoe.png",
      address: "0xbdb9615F6937a7B3632B4ef8b575BEcE0A0141d4",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });
    state.strategies.push({
      index: 23,
      slug: "traderjoe-magic-eth",
      name: "MAGIC/ETH",
      protocol: "TraderJoe",
      icon: "/protocols/traderjoe.png",
      address: "0x0BEe104911cd5957B0847935286E3C5C0CAE9560",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });
    state.strategies.push({
      index: 34,
      slug: "traderjoe-joe-eth",
      name: "JOE/ETH",
      protocol: "TraderJoe",
      icon: "/protocols/traderjoe.png",
      address: "0xD8aF3FCdC7f2dd7abA4D18c838CF017be98d7ea5",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });
    state.strategies.push({
      index: 35,
      slug: "balancer-rdnt-eth",
      name: "RDNT/ETH",
      protocol: "Balancer",
      icon: "/protocols/balancer.svg",
      address: "0x2882BE90D7150D26EEaf0A6791e5a6B2b2Fa1a05",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });
    state.strategies.push({
      index: 16,
      slug: "curve-tricrypto",
      name: "WBTC/ETH/USDT",
      protocol: "Curve",
      icon: "/protocols/curve.svg",
      address: "0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6",
      status: 4,
      cap: ZERO,
      apy: ZERO,
      tvl: ZERO,
      tvlTotal: ZERO,
      hidden: true,
    });

    setState(state);
  }

  useEffect(() => {
    fetchData();
    const handle = setInterval(fetchData, 30 * 1000);
    return () => clearInterval(handle);
  }, []);

  return { state, reload: fetchData };
}

export async function tokensOfOwner(provider, tokenAddress, account) {
  const network = await provider.getNetwork();
  try {
    if (network.chainId === 42161 && !isStaging) {
      let ids = [];
      let res = {};
      do {
        res = await (
          await fetch(
            process.env.NEXT_PUBLIC_RODEO_RPC_URL_ARBITRUM +
              `/getNFTs?withMetadata=false&pageKey=${
                res.pageKey || ""
              }&owner=${account}&contractAddresses%5B%5D=${tokenAddress}`
          )
        ).json();
        ids = ids.concat(
          res.ownedNfts.map((n) => parseInt(n.id.tokenId.slice(2), 16))
        );
      } while (res.pageKey);
      return ids;
    }
  } catch (e) {
    console.error("failed to fetch nfts using alchemy, defaulting to rpc", e);
  }
  const token = await new ethers.Contract(
    tokenAddress,
    [
      "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)",
    ],
    provider
  );

  const sentLogs = await token.queryFilter(
    token.filters.Transfer(account, null, null)
  );
  const receivedLogs = await token.queryFilter(
    token.filters.Transfer(null, account, null)
  );

  const logs = sentLogs
    .concat(receivedLogs)
    .sort(
      (a, b) =>
        a.blockNumber - b.blockNumber || a.transactionIndex - b.transactionIndex
    );

  const owned = new Set();
  for (const {
    args: { from, to, tokenId },
  } of logs) {
    if (to.toLowerCase() === account.toLowerCase()) {
      owned.add(tokenId.toString());
    } else if ((from.toLowerCase(), account.toLowerCase())) {
      owned.delete(tokenId.toString());
    }
  }
  return Array.from(owned);
}

const atomPositionIds = atom([]);
const atomPositions = atom({});

export function usePositions() {
  const { state } = useGlobalState();
  const { provider, address, networkName, contracts } = useWeb3();
  const [positionIds, setPositionIds] = useAtom(atomPositionIds);
  const [positions, setPositions] = useAtom(atomPositions);

  async function fetchData(address) {
    if (!address || !contracts) return;
    const ids = await tokensOfOwner(
      provider,
      contracts.positionManager.address,
      address
    );
    ids.sort((a, b) => parseInt(b) - parseInt(a));
    setPositionIds(ids);

    async function fetchPosition(id, address) {
      try {
        const values = await contracts.investorHelper.peekPosition(id);
        const index = values[1].toNumber();
        const strategy = state.strategies.find((s) => s.index === index);
        if (!strategy) return null;
        const pool = state.pools.find((p) => p.address === values[0]);
        const asset = state.assets[pool.asset];
        const poolContract = contracts.pool(pool.address);
        const priceAdjusted = values[8]
          .mul(ONE)
          .div(parseUnits("1", asset.decimals));

        const p = {
          id: id,
          address: address,
          pool: values[0],
          strategy: values[1].toNumber(),
          shares: values[2],
          sharesAst: values[4]
            .mul(ONE)
            .div(values[8])
            .mul(parseUnits("1", asset.decimals))
            .div(ONE),
          sharesUsd: values[4],
          borrow: values[3],
          borrowAst: values[5],
          borrowUsd: values[5].mul(priceAdjusted).div(ONE),
          amountAst: values[7],
          amountUsd: values[7].mul(priceAdjusted).div(ONE),
          health: values[6],
          assetPrice: values[8],
          strategyInfo: strategy,
          assetInfo: asset,
          poolInfo: pool,
          /*
          svg: JSON.parse(
            atob((await contracts.positionManager.tokenURI(id)).split(",")[1])
          ).image,
          */
        };

        p.profitUsd = p.sharesUsd
          .sub(p.amountUsd)
          .sub(p.borrowUsd)
          .mul(90)
          .div(100);
        p.profitPercent = ZERO;
        p.liquidationPercent = ZERO;
        if (p.amountUsd.gt(ZERO) && p.sharesUsd.gt(ZERO)) {
          p.profitPercent = p.profitUsd.mul(ONE).div(p.amountUsd);
          p.liquidationUsd = p.borrowUsd.mul(100).div(95);
          p.liquidationPercent = ONE.sub(
            p.liquidationUsd.mul(ONE).div(p.sharesUsd)
          );
          if (p.sharesUsd.gt(0)) {
            p.leverage = p.borrowUsd
              .mul(ONE)
              .div(p.sharesUsd.sub(p.borrowUsd))
              .add(ONE);
          }
        }

        if (strategy.name === "GLP") {
          const glpManager = new ethers.Contract(
            "0x3963ffc9dff443c2a94f21b129d429891e32ec18",
            ["function getAumInUsdg(bool) view returns (uint256)"],
            provider
          );
          const glp = new ethers.Contract(
            "0x4277f8f2c384827b5273592ff7cebd9f2c1ac258",
            ["function totalSupply() view returns (uint256)"],
            provider
          );
          if (window.glpPrice) {
            p.glpPrice = window.glpPrice;
          } else {
            const aumInUsdg = await glpManager.getAumInUsdg(false);
            const totalSupply = await glp.totalSupply();
            p.glpPrice = window.glpPrice = aumInUsdg.mul(ONE).div(totalSupply);
          }
        }

        return p;
      } catch (e) {
        console.error("ERROR FETCHING POSITION", id, e);
        return null;
      }
    }

    for (let p in positions) {
      if (ids.includes(p.index)) {
        setPositions((positions) => ({ ...positions, [id]: null }));
      }
    }
    ids.forEach(async (id) => {
      const position = await fetchPosition(id, address);
      if (!position) return;
      setPositions((positions) => ({ ...positions, [id]: position }));
    });
  }

  useEffect(() => {
    if (state.strategies.length === 0) return;
    fetchData(address).then(
      () => {},
      (e) => {
        console.error("positions", e);
      }
    );
  }, [networkName, address, state]);

  return {
    data: Object.values(positions)
      .filter((p) => p && p.address === address)
      .sort((a, b) => b.index - a.index),
    refetch: fetchData,
  };
}

export const ADDRESSES = {
  arbitrum: isStaging
    ? {
        investor: "0x3A806d2D7DbdbeE3aA5cD75BA9d737fc682ce367",
        investorHelper: "0x9d35CBC1F2FE7464E503ac447775668eB2832C28",
        positionManager: "0xbb2c59E4ea21f15cD43F915ed470C78E647F55eb",
        liquidityMining: "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1",
        privateInvestors: "0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463",
        privateInvestorsRewarder: "0xE38581a771B5A0bdf13D61fbf1E5efB3BbbFbFc3",
        vester: "0xbb5032d20b689d9eE69A7C490Bd02Fc9efC734c2",
        tokenStaking: "0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D",
        tokenStakingDividends: "0x40aDa8CE51aD45a0211a7f495A526E26e4b3b5Ea",
        token: "0x033f193b3Fceb22a440e89A2867E8FEE181594D9",
      }
    : {
        investor: "0x8accf43Dd31DfCd4919cc7d65912A475BfA60369",
        investorHelper: "0x6f456005A7CfBF0228Ca98358f60E6AE1d347E18",
        positionManager: "0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6",
        liquidityMining: "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1",
        privateInvestors: "0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463",
        privateInvestorsRewarder: "0xE38581a771B5A0bdf13D61fbf1E5efB3BbbFbFc3",
        vester: "0xbb5032d20b689d9eE69A7C490Bd02Fc9efC734c2",
        tokenStaking: "0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D",
        tokenStakingDividends: "0x40aDa8CE51aD45a0211a7f495A526E26e4b3b5Ea",
        token: "0x033f193b3Fceb22a440e89A2867E8FEE181594D9",
      },
  "arbitrum-rinkeby": {
    investor: "0x057c7a9627eff1d7054cde31015bcd1ede9a612d",
    investorHelper: "0x60923cf52f5ac7ce145bd3a5b34de02632fa4f50",
    positionManager: "0x54978E353C057aa6e3011cF819fBe08200814477",
  },
  "sepolia": {
    investor: "0x8accf43Dd31DfCd4919cc7d65912A475BfA60369",
    investorHelper: "0x6f456005A7CfBF0228Ca98358f60E6AE1d347E18",
    positionManager: "0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6",
    liquidityMining: "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1",
    privateInvestors: "0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463",
    privateInvestorsRewarder: "0xE38581a771B5A0bdf13D61fbf1E5efB3BbbFbFc3",
    vester: "0xbb5032d20b689d9eE69A7C490Bd02Fc9efC734c2",
    tokenStaking: "0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D",
    tokenStakingDividends: "0x40aDa8CE51aD45a0211a7f495A526E26e4b3b5Ea",
    token: "0x033f193b3Fceb22a440e89A2867E8FEE181594D9",
  },
  localhost: {
    investor: "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318",
    investorHelper: "0x959922be3caee4b8cd9a407cc3ac1c251c2007b1",
    positionManager: "0x9a9f2ccfde556a7e9ff0848998aa4a0cfd8863ae",
    liquidityMining: "0x68b1d87f95878fe05b998f19b66f4baba5de1aed",
  },
};

export const EXPLORER_URLS = {
  arbitrum: "arbiscan.io",
  sepolia: "sepolia.etherscan.io",
  "arbitrum-rinkeby": "testnet.arbiscan.io",
  localhost: "arbiscan.io",
};

export const rpcUrl =
  process.env.NEXT_PUBLIC_RODEO_RPC_URL_ARBITRUM ||
  "https://arb1.arbitrum.io/rpc";

export const rpcUrls = {
  42161: { http: rpcUrl },
  11155111: {http: "https://ethereum-sepolia.publicnode.com"},
  421611: { http: "https://rinkeby.arbitrum.io/rpc" },
  1337: { http: "http://localhost:8545" },
};

if (global.window) {
  window.ethers = ethers;
  window.provider = new ethers.providers.JsonRpcProvider(rpcUrl);
}

export const { chains, provider } = configureChains(
  [
    wagmiChains.arbitrum,
    wagmiChains.sepolia,
    ...(global.window && window.location.hostname === "localhost"
      ? [wagmiChains.localhost]
      : []),
  ],
  [
    jsonRpcProvider({
      rpc: (chain) => rpcUrls[chain.id],
    }),
  ]
);

const { connectors } = getDefaultWallets({
  appName: "Rodeo",
  projectId: "e86d5a5950be6b9f9e50f6d27285ef84",
  chains,
});

export const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
});

export function atom(initial = null) {
  let value = initial;
  let listeners = [];
  let listen = (fn) => {
    listeners.push(fn);
    return () => listeners.splice(listeners.indexOf(fn), 1);
  };
  let set = (v) => {
    if (typeof v === "function") v = v(value);
    value = v;
    listeners.forEach((fn) => fn());
  };
  return { get: () => value, set, listen };
}

export function useAtom(a) {
  let [value, setValue] = useState(a.get());
  useEffect(() => {
    let fn = () => setValue(a.get());
    return a.listen(fn);
  }, []);
  return [value, a.set];
}

export const parseUnits = ethers.utils.parseUnits;
export const formatUnits = ethers.utils.formatUnits;

export function bnToFloat(n) {
  return n.div(parseUnits("1", 12)).toNumber() / 1e6;
}

export function bnMin(a, b) {
  return a.lt(b) ? a : b;
}

export function bnMax(a, b) {
  return a.gt(b) ? a : b;
}

export function useSigner() {
  const { data: signer } = wagmiUseSigner();
  return signer;
}
export const useProvider = wagmiUseProvider;

export function useWeb3() {
  const provider = useProvider();
  const signer = wagmiUseSigner();
  const signerOrProvider =
    signer.isSuccess && !signer.isFetching && signer.data
      ? signer.data
      : provider;
  let { address, status: walletStatus } = useAccount();
  const { chain } = useNetwork();
  // For Production
  // const networkName = DEFAULT_NETWORK_NAME;
  // const chainId = DEFAULT_CHAIN_ID;
  const networkName = chain?.network || DEFAULT_NETWORK_NAME;
  const chainId = chain?.id || DEFAULT_CHAIN_ID;
  const contracts = getContracts(signerOrProvider, networkName);

  if (global.window && window.localStorage.getItem("mockAddress")) {
    address = window.localStorage.getItem("mockAddress");
  }

  return {
    provider: provider,
    signer: signerOrProvider,
    address: address || DEAD_ADDRESS,
    walletStatus,
    chainId,
    networkName,
    contracts,
  };
}

export function getContracts(signer, networkName) {
  const addresses = ADDRESSES[networkName];
  if (!signer) return null;
  if (!addresses) return null;
  const buildAsset = (address) => {
    return new ethers.Contract(
      address,
      [
        "function symbol() view returns (string)",
        "function totalSupply() view returns (uint)",
        "function balanceOf(address) view returns (uint)",
        "function allowance(address, address) view returns (uint)",
        "function approve(address, uint)",
      ],
      signer
    );
  };
  return {
    token: buildAsset(addresses.token),
    investor: new ethers.Contract(
      addresses.investor,
      [
        "error Unauthorized()",
        "error TransferFailed()",
        "error InsufficientAllowance()",
        "error InsufficientAmountForRepay()",
        "error InvalidPool()",
        "error InvalidStrategy()",
        "error PositionNotLiquidatable()",
        "error Undercollateralized()",
        "error OverMaxBorrowFactor()",
        "function strategies(uint) view returns (address)",
        "function nextPosition() view returns (uint)",
        "function nextStrategy() view returns (uint)",
        "function positions(uint) view returns (address, address, uint, uint, uint, uint, uint)",
      ],
      signer
    ),
    investorHelper: new ethers.Contract(
      addresses.investorHelper,
      [
        "function peekPools(address[]) view returns (uint[], uint[], uint[], uint[], uint[], uint[])",
        "function peekPoolInfos(address[]) view returns (address[], bool[], uint[], uint[], uint[], uint[])",
        "function peekPosition(uint) view returns (address, uint, uint, uint, uint, uint, uint, uint, uint)",
      ],
      signer
    ),
    positionManager: new ethers.Contract(
      addresses.positionManager,
      [
        "error WaitBeforeSelling()",
        "error InsufficientShares()",
        "error InsufficientBorrow()",
        "error CantBorrowAndDivest()",
        "error OverMaxBorrowFactor()",
        "error PositionNotLiquidatable()",
        "error InsufficientAmountForRepay()",
        "function ownerOf(uint) view returns (address)",
        "function tokenURI(uint) view returns (string)",
        "function mint(address, address, uint, uint, uint, bytes)",
        "function edit(uint, int, int, bytes)",
        "function burn(uint)",
      ],
      signer
    ),
    tokenStaking: new ethers.Contract(
      addresses.tokenStaking,
      [
        "function totalSupply() view returns (uint)",
        "function plugins(uint) view returns (uint,address,uint,address)",
        "function getUser(address,uint) view returns (uint,uint,uint[])",
        "function mint(uint,address)",
        "function burn(uint,uint)",
        "function allocate(uint,uint)",
        "function deallocate(uint,uint)",
      ],
      signer
    ),
    tokenStakingDividends: new ethers.Contract(
      addresses.tokenStakingDividends,
      [
        "function claimable(address,uint) view returns (uint,int)",
        "function claim()",
      ],
      signer
    ),
    liquidityMining: new ethers.Contract(
      addresses.liquidityMining,
      [
        "function rate() view returns (uint)",
        "function users(address) view returns (uint,int256)",
        "function getPending(address) view returns (uint)",
        "function deposit(uint,address)",
        "function withdraw(uint,address)",
        "function harvest(address)",
      ],
      signer
    ),
    privateInvestors: new ethers.Contract(
      addresses.privateInvestors,
      [
        "function totalDeposits() view returns (uint)",
        "function getUser(address) view returns (uint,uint,bool)",
        "function deposit(uint)",
      ],
      signer
    ),
    privateInvestorsRewarder: new ethers.Contract(
      addresses.privateInvestorsRewarder,
      [
        "function claim()",
        "function getInfo(address) view returns (uint,uint,uint,uint)",
      ],
      signer
    ),
    vester: new ethers.Contract(
      addresses.vester,
      [
        "function claim(uint,address)",
        "function schedulesCount(address) view returns (uint)",
        "function getSchedulesInfo(address,uint,uint) view returns (uint[],address[],uint[],uint[],uint[])",
        "function getSchedules(address,uint,uint) view returns (uint[],uint[],uint[])",
      ],
      signer
    ),
    asset: buildAsset,
    pool: (address) =>
      new ethers.Contract(
        address,
        [
          "function oracle() view returns (address)",
          "function borrowMin() view returns (uint)",
          "function mint(uint, address)",
          "function burn(uint, address)",
        ],
        signer
      ),
    strategy: (address) =>
      new ethers.Contract(
        address,
        [
          "function totalShares() view returns (uint)",
          "function rate(uint) view returns (uint)",
          "function cap() view returns (uint)",
          "function status() view returns (uint)",
        ],
        signer
      ),
    vault: (address) =>
      new ethers.Contract(
        address,
        [
          "function symbol() view returns (string)",
          "function totalSupply() view returns (uint)",
          "function balanceOf(address) view returns (uint)",
          "function allowance(address, address) view returns (uint)",
          "function approve(address, uint)",
          "function marketCapacity() view returns (uint)",
          "function totalAssets() view returns (uint)",
          "function strategy() view returns (address)"
        ],
        signer
      ),
      vaultStrategy: (address) =>
        new ethers.Contract(
          address,
          [
            "function getNetAssetsInfo() view returns (uint, uint, uint, uint)",
            "function getNetAssets() view returns (uint)",
            "function lendingLogic() view returns (address)"
          ],
          signer
      ),
      lendingLogic: (address) =>
        new ethers.Contract(
          address,
          [
            "function getNetAssetsInfo(address) view returns (uint, uint, uint, uint)"
          ],
          signer
        )
  };
}

export async function runTransaction(
  callPromise,
  progressContent,
  successContent,
  showExplorer = true,
  networkName
) {

  try {
    const tx = await callPromise;
    toast.dismiss();
    toast.info(<div>{progressContent}</div>, {
      position: "bottom-center",
      autoClose: false,
    });
    const receipt = await tx.wait();

    toast.dismiss();
    toast.success(
      <div>
        {successContent}
        <br />
        {showExplorer ? (
          <a
            href={`https://${EXPLORER_URLS[networkName]}/tx/${receipt.transactionHash}`}
            target="_blank"
            rel="noreferrer"
          >
            View in block explorer <Icon name="external-link" small />
          </a>
        ) : null}
      </div>,
      { position: "bottom-center", autoClose: showExplorer ? 10000 : 5000 }
    );
  } catch (err) {
    console.error("runTransaction:", err);
    toast.dismiss();
    throw err;
  }
}

export function formatHealthClassName(health) {
  if (health.eq(ONE)) return "text-green";
  if (health.lt(parseUnits("1.1", 18))) return "text-red";
  if (health.lt(parseUnits("1.5", 18))) return "text-yellow";
  return "text-green";
}

export function formatError(e) {
  const message =
    e?.data?.message ||
    e?.error?.data?.originalError?.message ||
    e.message ||
    String(e);
  if (message.includes("ERC20: transfer amount exceeds balance")) {
    return "Farm token balance too low for the moment";
  }
  if (message.includes("User denied transaction signature")) {
    return "You cancelled the transaction";
  }
  if (message.includes("user rejected transaction")) {
    return "You cancelled the transaction";
  }
  if (message.includes("MlpManager: cooldown duration not yet passed")) {
    return "Mycelium MLP on cooldown, wait 15 minutes and try again";
  }
  if (message.includes("cooldown duration not yet passed")) {
    return "Vela VLP on cooldown, wait 15 minutes and try again";
  }
  if (message.includes("GlpManager: cooldown duration")) {
    return "GMX GLP on cooldown, wait 15 minutes and try again";
  }
  if (message.includes("Vault: max USDG exceeded")) {
    return "GLP USDC deposits have reached maximum limit";
  }
  if (message.includes("Too little received")) {
    return "Slippage not high enough";
  }
  if (
    message.includes(
      "0x42581c740000000000000000000000000000000000000000000000000000000000000001"
    )
  ) {
    return "Leverage too high (max 10x)";
  }
  if (message.includes("0x42581c74")) {
    return (
      "Rodeo ranch owner blocked this action. Purchase more RDO? (" +
      e.error.data.data +
      ")"
    );
  }
  if (e?.error?.data?.data === "0x8618e15a") {
    return "Not enough oRDO bonus tokens left";
  }
  if (e?.error?.data?.data === "0xe273b446") {
    return "Borrow below minimum";
  }
  if (e?.error?.data?.data === "0xebb5bbef") {
    return "Not enough value withdrawn for borrow repay";
  }
  if (e?.error?.data?.data === "0xd7e991d2") {
    return "Deposit would put the pool above it's cap. Try a smaller amount or wait for space";
  }
  if (e?.error?.data?.data === "0x8e78f0cb") {
    return "Strategy is paused at the moment";
  }
  if (e?.error?.data?.data === "0x93799a61") {
    return "Lending pool is currently above it's maximum utilization. Wait for utilization to drop below the max again";
  }
  if (e?.error?.data?.data === "0x9e98b2b4") return "Slippage too high";
  if (e?.error?.data?.data === "0x584a7938") return "Not whitelisted";
  if (e?.error?.data?.data === "0x52df9fe5") return "All tokens have been sold";
  if (e?.error?.data?.data === "0xba93ede9") return "Closed for deposits";
  if (e?.error?.data?.data === "0x84b94f35") return "Not open for deposits yet";
  if (e?.error?.data?.data === "0x342fa66d")
    return "Deposit larger than allocation";
  if (message.includes("cannot estimate gas; transaction")) {
    if (!e.error) {
      return message;
    }
    if (!e.error.data.message) {
      return `${e.message} from:${e.transaction.from} data:${e.transaction.data}`;
    }
    return `${e.error.data.message} (${e.error.data.data}) from:${e.transaction.from} data:${e.transaction.data}`;
  }
  return message;
}

export function formatNumber(amount, decimals = 18, decimalsShown = 2) {
  if (typeof amount !== "number") {
    if (typeof amount === "string") {
      amount = parseUnits(amount, 0);
    }
    amount = parseFloat(ethers.utils.formatUnits(amount, decimals));
  }
  return Intl.NumberFormat("en-US", {
    useGrouping: true,
    minimumFractionDigits: decimalsShown,
    maximumFractionDigits: decimalsShown,
  }).format(amount);
}

export function formatAddress(address) {
  return address.slice(0, 6) + "…" + address.slice(-4);
}

export function formatDate(date) {
  if (date instanceof ethers.BigNumber) {
    date = date.toNumber() * 1000;
  }
  const d = new Date(date);
  if (d.getTime() === 0) return "N/A";
  const pad = (s) => ("0" + s).slice(-2);

  return [
    d.getFullYear() + "-",
    pad(d.getMonth() + 1) + "-",
    pad(d.getDate()) + " ",
    pad(d.getHours()) + ":",
    pad(d.getMinutes()),
  ].join("");
}

export function formatChartDate(date) {
  return `${date.getDate()}\
    ${date.toLocaleString("default", { month: "short" })}\
    ${date.getFullYear()}\
    ${String(date.getHours()).padStart(2, "0")}:${String(
    date.getMinutes()
  ).padStart(2, "0")}
    `;
}

export function formatKNumber(num, digits) {
  // return Math.abs(num) > 999 ? Math.sign(num)*((Math.abs(num)/1000).toFixed(1)) + 'K' : Math.sign(num)*Math.abs(num)

  const lookup = [
    { value: 1, symbol: "" },
    { value: 1e3, symbol: "k" },
    { value: 1e6, symbol: "M" },
    { value: 1e9, symbol: "G" },
    { value: 1e12, symbol: "T" },
    { value: 1e15, symbol: "P" },
    { value: 1e18, symbol: "E" }
  ];
  const rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
  var item = lookup.slice().reverse().find(function(item) {
    return num >= item.value;
  });
  return item ? (num / item.value).toFixed(digits).replace(rx, "$1") + item.symbol : "0";
}

export function capitalize(string) {
  return string[0].toUpperCase() + string.slice(1);
}
