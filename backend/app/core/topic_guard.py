from __future__ import annotations

import re


_REFUSAL_MESSAGE = (
    "I can only help with EV charging questions (charging stations, connectors, sessions, and troubleshooting). "
    "Tell me your charger/network, connector type (CCS/Type 2/J1772/CHAdeMO), and what error or symptom you see."
)


_ALLOW_PATTERNS = [
    # broad EV charging terms
    r"\bev\b",
    r"electric\s+vehicle",
    r"\bcharging\b",
    r"\bcharger\b",
    r"\bcharge\b",
    r"\bstation\b",
    r"\bwallbox\b",
    r"\bconnector\b",
    r"\bcable\b",
    r"\bplug\b",
    r"\bsession\b",
    # power/charging metrics
    r"\bkw\b",
    r"\bkwh\b",
    r"\bsoc\b",
    r"state\s+of\s+charge",
    # common connector standards
    r"\bccs\b",
    r"\btype\s*2\b",
    r"\bj1772\b",
    r"\bchademo\b",
    # charging modes
    r"\bac\b",
    r"\bdc\b",
    r"\bfast\s*charge\b",
    r"\blevel\s*[23]\b",
    # protocols/networks/apps
    r"\bocpp\b",
    r"rfid",
    r"charging\s+app",
    # typical errors
    r"error\s*code",
    r"fault",
    r"\btrip(ped)?\b",
]

# If user clearly talks about phone/laptop charging without EV context, treat as off-topic.
_DISALLOW_HINTS = [
    r"phone",
    r"iphone",
    r"android",
    r"laptop",
    r"macbook",
    r"power\s*bank",
    r"usb\s*-?c",
    r"lightning\b",
]


def refusal_message() -> str:
    return _REFUSAL_MESSAGE


def is_ev_charging_related(text: str) -> bool:
    """Best-effort scope guard.

    This is intentionally lightweight and conservative:
    - If we see strong EV-charging keywords, allow.
    - If we only see consumer-electronics charging hints (phone/laptop) and no EV indicators, refuse.
    - Otherwise, allow and let the system prompt enforce scope.
    """

    t = (text or "").strip().lower()
    if not t:
        return True

    allow = any(re.search(p, t) for p in _ALLOW_PATTERNS)
    if allow:
        # special-case: "phone charge" etc. If both allow+disallow hit, require an EV hint.
        disallow = any(re.search(p, t) for p in _DISALLOW_HINTS)
        if disallow and not re.search(r"\bev\b|electric\s+vehicle|ccs|type\s*2|j1772|chademo|wallbox|ocpp", t):
            return False
        return True

    # No EV charging keywords found; if user is talking about other charging contexts, refuse.
    disallow = any(re.search(p, t) for p in _DISALLOW_HINTS)
    if disallow:
        return False

    # Unknown topic: allow prompt to handle, but prefer scope-limited behavior.
    return False
