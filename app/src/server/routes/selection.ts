import { Router } from "express";
import type { GutDynamicsEngine } from "../services/gutDynamics.js";
import type { SelectionRequest } from "../../shared/types.js";

export function createSelectionRouter(engine: GutDynamicsEngine): Router {
  const router = Router();

  router.post("/", (req, res) => {
    const body = req.body as SelectionRequest;

    if (!body.foodId || typeof body.foodId !== "string") {
      res.status(400).json({ error: "Request must include a foodId string" });
      return;
    }

    if (!engine.validFoodIds.has(body.foodId)) {
      res.status(400).json({ error: `Unknown food id: ${body.foodId}` });
      return;
    }

    const result = engine.addSelection(body.foodId);

    res.json({
      foodId: body.foodId,
      ...result,
    });
  });

  return router;
}
