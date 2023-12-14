/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  async redirects() {
    return [
      {
        source: "/lend",
        destination: "/earn",
        permanent: true,
      },
      {
        source: "/private-sale",
        destination: "/private",
        permanent: true,
      },
    ];
  },
};

module.exports = nextConfig;
