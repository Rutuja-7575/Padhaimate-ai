import os
from dotenv import load_dotenv

load_dotenv(override=True)

class Settings:
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    CHROMA_DB_PATH: str = os.getenv("CHROMA_DB_PATH", "./data/chroma_db")

    # Comma-separated list of allowed origins, e.g.
    # "http://localhost:4000,http://localhost:5173"
    ALLOWED_ORIGINS: list[str] = [
        origin.strip()
        for origin in os.getenv(
            "ALLOWED_ORIGINS", "http://localhost:4000,http://localhost:5173"
        ).split(",")
        if origin.strip()
    ]

settings = Settings()