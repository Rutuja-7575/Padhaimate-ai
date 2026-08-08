"""
Stubs out the heavy embedding/vector-DB/LLM libraries before the app is
imported, so the test suite can run in CI (or on a laptop) without
downloading a sentence-transformer model, running Chroma, or needing a
real GROQ_API_KEY. The actual retrieval/generation logic in
app.core.rag_chain and app.core.vectorstore is exercised indirectly via
mocks in the individual test files -- these stubs only need to exist so
`import` succeeds.
"""
import sys
import types


def _stub_module(name: str, **attrs):
    module = types.ModuleType(name)
    for attr_name, attr_value in attrs.items():
        setattr(module, attr_name, attr_value)
    sys.modules[name] = module
    return module


class _DummyEmbeddings:
    def __init__(self, *args, **kwargs):
        pass


class _DummyChroma:
    def __init__(self, *args, **kwargs):
        pass


class _DummyChatGroq:
    def __init__(self, *args, **kwargs):
        pass

    def invoke(self, *args, **kwargs):
        raise NotImplementedError("ChatGroq is stubbed in tests; mock get_answer instead.")


if "langchain_huggingface" not in sys.modules:
    _stub_module("langchain_huggingface", HuggingFaceEmbeddings=_DummyEmbeddings)

if "langchain_chroma" not in sys.modules:
    _stub_module("langchain_chroma", Chroma=_DummyChroma)

if "langchain_groq" not in sys.modules:
    _stub_module("langchain_groq", ChatGroq=_DummyChatGroq)

if "langchain_text_splitters" not in sys.modules:
    class _DummySplitter:
        def __init__(self, *args, **kwargs):
            pass

        def split_text(self, text):
            return [text]

    _stub_module("langchain_text_splitters", RecursiveCharacterTextSplitter=_DummySplitter)

if "langchain_core" not in sys.modules:
    core_module = _stub_module("langchain_core")
    messages_module = types.ModuleType("langchain_core.messages")

    class SystemMessage:
        def __init__(self, content):
            self.content = content

    class HumanMessage:
        def __init__(self, content):
            self.content = content

    messages_module.SystemMessage = SystemMessage
    messages_module.HumanMessage = HumanMessage
    sys.modules["langchain_core.messages"] = messages_module