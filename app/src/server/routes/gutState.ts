import { Router } from "express";
import { loadGutState, saveGutState, createBaselineGutState } from "../services/persistence.js";

const router = Router();

router.get("/", (_req, res) => {
  const snapshot = loadGutState();
  res.json(snapshot);
});

router.post("/reset", (req, res) => {
  if (req.query.confirm !== "true") {
    res.status(400).json({ error: "Must include ?confirm=true to reset" });
    return;
  }

  const baseline = createBaselineGutState();
  saveGutState(baseline);
  res.json({ message: "Gut state reset to baseline", gutState: baseline });
});

export default router;
