import { Router } from "express";
import axios from "axios";
import { addHistoryEntry, getHistory, clearHistory } from "../historyStore.js";

const router = Router();
const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || "http://localhost:8000";

/**
 * POST /api/query
 * Forwards the question to the FastAPI RAG backend, then saves the
 * question/answer pair to local chat history before returning it to the client.
 */
router.post("/query", async (req, res) => {
  const { question } = req.body;

  if (!question || typeof question !== "string" || !question.trim()) {
    return res.status(400).json({ error: "A non-empty 'question' string is required." });
  }

  try {
    const response = await axios.post(`${FASTAPI_BASE_URL}/query`, { question });
    const { answer, sources } = response.data;

    await addHistoryEntry({ question, answer, sources });

    return res.json({ answer, sources });
  } catch (err) {
    const status = err.response?.status || 502;
    const detail = err.response?.data?.detail || "Could not reach the RAG backend.";
    return res.status(status).json({ error: detail });
  }
});

/**
 * GET /api/history
 * Returns saved chat history (most recent first) — this is Node-only,
 * FastAPI has no concept of history.
 */
router.get("/history", async (req, res) => {
  try {
    const history = await getHistory();
    return res.json({ history });
  } catch (err) {
    return res.status(500).json({ error: "Could not read chat history." });
  }
});

/**
 * DELETE /api/history
 * Clears saved chat history.
 */
router.delete("/history", async (req, res) => {
  try {
    await clearHistory();
    return res.json({ message: "Chat history cleared." });
  } catch (err) {
    return res.status(500).json({ error: "Could not clear chat history." });
  }
});

export default router;
