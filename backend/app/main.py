from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import routes_upload, routes_query, routes_documents
from app.config import settings

app = FastAPI(title="StudyMate AI Backend")

# Only the Node/Express BFF and local dev clients are allowed to call this
# directly. The Flutter app also hits this backend directly (see README
# roadmap), so its origin isn't relevant here since mobile HTTP clients
# don't send a browser Origin header the same way.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Content-Type"],
)


@app.get("/health")
def health_check():
    return {"status": "ok", "message": "StudyMate AI backend is running"}


app.include_router(routes_upload.router)
app.include_router(routes_query.router)
app.include_router(routes_documents.router)