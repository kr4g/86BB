import { Router } from "express";
import { processSelection } from "../services/microbiomeEngine.js";
import { CATALOG } from "../../shared/data/catalog.js";
import type { SelectionRequest } from "../../shared/types.js";

const router = Router();
const VALID_IDS = new Set(CATALOG.map((c) => c.id));

router.post("/", (req, res) => {
  const body = req.body as SelectionRequest;

  if (!body.foodId || typeof body.foodId !== "string") {
    res.status(400).json({ error: "Request must include a foodId string" });
    return;
  }

  if (!VALID_IDS.has(body.foodId)) {
    res.status(400).json({ error: `Unknown food id: ${body.foodId}` });
    return;
  }

  const result = processSelection(body.foodId);
  res.json(result);
});

export default router;
