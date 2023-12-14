import { useRef } from "react";

export default function PositionTrack({
  min = 1,
  max = 2,
  step = 0.1,
  value,
  className,
}) {
  const trackRef = useRef();
  let clamped = Math.min(max * 0.95, Math.max(min * 1.05, value));
  clamped = Math.log(clamped);
  min = Math.log(min);
  max = Math.log(max);

  if (value === "1.00") {
    clamped = max * 0.95;
    value = "∞";
  }

  const p = trackRef.current
    ? (trackRef.current.offsetWidth * (clamped - min)) / (max - min)
    : 0;
  return (
    <div
      ref={trackRef}
      className={`position-track flex flex-column ${className}`}
    >
      {value !== "0.00" ? (
        <div className="position-track__tooltip" style={{ left: `${p}px` }}>
          {value}
        </div>
      ) : null}
      <div className="position-track__slider"></div>
    </div>
  );
}
