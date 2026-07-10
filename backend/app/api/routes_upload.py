from fastapi import APIRouter, UploadFile, File, HTTPException

from app.utils.pdf_parser import extract_text_from_pdf
from app.core.chunking import chunk_text
from app.core.vectorstore import add_chunks_to_store

router = APIRouter()


@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    contents = await file.read()

    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    try:
        text = extract_text_from_pdf(contents)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Could not read this PDF. It may be corrupted or encrypted.",
        )

    if not text:
        raise HTTPException(
            status_code=400,
            detail="No extractable text found in this PDF. It may be a scanned image without OCR.",
        )

    chunks = chunk_text(text)
    num_stored = add_chunks_to_store(chunks, file.filename)

    return {
        "filename": file.filename,
        "chunks_stored": num_stored,
        "message": "Document successfully embedded and stored",
    }