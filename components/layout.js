import { useEffect, useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { ToastContainer } from "react-toastify";
import Head from "next/head";
import Link from "next/link";
import Logo from "./logo";
import Icon from "./icon";
import Footer from "./footer";
import ErrorBoundary from "./errorBoundary";
import { formatNumber, useWeb3, ServiceMode } from "../utils";

export default function Layout({
  title,
  children,
  navigation,
  backLink,
  hideWarning,
  service = ServiceMode.Farms
}) {
  
  const router = useRouter();
  const { contracts, signer, address, networkName } = useWeb3();
  const dynamicTitle = `${title ? title + " | " : ""}Rodeo`;
  const [mode, setMode] = useState("light");
  const [rdo, setRdo] = useState(0);

  function onToggleMode() {
    const newMode = mode === "light" ? "dark" : "light";
    setMode(newMode);
    localStorage.setItem("mode", newMode);
    document.body.classList.toggle("dark");
  }

  async function fetchData() {
    if (!contracts) return;
    setRdo(await contracts.liquidityMining.getPending(address));
  }

  useEffect(() => {
    if (service != ServiceMode.Vault && networkName != "sepolia")
      fetchData();
  }, [address, networkName]);

  useEffect(() => {
    if (global.window?.localStorage.getItem("mode") === "dark") {
      setMode("dark");
      document.body.classList.add("dark");
    }
  }, []);

  const links = (
    <>
      <Link href="/farm">
        <a className={router.pathname.includes("/farm") ? "active" : ""}>
          <Icon name="farm" />
          Farms
        </a>
      </Link>
      <Link href="/earn">
        <a className={router.pathname.includes("/earn") ? "active" : ""}>
          <Icon name="refresh" />
          Earn
        </a>
      </Link>
      <Link href="/vault">
        <a className={router.pathname.includes("/vault") ? "active" : ""}>
          <Icon name="refresh" />
          Vault
        </a>
      </Link>
      <Link href="/positions">
        <a className={router.pathname == "/positions" ? "active" : ""}>
          <Icon name="briefcase" />
          Positions
        </a>
      </Link>
      <Link href="/silos">
        <a className={router.pathname == "/silos" ? "active" : ""}>
          <Icon name="silo" />
          Silos
        </a>
      </Link>
      <Link href="/vesting">
        <a className={router.pathname == "/vesting" ? "active" : ""}>
          <Icon name="hourglass" />
          Vesting
        </a>
      </Link>
      <Link href="/analytics">
        <a className={router.pathname == "/analytics" ? "active" : ""}>
          <Icon name="bar-chart" />
          Analytics
        </a>
      </Link>
    </>
  );

  return (
    <>
      <Head>
        <title>{dynamicTitle}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <ToastContainer />

      <div className="app">
        <div className="hide container flex-phone items-center mt-4">
          <details className="mobile-nav">
            <summary>
              <Icon name="menu" />
            </summary>
            <nav>{links}</nav>
          </details>
          <div className="flex-1"></div>
          <div>
            <ConnectButton showBalance={false} />
          </div>
        </div>

        <div className="sidebar">
          <div className="sidebar-logo">
            <Logo wide height={38} />
          </div>
          <div className="sidebar-links">{links}</div>
        </div>
        <div className="container">
          <div className="header">
            <div className="header-row">
              <div className="flex items-center" style={{ minWidth: 0 }}>
                {backLink ? (
                  <Link href={backLink}>
                    <a className="header-back-link">
                      <Icon name="chevron-left" />
                    </a>
                  </Link>
                ) : null}
                <h1 className="truncate">{title}</h1>
              </div>
              <div className="flex items-center hide-phone">
                <a
                  className="header-button"
                  target="_blank"
                  rel="noreferrer"
                  href="https://app.1inch.io/#/42161/simple/swap/ETH/0x033f193b3Fceb22a440e89A2867E8FEE181594D9"
                >
                  Buy RDO
                </a>
                <a
                  className="header-button"
                  target="_blank"
                  rel="noreferrer"
                  href="https://app.camelot.exchange/pools/0xAB21B75f1f312879760Ca8690f7B91c1c2985F91"
                >
                  LP RDO/ETH
                </a>
                <Link href="/earn/usdc-v1">
                  <a className="header-button header-button-rdo">
                    {formatNumber(rdo, 18, 1)} RDO
                  </a>
                </Link>
                <a className="header-theme flex" onClick={onToggleMode}>
                  <Icon name="moon" />
                </a>
                <div className="header-wallet">
                  <ConnectButton showBalance={false} />
                </div>
              </div>
            </div>
          </div>

          {!hideWarning ? (
            <div className="card text-center mb-6">
              Rodeo Finance is{" "}
              <a
                href="https://docs.rodeofinance.xyz/contracts-audits-and-security/audits"
                target="_blank"
                rel="noreferrer"
              >
                <u>audited</u>
              </a>
              , but still in beta. Only deposit what you can lose.
            </div>
          ) : null}

          {
          service != ServiceMode.Vault &&
          networkName != "arbitrum" &&
          networkName != "arbitrum-rinkeby" &&
          networkName != "localhost" ? (
            <div
              style={{
                fontSize: 18,
                fontWeight: "bold",
                textAlign: "center",
                padding: "10vh 0",
              }}
            >
              Wrong network connected. Switch to Arbitrum
            </div>
          )
            : (
              <ErrorBoundary>{children}</ErrorBoundary>
            )
        }
            
        </div>
        <Footer />
      </div>
    </>
  );
}
