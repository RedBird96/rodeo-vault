import { useState, forwardRef, useRef, useEffect } from "react";
import Image from "next/image";
import Checkbox from "./checkbox";

export default function Dropdown({
  tokenList,
  selected,
  setSelected,
  header,
  multiSelect,
}) {
  const [search, setSearch] = useState("");
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

  tokenList = Object.keys(tokenList)
    .filter((key) =>
      tokenList[key].toUpperCase().includes(search.toUpperCase())
    )
    .reduce((res, key) => ((res[key] = tokenList[key]), res), {});

  return (
    <div className={`dropdown ${open ? "dropdown-open" : ""}`} ref={ref}>
      <div className="dropdown-select" onClick={() => setOpen(!open)}>
        {header}
      </div>

      <div className="dropdown-items">
        <input
          className="dropdown-search input"
          placeholder="Search ..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        {multiSelect && (
          <div className="flex justify-between mb-2">
            <a onClick={() => setSelected([])}>Clear</a>
            <a onClick={() => setSelected(Object.keys(tokenList))}>
              Select All
            </a>
          </div>
        )}
        {Object.keys(tokenList).map((key, index) => (
          <div
            className="dropdown-item"
            key={index}
            onClick={() => {
              if (multiSelect) {
                if (selected.indexOf(key) > -1) {
                  const updatedState = selected.filter((item) => item !== key);
                  setSelected(updatedState);
                } else {
                  const updatedState = [...selected, key];
                  setSelected(updatedState);
                }
              } else {
                if (key === selected[0]) setSelected([]);
                else setSelected([key]);
              }
            }}
          >
            <span>{tokenList[key]}</span>
            <Checkbox
              onClick={() => {}}
              checked={selected.length > 0 && selected.includes(key)}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
