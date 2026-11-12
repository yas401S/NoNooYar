#!/usr/bin/env python3
"""Persistent build-time worker for natural Persian speech assets."""
import os
import sys
from persian_speech_runtime import PiperSpeechEngine

engine = PiperSpeechEngine()
for raw in sys.stdin:
    line = raw.rstrip("\\n")
    if not line:
        continue
    try:
        output, text = line.split("\\t", 1)
        os.makedirs(os.path.dirname(output), exist_ok=True)
        engine.save(text, output)
        if not os.path.isfile(output) or os.path.getsize(output) == 0:
            raise RuntimeError("TTS engine produced an empty WAV file")
    except Exception as exc:
        try:
            with open(output + ".error", "w", encoding="utf-8") as f:
                f.write(str(exc))
        except Exception:
            pass
        print(f"Persian TTS failed: {exc}", file=sys.stderr, flush=True)
        sys.exit(1)
