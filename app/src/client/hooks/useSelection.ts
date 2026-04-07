import { useState, useCallback } from "react";

export function useSelection() {
  const [count, setCount] = useState(0);

  const select = useCallback((foodId: string) => {
    setCount((c) => c + 1);
    fetch("/api/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ foodId }),
    }).catch(() => {});
  }, []);

  return { count, select };
}
