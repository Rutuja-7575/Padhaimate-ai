import { useState, useEffect } from 'react';
import { checkHealth } from './services/api';
import UploadBox from './components/UploadBox';
import DocumentList from './components/DocumentList';
import ChatWindow from './components/ChatWindow';
import './App.css';

const TABS = [
  { id: 'upload', label: 'Upload', icon: '📤' },
  { id: 'chat', label: 'Chat', icon: '💬' },
  { id: 'library', label: 'Library', icon: '🗂️' },
];

function App() {
  const [status, setStatus] = useState('Checking...');
  const [statusType, setStatusType] = useState('checking');
  const [refreshTrigger, setRefreshTrigger] = useState(0);
  const [activeTab, setActiveTab] = useState('chat');

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
          <div className="brand-icon">
            <span className="material-symbols-rounded">auto_stories</span>
          </div>
          <h1>PadhaiMate</h1>
        </div>
        <span className={`status-dot status-${statusType}`} title={status} />
      </header>

      <div className="main-grid">
        <aside className="sidebar">
          <div className={`sidebar-section tab-section ${activeTab === 'upload' ? 'active' : ''}`}>
            <UploadBox
              onUploadSuccess={() => {
                setRefreshTrigger((n) => n + 1);
                setActiveTab('library');
              }}
            />
          </div>
          <div className={`sidebar-section grow tab-section ${activeTab === 'library' ? 'active' : ''}`}>
            <DocumentList refreshTrigger={refreshTrigger} />
          </div>
        </aside>

        <main className={`chat-panel tab-section ${activeTab === 'chat' ? 'active' : ''}`}>
          <ChatWindow />
        </main>
      </div>

      <nav className="mobile-tabbar">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            className={`mobile-tab ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            <span className="mobile-tab-icon">{tab.icon}</span>
            <span className="mobile-tab-label">{tab.label}</span>
          </button>
        ))}
      </nav>
    </div>
  );
}

export default App;