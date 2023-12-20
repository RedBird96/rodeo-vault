package main

import (
	"bytes"
	"context"
	"crypto/ecdsa"
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/big"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"reflect"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

var ZERO = bn(0, 0)
var YEAR = bn(365*24*60*60, 0)
var ONE = bn(1, 18)
var ONE6 = bn(1, 6)
var ONE8 = bn(1, 8)
var ONE10 = bn(1, 10)
var ONE12 = bn(1, 12)

var db *sqlx.DB
var client *ethclient.Client
var walletAddress common.Address
var walletKey *ecdsa.PrivateKey
var txOpts *bind.TransactOpts
var mux *http.ServeMux
var protocolTvl = ZERO
var taskEventsPositionsLock = &sync.Mutex{}
var tokenomics = &TokenomicsInfo{
	TokenPrice:             ZERO,
	MarketCap:              ZERO,
	MarketCapFullyDilluted: ZERO,
	SupplyCirculating:      ZERO,
	SupplyMax:              ZERO,
	SupplyTotal:            ZERO,
	SupplyPOL:              ZERO,
	SupplyXRDO:             ZERO,
	SupplyEcosystem:        ZERO,
	SupplyPartners:         ZERO,
	SupplyTeam:             ZERO,
	SupplyMultisig:         ZERO,
	SupplyDeployer:         ZERO,
}

var addressHelper = common.HexToAddress("0x988826F0fCDA660e769558A0bDDfE0ba6aDfFB8F")
var addressInvestor = common.HexToAddress("0x8accf43Dd31DfCd4919cc7d65912A475BfA60369")
var addressInvestorHelper = common.HexToAddress("0x6f456005A7CfBF0228Ca98358f60E6AE1d347E18")
var addressToken = common.HexToAddress("0x033f193b3Fceb22a440e89A2867E8FEE181594D9")

var chainId = int64(42161)
var initialBlock = "121947000"
var rpcMaxBlocksInBatch = uint64(1000)
var isProduction = env("TELEGRAM_BOT_TOKEN", "") != ""

func setup() {
	mux.HandleFunc("/", handleOverview)
	mux.HandleFunc("/pools/history", handlePoolsHistory)
	mux.HandleFunc("/apys/history", handleApysHistory)
	mux.HandleFunc("/positions/", handlePositionsAll)
	mux.HandleFunc("/positions/history", handlePositionsHistory)
	mux.HandleFunc("/positions/events", handlePositionsEvents)
	mux.HandleFunc("/earns", handleEarns)
	mux.HandleFunc("/liquidations", handleLiquidations)
	mux.HandleFunc("/analytics", handleAnalytics)
	mux.HandleFunc("/vault/position/history", handleVaultPositions)

	go taskQueryProtocolTvl()
	go taskQueryPools()
	go taskQueryPoolsRateModel()
	go taskQueryStrategies()
	go taskQueryStrategiesApys()
	go taskQueryProtocolTokenomics()
	go tasksRun()
}

var tasks = []*Task{
	{"earn", 60, 0, taskEarn},
	{"liquidate", 5 * 60, 0, taskLiquidate},
	{"pricesFetch", 60, 0, taskPricesFetch},
	{"pricesUpdate", 15 * 60, 0, taskPricesUpdate},
	{"queryProtocolTvl", 15 * 60, 0, taskQueryProtocolTvl},
	{"queryProtocolTokenomics", 15 * 60, 0, taskQueryProtocolTokenomics},
	{"queryPools", 60, 0, taskQueryPools},
	{"queryPoolsRateModel", 60 * 60, 0, taskQueryPoolsRateModel},
	{"queryStrategies", 5 * 60, 0, taskQueryStrategies},
	{"queryStrategiesApys", 15 * 60, 0, taskQueryStrategiesApys},
	{"historyPools", 60 * 60, 0, taskHistoryPools},
	{"historyApys", 60 * 60, 0, taskHistoryApys},
	{"historyPositions", 60 * 60, 0, taskHistoryPositions},
	{"eventsEarns", 30 * 60, 0, taskEventsEarns},
	{"eventsPositions", 5 * 60, 0, taskEventsPositions},
}

type Task struct {
	Name     string
	Schedule int64
	Next     int64
	Func     func()
}

type TokenomicsInfo struct {
	TokenPrice             *BigInt `json:"tokenPrice"`
	MarketCap              *BigInt `json:"marketCap"`
	MarketCapFullyDilluted *BigInt `json:"marketCapFullyDilluted"`
	SupplyCirculating      *BigInt `json:"supplyCirculating"`
	SupplyMax              *BigInt `json:"supplyMax"`
	SupplyTotal            *BigInt `json:"supplyTotal"`
	SupplyPOL              *BigInt `json:"supplyPOL"`
	SupplyXRDO             *BigInt `json:"supplyXRDO"`
	SupplyEcosystem        *BigInt `json:"supplyEcosystem"`
	SupplyPartners         *BigInt `json:"supplyPartners"`
	SupplyTeam             *BigInt `json:"supplyTeam"`
	SupplyMultisig         *BigInt `json:"supplyMultisig"`
	SupplyDeployer         *BigInt `json:"supplyDeployer"`
}

type AssetInfo struct {
	Address     string `json:"address"`
	Symbol      string `json:"symbol"`
	Name        string `json:"name"`
	Icon        string `json:"icon"`
	Decimals    int64  `json:"decimals"`
	Description string `json:"description"`
}

type PoolInfo struct {
	Asset   string `json:"asset"`
	Address string `json:"address"`
	Slug    string `json:"slug"`

	RateModelKink *BigInt `json:"rateModelKink"`
	RateModelBase *BigInt `json:"rateModelBase"`
	RateModelLow  *BigInt `json:"rateModelLow"`
	RateModelHigh *BigInt `json:"rateModelHigh"`

	Paused    bool    `json:"paused"`
	BorrowMin *BigInt `json:"borrowMin"`
	Cap       *BigInt `json:"cap"`
	Index     *BigInt `json:"index"`
	Shares    *BigInt `json:"shares"`
	Supply    *BigInt `json:"supply"`
	Borrow    *BigInt `json:"borrow"`
	Rate      *BigInt `json:"rate"`
	Price     *BigInt `json:"price"`
}

type VaultPoolInfo struct {
	Asset   string `json:"asset"`
	Address string `json:"address"`
	Slug    string `json:"slug"`

	GrossAPY int64   `json:"gross_apy"`
	NetAPY   float64 `json:"net_apy"`
	Tvl      *BigInt `json:"tvl"`
	Cap      *BigInt `json:"cap"`

	LockedAmount   *BigInt `json:"locked_amount"`
	Volume         *BigInt `json:"volume"`
	PerformanceFee float64 `json:"performance_fee"`
	ExitFee        float64 `json:"exit_fee"`
	ManagementFee  float64 `json:"management_fee"`
}

type StrategyInfo struct {
	Index          int64           `json:"index"`
	Slug           string          `json:"slug"`
	Name           string          `json:"name"`
	Protocol       string          `json:"protocol"`
	Icon           string          `json:"icon"`
	ApyType        string          `json:"apyType"`
	ApyId          string          `json:"apyId"`
	Description    string          `json:"description"`
	Fees           string          `json:"fees"`
	Assets         []StrategyAsset `json:"assets"`
	IsEarnDisabled bool            `json:"isEarnDisabled"`
	Hidden         bool            `json:"hidden"`

	Address  string  `json:"address"`
	Status   int64   `json:"status"`
	Slippage int64   `json:"slippage"`
	Cap      *BigInt `json:"cap"`
	Tvl      *BigInt `json:"tvl"`
	TvlTotal *BigInt `json:"tvlTotal"`
	Apy      *BigInt `json:"apy"`
}

type StrategyAsset struct {
	Ratio   float64 `json:"ratio"`
	Address string  `json:"address"`
}

type DbEarn struct {
	Id   int64
	Last time.Time
	Next time.Time
}

type DbPrice struct {
	Id    string    `json:"asset"`
	Price *BigInt   `json:"price"`
	Time  time.Time `json:"time"`
}

type DbPosition struct {
	Id          int64     `json:"id"`
	Chain       int64     `json:"chain"`
	Index       int64     `json:"index"`
	Pool        string    `json:"pool"`
	Strategy    string    `json:"strategy"`
	Shares      *BigInt   `json:"shares"`
	Borrow      *BigInt   `json:"borrow"`
	SharesValue *BigInt   `json:"shares_value"`
	BorrowValue *BigInt   `json:"borrow_value"`
	Life        *BigInt   `json:"life"`
	Amount      *BigInt   `json:"amount"`
	Price       *BigInt   `json:"price"`
	Created     time.Time `json:"created"`
	Updated     time.Time `json:"updated"`
}

type DbPositionHistory struct {
	Id          int64     `json:"id"`
	Chain       int64     `json:"chain"`
	Index       int64     `json:"index"`
	Time        time.Time `json:"time"`
	Shares      *BigInt   `json:"shares"`
	Borrow      *BigInt   `json:"borrow"`
	SharesValue *BigInt   `json:"shares_value"`
	BorrowValue *BigInt   `json:"borrow_value"`
	Life        *BigInt   `json:"life"`
	Amount      *BigInt   `json:"amount"`
	Price       *BigInt   `json:"price"`
}

type VaultPool struct {
}

var assets = map[string]*AssetInfo{
	"Other": &AssetInfo{
		Address:     "Other",
		Symbol:      "Other",
		Name:        "Other",
		Description: "A mix of smaller amounts of other tokens.",
	},
	"0x033f193b3Fceb22a440e89A2867E8FEE181594D9": &AssetInfo{
		Address:     "0x033f193b3Fceb22a440e89A2867E8FEE181594D9",
		Symbol:      "RDO",
		Name:        "Rodeo Token",
		Icon:        "/assets/rodeo.svg",
		Decimals:    18,
		Description: "",
	},
	"0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8": &AssetInfo{
		Address:     "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
		Symbol:      "USDC.e",
		Name:        "Bridged Circle USD Coin",
		Icon:        "/assets/usdc.svg",
		Decimals:    6,
		Description: "USDC is a fully collateralized US dollar stablecoin. USDC is issued by regulated financial institutions, backed by fully reserved assets, redeemable on a 1:1 basis for US dollars.",
	},
	"0x82aF49447D8a07e3bd95BD0d56f35241523fBab1": &AssetInfo{
		Address:     "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
		Symbol:      "WETH",
		Name:        "Wrapped Ether",
		Icon:        "/assets/eth.svg",
		Decimals:    18,
		Description: "The native currency that flows within the Ethereum economy is called Ether (ETH). Ether is typically used to pay for transaction fees called Gas, and it is the base currency of the network.",
	},
	"0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9": &AssetInfo{
		Address:     "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
		Symbol:      "USDT",
		Name:        "Tether USD",
		Icon:        "/assets/usdt.svg",
		Decimals:    6,
		Description: "Tether is a stablecoin pegged to the US Dollar. A stablecoin is a type of cryptocurrency whose value is pegged to another fiat currency like the US Dollar or to a commodity like Gold.Tether is the first stablecoin to be created and it is the most popular stablecoin used in the ecosystem.",
	},
	"0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f": &AssetInfo{
		Address:     "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
		Symbol:      "WBTC",
		Name:        "Wrapped Bitcoin",
		Icon:        "/assets/wbtc.svg",
		Decimals:    18,
		Description: "Wrapped Bitcoin (WBTC) is the first ERC20 token backed 1:1 with Bitcoin. Completely transparent. 100% verifiable. Community led.",
	},
	"0x5979D7b546E38E414F7E9822514be443A4800529": &AssetInfo{
		Address:     "0x5979D7b546E38E414F7E9822514be443A4800529",
		Symbol:      "wstETH",
		Name:        "Wrapped liquid staked Ether",
		Icon:        "/assets/wsteth.png",
		Decimals:    18,
		Description: "Lido’s Staked Ethereum, also known as stETH, is a digital asset representing ETH staked with Lido Finance, combining staking rewards with the value of the initial deposit.",
	},
	"0x912CE59144191C1204E64559FE8253a0e49E6548": &AssetInfo{
		Address:     "0x912CE59144191C1204E64559FE8253a0e49E6548",
		Symbol:      "ARB",
		Name:        "Arbitrum",
		Icon:        "/assets/arb.png",
		Decimals:    18,
		Description: "Arbitrum is a protocol that makes Ethereum transactions faster and cheaper. Developers use Arbitrum to build user-friendly decentralized apps (dApps) that can take advantage of the scalability benefits of the Arbitrum Rollup and AnyTrust protocols.",
	},
	"0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07": &AssetInfo{
		Address:     "0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07",
		Symbol:      "JOE",
		Name:        "TraderJoe",
		Icon:        "/assets/joe.png",
		Decimals:    18,
		Description: "Trader Joe provides all the functionality of a modern DEX and offers a convenient user interface, combined with speedy and cheap transactions. Users can provide liquidity by participating in one of its yield farms and earn JOE (JOE) as a reward token.",
	},
	"0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8": &AssetInfo{
		Address:     "0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8",
		Symbol:      "rETH",
		Name:        "Rocket Pool ETH",
		Icon:        "/assets/reth.png",
		Decimals:    18,
		Description: "Rocket Pool is a next generation decentralised staking pool protocol for Ethereum. Rocket Pool ETH (rETH) is the Rocket Pool protocol's liquid staking token. The rETH token represents an amount of ETH that is being staked and earning rewards within Ethereum Proof-of-Stake.",
	},
}

var pools = []*PoolInfo{
	&PoolInfo{
		Asset:   "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
		Address: "0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE",
		Slug:    "usdc-v1",
	},
}

var vaultPools = []*VaultPoolInfo{
	&VaultPoolInfo{
		Asset:   "0xCa13ea158e11DE30FF5FBb37d231C9B93849B2BA",
		Address: "0x08eccD9A9A8845Adc96A4e9a8c5f925698d5D532",
		Slug:    "ETH/wETH/stETH/wstETH",

		GrossAPY:       8,
		PerformanceFee: 0.62,
		ExitFee:        0.02,
		ManagementFee:  0.77,

		Tvl:          ONE,
		Cap:          ONE,
		LockedAmount: ONE,
		Volume:       ONE,
	},
}

var poolsTesting = []*PoolInfo{
	&PoolInfo{
		Asset:   "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
		Address: "0x3AfBAd98a5D76B37cb4d060B18A1B246FbACCFBa",
		Slug:    "usdc",
	},
}

var strategies = []*StrategyInfo{
	&StrategyInfo{
		Index:       12,
		Slug:        "gmx-glp",
		Name:        "GLP",
		Protocol:    "GMX",
		Icon:        "/protocols/gmx.png",
		Address:     "0x70116D50c89FC060203d1fA50374CF1B816Bd0f5",
		ApyType:     "defillama",
		ApyId:       "825688c0-c694-4a6b-8497-177e425b7348",
		Description: "Uses USDC to mint GMX GLP and stakes it for ETH fees and esGMX rewards, compounding over time. This mean you will have ~50% exposure to BTC and ETH.",
		Fees:        "USDC to GLP minting fee *currently 0.45%, GLP to USDC fee *currently 0.05%",
		Assets: []StrategyAsset{
			{38.8, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
			{29.9, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
			{18.2, "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"},
			{13.1, "Other"},
		},
	},
	&StrategyInfo{
		Index:       30,
		Slug:        "plutus-plvglp",
		Name:        "plvGLP",
		Protocol:    "PlutusDAO",
		Icon:        "/protocols/plutusdao.png",
		Address:     "0x4c38dAEc4059151e0beb57AaD2aF0178273FFf28",
		ApyType:     "plutus",
		ApyId:       "plvglp",
		Description: "Mints GMX GLP, then mints plvGLP with it, then deposits that in Plutus's PLS farm for extra yield.",
		Fees:        "2% exit fee (0.5% goes to plvGLP stakers / 1.5% to plutus), USDC to GLP minting fee *currently 0.45%, GLP to USDC fee *currently 0.05%",
		Assets: []StrategyAsset{
			{38.8, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
			{29.9, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
			{18.2, "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"},
			{13.1, "Other"},
		},
	},
	&StrategyInfo{
		Index:       20,
		Slug:        "jones-jusdc",
		Name:        "jUSDC",
		Protocol:    "JonesDAO",
		Icon:        "/protocols/jonesdao.png",
		Address:     "0xDC34bE34Af0459c336b68b58b7B0aD2CB755b42c",
		ApyType:     "defillama",
		ApyId:       "dde58f35-2d08-4789-a641-1225b72c3147",
		Description: "Mints JonesDAO jUSDC (USDC is lent to jGLP vault for extra leverage), collecting rewards. Because of the one day lock on withdrawals, only 10% of this farm's funds are available for withdrawal at a time, refilled daily. Earned fees are compounded every 8 hours.",
		Fees:        "0.97% vault retention fee",
		Assets: []StrategyAsset{
			{100, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
		},
	},
	&StrategyInfo{
		Index:       42,
		Slug:        "jones-jusdc-stip",
		Name:        "jUSDC (w/ ARB STIP)",
		Protocol:    "JonesDAO",
		Icon:        "/protocols/jonesdao.png",
		Address:     "0xBCE20348A49d3C97a5E76F520B8B5fA720BD621c",
		ApyType:     "jusdc-stip",
		ApyId:       "0x0aEfaD19aA454bCc1B1Dd86e18A7d58D0a6FAC38",
		Description: "Mints JonesDAO jUSDC (USDC is lent to jGLP vault for extra leverage), collecting rewards. Because of the one day lock on withdrawals, only 10% of this farm's funds are available for withdrawal at a time, refilled daily. Earned fees are compounded every 8 hours.",
		Fees:        "0.97% vault retention fee. **1% ARB STIP deposit fee**",
		Assets: []StrategyAsset{
			{100, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
		},
		Hidden: true,
	},
	&StrategyInfo{
		Index:       36,
		Slug:        "pendle-wsteth",
		Name:        "wstETH",
		Protocol:    "Pendle",
		Icon:        "/protocols/pendle.png",
		Address:     "0xe3D0aA8F26120454938049569e570Af848aEEebD",
		ApyType:     "defillama",
		ApyId:       "f05aa688-f627-4438-89c6-2fef135510c7",
		Description: "Swaps to wstETH and deposits in the Pendle pool, earning LP fees and compounding PENDLE incentives.",
		Fees:        "",
		Assets: []StrategyAsset{
			{100, "0x5979D7b546E38E414F7E9822514be443A4800529"},
		},
		IsEarnDisabled: true,
	},
	&StrategyInfo{
		Index:       37,
		Slug:        "pendle-reth",
		Name:        "rETH",
		Protocol:    "Pendle",
		Icon:        "/protocols/pendle.png",
		Address:     "0x44511DaEeC95Bc8f9B5fE9dDE222E1a9Cc09Cf92",
		ApyType:     "defillama",
		ApyId:       "35fe5f76-3b7d-42c8-9e54-3da70fbcb3a9",
		Description: "Swaps to rETH and deposits in the Pendle pool, earning LP fees and compounding PENDLE incentives.",
		Fees:        "",
		Assets: []StrategyAsset{
			{100, "0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8"},
		},
		IsEarnDisabled: true,
	},
	&StrategyInfo{
		Index:       40,
		Slug:        "pendle-arb-eth",
		Name:        "ARB/ETH",
		Protocol:    "Pendle",
		Icon:        "/protocols/pendle.png",
		Address:     "0x21D8cEaF2C566efc83DC160F879Bf1dE5562c7c6",
		ApyType:     "defillama",
		ApyId:       "5f1f25a8-eab7-44bc-958f-6195e012ea55",
		Description: "Swaps to ARB/ETH LP and deposits in the Pendle pool, earning LP fees and compounding PENDLE incentives.",
		Fees:        "",
		Assets: []StrategyAsset{
			{50, "0x912CE59144191C1204E64559FE8253a0e49E6548"},
			{50, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
		},
		IsEarnDisabled: true,
	},
	&StrategyInfo{
		Index:       27,
		Slug:        "camelot-eth-usdc",
		Name:        "USDC/ETH",
		Protocol:    "Camelot V2",
		Icon:        "/protocols/camelot.svg",
		Address:     "0x91308b8d5e2352C7953D88A55D1012D68bF1EfD0",
		ApyType:     "camelot",
		ApyId:       "0x91308b8d5e2352C7953D88A55D1012D68bF1EfD0",
		Description: "Invests funds into Camelot's LP pool and stakes it in the NFTPool for GRAIL rewards. Rewards are then auto-compounded into more LP tokens.",
		Fees:        "0.15% swap fees when rebalancing and entering",
		Assets: []StrategyAsset{
			{50, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
			{50, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
		},
	},
	&StrategyInfo{
		Index:       33,
		Slug:        "camelot-arb-eth",
		Name:        "ARB/ETH",
		Protocol:    "Camelot V2",
		Icon:        "/protocols/camelot.svg",
		Address:     "0xA36bBd6494Fd59091898DA15FFa69a35bF0676b0",
		ApyType:     "camelot",
		ApyId:       "0xA36bBd6494Fd59091898DA15FFa69a35bF0676b0",
		Description: "Invests funds into Camelot's LP pool and stakes it in the NFTPool for GRAIL rewards. Rewards are then auto-compounded into more LP tokens.",
		Fees:        "0.30% swap fees when rebalancing and entering",
		Assets: []StrategyAsset{
			{50, "0x912CE59144191C1204E64559FE8253a0e49E6548"},
			{50, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
		},
	},
	&StrategyInfo{
		Index:       4,
		Slug:        "sushi-eth-usdc",
		Name:        "USDC/ETH",
		Protocol:    "SushiSwap",
		Icon:        "/protocols/sushiswap.png",
		Address:     "0x88C907770735B1fc9d9cCB1A8F73dC17e75C0699",
		ApyType:     "defillama",
		ApyId:       "78609c6a-5e49-4a9f-9b34-90f0a1e5f7fd",
		Description: "Invests funds into SushiSwap's USDC/ETH LP pool and stakes it in the Onsen menu for Sushi rewards. Rewards are then auto-compounded into more LP tokens.",
		Fees:        "0.15% swap fees",
		Assets: []StrategyAsset{
			{50, "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"},
			{50, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
		},
	},
	&StrategyInfo{
		Index:       5,
		Slug:        "sushi-eth-usdt",
		Name:        "USDT/ETH",
		Protocol:    "SushiSwap",
		Icon:        "/protocols/sushiswap.png",
		Address:     "0x61d9ce922D133B8fcDc8B46aEfB586b125DA95C1",
		ApyType:     "defillama",
		ApyId:       "abe3c385-bde7-4350-9f35-2f574ad592d6",
		Description: "Invests funds into SushiSwap's USDT/ETH LP pool and stakes it in the Onsen menu for Sushi rewards. Rewards are then auto-compounded into more LP tokens.",
		Fees:        "0.30% swap fees",
		Assets: []StrategyAsset{
			{50, "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"},
			{50, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"},
		},
		IsEarnDisabled: true,
	},
}

var strategiesTesting = []*StrategyInfo{
	&StrategyInfo{
		Index:       0,
		Slug:        "gamma-eth-usdc-500",
		Name:        "ETH/USDC 0.05 Wide",
		Protocol:    "Gamma",
		Icon:        "/protocols/gamma.svg",
		Address:     "0x3F4d4212b56B179209a2E27BE14211877Ad6b9CA",
		ApyType:     "defillama",
		ApyId:       "76f68a08-289f-42d1-ae4e-691fb6732c26",
		Description: "Blah.",
		Fees:        "9000%",
		Assets:      []StrategyAsset{{100, "Other"}},
	},
	&StrategyInfo{
		Index:       5,
		Slug:        "gmxgm-eth",
		Name:        "ETH",
		Protocol:    "GMX V2",
		Icon:        "/protocols/gmx.png",
		Address:     "0xb2fE9AF59c81226D408e4375aB76A933a5897e76",
		ApyType:     "defillama",
		ApyId:       "61b4c35c-97f6-4c05-a5ff-aeb4426adf5b",
		Description: "Blah.",
		Fees:        "9000%",
		Assets:      []StrategyAsset{{100, "Other"}},
	},
}

func main() {
	sqlx.NameMapper = stringToSnakeCase
	var err error
	db, err = sqlx.Open("postgres", env("DATABASE_URL", "postgres://admin:admin@localhost/rodeo?sslmode=disable"))
	check(err)
	client, err = ethclient.Dial(env("RPC_URL_MAINNET", "wss://arb1.arbitrum.io/rpc"))
	check(err)
	walletKey = crypto.ToECDSAUnsafe(common.FromHex(env("RODEO_PRIVATE_KEY_MAINNET", "")))
	walletAddress = crypto.PubkeyToAddress(walletKey.PublicKey)
	txOpts, err = bind.NewKeyedTransactorWithChainID(walletKey, big.NewInt(42161))
	check(err)
	txOpts.NoSend = !isProduction
	mux = http.NewServeMux()
	if !isProduction {
		blockNumber, err := client.BlockNumber(context.Background())
		check(err)
		initialBlock = intToString(int64(blockNumber))
	}
	if env("RODEO_ENV", "") == "staging" {
		// staging/testing contracts
		addressInvestor = common.HexToAddress("0x3A806d2D7DbdbeE3aA5cD75BA9d737fc682ce367")
		addressInvestorHelper = common.HexToAddress("0x9d35CBC1F2FE7464E503ac447775668eB2832C28")
		addressToken = common.HexToAddress("0x033f193b3Fceb22a440e89A2867E8FEE181594D9")
		pools = poolsTesting
		strategies = strategiesTesting
	}

	setup()

	handler := func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if e := recover(); e != nil {
				stack := string(debug.Stack())
				log.Printf("PANIC: %s\n%s\n", e, stack)
				httpResJson(w, 500, J{
					"error": fmt.Sprintf("%s", e),
					"stack": strings.Split(stack, "\n"),
				})
			}
		}()
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "OPTIONS, GET, POST")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		mux.ServeHTTP(w, r)
	}
	port := env("PORT", "4000")
	log.Println("starting on port", port)
	log.Fatal(http.ListenAndServe(":"+port, http.HandlerFunc(handler)))
}

func handleOverview(w http.ResponseWriter, r *http.Request) {
	httpResJson(w, 200, J{
		"message":     "Henlo cowboy!",
		"tvl":         protocolTvl,
		"tokenomics":  tokenomics,
		"assets":      assets,
		"pools":       pools,
		"strategies":  strategies,
		"vault_pools": vaultPools,
	})
}

func handlePrices(w http.ResponseWriter, r *http.Request) {
	prices := []*DbPrice{}
	check(dbSelect(&prices, "select id, avg(price) as price, max(time) as time from prices where time > now() - '1 hour'::interval group by id order by time desc"))
	httpResJson(w, 200, J{"data": prices})
}

func sqlWindowedQuery(q url.Values) (string, string) {
	intervals := map[string]string{"hour": "hour", "day": "day", "week": "week"}
	interval, ok := intervals[q.Get("interval")]
	if !ok {
		interval = "hour"
	}
	length, err := strconv.Atoi(q.Get("length"))
	if err != nil {
		length = 100
	}
	return `with t as (select generate_series(
    date_trunc('` + interval + `', now()) - '` + strconv.Itoa(length-2) + ` ` + interval + `'::interval,
    date_trunc('` + interval + `', now()) + '1 ` + interval + `'::interval,
    '1 ` + interval + `'::interval
  ) as t)`, interval
}

func handlePoolsHistory(w http.ResponseWriter, r *http.Request) {
	query, interval := sqlWindowedQuery(r.URL.Query())
	data := []struct {
		T      time.Time `json:"t"`
		Index  *BigInt   `json:"index"`
		Share  *BigInt   `json:"share"`
		Supply *BigInt   `json:"supply"`
		Borrow *BigInt   `json:"borrow"`
		Rate   *BigInt   `json:"rate"`
		Price  *BigInt   `json:"price"`
	}{}
	check(dbSelect(&data, query+` select t.t, coalesce(avg("index")::numeric(32), 0) as "index", coalesce(avg(share)::numeric(32), 0) as share, coalesce(avg(supply)::numeric(32), 0) as supply, coalesce(avg(borrow)::numeric(32), 0) as borrow, coalesce(avg(rate)::numeric(32), 0) as rate, coalesce(avg(price)::numeric(32), 0) as price
    from t
    left join pools_history on t.t = date_trunc('`+interval+`', time)
      and chain = $1 and lower(address) = lower($2)
    group by 1 order by 1`, r.URL.Query().Get("chain"), r.URL.Query().Get("address")))
	httpResJson(w, 200, data)
}

func handleApysHistory(w http.ResponseWriter, r *http.Request) {
	query, interval := sqlWindowedQuery(r.URL.Query())
	data := []struct {
		T   time.Time `json:"t"`
		Apy *BigInt   `json:"apy"`
		Tvl *BigInt   `json:"tvl"`
	}{}
	check(dbSelect(&data, query+` select
    t.t, coalesce(avg(apy)::numeric(32), 0) as apy, coalesce(avg(tvl)::numeric(32), 0) as tvl
    from t
    left join apys_history on t.t = date_trunc('`+interval+`', time)
      and chain = $1 and lower(address) = lower($2)
    group by 1 order by 1`, r.URL.Query().Get("chain"), r.URL.Query().Get("address")))
	httpResJson(w, 200, data)
}

func handlePositionsAll(w http.ResponseWriter, r *http.Request) {
	data := []struct {
		Index        int64     `json:"index"`
		Pool         string    `json:"pool"`
		Strategy     string    `json:"strategy"`
		Shares       *BigInt   `json:"shares"`
		Borrow       *BigInt   `json:"borrow"`
		Shares_Value *BigInt   `json:"shares_value"`
		Borrow_Value *BigInt   `json:"borrow_value"`
		Life         *BigInt   `json:"life"`
		Amount       *BigInt   `json:"amount"`
		Price        *BigInt   `json:"price"`
		Created      time.Time `json:"created"`
		Updated      time.Time `json:"updated"`
	}{}
	check(dbSelect(&data, `select * from positions where "strategy" not in ('38', '41') order by chain, "index" desc`))
	httpResJson(w, 200, data)
}

func handlePositionsHistory(w http.ResponseWriter, r *http.Request) {
	query, interval := sqlWindowedQuery(r.URL.Query())
	data := []struct {
		T            time.Time `json:"t"`
		Shares       *BigInt   `json:"shares"`
		Borrow       *BigInt   `json:"borrow"`
		Shares_value *BigInt   `json:"shares_value"`
		Borrow_value *BigInt   `json:"borrow_value"`
		Life         *BigInt   `json:"life"`
		Amount       *BigInt   `json:"amount"`
		Price        *BigInt   `json:"price"`
	}{}
	check(dbSelect(&data, query+` select
      t.t, coalesce(avg(shares)::numeric(32), 0) as shares, coalesce(avg(borrow)::numeric(32), 0) as borrow, coalesce(avg(shares_value)::numeric(32), 0) as shares_value, coalesce(avg(borrow_value)::numeric(32), 0) as borrow_value, coalesce(avg(life)::numeric(32), 0) as life, coalesce(avg(amount)::numeric(32), 0) as amount, coalesce(avg(price)::numeric(32), 0) as price
    from t
    left join positions_history on t.t = date_trunc('`+interval+`', time)
      and chain = $1 and "index" = $2
    group by 1 order by 1`, r.URL.Query().Get("chain"), r.URL.Query().Get("index")))
	httpResJson(w, 200, data)
}

func handlePositionsEvents(w http.ResponseWriter, r *http.Request) {
	data := []struct {
		Time  time.Time `json:"time"`
		Block *BigInt   `json:"block"`
		Name  string    `json:"name"`
		Data  J         `json:"data"`
	}{}
	check(dbSelect(&data, `select time, block, name, data from positions_events
    where chain = $1 and "index" = $2 order by time`, r.URL.Query().Get("chain"), r.URL.Query().Get("index")))
	httpResJson(w, 200, data)
}

func handleEarns(w http.ResponseWriter, r *http.Request) {
	data := []struct {
		Time     time.Time `json:"time"`
		Strategy string    `json:"strategy"`
		Block    *BigInt   `json:"block"`
		Earn     *BigInt   `json:"earn"`
		Tvl      *BigInt   `json:"tvl"`
	}{}
	check(dbSelect(&data, `select time, strategy, block, earn, tvl
    from strategies_profits order by time desc limit 100`))
	httpResJson(w, 200, data)
}

func handleLiquidations(w http.ResponseWriter, r *http.Request) {
	data := []struct {
		Time     time.Time `json:"time"`
		Chain    string    `json:"chain"`
		Index    int64     `json:"index"`
		Strategy string    `json:"strategy"`
		Data     J         `json:"data"`
		Pool     string    `json:"pool"`
		Amount   *BigInt   `json:"amount"`
		Created  time.Time `json:"created"`
	}{}
	check(dbSelect(&data, `select time, p.chain, p."index", p.strategy, data, p.pool, p.amount, p.created
    from positions_events
    left join positions p on p."index" = positions_events."index"
    where name = 'Kill' and time > now() - interval '14 days'
    order by time desc`))
	httpResJson(w, 200, data)
}

func handleAnalytics(w http.ResponseWriter, r *http.Request) {
	largest := []*DbPosition{}
	check(dbSelect(&largest, `select * from positions order by shares_value desc limit 10`))
	profit := []*DbPosition{}
	check(dbSelect(&profit, `select * from positions where amount > 0 and shares_value > 0 order by ((shares_value - ((borrow_value + amount) * price / 1e6)) * 1e18 / (amount * price / 1e6)) desc limit 10`))
	danger := []*DbPosition{}
	check(dbSelect(&danger, `select * from positions where shares_value > 10e18 and life > 1e18 order by life asc limit 10`))
	httpResJson(w, 200, J{
		"largest": largest,
		"profit":  profit,
		"danger":  danger,
	})
}

func handleVaultPositions(w http.ResponseWriter, r *http.Request) {
	query, interval := sqlWindowedQuery(r.URL.Query())
	data := []struct {
		T            time.Time `json:"t"`
		Shares       *BigInt   `json:"shares"`
		Borrow       *BigInt   `json:"borrow"`
		Shares_value *BigInt   `json:"shares_value"`
		Borrow_value *BigInt   `json:"borrow_value"`
		Life         *BigInt   `json:"life"`
		Amount       *BigInt   `json:"amount"`
		Price        *BigInt   `json:"price"`
	}{}
	check(dbSelect(&data, query+` select
      t.t, coalesce(avg(shares)::numeric(32), 0) as shares, coalesce(avg(borrow)::numeric(32), 0) as borrow, coalesce(avg(shares_value)::numeric(32), 0) as shares_value, coalesce(avg(borrow_value)::numeric(32), 0) as borrow_value, coalesce(avg(life)::numeric(32), 0) as life, coalesce(avg(amount)::numeric(32), 0) as amount, coalesce(avg(price)::numeric(32), 0) as price
    from t
    left join positions_history on t.t = date_trunc('`+interval+`', time)
      and chain = $1 and "index" = $2
    group by 1 order by 1`, r.URL.Query().Get("chain"), r.URL.Query().Get("index")))
	httpResJson(w, 200, data)
}

func tasksRun() {
	now := time.Now().Unix()
	for _, t := range tasks {
		s := t.Schedule
		t.Next = ((now + s) / s) * s
	}
	for {
		now = time.Now().Unix()
		for _, t := range tasks {
			if now > t.Next {
				go func(t *Task) {
					defer func() {
						if e := recover(); e != nil {
							message := fmt.Sprintf("%s", e)
							log.Println("ERROR running task", t.Name, e)
							if !strings.Contains(message, "Too Many Requests") && !strings.Contains(message, "write: broken pipe") {
								telegramMessage("ERROR running task " + t.Name + ": " + message + "\n```\n" + string(debug.Stack()) + "\n```")
							}
						}
					}()
					log.Printf("running task %s %d %d %d\n", t.Name, t.Next, t.Schedule, now)
					t.Next = t.Next + t.Schedule
					t.Func()
				}(t)
			}
		}
		time.Sleep(1 * time.Second)
	}
}

func taskEarn() {
	now := time.Now()
	earns := []*DbEarn{}
	check(dbSelect(&earns, "select * from earns"))
	for _, s := range strategies {
		if s.IsEarnDisabled {
			continue
		}
		next := time.Time{}
		for _, e := range earns {
			if e.Id == s.Index {
				next = e.Next
			}
		}
		log.Println("thinking of earning", s.Index, now.After(next), next.Format(time.DateTime))
		if now.After(next) {
			log.Printf("earning strategy %d %s\n", s.Index, s.Address)
			check(dbPut("earns", &DbEarn{
				Id:   s.Index,
				Last: now,
				Next: now.Add(time.Duration(rand.Int63n(2*8*60*60)) * time.Second),
			}))
			strategyContract, err := NewStrategy(common.HexToAddress(s.Address), client)
			check(err)
			txHash, err := waitTx(strategyContract.Earn(nextTxOpts()))
			if err != nil {
				if !strings.Contains(err.Error(), "429 Too Many Requests") {
					telegramMessage("ERROR taskEarn strategy:%d (%s %s) address: %s message:%s\n", s.Index, s.Name, s.Protocol, s.Address, err)
				}
				continue
			}

			log.Printf("taskEarn strategy:%d (%s %s) address: %s hash:%s\n", s.Index, s.Name, s.Protocol, s.Address, txHash)
			telegramMessage("💵 [%s %s | %d](https://arbiscan.io/address/%s) - [Tx](https://arbiscan.io/tx/%s)", s.Name, s.Protocol, s.Index, s.Address, txHash)
		}
	}
}

func taskLiquidate() {
	investorContract, err := NewInvestor(addressInvestor, client)
	check(err)
	positions := []*DbPosition{}
	check(dbSelect(&positions, `select * from positions where life < 1.05e18 and shares > 0`))
	for _, p := range positions {
		go func(p *DbPosition) {
			life, err := investorContract.Life(nil, big.NewInt(p.Index))
			if err != nil {
				log.Println("taskLiquidate: error fetching life:", p.Index)
				return
			}
			if life.Cmp(ONE.Std()) == -1 {
				log.Println("taskLiquidate: liquidating:", p.Index, bnw(life).Float())
				tx, err := investorContract.Kill(nextTxOpts(), big.NewInt(p.Index), []byte{})
				if err != nil {
					log.Println("taskLiquidate: error:", p.Index, err)
					return
				}
				r, err := bind.WaitMined(context.Background(), client, tx)
				if err != nil {
					log.Println("taskLiquidate: error waiting:", p.Index, err)
					return
				}
				log.Println("taskLiquidate: liquidated:", p.Index, r.TxHash.Hex())
			}
		}(p)
		time.Sleep(100 * time.Millisecond)
	}
}

var pricesAssets = []struct {
	Token       string
	OraclePrice string
	OracleChain string
}{
	{"0x033f193b3Fceb22a440e89A2867E8FEE181594D9", "0x309349d5D02C6f8b50b5040e9128E1A8375042D7", "0xbB12Db28715B45199DC83E1dF756fDf27954244B"}, // RDO
	{"0x51318B7D00db7ACc4026C88c3952B66278B6A67F", "0x8E5c55eae441269FBd3185649076082Df4383aee", "0x798158E3C5AbB4Cb1394748bfF231F8B15b7a134"}, // PLS
	{"0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8", "0x63dd6107bbF26d03a0eF1f6EeC2aCe28C9FE37f0", "0xD0F60cbF8513671995AcBF042DD61bbe337bB03d"}, // GRAIL
	{"0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8", "0x5e26601c1C0AACF0F588f4B24c433990B728D65a", "0x6e90cc4f0BCc7D53773eECE2F3A1f84Aa5be3D4a"}, // PENDLE
}

func taskPricesFetch() {
	for _, a := range pricesAssets {
		oraclePriceContract, err := NewOracle(common.HexToAddress(a.OraclePrice), client)
		check(err)
		priceStd, err := oraclePriceContract.LatestAnswer(nil)
		check(err)
		price := (*BigInt)(priceStd)
		log.Println("prices", a.Token, price.Div(bn(1, 14)).String())
		check(dbPut("prices", &DbPrice{
			Id:    a.Token,
			Price: price,
			Time:  time.Now(),
		}))
	}
}

func taskPricesUpdate() {
	for _, a := range pricesAssets {
		oracleChainContract, err := NewOracle(common.HexToAddress(a.OracleChain), client)
		check(err)
		priceAvgRow := struct{ Price *BigInt }{}
		check(dbGet(&priceAvgRow, "select avg(price) as price from prices where id = $1 and time > now() - '2 hour'::interval", a.Token))
		priceAvg := priceAvgRow.Price
		if priceAvg.Eq(ZERO) {
			continue
		}
		txHash, err := waitTx(oracleChainContract.Update(nextTxOpts(), priceAvg.Std()))
		if err != nil {
			if !strings.Contains(err.Error(), "429 Too Many Requests") {
				telegramMessage("ERROR taskPrice token:%s price:%0.4f message:%s", a.Token, priceAvg.Float(), err)
			}
			continue
		}
		//telegramMessage("taskPrice token:%s price:%0.4f hash:%s\n", a.Token, priceAvg.Float(), txHash)
		log.Printf("taskPrice token:%s price:%0.4f hash:%s\n", a.Token, priceAvg.Float(), txHash)
	}
}

func taskQueryProtocolTvl() {
	result := struct{ Tvl *BigInt }{}
	check(dbGet(&result, `select coalesce(sum(shares_value), 0) as tvl from positions where chain = 42161 and "index" not in (524, 525)`))

	usdcContract, err := NewOther(common.HexToAddress("0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"), client)
	// Pick one place to check for broken connection and reset
	if err != nil && strings.Contains(err.Error(), "write: connection reset by peer") {
		client, err = ethclient.Dial(env("RPC_URL_MAINNET", "wss://arb1.arbitrum.io/rpc"))
		check(err)
	}
	check(err)
	usdcAvailable, err := usdcContract.BalanceOf(nil, common.HexToAddress("0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE"))
	check(err)
	protocolTvl = result.Tvl.Add(bnw(usdcAvailable).Mul(ONE12))
}

func taskQueryProtocolTokenomics() {
	tokenContract, err := NewOther(addressToken, client)
	check(err)
	tokenLpToken, err := NewOther(common.HexToAddress("0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39"), client)
	check(err)
	w := func(n *big.Int, err error) *BigInt {
		if err != nil {
			log.Println("taskQueryProtocolTokenomics", err)
			return ZERO
		}
		return bnw(n)
	}
	price := &DbPrice{}
	check(dbGet(price, "select coalesce(avg(price), 0) as price from prices where time > now() - '1 hour'::interval and id = '0x033f193b3Fceb22a440e89A2867E8FEE181594D9'"))
	tokenomics.TokenPrice = price.Price
	if !isProduction {
		tokenomics.TokenPrice = bn(1357, 14)
	}
	tokenomics.SupplyMax = bn(100_000_000, 18)
	tokenomics.SupplyPOL = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39"))).Mul(w(tokenLpToken.BalanceOf(nil, common.HexToAddress("0xbe98143d91AcdD381E5ed17e6b868dc30Eb8Ca68")))).Div(w(tokenLpToken.TotalSupply(nil)))
	tokenomics.SupplyXRDO = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D")))
	tokenomics.SupplyTeam = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x8c1Db765d956627F5C933EDcF3d628aa34E4a35c")))
	tokenomics.SupplyEcosystem = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x91E375808aD4DCE30461c852B3C64a6a13981d3C")))
	tokenomics.SupplyPartners = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x6Bdee28E211BeD4cC0BEB6276A4dbbc108cb1878")))
	tokenomics.SupplyMultisig = w(tokenContract.BalanceOf(nil, common.HexToAddress("0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a")))
	tokenomics.SupplyDeployer = w(tokenContract.BalanceOf(nil, common.HexToAddress("0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9")))
	tokenomics.SupplyTotal = w(tokenContract.TotalSupply(nil))
	tokenomics.SupplyCirculating = tokenomics.SupplyTotal.
		Sub(tokenomics.SupplyPOL).
		Sub(tokenomics.SupplyXRDO).
		Sub(tokenomics.SupplyTeam).
		Sub(tokenomics.SupplyEcosystem).
		Sub(tokenomics.SupplyPartners).
		Sub(tokenomics.SupplyMultisig).
		Sub(tokenomics.SupplyDeployer)
	tokenomics.MarketCap = tokenomics.TokenPrice.Mul(tokenomics.SupplyCirculating).Div(ONE)
	tokenomics.MarketCapFullyDilluted = tokenomics.TokenPrice.Mul(tokenomics.SupplyTotal).Div(ONE)
}

func taskQueryPools() {
	helperContract, err := NewHelper(addressHelper, client)
	check(err)
	for _, p := range pools {
		result, err := helperContract.Pool(nil, common.HexToAddress(p.Address))
		check(err)
		p.Paused = result.Paused
		p.BorrowMin = bnw(result.BorrowMin)
		p.Cap = bnw(result.Cap)
		p.Index = bnw(result.Index)
		p.Shares = bnw(result.Shares)
		p.Supply = bnw(result.Supply)
		p.Borrow = bnw(result.Borrow)
		p.Rate = bnw(result.Rate)
		p.Price = bnw(result.Price)
	}
}

func taskQueryPoolsRateModel() {
	helperContract, err := NewHelper(addressHelper, client)
	check(err)
	for _, p := range pools {
		result, err := helperContract.RateModel(nil, common.HexToAddress(p.Address))
		check(err)
		p.RateModelKink = bnw(result.Kink)
		p.RateModelBase = bnw(result.Base)
		p.RateModelLow = bnw(result.Low)
		p.RateModelHigh = bnw(result.High)
	}
}

func taskQueryStrategies() {
	helperContract, err := NewHelper(addressHelper, client)
	check(err)
	indexes := []*big.Int{}
	for _, s := range strategies {
		indexes = append(indexes, big.NewInt(s.Index))
	}
	result, err := helperContract.Strategies(nil, addressInvestor, indexes)
	check(err)
	for i, s := range strategies {
		s.Address = result.Addresses[i].String()
		s.Status = result.Statuses[i].Int64()
		s.Slippage = result.Slippages[i].Int64()
		s.Cap = bnw(result.Caps[i])
		s.Tvl = bnw(result.Tvls[i])
	}
}

func taskQueryStrategiesApys() {
	var defiLlamaPools = struct {
		Status string
		Data   []struct {
			Pool   string
			Apy    float64
			TvlUsd float64
		}
	}{}
	var camelotPools = struct {
		Data struct {
			Pools map[string]struct {
				OneWeekAverageAPR float64 `json:"oneWeekAverageAPR"`
				AverageReserveUSD float64 `json:"averageReserveUSD"`
			}
		}
	}{}
	var camelotNftPools = struct {
		Data struct {
			NftPools map[string]struct {
				MinIncentivesApr float64 `json:"minIncentivesApr"`
			}
		}
	}{}

	for _, s := range strategies {
		switch s.ApyType {
		case "defillama":
			if defiLlamaPools.Status != "success" {
				check(httpGet(&defiLlamaPools, "https://yields.llama.fi/pools"))
			}
			for _, p := range defiLlamaPools.Data {
				if p.Pool == s.ApyId {
					s.Apy = bnf(p.Apy / 100)
					s.TvlTotal = bnf(p.TvlUsd)
					break
				}
			}

		case "plutus":
			// GLP PRICE
			glpManagerContract, err := NewOther(common.HexToAddress("0x321F653eED006AD1C29D174e17d96351BDe22649"), client)
			check(err)
			glpAum, err := glpManagerContract.GetAumInUsdg(nil, false)
			check(err)
			glpTokenContract, err := NewOther(common.HexToAddress("0x4277f8f2c384827b5273592ff7cebd9f2c1ac258"), client)
			check(err)
			glpTotalSupply, err := glpTokenContract.TotalSupply(nil)
			check(err)
			glpPrice := bnw(glpAum).Mul(ONE).Div(bnw(glpTotalSupply))

			// PLS APY
			plsFarmContract, err := NewOther(common.HexToAddress("0x4E5Cf54FdE5E1237e80E87fcbA555d829e1307CE"), client)
			check(err)
			plsPerSecond, err := plsFarmContract.PlsPerSecond(nil)
			check(err)

			plvGlpTokenContract, err := NewOther(common.HexToAddress("0x5326E71Ff593Ecc2CF7AcaE5Fe57582D6e74CFF1"), client)
			check(err)
			plvGlpBalanceInFarm, err := plvGlpTokenContract.BalanceOf(nil, common.HexToAddress("0x4E5Cf54FdE5E1237e80E87fcbA555d829e1307CE"))
			check(err)

			plsOracleContract, err := NewOther(common.HexToAddress("0x8E5c55eae441269FBd3185649076082Df4383aee"), client)
			check(err)
			plsPrice, err := plsOracleContract.LatestAnswer(nil)
			check(err)

			plsValuePerYear := bnw(plsPerSecond).Mul(YEAR).Mul(bnw(plsPrice)).Div(ONE)
			farmTvl := bnw(plvGlpBalanceInFarm).Mul(glpPrice).Div(ONE)
			farmApr := plsValuePerYear.Mul(ONE).Div(farmTvl)

			// GLP APY
			glpFarmContract, err := NewOther(common.HexToAddress("0x4e971a87900b931fF39d1Aad67697F49835400b6"), client)
			check(err)
			ethPerSecond, err := glpFarmContract.TokensPerInterval(nil)
			check(err)
			glpFarmSuppply, err := glpFarmContract.TotalSupply(nil)
			check(err)

			ethOracleContract, err := NewOther(common.HexToAddress("0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612"), client)
			check(err)
			ethPrice, err := ethOracleContract.LatestAnswer(nil)
			check(err)
			ethValuePerYear := bnw(ethPerSecond).Mul(YEAR).Mul(bnw(ethPrice)).Div(ONE8)
			glpTvl := bnw(glpFarmSuppply).Mul(glpPrice).Div(ONE)
			glpApr := ethValuePerYear.Mul(ONE).Div(glpTvl)

			s.Apy = aprToApy(glpApr.Add(farmApr))
			s.TvlTotal = farmTvl

		case "camelot":
			if len(camelotPools.Data.Pools) == 0 {
				check(httpGet(&camelotPools, "https://api.camelot.exchange/v2/liquidity-v2-pools-data"))
			}
			if len(camelotNftPools.Data.NftPools) == 0 {
				check(httpGet(&camelotNftPools, "https://api.camelot.exchange/v2/nft-pools"))
			}
			strategyContract, err := NewOther(common.HexToAddress(s.ApyId), client)
			check(err)
			poolAddress, err := strategyContract.Pool(nil)
			check(err)
			nftPoolAddress, err := strategyContract.NftPool(nil)
			check(err)
			pool := camelotPools.Data.Pools[poolAddress.String()]
			nftPool := camelotNftPools.Data.NftPools[nftPoolAddress.String()]
			s.Apy = bnf((pool.OneWeekAverageAPR + nftPool.MinIncentivesApr) / 100)
			s.TvlTotal = bnf(pool.AverageReserveUSD)

		case "jusdc-stip":
			if defiLlamaPools.Status != "success" {
				check(httpGet(&defiLlamaPools, "https://yields.llama.fi/pools"))
			}
			for _, p := range defiLlamaPools.Data {
				if p.Pool == "dde58f35-2d08-4789-a641-1225b72c3147" {
					s.Apy = bnf(p.Apy / 100)
					s.TvlTotal = bnf(p.TvlUsd)
					break
				}
			}
			if s.Apy == nil {
				s.Apy = ZERO
			}

			jusdcContract, err := NewOther(common.HexToAddress("0xe66998533a1992ece9ea99cdf47686f4fc8458e0"), client)
			check(err)
			jusdcBalance, err := jusdcContract.BalanceOf(nil, common.HexToAddress(s.ApyId))
			check(err)
			arbOracle, err := NewOther(common.HexToAddress("0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6"), client)
			check(err)
			arbPrice, err := arbOracle.LatestAnswer(nil)
			check(err)
			arbPerSecond := bn(296980464625036965*1576/10000, 0)
			farmingApy := arbPerSecond.Mul(bnw(arbPrice)).Mul(ONE10).Mul(YEAR).
				Div(bnw(jusdcBalance))
			s.Apy = s.Apy.Add(farmingApy)
		}
	}
}

func taskHistoryPools() {
	for _, p := range pools {
		if p.Index == nil {
			continue
		}
		lmAddress := common.HexToAddress("0x3a039a4125e8b8012cf3394ef7b8b02b739900b1")
		lmContract, err := NewOther(lmAddress, client)
		check(err)
		lmRate, err := lmContract.Rate(nil)
		check(err)
		poolContract, err := NewOther(common.HexToAddress(p.Address), client)
		check(err)
		lmBalance, err := poolContract.BalanceOf(nil, lmAddress)
		check(err)
		check(dbExec(`insert into pools_history (id, chain, address, time, "index", share, supply, borrow, rate, price, lm_rate, lm_balance) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`, newId(), chainId, p.Address, time.Now(), p.Index, p.Shares, p.Supply, p.Borrow, p.Rate, p.Price, bnw(lmRate), bnw(lmBalance)))
	}
}

func taskHistoryApys() {
	for _, s := range strategies {
		if s.Apy == nil {
			continue
		}
		check(dbExec(`insert into apys_history (id, chain, "index", address, time, apy, tvl, tvl_internal) values ($1, $2, $3, $4, $5, $6, $7, $8)`, newId(), chainId, s.Index, s.Address, time.Now(), s.Apy, s.TvlTotal, s.Tvl))
	}
}

func taskHistoryPositions() {
	helperContract, err := NewHelper(addressInvestorHelper, client)
	check(err)
	investorContract, err := NewInvestor(addressInvestor, client)
	check(err)
	nextIndexRaw, err := investorContract.NextPosition(nil)
	check(err)
	nextIndex := nextIndexRaw.Int64()

	positions := []*DbPosition{}
	check(dbSelect(&positions, `select id, "index", shares, created from positions`))

	for i := nextIndex - 1; i >= 0; i-- {
		p := &DbPosition{Shares: ZERO}
		for _, pp := range positions {
			if pp.Index == i {
				p = pp
				break
			}
		}
		if p.Id != 0 && p.Shares.Eq(ZERO) {
			continue
		}

		result, err := helperContract.PeekPosition(nil, big.NewInt(i))
		if err != nil {
			log.Println("historyPositions: error fetching position", i, err)
			continue
		}

		if p.Id == 0 {
			p.Id = newId()
			p.Created = time.Now()
		}
		p.Chain = chainId
		p.Index = i
		p.Pool = result.Pool.Hex()
		p.Strategy = result.Strategy.String()
		p.Shares = bnw(result.Shares)
		p.Borrow = bnw(result.Borrow)
		p.SharesValue = bnw(result.SharesValue)
		p.BorrowValue = bnw(result.BorrowValue)
		p.Life = bnw(result.Life)
		p.Amount = bnw(result.Amount)
		p.Price = bnw(result.Price)
		p.Updated = time.Now()

		dbPut("positions", p)
		dbPut("positions_history", &DbPositionHistory{
			Id:          newId(),
			Chain:       p.Chain,
			Index:       p.Index,
			Time:        p.Updated,
			Shares:      p.Shares,
			Borrow:      p.Borrow,
			SharesValue: p.SharesValue,
			BorrowValue: p.BorrowValue,
			Life:        p.Life,
			Amount:      p.Amount,
			Price:       p.Price,
		})
		time.Sleep(50 * time.Millisecond)
	}
}

func taskEventsEarns() {
	latestBlock, err := client.BlockNumber(context.Background())
	check(err)
	lastBlock := uint64(stringToInt(cacheGet("lastBlock:earns", initialBlock)))

	for start := lastBlock; start < latestBlock; start += rpcMaxBlocksInBatch {
		log.Println("taskEventsEarns: ", start)
		end := start + rpcMaxBlocksInBatch
		if end > latestBlock {
			end = latestBlock
		}
		for _, s := range strategies {
			strategyContract, err := NewStrategy(common.HexToAddress(s.Address), client)
			check(err)
			iterator, err := strategyContract.FilterEarn(&bind.FilterOpts{
				Start: start + 1,
				End:   &end,
			})
			check(err)
			for iterator.Next() {
				e := iterator.Event
				log.Println("taskEventsEarns: Earn:", e)
				strategy, block := strategyAndBlock(e.Raw)
				check(dbExec(`insert into strategies_profits (id, block, txhash, time, strategy, earn, tvl) values ($1, $2, $3, $4, $5, $6, $7)`, newId(), e.Raw.BlockNumber, e.Raw.TxHash.Hex(), time.Unix(int64(block.Time), 0), e.Raw.Address.Hex(), bnw(e.Profit), bnw(e.Tvl)))
				if strategy != nil && e.Profit.Cmp(big.NewInt(0)) > 0 {
					telegramMessage("Strategy Profit: **%s** %s\nProfit_%.2f\n_TVL_ %.0f\n_Time_ %s", strategy.Name, strategy.Protocol, bnw(e.Profit).Float(), bnw(e.Tvl).Float(), time.Unix(int64(block.Time), 0).Format(time.DateTime))
				}
			}
			if iterator.Error() != nil {
				log.Println("taskEventsEarns: error:", iterator.Error())
				telegramMessage("taskEventsEarns: error: %s", iterator.Error())
			}
		}

		check(cacheSet("lastBlock:earns", intToString(int64(end)), cacheForever))
	}
}

func taskEventsPositions() {
	taskEventsPositionsLock.Lock()
	defer taskEventsPositionsLock.Unlock()
	investorContract, err := NewInvestor(addressInvestor, client)
	check(err)
	latestBlock, err := client.BlockNumber(context.Background())
	check(err)
	lastBlock := uint64(stringToInt(cacheGet("lastBlock:positions", initialBlock)))

	for start := lastBlock; start < latestBlock; start += rpcMaxBlocksInBatch {
		log.Println("taskEventsPositions: ", start)

		// Edits
		end := start + rpcMaxBlocksInBatch
		if end > latestBlock {
			end = latestBlock
		}
		iterator, err := investorContract.FilterEdit(&bind.FilterOpts{
			Start: start + 1,
			End:   &end,
		}, nil)
		check(err)
		for iterator.Next() {
			e := iterator.Event
			log.Println("taskEventsPositions: Edit:", e)
			strategy, block := strategyAndBlock(e.Raw)
			dataBytes, err := json.Marshal(J{
				"amount":   e.Amount.String(),
				"borrow":   e.Borrow.String(),
				"shares":   e.SharesChange.String(),
				"borrowed": e.BorrowChange.String(),
			})
			check(err)
			check(dbExec(`insert into positions_events (id, chain, index, block, txhash, time, name, data) values ($1, $2, $3, $4, $5, $6, $7, $8)`, newId(), chainId, bnw(e.Index), e.Raw.BlockNumber, e.Raw.TxHash.Hex(), time.Unix(int64(block.Time), 0), "Edit", dataBytes))
			if strategy != nil {
				strategyContract, err := NewStrategy(common.HexToAddress(strategy.Address), client)
				check(err)
				sharesValue, err := strategyContract.Rate(nil, e.SharesChange.Abs(e.SharesChange))
				check(err)
				borrow := bnw(e.BorrowChange).Mul(pools[0].Index).Div(ONE6)
				if e.SharesChange.Cmp(ZERO.Std()) == -1 {
					sharesValue = sharesValue.Mul(sharesValue, big.NewInt(-1))
				}
				telegramMessage("Position Change: **#%d %s %s**\n_Shares_ %.2f\n_Borrow_ %.2f", e.Index.Int64(), strategy.Name, strategy.Protocol, bnw(sharesValue).Float(), borrow.Float())
			}
			if iterator.Error() != nil {
				log.Println("taskEventsPositions: error:", iterator.Error())
				telegramMessage("taskEventsPositions: error: %s", iterator.Error())
			}

			// Kills
			iterator, err := investorContract.FilterKill(&bind.FilterOpts{
				Start: start + 1,
				End:   &end,
			}, nil, nil)
			check(err)
			for iterator.Next() {
				e := iterator.Event
				log.Println("taskEventsPositions: Kill:", e)
				strategy, block := strategyAndBlock(e.Raw)
				dataBytes, err := json.Marshal(J{
					"amount": e.Amount.String(),
					"borrow": e.Borrow.String(),
					"fee":    e.Fee.String(),
					"keeper": e.Keeper.Hex(),
				})
				check(err)
				check(dbExec(`insert into positions_events (id, chain, index, block, txhash, time, name, data) values ($1, $2, $3, $4, $5, $6, $7, $8)`, newId(), chainId, bnw(e.Index), e.Raw.BlockNumber, e.Raw.TxHash.Hex(), time.Unix(int64(block.Time), 0), "Kill", dataBytes))
				if strategy != nil {
					strategyContract, err := NewStrategy(common.HexToAddress(strategy.Address), client)
					check(err)
					sharesValue, err := strategyContract.Rate(nil, e.Amount.Abs(e.Amount))
					check(err)
					borrow := bnw(e.Borrow).Mul(pools[0].Index).Div(ONE6)
					if e.Amount.Cmp(ZERO.Std()) == -1 {
						sharesValue = sharesValue.Mul(sharesValue, big.NewInt(-1))
					}
					telegramMessage("Position Liquidation: %d %s %s Shares %.2f Borrow %.2f Fee %.2f Keeper %s", e.Index.Int64(), strategy.Name, strategy.Protocol, bnw(sharesValue).Float(), borrow.Float(), bnw(e.Fee).Mul(ONE12).Float(), e.Keeper.Hex())
				}
			}
			if iterator.Error() != nil {
				log.Println("taskEventsPositions: error:", iterator.Error())
				telegramMessage("taskEventsPositions: error: %s", iterator.Error())
			}
		}

		check(cacheSet("lastBlock:positions", intToString(int64(end)), cacheForever))
	}
}

// UTILS ///////////////////////////////////////////////////////////////////////

type J map[string]interface{}

func (j *J) Value() (driver.Value, error) {
	bs, err := json.Marshal(j)
	return string(bs), err
}

func (j *J) Scan(value interface{}) error {
	if value == nil {
		j = nil
		return nil
	}
	switch t := value.(type) {
	case []uint8:
		return json.Unmarshal([]byte(value.([]uint8)), j)
	default:
		return fmt.Errorf("Could not scan type %T into J", t)
	}
}

type BigInt big.Int

func (b *BigInt) Value() (driver.Value, error) {
	if b != nil {
		return (*big.Int)(b).String(), nil
	}
	return nil, nil
}

func (b *BigInt) Scan(value interface{}) error {
	if value == nil {
		b = nil
	}
	switch t := value.(type) {
	case []uint8:
		f, _, err := big.ParseFloat(string(value.([]uint8)), 10, 0, big.ToNearestEven)
		if err != nil {
			return fmt.Errorf("failed to load value to []uint8: %v", value)
		}
		f.Int((*big.Int)(b))
	default:
		return fmt.Errorf("Could not scan type %T into BigInt", t)
	}
	return nil
}

func (b *BigInt) MarshalJSON() ([]byte, error) {
	if b == nil {
		return []byte(`"0"`), nil
	}
	return json.Marshal(b.String())
}

func (b *BigInt) UnmarshalJSON(data []byte) error {
	if _, ok := (*big.Int)(b).SetString(string(data), 10); !ok {
		return fmt.Errorf("failed to parse bigint %s", string(data))
	}
	return nil
}

func (b *BigInt) Eq(a *BigInt) bool {
	return (*big.Int)(b).Cmp((*big.Int)(a)) == 0
}

func (b *BigInt) Add(a *BigInt) *BigInt {
	return (*BigInt)((&big.Int{}).Add((*big.Int)(b), (*big.Int)(a)))
}

func (b *BigInt) Sub(a *BigInt) *BigInt {
	return (*BigInt)((&big.Int{}).Sub((*big.Int)(b), (*big.Int)(a)))
}

func (b *BigInt) Mul(a *BigInt) *BigInt {
	return (*BigInt)((&big.Int{}).Mul((*big.Int)(b), (*big.Int)(a)))
}

func (b *BigInt) Div(a *BigInt) *BigInt {
	return (*BigInt)((&big.Int{}).Div((*big.Int)(b), (*big.Int)(a)))
}

func (b *BigInt) Std() *big.Int {
	return (*big.Int)(b)
}

func (b *BigInt) Float() float64 {
	return float64((*big.Int)(b.Div(ONE12)).Uint64()) / 1000000
}

func (b *BigInt) String() string {
	return (*big.Int)(b).String()
}

func env(key string, alt string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return alt
}

var idSeq int64 = 0

func newId() int64 {
	atomic.AddInt64(&idSeq, 1)
	id := (time.Now().UnixNano() / int64(time.Millisecond)) - 1262304000000
	id = id << 12
	id = id | (idSeq % 4096)
	return id
}

func stringToSnakeCase(src string) string {
	isUpper := func(r rune) bool {
		return r >= 'A' && r <= 'Z'
	}
	buf := ""
	for i, v := range src {
		if i > 0 && isUpper(v) && !isUpper([]rune(src)[i-1]) {
			buf += "_"
		}
		buf += string(v)
	}
	buf = strings.Replace(buf, "/", "_", -1)
	return strings.ToLower(buf)
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func bn(num int64, base int64) *BigInt {
	x := big.NewInt(0).Exp(big.NewInt(10), big.NewInt(base), nil)
	n := big.NewInt(num)
	return (*BigInt)(n.Mul(n, x))
}

func bnf(num float64) *BigInt {
	n := big.NewInt(int64(num * 1000000000))
	n.Mul(n, big.NewInt(1000000000))
	return (*BigInt)(n)
}

func bnw(b *big.Int) *BigInt {
	return (*BigInt)(b)
}

func httpResJson(w http.ResponseWriter, code int, v interface{}) {
	bs, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		httpResJson(w, 500, map[string]interface{}{"error": err.Error()})
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(bs)
}

func httpGet(v interface{}, url string) error {
	res, err := http.DefaultClient.Get(url)
	if err != nil {
		return err
	}
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}
	if res.StatusCode >= 400 {
		return fmt.Errorf("httpGet: error: %d: %s", res.StatusCode, string(body))
	}
	return json.Unmarshal(body, v)
}

func dbGet(result interface{}, sql string, args ...interface{}) error {
	log.Println("dbGet:", sql, args)
	return db.Get(result, sql, args...)
}

func dbGetWhere(table string, result interface{}, where string, args ...interface{}) error {
	sql := `select * from ` + table + ` where ` + where + ` limit 1`
	return dbGet(result, sql, args...)
}

func dbSelect(result interface{}, sql string, args ...interface{}) error {
	log.Println("dbSelect:", sql, args)
	return db.Select(result, sql, args...)
}

func dbSelectWhere(table string, result interface{}, where string, args ...interface{}) error {
	sql := `select * from ` + table + ` where ` + where
	return dbSelect(result, sql, args...)
}

func dbPut(table string, entity interface{}) error {
	log.Println("dbPut:", entity)
	cols := []string{}
	args := []interface{}{}

	v := reflect.ValueOf(entity)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	if v.Kind() != reflect.Struct {
		return fmt.Errorf("dbPut: value is not a struct: %#v", entity)
	}
	vt := v.Type()
	for i := 0; i < vt.NumField(); i++ {
		cols = append(cols, stringToSnakeCase(vt.Field(i).Name))
		args = append(args, v.Field(i).Interface())
	}

	join := strings.Join
	vars := []string{}
	sets := []string{}
	for i, c := range cols {
		vars = append(vars, "$"+strconv.Itoa(i+1))
		sets = append(sets, c+" = "+vars[i])
	}
	sql := "insert into %s (%s) values (%s) on conflict (id) do update set %s returning *"
	sql = fmt.Sprintf(sql, table, join(cols, ", "), join(vars, ", "), join(sets, ", "))
	return dbGet(entity, sql, args...)
}

func dbExec(sql string, args ...interface{}) error {
	_, err := db.Exec(sql, args...)
	return err
}

func dbDelete(table string, model interface{}) error {
	v := reflect.ValueOf(model)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	return dbExec(fmt.Sprintf("delete from %s where id = $1", table), v.Field(0).Interface())
}

const cacheForever int64 = 20 * 365 * 24 * 60 * 60

func cacheGet(key, alt string) string {
	value := struct{ Value string }{}
	err := dbGet(&value, `select value from cache where key = $1 and now() < expires`, key)
	if err != nil {
		return alt
	}
	return value.Value
}

func cacheSet(key, value string, ttlSeconds int64) error {
	return dbExec(`insert into cache (key, value, expires) values ($1, $2, $3) on conflict (key) do update set value = $2, expires = $3`, key, value, time.Now().Add(time.Duration(ttlSeconds)*time.Second))
}

func telegramMessage(message string, args ...interface{}) {
	defer func() {
		if e := recover(); e != nil {
			log.Println("ERROR sending telegram message:", e)
		}
	}()
	text := fmt.Sprintf(message, args...)
	log.Println("telegramMessage:", strings.Replace(text, "\n", " ", -1))
	if !isProduction {
		return
	}
	chatID := env("TELEGRAM_CHAT_ID", "")
	if strings.HasPrefix(text, "ERROR") {
		chatID = env("TELEGRAM_CHAT_ID_ERRORS", "")
	}
	bs, err := json.Marshal(map[string]interface{}{
		"chat_id":                  chatID,
		"text":                     text,
		"parse_mode":               "Markdown",
		"disable_web_page_preview": true,
	})
	check(err)
	_, err = http.Post(fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", env("TELEGRAM_BOT_TOKEN", "")), "application/json", bytes.NewReader(bs))
	check(err)
}

func nextTxOpts() *bind.TransactOpts {
	//txOpts.Nonce = bnw(txOpts.Nonce).Add(bn(1, 0)).Std()
	next := *txOpts
	//nonce, err := client.PendingNonceAt(context.Background(), txOpts.From)
	//check(err)
	//next.Nonce = big.NewInt(int64(nonce))
	return &next
}

func waitTx(tx *types.Transaction, err error) (string, error) {
	if err != nil {
		return "", err
	}
	if isProduction {
		//r, err := bind.WaitMined(context.Background(), client, tx)
		time.Sleep(4100 * time.Millisecond)
		return tx.Hash().Hex(), err
	} else {
		return tx.Hash().Hex(), nil
	}
}

func aprToApy(apr *BigInt) *BigInt {
	n := apr.Std()
	n.Div(n, big.NewInt(365))
	n.Add(n, ONE.Std())
	x := (&big.Int{}).Set(n)
	for i := 0; i < 365; i++ {
		x.Mul(x, n)
		x.Div(x, ONE.Std())
	}
	return bnw(x.Sub(x, ONE.Std()))
}

func strategyAndBlock(l types.Log) (*StrategyInfo, *types.Header) {
	var strategy *StrategyInfo
	for _, s := range strategies {
		if s.Address == l.Address.Hex() {
			strategy = s
			break
		}
	}
	block, err := client.HeaderByNumber(context.Background(), big.NewInt(int64(l.BlockNumber)))
	check(err)
	return strategy, block
}

func stringToInt(a string) int64 {
	i, err := strconv.ParseInt(a, 10, 64)
	check(err)
	return i
}

func intToString(i int64) string {
	return strconv.FormatInt(i, 10)
}
