import { useState, useEffect } from 'react';
import { getDocuments, deleteDocument } from '../services/api';

const SPINE_COLORS = ['#9b8cff', '#d6ff3f', '#ff6f91', '#4ecdc4'];
const spineFor = (name) => {
  const sum = [...name].reduce((a, c) => a + c.charCodeAt(0), 0);
  return SPINE_COLORS[sum % SPINE_COLORS.length];
};

function DocumentList({ refreshTrigger }) {
  const [docs, setDocs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [deletingFile, setDeletingFile] = useState(null);

  const fetchDocs = async () => {
    setLoading(true);
    try {
      const res = await getDocuments();
      setDocs(res.data.documents);
    } catch (err) {
      console.error('Failed to fetch documents', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDocs(); }, [refreshTrigger]);

  const handleDelete = async (filename) => {
    setDeletingFile(filename);
    try {
      await deleteDocument(filename);
      await fetchDocs();
    } catch (err) {
      console.error('Delete failed', err);
    } finally {
      setDeletingFile(null);
    }
  };

  return (
    <div className="card">
      <span className="card-label">Step 02</span>
      <h3>Your Library</h3>
      {loading ? (
        <p className="muted-text">Loading…</p>
      ) : docs.length === 0 ? (
        <div className="empty-state">Nothing here yet — upload a PDF to get started.</div>
      ) : (
        <ul className="doc-list">
          {docs.map((doc) => (
            <li key={doc.filename} className="doc-item" style={{ '--spine': spineFor(doc.filename) }}>
              <div className="doc-info">
                <span className="doc-name">{doc.filename}</span>
                <span className="doc-chunks">{doc.chunks} chunks</span>
              </div>
              <button
                className="delete-btn"
                onClick={() => handleDelete(doc.filename)}
                disabled={deletingFile === doc.filename}
                title="Delete document"
              >
                {deletingFile === doc.filename ? '…' : '✕'}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default DocumentList;