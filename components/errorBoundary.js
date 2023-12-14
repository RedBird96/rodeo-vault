import { Component } from "react";
import { formatError } from "../utils";

export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  render() {
    if (this.state.error) {
      return (
        <div
          className="card text-primary text-center mt-6 container"
          style={{ padding: "15vh 16px" }}
        >
          <h1 className="m-0">Error!</h1>
          <div>{formatError(this.state.error)}</div>
        </div>
      );
    }

    return this.props.children;
  }
}
