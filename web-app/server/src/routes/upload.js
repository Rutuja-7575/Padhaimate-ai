import { Router } from "express";
import multer from "multer";
import axios from "axios";
import FormData from "form-data";

const router = Router();
const FASTAPI_BASE_URL = process.env.FASTAPI_BASE_URL || "http://localhost:8000";

// Keep the uploaded file in memory just long enough to forward it — we don't
// need to persist it on the Node side, FastAPI/Chroma is the source of truth.
const upload = multer({ storage: multer.memoryStorage() });

/**
 * POST /api/upload
 * Accepts a PDF from the client (multipart/form-data, field name "file")
 * and forwards it to the FastAPI /upload endpoint.
 */
router.post("/upload", upload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file was uploaded (expected field 'file')." });
  }

  try {
    const formData = new FormData();
    formData.append("file", req.file.buffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype,
    });

    const response = await axios.post(`${FASTAPI_BASE_URL}/upload`, formData, {
      headers: formData.getHeaders(),
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
    });

    return res.json(response.data);
  } catch (err) {
    const status = err.response?.status || 502;
    const detail = err.response?.data?.detail || "Could not reach the RAG backend.";
    return res.status(status).json({ error: detail });
  }
});

export default router;
