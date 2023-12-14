import { useState } from "react";
import {
  parseUnits,
  formatUnits,
  runTransaction,
  formatNumber,
  formatError,
} from "../utils";

export default function ActionModal({
  title,
  description,
  action,
  hasAmount,
  decimals = 18,
  balance,
  onSubmit,
  onReload,
  onError,
  onHide,
  labelSymbol = "",
  labelRunning = "Confirming transaction...",
  labelComplete = "Transaction confirmed",
  amount,
  setAmount,
  extraFields,
}) {
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [thisAmount, thisSetAmount] = useState("");
  if (!setAmount) {
    amount = thisAmount;
    setAmount = thisSetAmount;
  }

  async function onFormSubmit(e) {
    e.preventDefault();
    setError("");
    let parsedAmount;
    try {
      parsedAmount = parseUnits(amount || "0", decimals);
    } catch (e) {
      console.log(e);
      setError("Invalid amount");
      return;
    }
    try {
      setLoading(true);
      const call = onSubmit(parsedAmount);
      if (call) {
        await runTransaction(
          call,
          labelRunning,
          labelComplete,
          true,
          "arbitrum"
        );
      }
      setError("");
      if (onReload) onReload();
    } catch (e) {
      console.error(e);
      setError(formatError(e));
      if (onError) onError(e);
    } finally {
      setLoading(false);
    }
  }

  function onMax() {
    setAmount(formatUnits(balance, decimals).replaceAll(",", ""));
  }

  return (
    <div className="modal" onClick={onHide}>
      <form
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        onSubmit={onFormSubmit}
      >
        <h2 className="title mt-0">{title}</h2>
        {description ? <p className="mb-4">{description}</p> : null}
        {error ? <div className="error mb-4">{error}</div> : null}
        {hasAmount ? (
          <>
            <label className="label flex">
              <div className="flex-1">Amount</div>
              {balance ? (
                <div>
                  {formatNumber(balance, decimals)} {labelSymbol}{" "}
                  <a onClick={onMax}>Max</a>
                </div>
              ) : null}
            </label>
            <input
              className="input mb-4"
              placeholder="0.0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          </>
        ) : null}
        {extraFields || null}
        <button className="button w-full" type="submit">
          {loading ? "Loading..." : action}
        </button>
      </form>
    </div>
  );
}
