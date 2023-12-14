import Link from "next/link";

export default function Button({
  children,
  onClick,
  href,
  className = "",
  ...props
}) {
  function onClickWrapper(e) {
    e.preventDefault();
    onClick(e);
  }
  if (href) {
    return (
      <Link href={href}>
        <a className={`button ${className}`} {...props}>
          {children}
        </a>
      </Link>
    );
  }
  return (
    <button
      className={`button ${className}`}
      onClick={onClickWrapper}
      {...props}
    >
      {children}
    </button>
  );
}
