import Link from "next/link";
import Logo from "./logo";

export default function Footer() {
  return (
    <div className="footer container">
      <div className="footer-logo">
        <Logo wide />
      </div>
      <div className="footer-links">
        <Link href="/farm">
          <a>Farms</a>
        </Link>
        <Link href="/earn">
          <a>Earn</a>
        </Link>
        <a
          href="https://docs.rodeofinance.xyz/the-protocol/faq"
          target="_blank"
          rel="noreferrer"
        >
          FAQ
        </a>
        <a
          href="https://docs.rodeofinance.xyz/the-protocol/how-to-participate/farmers-borrowers"
          target="_blank"
          rel="noreferrer"
        >
          Guides
        </a>
        <a
          href="https://twitter.com/Rodeo_Finance"
          target="_blank"
          rel="noreferrer"
        >
          Contact Us
        </a>
        <a
          href="https://forms.gle/JvbJL5AhScscdRTt8"
          target="_blank"
          rel="noreferrer"
        >
          Partnerships
        </a>
      </div>
      <div className="text-faded mb-6 font-sm">
        Rodeo Finance is a leveraged yield farming product, and using leveraged
        products involves certain risks. Please read{" "}
        <a
          href="https://docs.rodeofinance.xyz/"
          target="_blank"
          rel="noreferrer"
        >
          here
        </a>{" "}
        to understand these risks. As a user of our protocol, you are in
        agreement that you are aware of these risks, and that all liability
        resides with you. So please don’t invest your life savings, or risk
        assets you can’t afford to lose. Try to be as careful with your funds as
        we are with our code.
      </div>
      <div className="text-faded mb-6">
        © 2022 Rodeo Finance, All rights reserved.
      </div>
    </div>
  );
}
