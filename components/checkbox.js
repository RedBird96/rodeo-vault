export default function CheckBox({
  children,
  onClick,
  href,
  checked,
  className = "",
  ...props
}) {
  function onClickWrapper(e) {
    e.preventDefault();
    onClick(e);
  }
  return (
    <span
      className={`checkbox ${className}`}
      onClick={onClickWrapper}
      {...props}
    >
      <input type="checkbox" checked={checked} readOnly />
      <span></span>
    </span>
  );
}
