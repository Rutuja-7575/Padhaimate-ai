from fastapi import APIRouter
from pydantic import BaseModel

from app.core.rag_chain import get_answer

router = APIRouter()


class QueryRequest(BaseModel):
    question: str


@router.post("/query")
async def query_documents(request: QueryRequest):
    result = get_answer(request.question)
    return result