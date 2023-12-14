import { useState, forwardRef, useRef, useEffect } from "react";
import Image from "next/image";
import Checkbox from "./checkbox";

export default function TokenDropdown({ tokenList, selected, setSelected }) {
  const [open, setOpen] = useState(false);
  const ref = useRef();

  useEffect(() => {
    function handleClickOutside(e) {
      if (ref.current && !ref.current.contains(e.target)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [ref]);

  return (
    <div className={`dropdown ${open ? "dropdown-open" : ""}`} ref={ref}>
      <div className="dropdown-select" onClick={() => setOpen(!open)}>
        <Image src={tokenList[selected]} alt="token" width={24} height={24} />
      </div>
      {open && (
        <div className="dropdown-items">
          {Object.keys(tokenList).map((key, index) => (
            <div
              className="dropdown-item"
              key={index}
              onClick={() => setSelected(key)}
            >
              <Image src={tokenList[key]} alt="token" width={24} height={24} />
              <span>{key.toUpperCase()}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
