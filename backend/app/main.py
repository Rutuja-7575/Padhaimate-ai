from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import routes_upload, routes_query, routes_documents

app = FastAPI(title="StudyMate AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {"status": "ok", "message": "StudyMate AI backend is running"}


app.include_router(routes_upload.router)
app.include_router(routes_query.router)
app.include_router(routes_documents.router)