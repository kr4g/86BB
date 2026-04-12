import express from "express";
import { config } from "./config.js";
import { initOsc } from "./services/oscClient.js";
import { GutDynamicsEngine } from "./services/gutDynamics.js";
import { createSelectionRouter } from "./routes/selection.js";
import { createGutStateRouter } from "./routes/gutState.js";

initOsc(config.oscPort);

const engine = new GutDynamicsEngine();

const app = express();
app.use(express.json());

app.use("/api/select", createSelectionRouter(engine));
app.use("/api/gut-state", createGutStateRouter(engine));

app.use((_req, res) => {
  res.status(404).end();
});

const snap = engine.getSnapshot();
console.log(
  `[86BB] ${snap.totalSelections} selections, created ${snap.createdAt}`,
);

app.listen(config.port, "0.0.0.0", () => {
  console.log(`[86BB] Server listening on 0.0.0.0:${config.port}`);
  console.log(
    `[86BB] alpha: ${config.alphaSlow}, sensitivity: ${config.sensitivity}, kick: ${config.kickScale}`,
  );
});
