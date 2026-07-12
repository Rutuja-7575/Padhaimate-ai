# PadhaiMate AI

PadhaiMate is a document Q&A assistant. Upload a PDF, ask questions about it in plain language, and get answers grounded in the actual content of the document — with the source chunks it used to answer, so you can verify it isn't making things up.

It's built as three connected pieces on top of one shared backend:

- A **RAG pipeline** (FastAPI + ChromaDB) that does the actual reading, chunking, embedding, and answering
- A **Flutter mobile app** for uploading and chatting with your documents on the go
- A **React web app**, fronted by a small **Node/Express layer**, for the same in the browser

## Why

Most study material — lecture PDFs, notes, textbooks — is long and hard to search. PadhaiMate lets you upload it once and just ask it questions, the way you'd ask a senior who already read it, instead of re-reading the whole thing yourself.

## Architecture

```
                        ┌─────────────────┐
                        │   ChromaDB       │
                        │  (vector store)  │
                        └────────▲─────────┘
                                 │
   ┌──────────────┐     ┌───────┴────────┐     ┌──────────────┐
   │ React Web App│────▶│  FastAPI Backend│◀────│ Flutter App  │
   │              │     │  (RAG pipeline) │     └──────────────┘
   └──────┬───────┘     └───────┬────────┘
          │                     │
          ▼                     ▼
   ┌──────────────┐     ┌───────────────┐
   │ Node/Express  │────▶│   Groq LLM    │
   │  (BFF layer)  │     │ (llama-3.1-8b)│
   └──────────────┘     └───────────────┘
```

The React client never talks to FastAPI directly — it goes through a small Node/Express layer first. That layer exists to do the things a raw frontend shouldn't be doing itself: rate limiting requests before they hit the LLM-backed endpoints, restricting CORS to just the actual client origin (FastAPI's CORS is wide open for local dev), and giving errors from the Python backend a consistent JSON shape before they reach the browser. The Flutter app currently talks to FastAPI directly (see [roadmap](#known-limitations--roadmap)).

**How a query actually works:**

1. PDF is uploaded → text extracted with `pypdf` → split into overlapping chunks (500 chars, 50 char overlap) with LangChain's `RecursiveCharacterTextSplitter`
2. Chunks are embedded locally with a free HuggingFace sentence-transformer (`all-MiniLM-L6-v2` — no API key needed for this part) and stored in ChromaDB
3. On a question, the top-k most similar chunks are retrieved from Chroma and passed as context to a Groq-hosted LLaMA 3.1 model
4. The model is instructed to answer **only from the retrieved context** (with one exception: it can define a term directly if asked), and the response includes which document/chunk it drew from

## Tech stack

| Layer | Tech |
|---|---|
| RAG backend | FastAPI, LangChain, ChromaDB, HuggingFace sentence-transformers, Groq (LLaMA 3.1 8B) |
| BFF layer | Node.js, Express, express-rate-limit, Helmet |
| Web frontend | React 19, Vite, Axios |
| Mobile app | Flutter, Dart |
| PDF parsing | pypdf |

## Project structure

```
Padhaimate-ai/
├── backend/            # FastAPI RAG service
│   └── app/
│       ├── api/        # upload / query / documents routes
│       ├── core/       # chunking, embeddings, vectorstore, rag_chain
│       ├── utils/       # pdf parsing
│       └── models/     # pydantic schemas
├── web-app/
│   ├── client/         # React + Vite frontend
│   └── server/         # Node/Express BFF layer
└── mobile-app/
    └── padhaimate_app/ # Flutter app
```

## Getting started

### 1. Backend (start this first — everything else depends on it)

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# then add your GROQ_API_KEY in .env — get one free at https://console.groq.com

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend now runs at `http://localhost:8000`. Check `http://localhost:8000/health` to confirm it's up.

Docker alternative:
```bash
cd backend
docker build -t padhaimate-backend .
docker run -p 8000:8000 --env-file .env padhaimate-backend
```

### 2. Node/Express server (the layer the React client talks to)

```bash
cd web-app/server
npm install
cp .env.example .env
npm run dev
```

Runs at `http://localhost:4000`. Check `http://localhost:4000/api/health` — it should report both itself and the FastAPI backend as reachable.

### 3. Web app

```bash
cd web-app/client
npm install
npm run dev
```

Runs at `http://localhost:5173` by default, and expects the Node server at `http://localhost:4000`.

### 4. Mobile app

```bash
cd mobile-app/padhaimate_app
flutter pub get
flutter run
```

The backend base URL is set in `lib/services/api_service.dart`. If you're running on:
- **Android emulator** → use `10.0.2.2` instead of `localhost`
- **iOS simulator** → `localhost` works as-is
- **physical device** → use your machine's LAN IP (e.g. `192.168.x.x`)

## API reference

**Node/Express layer** (`http://localhost:4000`) — what the React client calls:

| Method | Route | Description |
|---|---|---|
| GET | `/api/health` | Reports Node status + whether FastAPI is reachable |
| POST | `/api/upload` | Accepts a PDF, forwards it to FastAPI |
| POST | `/api/query` | Forwards a question to FastAPI, returns the answer |
| GET | `/api/documents` | Forwards to FastAPI, lists stored documents |
| DELETE | `/api/documents/:filename` | Forwards to FastAPI, deletes a document |

**FastAPI backend** (`http://localhost:8000`) — called directly by the Flutter app, and internally by the Node layer:

| Method | Route | Description |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/upload` | Upload a PDF, chunk + embed + store it |
| POST | `/query` | Ask a question, get an answer grounded in stored documents |
| GET | `/documents` | List uploaded documents and their chunk counts |
| DELETE | `/documents/{filename}` | Remove a document and its chunks from the store |

## Known limitations / roadmap

Being upfront about where this stands right now:

- No authentication — anyone with the Node/FastAPI URL can upload/query/delete. Fine for local/demo use, not production-ready as-is.
- FastAPI's own CORS is wide open (`allow_origins=["*"]`); the Node layer restricts *its* CORS to the client origin, but FastAPI is still reachable directly if someone finds the port.
- PDF-only input, and only text-based PDFs (no OCR yet, so scanned/image PDFs won't extract text).
- The Flutter app talks to FastAPI directly rather than going through the Node layer, so it doesn't get the rate limiting benefit yet.
- No automated CI pipeline yet.

Planned next: automated tests for both backend and Node layer, API key auth end-to-end, OCR fallback for scanned PDFs, and routing the Flutter app through the Node layer too.

## License

MIT