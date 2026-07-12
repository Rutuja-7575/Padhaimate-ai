# PadhaiMate — Node/Express Server

This is a small Express "backend-for-frontend" (BFF) that sits between the
React client and the FastAPI RAG backend.

```
React (client, :5173)  →  Node/Express (server, :4000)  →  FastAPI (backend, :8000)
                                     ↓
                          data/history.json (chat history)
```

It does two things:

1. **Proxies** `/upload`, `/query`, and `/documents` through to the FastAPI
   backend, so the React client only ever talks to one server.
2. **Adds chat history** — every question/answer pair sent through `/api/query`
   gets saved to `data/history.json`, and can be listed or cleared via
   `/api/history`. FastAPI has no concept of this; it's purely a Node feature.

## Setup

```bash
cd web-app/server
npm install
cp .env.example .env
npm run dev
```

The server starts on **http://localhost:4000** by default. Make sure the
FastAPI backend is already running on **http://localhost:8000** (`uvicorn app.main:app --reload`).

## Endpoints

| Method | Path                    | Description                                  |
|--------|-------------------------|-----------------------------------------------|
| GET    | `/health`               | Node server health + FastAPI reachability     |
| POST   | `/api/upload`           | Upload a PDF (proxies to FastAPI `/upload`)   |
| POST   | `/api/query`            | Ask a question (proxies to FastAPI `/query`, saves to history) |
| GET    | `/api/documents`        | List uploaded documents (proxies to FastAPI)  |
| DELETE | `/api/documents/:name`  | Delete a document (proxies to FastAPI)        |
| GET    | `/api/history`          | List saved chat history (Node-only feature)   |
| DELETE | `/api/history`          | Clear saved chat history                      |

## Wiring up the React client

In `web-app/client/src/services/api.js`, change the `baseURL` from
`http://localhost:8000` to `http://localhost:4000/api`, and point
`checkHealth` at `http://localhost:4000/health` (outside the `/api` prefix).
See the updated file provided alongside this server.
