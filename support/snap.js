const ethers = require("ethers");

const ONE = ethers.utils.parseUnits("1", 18);
const ONE6 = ethers.utils.parseUnits("1", 6);
const ONE12 = ethers.utils.parseUnits("1", 12);
const rpc =
  process.env.NEXT_PUBLIC_RODEO_RPC_URL_ARBITRUM ||
  "https://arb1.arbitrum.io/rpc";
const provider = new ethers.providers.StaticJsonRpcProvider(rpc, 42161);

function call(address, fn, ...args) {
  //console.log("call", address, fn, args);
  let [name, params, returns] = fn.split("-");
  const rname = name[0] === "+" ? name.slice(1) : name;
  let efn = `function ${rname}(${params}) external`;
  if (name[0] !== "+") efn += " view";
  if (returns) efn += ` returns (${returns})`;
  const contract = new ethers.Contract(address, [efn], provider);

(async () => {
  const liquidityMining = "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1";

  const logs = await provider.getLogs({
    fromBlock: 97215676,
    address: "0x3A039A4125E8B8012CF3394eF7b8b02b739900b1",
    topics: [
      "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c",
      null,
      null,
    ],
  });
  let addresses = logs
    .map((l) => ethers.utils.getAddress("0x" + l.topics[1].slice(26)))
    .sort();
  addresses = [...new Set(addresses)];

  const eps = ethers.utils.parseUnits("3456124839563555776551182", 0);
  let totalOwed = ethers.utils.parseUnits("0");
  for (let a of addresses) {
    const lmData = await call(
      liquidityMining,
      "users-address-uint256,int256",
      a
    );
    const owed = lmData[0].mul(eps).div(ONE12).sub(lmData[1]);
    totalOwed = totalOwed.add(owed);
    console.log(a, owed.div(ONE).toString());
  }
  console.log("total", totalOwed.div(ONE).toString());
})();
