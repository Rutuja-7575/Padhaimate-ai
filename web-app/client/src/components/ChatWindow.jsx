import { useState, useRef, useEffect } from 'react';
import { queryDocuments } from '../services/api';

const SUGGESTIONS = ['Summarize this document', 'List key points', 'Explain chapter 1', 'Give me 5 quiz questions'];

const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

function ChatWindow() {
  const [question, setQuestion] = useState('');
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [listening, setListening] = useState(false);
  const [speakEnabled, setSpeakEnabled] = useState(true);
  const [speakingId, setSpeakingId] = useState(null);
  const logRef = useRef(null);
  const recognitionRef = useRef(null);

  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  }, [messages, loading]);

  useEffect(() => {
    if (!SpeechRecognition) return;
    const recognition = new SpeechRecognition();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = 'en-US';

    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      setQuestion(transcript);
      ask(transcript);
    };
    recognition.onend = () => setListening(false);
    recognition.onerror = () => setListening(false);

    recognitionRef.current = recognition;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toggleListening = () => {
    if (!recognitionRef.current) {
      alert('Voice input is not supported in this browser. Try Chrome or Edge.');
      return;
    }
    if (listening) {
      recognitionRef.current.stop();
      setListening(false);
    } else {
      setListening(true);
      recognitionRef.current.start();
    }
  };

  const speak = (text, id) => {
    if (!window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 1;
    utterance.pitch = 1;
    utterance.onstart = () => setSpeakingId(id);
    utterance.onend = () => setSpeakingId(null);
    utterance.onerror = () => setSpeakingId(null);
    window.speechSynthesis.speak(utterance);
  };

  const stopSpeaking = () => {
    window.speechSynthesis?.cancel();
    setSpeakingId(null);
  };

  const ask = async (text) => {
    const q = (text ?? question).trim();
    if (!q) return;
    const userMsgId = Date.now();
    setMessages((prev) => [...prev, { id: userMsgId, role: 'user', text: q }]);
    setQuestion('');
    setLoading(true);

    try {
      const res = await queryDocuments(q);
      const answerText = res.data.answer || res.data.response || JSON.stringify(res.data);
      const aiId = Date.now() + 1;
      setMessages((prev) => [...prev, { id: aiId, role: 'ai', text: answerText }]);
      if (speakEnabled) speak(answerText, aiId);
    } catch (err) {
      const errorMsg = err.response?.data?.detail || 'Something went wrong answering that.';
      setMessages((prev) => [...prev, { id: Date.now() + 1, role: 'ai', text: errorMsg, isError: true }]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      ask();
    }
  };

  return (
    <>
      <div className="chat-toolbar">
        <button
          className={`speak-toggle ${speakEnabled ? 'on' : 'off'}`}
          onClick={() => {
            if (speakEnabled) stopSpeaking();
            setSpeakEnabled((v) => !v);
          }}
          title={speakEnabled ? 'Mute AI voice replies' : 'Enable AI voice replies'}
        >
          <span className="material-symbols-rounded">{speakEnabled ? 'volume_up' : 'volume_off'}</span>
        </button>
      </div>

      <div className="chat-log" ref={logRef}>
        {messages.length === 0 ? (
          <div className="chat-empty">
            <div className="empty-icon">✨</div>
            <span className="big-mark">Ask me anything</span>
            <span className="muted-text">Type, or tap the mic to speak your question.</span>
            <div className="suggestion-chips">
              {SUGGESTIONS.map((s) => (
                <button key={s} className="suggestion-chip" onClick={() => ask(s)}>{s}</button>
              ))}
            </div>
          </div>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`chat-row ${msg.role} ${msg.isError ? 'error' : ''}`}>
              {msg.role === 'ai' && <div className="chat-avatar">{msg.isError ? '⚠️' : '✨'}</div>}
              <div className={`chat-bubble ${msg.role} ${msg.isError ? 'error' : ''}`}>
                {msg.text}
                {msg.role === 'ai' && !msg.isError && (
                  <button
                    className="replay-btn"
                    onClick={() => (speakingId === msg.id ? stopSpeaking() : speak(msg.text, msg.id))}
                    title={speakingId === msg.id ? 'Stop reading' : 'Read aloud'}
                  >
                    <span className="material-symbols-rounded">
                      {speakingId === msg.id ? 'stop_circle' : 'volume_up'}
                    </span>
                  </button>
                )}
              </div>
            </div>
          ))
        )}
        {loading && (
          <div className="chat-row ai">
            <div className="chat-avatar">✨</div>
            <div className="chat-bubble ai typing">
              Thinking
              <span className="dots">
                <span style={{ '--i': 0 }}>.</span>
                <span style={{ '--i': 1 }}>.</span>
                <span style={{ '--i': 2 }}>.</span>
              </span>
            </div>
          </div>
        )}
      </div>

      <div className="chat-input-row">
        <button
          className={`mic-btn ${listening ? 'listening' : ''}`}
          onClick={toggleListening}
          title={listening ? 'Stop listening' : 'Speak your question'}
        >
          <span className="material-symbols-rounded">{listening ? 'mic' : 'mic_none'}</span>
        </button>
        <input
          type="text"
          className="chat-input"
          placeholder={listening ? 'Listening…' : 'Ask about your notes…'}
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          onKeyDown={handleKeyDown}
        />
        <button className="upload-btn" onClick={() => ask()} disabled={loading}>
          Ask
        </button>
      </div>
    </>
  );
}

export default ChatWindow;