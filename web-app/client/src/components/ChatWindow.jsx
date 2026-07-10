import { useState, useRef, useEffect } from 'react';
import { queryDocuments } from '../services/api';

function ChatWindow() {
  const [question, setQuestion] = useState('');
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const logRef = useRef(null);

  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  }, [messages, loading]);

  const handleAsk = async () => {
    if (!question.trim()) return;
    const userMessage = { role: 'user', text: question };
    setMessages((prev) => [...prev, userMessage]);
    setQuestion('');
    setLoading(true);

    try {
      const res = await queryDocuments(userMessage.text);
      const answerText = res.data.answer || res.data.response || JSON.stringify(res.data);
      setMessages((prev) => [...prev, { role: 'ai', text: answerText }]);
    } catch (err) {
      const errorMsg = err.response?.data?.detail || 'Something went wrong answering that.';
      setMessages((prev) => [...prev, { role: 'ai', text: errorMsg, isError: true }]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleAsk();
    }
  };

  return (
    <>
      <div className="chat-log" ref={logRef}>
        {messages.length === 0 ? (
          <div className="chat-empty">
            <span className="big-mark">Ask anything about your documents.</span>
            <span className="muted-text">Upload a PDF on the left, then start the conversation here.</span>
          </div>
        ) : (
          messages.map((msg, i) => (
            <div key={i} className={`chat-bubble ${msg.role} ${msg.isError ? 'error' : ''}`}>
              {msg.text}
            </div>
          ))
        )}
        {loading && (
          <div className="chat-bubble ai typing">
            Thinking
            <span className="dots">
              <span style={{ '--i': 0 }}>.</span>
              <span style={{ '--i': 1 }}>.</span>
              <span style={{ '--i': 2 }}>.</span>
            </span>
          </div>
        )}
      </div>

      <div className="chat-input-row">
        <input
          type="text"
          className="chat-input"
          placeholder="e.g. Summarize chapter 2..."
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          onKeyDown={handleKeyDown}
        />
        <button className="upload-btn" onClick={handleAsk} disabled={loading}>
          Ask
        </button>
      </div>
    </>
  );
}

export default ChatWindow;