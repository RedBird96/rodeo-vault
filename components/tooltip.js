export default function Tooltip({ tip }) {
  return (
    <span className="tooltip icon-info">
      <span className="tooltip-box">{tip}</span>
    </span>
  );
}
