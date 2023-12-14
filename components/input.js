import Image from "next/image";
import DropdownTokens from "./dropdownTokens";
import { useState } from "react";

const tokenList = {
  usdc: "/assets/usdc.svg",
};

export default function Input({
  value,
  placeholder = "0.00",
  position = "left",
  icon = null,
  onMax = null,
  className = "",
  maxButtonStyle = {},
  tokenSelectable,
  ...rest
}) {
  const [selected, setSelected] = useState("usdc");
  return (
    <div
      className={
        "input__container flex " +
        (!tokenSelectable && icon ? "input__with-icon" : "")
      }
    >
      {tokenSelectable && (
        <DropdownTokens
          tokenList={tokenList}
          selected={selected}
          setSelected={setSelected}
        />
      )}
      {!tokenSelectable && icon ? (
        <div className="input__img flex">
          <Image src={icon} width={20} height={20} alt={"Asset icon"} />
        </div>
      ) : null}
      <input
        className={`input ${className}`}
        style={{
          textAlign: position,
          paddingLeft: tokenSelectable ? null : icon ? "42px" : null,
          paddingRight: null,
          marginLeft: tokenSelectable ? "86px" : null,
          borderRadius: tokenSelectable ? "0px 12px 12px 0px" : null,
          borderLeft: tokenSelectable ? 0 : "1px solid rgba(0, 0, 0, 0.15)",
        }}
        value={value}
        placeholder={placeholder}
        {...rest}
      />
      {onMax ? (
        <button
          onClick={onMax}
          className="button button-link ml-2"
          style={maxButtonStyle}
        >
          Max
        </button>
      ) : null}
    </div>
  );
}
