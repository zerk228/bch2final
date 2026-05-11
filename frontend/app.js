import { BrowserProvider, Contract, formatEther, parseEther, getAddress } from "https://esm.sh/ethers@6.13.2";

const ADDR = {
  rwa: "0x0000000000000000000000000000000000000000",
  gov: "0x0000000000000000000000000000000000000000",
  vault: "0x0000000000000000000000000000000000000000",
  amm: "0x0000000000000000000000000000000000000000",
  governor: "0x0000000000000000000000000000000000000000",
};
const SUBGRAPH = "https://api.studio.thegraph.com/query/00000/rwa-subgraph/v0.0.1";
const EXPECTED_CHAIN_ID = 421614n;

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function decimals() view returns (uint8)",
];
const GOV_ABI = [
  ...ERC20_ABI,
  "function getVotes(address) view returns (uint256)",
  "function delegates(address) view returns (address)",
  "function delegate(address)",
];
const VAULT_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function deposit(uint256,address) returns (uint256)",
  "function asset() view returns (address)",
];
const AMM_ABI = [
  "function getReserves() view returns (uint256,uint256)",
  "function token0() view returns (address)",
  "function token1() view returns (address)",
  "function swap(address,uint256,uint256,address) returns (uint256)",
];
const GOVERNOR_ABI = [
  "function state(uint256) view returns (uint8)",
  "function castVote(uint256,uint8) returns (uint256)",
];

const $ = (id) => document.getElementById(id);
const setStatus = (msg, kind = "ok") => {
  const el = $("status");
  el.textContent = msg;
  el.className = kind;
};
const fmtErr = (e) => {
  const m = e?.shortMessage || e?.reason || e?.info?.error?.message || e?.message || "Unknown error";
  if (m.includes("user rejected")) return "Transaction rejected in wallet.";
  if (m.includes("insufficient funds")) return "Insufficient balance.";
  return m;
};

let provider, signer, account;

async function connect() {
  if (!window.ethereum) {
    setStatus("MetaMask not detected. Install MetaMask.", "err");
    return;
  }
  try {
    provider = new BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    account = await signer.getAddress();
    $("acct").textContent = account;
    await checkNetwork();
    await refresh();
    await loadProposals();
  } catch (e) {
    setStatus(fmtErr(e), "err");
  }
}

async function checkNetwork() {
  const net = await provider.getNetwork();
  $("net").textContent = net.name + " (" + net.chainId + ")";
  if (net.chainId !== EXPECTED_CHAIN_ID) {
    setStatus("Wrong network. Switching to Arbitrum Sepolia.", "err");
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x66eee" }],
      });
    } catch (e) {
      setStatus("Please switch your wallet to Arbitrum Sepolia.", "err");
    }
  }
}

async function refresh() {
  try {
    const rwa = new Contract(ADDR.rwa, ERC20_ABI, signer);
    const gov = new Contract(ADDR.gov, GOV_ABI, signer);
    const vault = new Contract(ADDR.vault, VAULT_ABI, signer);
    const amm = new Contract(ADDR.amm, AMM_ABI, signer);
    const [rwaBal, vBal, vp, dlg, reserves] = await Promise.all([
      rwa.balanceOf(account),
      vault.balanceOf(account),
      gov.getVotes(account),
      gov.delegates(account),
      amm.getReserves(),
    ]);
    $("rwaBal").textContent = formatEther(rwaBal);
    $("vBal").textContent = formatEther(vBal);
    $("vp").textContent = formatEther(vp);
    $("dlg").textContent = dlg;
    $("res").textContent = formatEther(reserves[0]) + " / " + formatEther(reserves[1]);
  } catch (e) {
    setStatus(fmtErr(e), "err");
  }
}

async function doSwap() {
  try {
    const amt = parseEther($("swapAmt").value || "0");
    const rwa = new Contract(ADDR.rwa, ERC20_ABI, signer);
    setStatus("Approving...");
    const a = await rwa.approve(ADDR.amm, amt);
    await a.wait();
    const amm = new Contract(ADDR.amm, AMM_ABI, signer);
    setStatus("Swapping...");
    const tx = await amm.swap(ADDR.rwa, amt, 0, account);
    await tx.wait();
    setStatus("Swap confirmed.");
    await refresh();
  } catch (e) {
    setStatus(fmtErr(e), "err");
  }
}

async function doDeposit() {
  try {
    const amt = parseEther($("depAmt").value || "0");
    const rwa = new Contract(ADDR.rwa, ERC20_ABI, signer);
    setStatus("Approving...");
    const a = await rwa.approve(ADDR.vault, amt);
    await a.wait();
    const vault = new Contract(ADDR.vault, VAULT_ABI, signer);
    setStatus("Depositing...");
    const tx = await vault.deposit(amt, account);
    await tx.wait();
    setStatus("Deposit confirmed.");
    await refresh();
  } catch (e) {
    setStatus(fmtErr(e), "err");
  }
}

const STATES = ["Pending", "Active", "Canceled", "Defeated", "Succeeded", "Queued", "Expired", "Executed"];

async function loadProposals() {
  try {
    const q = `{ proposals(orderBy: startBlock, orderDirection: desc, first: 10) { id proposer description forVotes againstVotes } }`;
    const res = await fetch(SUBGRAPH, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ query: q }),
    });
    const j = await res.json();
    const tbody = $("proposals").querySelector("tbody");
    tbody.innerHTML = "";
    if (!j.data || !j.data.proposals) return;
    const governor = new Contract(ADDR.governor, GOVERNOR_ABI, signer);
    for (const p of j.data.proposals) {
      let stateLabel = "?";
      try {
        const s = await governor.state(p.id);
        stateLabel = STATES[Number(s)] || s.toString();
      } catch {}
      const tr = document.createElement("tr");
      tr.innerHTML = `<td>${p.id.slice(0, 10)}…</td><td>${p.description}</td><td>${stateLabel}</td><td>${formatEther(p.forVotes)}</td><td>${formatEther(p.againstVotes)}</td><td><button data-id="${p.id}">Vote For</button></td>`;
      tbody.appendChild(tr);
    }
    tbody.querySelectorAll("button").forEach((b) =>
      b.addEventListener("click", async () => {
        try {
          const governor = new Contract(ADDR.governor, GOVERNOR_ABI, signer);
          const tx = await governor.castVote(b.dataset.id, 1);
          await tx.wait();
          setStatus("Vote cast.");
          await loadProposals();
        } catch (e) {
          setStatus(fmtErr(e), "err");
        }
      })
    );
  } catch (e) {
    setStatus("Subgraph fetch failed: " + fmtErr(e), "err");
  }
}

$("connect").addEventListener("click", connect);
$("swap").addEventListener("click", doSwap);
$("dep").addEventListener("click", doDeposit);

if (window.ethereum) {
  window.ethereum.on("chainChanged", () => location.reload());
  window.ethereum.on("accountsChanged", () => location.reload());
}
