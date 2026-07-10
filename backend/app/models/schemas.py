from pydantic import BaseModel
from typing import Optional


class QueryRequest(BaseModel):
    question: str


class SourceChunk(BaseModel):
    source: Optional[str] = None
    chunk_index: Optional[int] = None


class QueryResponse(BaseModel):
    answer: str
    sources: list[SourceChunk] = []


class UploadResponse(BaseModel):
    filename: str
    chunks_stored: int
    message: str


class DocumentInfo(BaseModel):
    filename: str
    chunks: int