"""
Tests for the /query endpoint.

We mock `get_answer` (which internally calls Chroma + Groq) so these tests
run fast, free, and without needing a live GROQ_API_KEY or a populated
vector store. This checks the HTTP layer: request validation, response
shape, and error handling -- not the quality of the LLM's answers.
"""
from unittest.mock import patch

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"


@patch("app.api.routes_query.get_answer")
def test_query_returns_answer_and_sources(mock_get_answer):
    mock_get_answer.return_value = {
        "answer": "The mitochondria is the powerhouse of the cell.",
        "sources": [{"source": "biology_notes.pdf", "chunk_index": 2}],
    }

    response = client.post("/query", json={"question": "What is the mitochondria?"})

    assert response.status_code == 200
    body = response.json()
    assert body["answer"] == "The mitochondria is the powerhouse of the cell."
    assert body["sources"][0]["source"] == "biology_notes.pdf"
    mock_get_answer.assert_called_once_with("What is the mitochondria?")


@patch("app.api.routes_query.get_answer")
def test_query_with_no_matching_context_returns_empty_sources(mock_get_answer):
    mock_get_answer.return_value = {
        "answer": "I couldn't find anything about that in your documents.",
        "sources": [],
    }

    response = client.post("/query", json={"question": "Unrelated question"})

    assert response.status_code == 200
    assert response.json()["sources"] == []


def test_query_rejects_missing_question_field():
    response = client.post("/query", json={})
    assert response.status_code == 422


def test_query_rejects_non_string_question():
    response = client.post("/query", json={"question": 12345})
    assert response.status_code == 422


@patch("app.api.routes_documents.list_documents")
def test_list_documents_returns_stored_files(mock_list_documents):
    mock_list_documents.return_value = [
        {"filename": "notes.pdf", "chunks": 14},
    ]

    response = client.get("/documents")

    assert response.status_code == 200
    assert response.json() == {"documents": [{"filename": "notes.pdf", "chunks": 14}]}


@patch("app.api.routes_documents.delete_document")
def test_delete_document_reports_when_nothing_found(mock_delete_document):
    mock_delete_document.return_value = 0

    response = client.delete("/documents/nonexistent.pdf")

    assert response.status_code == 200
    assert "No chunks found" in response.json()["message"]


@patch("app.api.routes_documents.delete_document")
def test_delete_document_reports_chunk_count(mock_delete_document):
    mock_delete_document.return_value = 5

    response = client.delete("/documents/notes.pdf")

    assert response.status_code == 200
    assert "Deleted 5 chunks" in response.json()["message"]