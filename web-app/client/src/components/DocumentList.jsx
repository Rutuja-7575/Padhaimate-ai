import { useState, useEffect } from 'react';
import { getDocuments, deleteDocument } from '../services/api';

const SPINE_COLORS = ['violet', 'lime'];
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
    if (!window.confirm(`Remove "${filename}" from your library?`)) return;
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
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div className="card-badge lime">🗂️</div>
        {docs.length > 0 && (
          <span className="doc-count-pill">{docs.length} {docs.length === 1 ? 'doc' : 'docs'}</span>
        )}
      </div>
      <h3>Your Library</h3>
      {loading ? (
        <p className="muted-text">Loading…</p>
      ) : docs.length === 0 ? (
        <div className="empty-state">Nothing here yet — upload a PDF to get started.</div>
      ) : (
        <ul className="doc-list">
          {docs.map((doc) => {
            const color = spineFor(doc.filename);
            return (
              <li key={doc.filename} className="doc-item">
                <div
                  className="doc-icon"
                  style={{
                    background: color === 'lime'
                      ? 'linear-gradient(135deg, #d6ff3f, #b8e82f)'
                      : 'linear-gradient(135deg, #9b8cff, #6e5fe0)',
                    color: color === 'lime' ? '#0b0d17' : '#fff',
                  }}
                >
                  📄
                </div>
                <div className="doc-info">
                  <span className="doc-name">{doc.filename}</span>
                  <span className="doc-chunks">{doc.chunks} chunks indexed</span>
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
            );
          })}
        </ul>
      )}
    </div>
  );
}

export default DocumentList;