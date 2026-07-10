from pypdf import PdfReader
import io

def extract_text_from_pdf(file_bytes: bytes) -> str:
    """
    Takes raw PDF bytes and returns extracted text as a single string.
    """
    reader = PdfReader(io.BytesIO(file_bytes))
    text = ""
    for page in reader.pages:
        page_text = page.extract_text()
        if page_text:
            text += page_text + "\n"
    return text.strip()