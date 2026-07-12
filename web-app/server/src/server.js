import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import axios from "axios";

import uploadRoutes from "./routes/upload.js";
import queryRoutes from "./routes/query.js";
import documentsRoutes from "./routes/documents.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;
const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || "http://localhost:8000";

app.use(cors());
app.use(express.json());

/**
 * GET /health
 * Basic liveness check for the Node server itself, plus a check on whether
 * it can reach the FastAPI backend it depends on.
 */
app.get("/health", async (req, res) => {
  let backendStatus = "unreachable";
  try {
    await axios.get(`${FASTAPI_BASE_URL}/health`, { timeout: 3000 });
    backendStatus = "ok";
  } catch {
    backendStatus = "unreachable";
  }

  res.json({
    status: "ok",
    message: "PadhaiMate Node server is running",
    fastapi_backend: backendStatus,
  });
});

app.use("/api", uploadRoutes);
app.use("/api", queryRoutes);
app.use("/api", documentsRoutes);

app.listen(PORT, () => {
  console.log(`PadhaiMate Node server listening on http://localhost:${PORT}`);
  console.log(`Forwarding RAG requests to FastAPI at ${FASTAPI_BASE_URL}`);
});
