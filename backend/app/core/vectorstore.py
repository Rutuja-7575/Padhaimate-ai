from langchain_chroma import Chroma
from app.core.embeddings import get_embedding_model
from app.config import settings

def get_vectorstore():
    embedding_model = get_embedding_model()
    vectorstore = Chroma(
        collection_name="studymate_docs",
        embedding_function=embedding_model,
        persist_directory=settings.CHROMA_DB_PATH
    )
    return vectorstore

def add_chunks_to_store(chunks: list[str], filename: str):
    vectorstore = get_vectorstore()
    metadatas = [{"source": filename, "chunk_index": i} for i in range(len(chunks))]
    vectorstore.add_texts(texts=chunks, metadatas=metadatas)
    return len(chunks)

def list_documents():
    """
    Returns a list of unique filenames currently stored, with their chunk counts.
    """
    vectorstore = get_vectorstore()
    data = vectorstore.get()  # returns all stored items
    
    doc_counts = {}
    for metadata in data["metadatas"]:
        source = metadata.get("source", "unknown")
        doc_counts[source] = doc_counts.get(source, 0) + 1
    
    return [{"filename": name, "chunks": count} for name, count in doc_counts.items()]

def delete_document(filename: str):
    """
    Deletes all chunks belonging to a given filename.
    """
    vectorstore = get_vectorstore()
    data = vectorstore.get()
    
    ids_to_delete = [
        data["ids"][i] for i, metadata in enumerate(data["metadatas"])
        if metadata.get("source") == filename
    ]
    
    if not ids_to_delete:
        return 0
    
    vectorstore.delete(ids=ids_to_delete)
    return len(ids_to_delete)