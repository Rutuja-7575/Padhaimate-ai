import { useState, useEffect } from 'react';
import { checkHealth } from './services/api';
import UploadBox from './components/UploadBox';
import DocumentList from './components/DocumentList';
import ChatWindow from './components/ChatWindow';
import './App.css';

function App() {
  const [status, setStatus] = useState('Checking...');
  const [statusType, setStatusType] = useState('checking');
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  useEffect(() => {
    checkHealth()
      .then((res) => {
        setStatus(res.data.message);
        setStatusType('ok');
      })
      .catch(() => {
        setStatus('Could not reach backend');
        setStatusType('error');
      });
  }, []);

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <h1>Padhai <span className="highlight-mark">Mate AI</span></h1>
          <span className="tagline">RAG-powered document Q&A</span>
        </div>
        <span className={`status-dot status-${statusType}`} title={status} />
      </header>

      <div className="main-grid">
        <aside className="sidebar">
          <div className="sidebar-section">
            <div className="section-label">Add a document</div>
            <UploadBox onUploadSuccess={() => setRefreshTrigger((n) => n + 1)} />
          </div>
          <div className="sidebar-section grow">
            <div className="section-label">Library</div>
            <DocumentList refreshTrigger={refreshTrigger} />
          </div>
        </aside>

        <main className="chat-panel">
          <ChatWindow />
        </main>
      </div>
    </div>
  );
}

export default App;