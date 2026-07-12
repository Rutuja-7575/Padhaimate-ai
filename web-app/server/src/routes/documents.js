import { Router } from "express";
import axios from "axios";

const router = Router();
const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || "http://localhost:8000";

/**
 * GET /api/documents
 * Returns the list of uploaded documents from FastAPI/Chroma.
 */
router.get("/documents", async (req, res) => {
  try {
    const response = await axios.get(`${FASTAPI_BASE_URL}/documents`);
    return res.json(response.data);
  } catch (err) {
    const status = err.response?.status || 502;
    const detail = err.response?.data?.detail || "Could not reach the RAG backend.";
    return res.status(status).json({ error: detail });
  }
});

/**
 * DELETE /api/documents/:filename
 * Deletes a document's chunks via FastAPI.
 */
router.delete("/documents/:filename", async (req, res) => {
  try {
    const response = await axios.delete(
      `${FASTAPI_BASE_URL}/documents/${encodeURIComponent(req.params.filename)}`
    );
    return res.json(response.data);
  } catch (err) {
    const status = err.response?.status || 502;
    const detail = err.response?.data?.detail || "Could not reach the RAG backend.";
    return res.status(status).json({ error: detail });
  }
});

export default router;
