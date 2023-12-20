import { useEffect, Component } from "react";
import { formatError } from "../utils";
import { WagmiConfig } from "wagmi";
import {
  RainbowKitProvider,
  lightTheme,
  darkTheme,
} from "@rainbow-me/rainbowkit";
import { useNetwork } from "wagmi";
import { wagmiClient, chains, DEFAULT_NETWORK_NAME } from "../utils";
import ErrorBoundary from "../components/errorBoundary";
import Layout from "../components/layout";

import "@rainbow-me/rainbowkit/styles.css";
import "react-toastify/dist/ReactToastify.css";
import "../styles.scss";

export default function App({ Component, pageProps }) {
  const { chain } = useNetwork();
  const networkName = chain?.network || DEFAULT_NETWORK_NAME;

  const themeOverrides = (theme) => {
    return Object.assign(theme, {
      colors: Object.assign(theme.colors, {
        accentColor: "var(--primary)",
      }),
      radii: Object.assign(theme.radii, {
        actionButton: "8px",
        connectButton: "8px",
        menuButton: "8px",
        modal: "8px",
        modalMobile: "8px",
      }),
    });
  };
  const theme = {
    lightMode: themeOverrides(lightTheme()),
    darkMode: themeOverrides(darkTheme()),
  };

  useEffect(() => {
    if (window.location.hostname === "alpha.rodeofinance.xyz") {
      window.location.href = "https://www.rodeofinance.xyz/farm";
    }
  }, []);

  return (
    <ErrorBoundary>
      <WagmiConfig client={wagmiClient}>
        <RainbowKitProvider chains={chains} theme={theme}>
          {networkName != "arbitrum" && networkName != "localhost" && networkName != "sepolia" ? (
            <Layout title="Wrong network"></Layout>
          ) : (
            <ErrorBoundary>
              <Component {...pageProps} />
            </ErrorBoundary>
          )}
        </RainbowKitProvider>
      </WagmiConfig>
    </ErrorBoundary>
  );
}
