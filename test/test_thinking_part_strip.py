#!/usr/bin/env python3
"""
Unit tests for LoggingOpenAIModel._strip_thinking_parts().

Covers:
  - ModelResponse with both ThinkingPart and TextPart -> only TextPart remains
  - ModelResponse with only ThinkingPart -> parts list becomes empty, message stays
  - Messages with no ThinkingPart -> list unchanged
  - Empty messages list -> no error
"""

import os
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "agent"))

with patch.dict(
    "sys.modules",
    {
        "llama_index.core": MagicMock(),
        "llama_index.embeddings.huggingface": MagicMock(),
        "llama_index.readers.file": MagicMock(),
        "llama_index.llms.deepseek": MagicMock(),
    },
):
    pass

from pydantic_ai.messages import (
    ModelMessage,
    ModelRequest,
    ModelResponse,
    SystemPromptPart,
    TextPart,
    ThinkingPart,
)

with patch.dict(os.environ, {"OPENAI_API_KEY": "k", "OPENAI_MODEL": "m", "OPENAI_BASE_URL": "u"}):
    from src.agent.model import LoggingOpenAIModel


class TestStripThinkingParts(unittest.TestCase):
    def _make_model(self):
        return LoggingOpenAIModel.__new__(LoggingOpenAIModel)

    def test_mixed_thinking_and_text(self):
        model = self._make_model()
        messages: list[ModelMessage] = [
            ModelResponse(parts=[ThinkingPart(content="reasoning"), TextPart(content="hello")]),
        ]
        model._strip_thinking_parts(messages)
        self.assertEqual(len(messages), 1)
        self.assertEqual(len(messages[0].parts), 1)
        self.assertIsInstance(messages[0].parts[0], TextPart)
        self.assertEqual(messages[0].parts[0].content, "hello")

    def test_only_thinking_parts(self):
        model = self._make_model()
        messages: list[ModelMessage] = [
            ModelResponse(parts=[ThinkingPart(content="only reasoning")]),
        ]
        model._strip_thinking_parts(messages)
        self.assertEqual(len(messages), 1)
        self.assertEqual(messages[0].parts, [])

    def test_no_thinking_parts(self):
        model = self._make_model()
        messages: list[ModelMessage] = [
            ModelResponse(parts=[TextPart(content="text")]),
        ]
        model._strip_thinking_parts(messages)
        self.assertEqual(len(messages), 1)
        self.assertEqual(len(messages[0].parts), 1)
        self.assertIsInstance(messages[0].parts[0], TextPart)

    def test_empty_list(self):
        model = self._make_model()
        messages: list[ModelMessage] = []
        model._strip_thinking_parts(messages)
        self.assertEqual(messages, [])

    def test_preserves_model_requests(self):
        model = self._make_model()
        messages: list[ModelMessage] = [
            ModelRequest(parts=[SystemPromptPart(content="sys")]),
            ModelResponse(parts=[ThinkingPart(content="think"), TextPart(content="reply")]),
            ModelRequest(parts=[SystemPromptPart(content="user msg")]),
        ]
        model._strip_thinking_parts(messages)
        self.assertEqual(len(messages), 3)
        self.assertIsInstance(messages[0], ModelRequest)
        self.assertIsInstance(messages[2], ModelRequest)
        self.assertEqual(len(messages[1].parts), 1)
        self.assertIsInstance(messages[1].parts[0], TextPart)


if __name__ == "__main__":
    unittest.main()
