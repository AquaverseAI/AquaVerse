"""
M3 quantitative engine — in-process wiring to the real trained model (P0.3).

Replaces the httpx round-trip `advisory/router.py` used to make to
`mock_m3.py` (a hardcoded-IP placeholder that returned a canned narration
string regardless of input, see `tests/fixtures/mock_m3.py` for the
quarantined original). The actual trained engine already lives at
`ml/serving/m3/m3_decision_engine.py` — `M3DecisionEngine` loads two
LightGBM boosters and does real inference in a few milliseconds, no GPU
and no network hop required.

`ml/serving/m3` is not an installable package: `m3_decision_engine.py` does
a same-directory-relative `from sim.species import ...`, resolved via
`ml/serving/m3/sim/__init__.py`. To import it as-is (without moving/forking
the module and its trained `.txt` model artifacts, which would also break
its own training/eval scripts that assume this layout), its directory must
be on `sys.path` first. That directory comes from
`Settings.m3_engine_dir` — never a hardcoded literal — so it can be
relocated per-environment via `.env`.

Loading the boosters is real file I/O; `get_m3_engine_bundle()` is memoized
with `lru_cache` (same cached-singleton shape as `app.config.get_settings`)
so that happens once per process, not once per `/v1/ask` request.
"""

from __future__ import annotations

import sys
from collections.abc import Callable
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    pass


@dataclass(frozen=True)
class M3EngineBundle:
    """The loaded M3 engine plus the dataclasses/formatter it defines.

    Bundled together (rather than exported as separate module-level names)
    because all of it only becomes importable *after* `sys.path` has been
    patched with the configured engine directory — see module docstring.
    """

    engine: Any  # m3_decision_engine.M3DecisionEngine instance
    PondSnapshot: type
    M3Payload: type
    payload_to_instruction: Callable[[Any], str]


def _ensure_engine_dir_on_path() -> None:
    """Insert `Settings.m3_engine_dir` onto `sys.path` if not already present."""
    from app.config import get_settings

    settings = get_settings()
    resolved = str(Path(settings.m3_engine_dir).resolve())
    if resolved not in sys.path:
        sys.path.insert(0, resolved)


@lru_cache(maxsize=1)
def get_m3_engine_bundle() -> M3EngineBundle:
    """
    Return the process-wide `M3EngineBundle` singleton.

    First call patches `sys.path`, imports `m3_decision_engine`, and
    constructs `M3DecisionEngine()` (reads the two LightGBM `.txt` boosters
    from disk). Every subsequent call — e.g. once per `/v1/ask` request —
    returns the same cached bundle, so model files are read exactly once
    per process.
    """
    _ensure_engine_dir_on_path()

    from m3_decision_engine import (  # type: ignore[import-not-found]
        M3DecisionEngine,
        M3Payload,
        PondSnapshot,
        payload_to_instruction,
    )

    return M3EngineBundle(
        engine=M3DecisionEngine(),
        PondSnapshot=PondSnapshot,
        M3Payload=M3Payload,
        payload_to_instruction=payload_to_instruction,
    )
