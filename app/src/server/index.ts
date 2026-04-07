import express from "express";
import { config } from "./config.js";
import { loadGutState } from "./services/persistence.js";
import selectionRouter from "./routes/selection.js";
import gutStateRouter from "./routes/gutState.js";

const app = express();

app.use(express.json());

app.use("/api/select", selectionRouter);
app.use("/api/gut-state", gutStateRouter);
app.use("/api/reset", gutStateRouter);

app.use((_req, res) => {
  res.status(404).end();
});

const snapshot = loadGutState();
console.log(
  `Loaded gut state: ${snapshot.totalOrders} orders, created ${snapshot.createdAt}`,
);

app.listen(config.port, () => {
  console.log(`86BB server listening on http://localhost:${config.port}`);
});
