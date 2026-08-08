import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import dotenv from "dotenv";
import axios from "axios";

import uploadRoutes from "./routes/upload.js";
import queryRoutes from "./routes/query.js";
import documentsRoutes from "./routes/documents.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;
const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || "http://localhost:8000";
const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || "http://localhost:5173";

app.use(helmet());
app.use(cors({ origin: CLIENT_ORIGIN }));
app.use(express.json());

// Applies to the LLM-backed /api/query and /api/upload routes so a single
// client can't hammer the Groq-backed endpoint or flood the vector store.
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20, // 20 requests per minute per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please slow down and try again shortly." },
});

app.use("/api/query", apiLimiter);
app.use("/api/upload", apiLimiter);

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