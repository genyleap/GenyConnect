#!/usr/bin/env python3
"""Fail when Persian UI coverage or typography regresses."""

from __future__ import annotations

import json
import re
from pathlib import Path

import generate_ui_translations as generator


TECHNICAL_UNTRANSLATED = {
    "1.1.1.1\n8.8.8.8\ndns.google",
    "[A-Z]", "[a-z]", "Genyleap LLC", "HTTP + SOCKS5", "IP/CIDR",
    "support@genyleap.com", "VPN SOCKS5 127.0.0.1:", "Xray-core", "xray-core",
}

FORBIDDEN_TRANSLATION_FRAGMENTS = {
    "جوراب 5": "SOCKS5 must remain a technical protocol name",
    "اشعه ایکس": "Xray is a product/runtime name",
    "هسته ایکس": "Xray is a product/runtime name",
    "اختلاف نظر": "Discord is a product name",
    "کاغذ سفید": "White Paper needs product-aware wording",
    "چک جمع": "Checksum needs technical wording",
    "ثبت نام غیرفعال": "logging was mistranslated as registration",
    "توسعه پشتیبانی": "Support Development word order is invalid",
}

TYPOGRAPHY_PATTERNS = {
    "Arabic ی/ک variant": re.compile(r"[يىكۀة]"),
    "detached می/نمی prefix": re.compile(r"(?<![\u0600-\u06ff])(?:می|نمی) "),
    "detached plural suffix": re.compile(r"[\u0600-\u06ff] ها(?:\b|ی)"),
    "detached comparative suffix": re.compile(r"[\u0600-\u06ff] (?:تر|ترین)(?=$|[\s،؛؟!:.])"),
    "space before punctuation": re.compile(r"[ \t]+[،؛؟!.:]"),
}


def main() -> int:
    catalog_path = generator.CATALOG_ROOT / "fa.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    sources = generator.extract_sources()
    failures: list[str] = []

    for source in sources:
        value = str(catalog.get(source, "")).strip()
        if not value:
            failures.append(f"missing Persian translation: {source!r}")
            continue
        for label, pattern in TYPOGRAPHY_PATTERNS.items():
            if pattern.search(value):
                failures.append(f"{label}: {source!r} => {value!r}")
        for fragment, reason in FORBIDDEN_TRANSLATION_FRAGMENTS.items():
            if fragment in value:
                failures.append(f"{reason}: {source!r} => {value!r}")

        english_words = re.findall(r"[A-Za-z]+", source)
        contains_persian = re.search(r"[\u0600-\u06ff]", value) is not None
        if len(english_words) >= 2 and not contains_persian and source not in TECHNICAL_UNTRANSLATED:
            failures.append(f"apparently untranslated: {source!r} => {value!r}")

    # Catch direct literal display bindings. Component property defaults are
    # allowed because their actual Text items pass the value through I18n.t().
    binding = re.compile(r"\b(?:text|title|subtitle|description|placeholderText|label)\s*:")
    declaration = re.compile(r"\bproperty\s+string\s+")
    for path in sorted(generator.UI_ROOT.rglob("*.qml")):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not binding.search(line) or declaration.search(line) or "I18n." in line:
                continue
            literals = []
            for match in generator.QUOTED.finditer(line):
                decoded = generator.decode_qml_string(match.group(1))
                if decoded and generator.looks_user_facing(decoded):
                    literals.append(decoded)
            if literals:
                failures.append(
                    f"literal display binding bypasses I18n: {path.relative_to(generator.ROOT)}:"
                    f"{line_number}: {literals!r}"
                )

    if failures:
        print("Persian UI audit FAILED")
        for failure in failures:
            print("-", failure)
        return 1

    print(f"Persian UI audit passed: {len(sources)} translated strings checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
