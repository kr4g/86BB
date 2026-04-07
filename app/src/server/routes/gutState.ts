import { Router } from "express";
import type { GutDynamicsEngine } from "../services/gutDynamics.js";

export function createGutStateRouter(engine: GutDynamicsEngine): Router {
  const router = Router();

  router.get("/", (_req, res) => {
    res.json(engine.getSnapshot());
  });

  router.post("/reset", (req, res) => {
    if (req.query.confirm !== "true") {
      res.status(400).json({ error: "Must include ?confirm=true to reset" });
      return;
    }

    engine.reset();
    res.json({ message: "Gut state reset to baseline", state: engine.getSnapshot() });
  });

  return router;
}
