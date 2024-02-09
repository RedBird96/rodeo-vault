CREATE TABLE pools_history (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  address text NOT NULL,
  time timestamptz NOT NULL DEFAULT now(),
  "index" decimal NOT NULL,
  share decimal NOT NULL,
  supply decimal NOT NULL,
  borrow decimal NOT NULL,
  rate decimal NOT NULL,
  price decimal NOT NULL,
  lm_rate decimal NOT NULL,
  lm_balance decimal NOT NULL
);
CREATE INDEX pools_history_idx ON pools_history (chain, address, time);

CREATE TABLE pools_events (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  address text NOT NULL,
  time timestamptz NOT NULL DEFAULT now(),
  block decimal NOT NULL,
  txhash text NOT NULL,
  name text NOT NULL,
  who text NOT NULL,
  amount1 decimal NOT NULL,
  amount2 decimal NOT NULL,
  amount3 decimal NOT NULL
);
CREATE INDEX pools_events_idx ON pools_events (chain, address, time);

CREATE TABLE positions (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  "index" int NOT NULL,
  pool text NOT NULL,
  strategy text NOT NULL,
  shares decimal NOT NULL,
  borrow decimal NOT NULL,
  shares_value decimal NOT NULL,
  borrow_value decimal NOT NULL,
  life decimal NOT NULL,
  amount decimal NOT NULL,
  price decimal NOT NULL,
  created timestamptz NOT NULL DEFAULT now(),
  updated timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX positions_idx ON positions (chain, "index");

CREATE TABLE positions_history (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  "index" int NOT NULL,
  time timestamptz NOT NULL DEFAULT now(),
  shares decimal NOT NULL,
  borrow decimal NOT NULL,
  shares_value decimal NOT NULL,
  borrow_value decimal NOT NULL,
  life decimal NOT NULL,
  amount decimal NOT NULL,
  price decimal NOT NULL
);
CREATE INDEX positions_history_idx ON positions_history (chain, "index", time);

CREATE TABLE positions_events (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  "index" int NOT NULL,
  time timestamptz NOT NULL DEFAULT now(),
  block decimal NOT NULL,
  txhash text NOT NULL,
  name text NOT NULL,
  data jsonb NOT NULL
);
CREATE INDEX positions_events_idx ON positions_events (chain, "index", time);

CREATE TABLE apys_history (
  id bigint NOT NULL PRIMARY KEY,
  chain int NOT NULL,
  "index" int NOT NULL,
  address text NOT NULL,
  time timestamptz NOT NULL DEFAULT now(),
  apy decimal NOT NULL,
  tvl decimal NOT NULL,
  tvl_internal decimal NOT NULL
);
CREATE INDEX apys_history_idx ON apys_history (chain, address, time);

CREATE TABLE tasks (
  id text NOT NULL PRIMARY KEY,
  task text NOT NULL,
  error text NOT NULL,
  time timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tasks_schedules (
  id text NOT NULL PRIMARY KEY,
  time timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE strategies_profits (
  id text NOT NULL PRIMARY KEY,
  time timestamptz NOT NULL DEFAULT now(),
  strategy text NOT NULL,
  block decimal NOT NULL,
  txhash text NOT NULL,
  earn decimal NOT NULL,
  tvl decimal NOT NULL
);

CREATE TABLE earns (
  id bigint NOT NULL PRIMARY KEY,
  last timestamptz NOT NULL,
  next timestamptz NOT NULL
);

CREATE TABLE prices (
  id text NOT NULL PRIMARY KEY,
  price decimal NOT NULL,
  time timestamptz NOT NULL
);

CREATE TABLE cache (
  key text NOT NULL PRIMARY KEY,
  value text NOT NULL,
  expires timestamptz NOT NULL
);

CREATE TABLE vault_position_history (
    id bigint NOT NULL PRIMARY KEY,
    action integer,
    amount numeric,
    status text NOT NULL,
    wallet text NOT NULL,
    "time" text NOT NULL
);