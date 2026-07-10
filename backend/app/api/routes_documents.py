from fastapi import APIRouter

from app.core.vectorstore import list_documents, delete_document

router = APIRouter()


@router.get("/documents")
async def get_documents():
    docs = list_documents()
    return {"documents": docs}


@router.delete("/documents/{filename}")
async def remove_document(filename: str):
    deleted_count = delete_document(filename)
    if deleted_count == 0:
        return {"message": f"No chunks found for '{filename}'"}
    return {"message": f"Deleted {deleted_count} chunks for '{filename}'"}