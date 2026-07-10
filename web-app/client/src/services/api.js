import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8000',
});

export const checkHealth = () => api.get('/health');

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