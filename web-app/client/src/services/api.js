import axios from 'axios';

const NODE_BASE_URL = 'http://localhost:4000';

const api = axios.create({
  baseURL: `${NODE_BASE_URL}/api`,
});

// NOTE: /health is defined directly on the Node app (not under the /api
// router), so it must be called at the root, not through the `api`
// instance whose baseURL already includes /api — otherwise this resolves
// to /api/health, which doesn't exist and returns 404.
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

export default api;