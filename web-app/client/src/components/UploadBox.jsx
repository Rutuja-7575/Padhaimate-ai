import { useState, useRef } from 'react';
import { uploadDocument } from '../services/api';

function UploadBox({ onUploadSuccess }) {
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState('');
  const [statusType, setStatusType] = useState('neutral');
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef(null);

  const pickFile = (f) => {
    if (!f) return;
    setFile(f);
    setStatus('');
  };

  const handleUpload = async () => {
    if (!file) {
      setStatus('Please select a PDF file first.');
      setStatusType('fail');
      return;
    }

    setLoading(true);
    setProgress(0);
    setStatus('');

    try {
      const res = await uploadDocument(file, setProgress);
      setStatus(`${res.data.message} — ${res.data.chunks_stored} chunks stored`);
      setStatusType('success');
      setFile(null);
      if (onUploadSuccess) onUploadSuccess();
    } catch (err) {
      const errorMsg = err.response?.data?.detail || 'Upload failed. Check backend logs.';
      setStatus(errorMsg);
      setStatusType('fail');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <div className="card-badge violet">📚</div>
      <h3>Upload a PDF</h3>

      <div
        className={`dropzone ${dragging ? 'dragging' : ''} ${file ? 'has-file' : ''}`}
        onClick={() => inputRef.current.click()}
        onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          pickFile(e.dataTransfer.files[0]);
        }}
      >
        <div className="dropzone-icon-circle">{file ? '📄' : '⬆'}</div>
        <div className="dropzone-text">
          {file ? file.name : 'Drag a PDF here, or click to browse'}
        </div>
        <div className="dropzone-sub">
          {file ? `${(file.size / 1024).toFixed(0)} KB • ready to upload` : 'Only .pdf files are supported'}
        </div>
        <input
          ref={inputRef}
          type="file"
          accept=".pdf"
          onChange={(e) => pickFile(e.target.files[0])}
        />
      </div>

      <button className="upload-btn" onClick={handleUpload} disabled={loading || !file}>
        {loading ? `Uploading… ${progress}%` : '⚡ Upload & analyze'}
      </button>

      {loading && (
        <div className="progress-track">
          <div className="progress-fill" style={{ width: `${progress}%` }} />
        </div>
      )}

      {status && (
        <p className={`status-message status-${statusType}`}>{status}</p>
      )}
    </div>
  );
}

export default UploadBox;