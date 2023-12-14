import Link from "next/link";
import Head from "next/head";
import Logo from "./logo";
import Icon from "./icon";
import Footer from "./footer";

export default function LayoutWebsite({ title, children }) {
  return (
    <>
      <Head>
        <title>{`${title ? `${title} | ` : ""} Rodeo Finance`}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>

      <div className="homepage">
        <div className="container">
          <div className="header-website">
            <div className="grid-3">
              <div className="text-center-phone">
                <Link href="/">
                  <a className="logo">
                    <img src="/logo.png" />
                  </a>
                </Link>
              </div>
              <div className="header-website-links">
                <Link href="#overview">
                  <a>Overview</a>
                </Link>
                <Link href="#why">
                  <a>Why</a>
                </Link>
                <Link href="#integrations">
                  <a>Integrations</a>
                </Link>
              </div>
              <div className="text-right">
                <Link href="/farm">
                  <a className="button w-full-phone">Launch App</a>
                </Link>
              </div>
            </div>
          </div>

          {children}

          <div className="home-icons" id="integrations">
            <h2>Join Our Community</h2>
            <div className="home-icons-row">
              <a
                className="home-icon"
                href="https://t.me/rodeofinance"
                target="_blank"
                rel="noreferrer"
              >
                <Icon name="telegram" />
              </a>
              <a
                className="home-icon"
                href="https://twitter.com/Rodeo_Finance"
                target="_blank"
                rel="noreferrer"
              >
                <Icon name="twitter" />
              </a>
              <a
                className="home-icon"
                href="https://discord.gg/6N9braAzms"
                target="_blank"
                rel="noreferrer"
              >
                <Icon name="discord" />
              </a>
              <a
                className="home-icon"
                href="https://docs.rodeofinance.xyz/"
                target="_blank"
                rel="noreferrer"
              >
                <Icon name="gitbook" />
              </a>
              <a
                className="home-icon"
                href="https://medium.com/@Rodeo_Finance"
                target="_blank"
                rel="noreferrer"
              >
                <Icon name="medium" />
              </a>
            </div>
          </div>
        </div>
        <Footer />
      </div>
    </>
  );
}
