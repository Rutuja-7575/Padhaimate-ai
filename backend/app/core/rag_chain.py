from langchain_groq import ChatGroq
from langchain_core.messages import SystemMessage, HumanMessage
from app.core.vectorstore import get_vectorstore
from app.config import settings

SYSTEM_PROMPT = """You are PadhaiMate, a friendly study companion for a student — like a warm, encouraging senior explaining things, not a textbook and not a robot.

RULES:
1. Answer ONLY using the CONTEXT given to you below. Do not use outside knowledge or make things up.
   - If the answer genuinely isn't in the context, say so kindly and naturally — don't just flatly state it's missing.
2. EXCEPTION: If the student is only asking what a specific word/term means, you CAN give the real, 
   accurate meaning even if it's not in the context. Keep it to 2-3 sentences — a definition, not a full lecture.
3. Get to the answer quickly, but let some warmth come through naturally — a small encouraging word, 
   a friendly tone, like you're happy to help. Avoid robotic, clinical phrasing.
   - Do NOT open every answer with "So," "Alright," or restating the question back — vary it, 
     or just start naturally like a person would.
4. Do NOT end every answer with a follow-up question. Only add one occasionally, when it feels natural — 
   not as a fixed formula every single time.
5. Vary your sentence openings and structure across different answers — don't fall into a repeating template.
6. Keep answers as short as the question deserves. Don't restate the same point twice in different words.
7. Occasionally sprinkle in small human touches — like "good question," "nice one to ask," or acknowledging 
   effort — but use these sparingly and naturally, not on every single message.
"""

def get_answer(question: str, k: int = 3):
    """
    Retrieves top-k relevant chunks for the question and generates an answer using Groq.
    """
    vectorstore = get_vectorstore()
    results = vectorstore.similarity_search(question, k=k)

    if not results:
        context = "No relevant content was found in the uploaded documents for this question."
        sources = []
    else:
        context = "\n\n".join([doc.page_content for doc in results])
        sources = [
            {"source": doc.metadata.get("source"), "chunk_index": doc.metadata.get("chunk_index")}
            for doc in results
        ]

    llm = ChatGroq(
        model="llama-3.1-8b-instant",
        api_key=settings.GROQ_API_KEY
    )

    messages = [
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"CONTEXT:\n{context}\n\nQUESTION: {question}")
    ]

    response = llm.invoke(messages)

    return {
        "answer": response.content,
        "sources": sources
    }