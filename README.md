## Rodeo Monorepo

Rodeo Finance's world live here.

- `contracts/` Smart contracts (see readme)
- `pages/api/` API providing historical data and event. Worker taking care for data collection, strategy cranking and liquidations
- `pages/*.js` Website pages
- `pages/*/*.js` App pages

### Setup

Follow there steps to run the app locally:

1. Install node, npm, [forge/foundry](https://github.com/foundry-rs/foundry/tree/master/foundryup), postgresql
1. Make sure you have a postgres user named `admin` with a password `admin` created (`CREATE ROLE admin WITH SUPERUSER LOGIN PASSWORD 'admin';`)
2. Run `npm run db` to create the database tables
3. In a separate terminal, in the `contracts/` folder, run `make node`
4. In the `contracts/` folder, run `make deploy-local` to deploy all contracts to your local blockchain node running in the other terminal
5. You are now ready to run the app using `npm run start`
6. If you want to run the background worker to backfill some APY / historical statistics you can run `npm run worker` anytime

Make sure to add the private key `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` to metamask, this is the local blockchain account that has some test USDC to use.

If you want to run the app against the mainnet contracts, it should be as simple as connecting metamask while on the Arbitrum One network but running the app with `npm run prod` will make sure that a few enviroment variables are more appropriate for a mainnet environment (especially around API endpoints and APY fetching)

### API

**`/apy/defillama`**

- `id` DefiLlama UUID of the yield/pool

https://www.rodeofinance.xyz/api/apy/defillama?id=bf5ee77b-0a22-497c-abec-617ef376531c

```json
{
  "apy":30.64,
  "tvl":3484110
}
```

**`/apy/uniswapv3`**

- `id` Address of the UniswapV3 rodeo strategy contract (not the pool contract, so it can account for concentrated liquidity)

https://www.rodeofinance.xyz/api/apy/uniswapv3?id=0xc8A3842930f5e25dFfa73cAa33191dC42E079E31

```json
{
  "apy": 3.398277331596966,
  "tvl": 11473508
}
```

**`/pools/history`**

- `chain` Chain ID (e.g. 42161 for Arbitrum, 1337 for localhost)
- `address` Address of the rodeo pool contract
- `interval` Interval length, either "hour", "day", or "week" (default is hour)
- `length` Number of recent intervals to return (default is 100)

https://www.rodeofinance.xyz/api/pools/history?chain=42161&address=0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE&interval=day&length=2

```json
[
  {
    "t": "2022-11-28T00:00:00.000Z",
    "index": "1000378851095876913",
    "share": "591471847",
    "supply": "591505610",
    "borrow": "454548238",
    "rate": "1174021585",
    "price": "1000099250000000000"
  },
  {
    "t": "2022-11-29T00:00:00.000Z",
    "index": "1000450257923041827",
    "share": "610420313",
    "supply": "610492003",
    "borrow": "524342155",
    "rate": "1574461234",
    "price": "999929165652173913"
  }
]
```

**`/positions`**

- `chain` Chain ID (e.g. 42161 for Arbitrum, 1337 for localhost)
- `index` Position index (in the Investor contract) (or NFT ID)

https://www.rodeofinance.xyz/api/positions?chain=42161&index=0

```json
[
  {
    "id": "1668604268892161",
    "chain": "42161",
    "index": "0",
    "pool": "0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE",
    "strategy": "0xc8A3842930f5e25dFfa73cAa33191dC42E079E31",
    "shares": "323263171943",
    "borrow": "12499938",
    "shares_value": "23001388992753000199",
    "borrow_value": "12509966",
    "life": "1746245343123133604",
    "amount": "9968397",
    "price": "1000267720000000000",
    "created": "2022-11-28T23:28:09.085Z",
    "updated": "2022-11-30T15:08:07.443Z"
  }
]
```

**`/positions/history`**

- `chain` Chain ID (e.g. 42161 for Arbitrum, 1337 for localhost)
- `index` Position index (in the Investor contract) (or NFT ID)
- `interval` Interval length, either "hour", "day", or "week" (default is hour)
- `length` Number of recent intervals to return (default is 100)

https://www.rodeofinance.xyz/api/positions/history?chain=42161&index=0&interval=day&length=2

```json
[
  {
    "t": "2022-11-28T00:00:00.000Z",
    "shares": "323263171943",
    "borrow": "12499938",
    "shares_value": "22124674372513277665",
    "borrow_value": "12504658",
    "life": "1680682028010714411",
    "amount": "9968397",
    "price": "1000099250000000000"
  },
  {
    "t": "2022-11-29T00:00:00.000Z",
    "shares": "323263171943",
    "borrow": "12499938",
    "shares_value": "22456912553879082073",
    "borrow_value": "12505565.652173913043",
    "life": "1706087061131286497",
    "amount": "9968397",
    "price": "999929165652173913"
  }
]
```

**`/positions/events`**

- `chain` Chain ID (e.g. 42161 for Arbitrum, 1337 for localhost)
- `index` Position index (in the Investor contract) (or NFT ID)

https://www.rodeofinance.xyz/api/positions/events?chain=42161&index=1

```json
[
  {
    "time": "2022-11-28T15:56:47.411Z",
    "block": "39160850",
    "name": "Earn",
    "data": {
      "amount": "10000000",
      "borrow": "30000000",
      "borrowFee": "0",
      "id": "1",
      "pool": "0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE",
      "strategy": "0x878737EF4F32d91E25F5a6E723B1c83607Fd2e53",
      "user": "0x367e849B764FF6C3279D4bBCF1cCade0085B402f"
    }
  },
  {
    "time": "2022-11-28T15:56:47.427Z",
    "block": "39169045",
    "name": "Sell",
    "data": {
      "amount": "1007621",
      "balance": "999999",
      "borrow": "999993",
      "fee": "0",
      "id": "1",
      "shares": "1198476721809276175",
      "user": "0x367e849B764FF6C3279D4bBCF1cCade0085B402f"
    }
  }
]
```

### Developing

Run the app using `npm run dev` and visit `localhost:3000`. To build the app
for deployment use `npm run build`.

This project uses next.js.
