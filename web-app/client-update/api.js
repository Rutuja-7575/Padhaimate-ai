import axios from 'axios';

// The React client now talks ONLY to the Node/Express server (the BFF).
// The Node server is the one that talks to the FastAPI RAG backend.
const NODE_BASE_URL = 'http://localhost:4000';

const api = axios.create({
  baseURL: `${NODE_BASE_URL}/api`,
});

export const checkHealth = () => axios.get(`${NODE_BASE_URL}/health`);

export const uploadDocument = (file, onProgress) => {
  const formData = new FormData();
  formData.append('file', file);
  return api.post('/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (e) => {
      if (onProgress && e.total) {
        onProgress(Math.round((e.loaded * 100) / e.total));
      }
    },
  });
};

export const queryDocuments = (question) => api.post('/query', { question });
export const getDocuments = () => api.get('/documents');
export const deleteDocument = (filename) => api.delete(`/documents/${filename}`);

// New: chat history, backed by the Node server (not FastAPI)
export const getHistory = () => api.get('/history');
export const clearHistory = () => api.delete('/history');

export default api;
