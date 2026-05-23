#!/usr/bin/env python3
"""
Parse all prayer markdown files and generate 5 structured JSON seed files.
"""

from __future__ import annotations

import json
import os
import re
import uuid
from pathlib import Path
from typing import Optional, Tuple

# ─── Constants ────────────────────────────────────────────────────────────────

NAMESPACE = uuid.NAMESPACE_DNS

CONTENT_DIR = Path(__file__).parent
SEED_DIR = CONTENT_DIR / "seed"

BOOK_CODES = {
    "Genesis": ("GEN", "Genesis"),
    "Exodus": ("EXO", "Exodus"),
    "Leviticus": ("LEV", "Leviticus"),
    "Numbers": ("NUM", "Numbers"),
    "Deuteronomy": ("DEU", "Deuteronomy"),
    "Joshua": ("JOS", "Joshua"),
    "Judges": ("JDG", "Judges"),
    "Ruth": ("RUT", "Ruth"),
    "1 Samuel": ("1SA", "1 Samuel"),
    "2 Samuel": ("2SA", "2 Samuel"),
    "1 Kings": ("1KI", "1 Kings"),
    "2 Kings": ("2KI", "2 Kings"),
    "1 Chronicles": ("1CH", "1 Chronicles"),
    "2 Chronicles": ("2CH", "2 Chronicles"),
    "Nehemiah": ("NEH", "Nehemiah"),
    "Job": ("JOB", "Job"),
    "Psalm": ("PSA", "Psalms"),
    "Psalms": ("PSA", "Psalms"),
    "Proverbs": ("PRO", "Proverbs"),
    "Ecclesiastes": ("ECC", "Ecclesiastes"),
    "Song of Solomon": ("SNG", "Song of Solomon"),
    "Isaiah": ("ISA", "Isaiah"),
    "Jeremiah": ("JER", "Jeremiah"),
    "Lamentations": ("LAM", "Lamentations"),
    "Ezekiel": ("EZK", "Ezekiel"),
    "Daniel": ("DAN", "Daniel"),
    "Hosea": ("HOS", "Hosea"),
    "Joel": ("JOL", "Joel"),
    "Amos": ("AMO", "Amos"),
    "Micah": ("MIC", "Micah"),
    "Habakkuk": ("HAB", "Habakkuk"),
    "Zephaniah": ("ZEP", "Zephaniah"),
    "Zechariah": ("ZEC", "Zechariah"),
    "Malachi": ("MAL", "Malachi"),
    "Matthew": ("MAT", "Matthew"),
    "Mark": ("MRK", "Mark"),
    "Luke": ("LUK", "Luke"),
    "John": ("JHN", "John"),
    "Acts": ("ACT", "Acts"),
    "Romans": ("ROM", "Romans"),
    "1 Corinthians": ("1CO", "1 Corinthians"),
    "2 Corinthians": ("2CO", "2 Corinthians"),
    "Galatians": ("GAL", "Galatians"),
    "Ephesians": ("EPH", "Ephesians"),
    "Philippians": ("PHP", "Philippians"),
    "Colossians": ("COL", "Colossians"),
    "1 Thessalonians": ("1TH", "1 Thessalonians"),
    "2 Thessalonians": ("2TH", "2 Thessalonians"),
    "1 Timothy": ("1TI", "1 Timothy"),
    "2 Timothy": ("2TI", "2 Timothy"),
    "Titus": ("TIT", "Titus"),
    "Hebrews": ("HEB", "Hebrews"),
    "James": ("JAS", "James"),
    "1 Peter": ("1PE", "1 Peter"),
    "2 Peter": ("2PE", "2 Peter"),
    "1 John": ("1JN", "1 John"),
    "2 John": ("2JN", "2 John"),
    "3 John": ("3JN", "3 John"),
    "Jude": ("JUD", "Jude"),
    "Revelation": ("REV", "Revelation"),
}

THEME_META = {
    "Thanksgiving":       ("sun.max.fill",            "#F59E0B"),
    "The Holy Spirit":    ("wind",                    "#8B5CF6"),
    "Intercession":       ("hands.and.sparkles.fill", "#3B82F6"),
    "Confession":         ("heart.slash.fill",        "#EF4444"),
    "Worship":            ("music.note",              "#F59E0B"),
    "Identity":           ("person.fill",             "#06B6D4"),
    "Guidance":           ("location.north.fill",     "#1D4ED8"),
    "Spiritual Warfare":  ("shield.fill",             "#991B1B"),
    "Healing":            ("cross.fill",              "#10B981"),
    "The Nations":        ("globe",                   "#1E40AF"),
    "Family":             ("house.fill",              "#F97316"),
    "Ministry":           ("building.columns.fill",   "#7C3AED"),
    "Blessing":           ("sparkles",                "#D97706"),
    "Lament":             ("cloud.rain.fill",         "#6B7280"),
    "Love":               ("heart.fill",              "#EC4899"),
    "Hope":               ("sunrise.fill",            "#F97316"),
    "Peace":              ("leaf.fill",               "#059669"),
    "Fear":               ("hand.raised.fill",        "#60A5FA"),
    "Temptation":         ("flame.fill",              "#B45309"),
    "Trust":              ("anchor.fill",             "#1E3A8A"),
    "Anger":              ("flame.fill",              "#DC2626"),
    "Pride":              ("crown.fill",              "#6D28D9"),
}

DEFAULT_META = ("questionmark.circle", "#6B7280")

# ─── UUID helpers ──────────────────────────────────────────────────────────────

def make_uuid(key: str) -> str:
    return str(uuid.uuid5(NAMESPACE, key))

def theme_id(sort_order: int) -> str:
    return make_uuid(f"theme:{sort_order}")

def topic_id(theme_sort: int, topic_sort: int) -> str:
    return make_uuid(f"topic:{theme_sort}:{topic_sort}")

def prayer_id(theme_sort: int, topic_sort: int, prayer_num: int) -> str:
    return make_uuid(f"prayer:{theme_sort}:{topic_sort}:{prayer_num}")

def scripture_id(book_code: str, chapter: int, verse_start: int, verse_end) -> str:
    ve = "null" if verse_end is None else str(verse_end)
    return make_uuid(f"scripture:{book_code}:{chapter}:{verse_start}:{ve}")

# ─── Scripture parsing ─────────────────────────────────────────────────────────

def parse_book_name(raw: str) -> Optional[Tuple[str, str]]:
    """Return (book_code, canonical_book_name) or None."""
    raw = raw.strip()
    # Try exact match first
    if raw in BOOK_CODES:
        return BOOK_CODES[raw]
    # Try case-insensitive match
    for key, val in BOOK_CODES.items():
        if key.lower() == raw.lower():
            return val
    return None

def parse_scripture_ref(ref_str: str) -> Optional[dict]:
    """
    Parse a scripture reference like 'Psalm 19:1-2' or '1 John 4:18'.
    Returns a dict with keys: book, book_code, chapter, verse_start, verse_end, reference.
    Returns None if parsing fails.
    """
    ref_str = ref_str.strip()

    # Match pattern: BookName Chapter:Verse or Chapter:Verse-Verse
    # Book name may start with a digit (e.g. "1 John")
    # Pattern: everything up to the last space before the chapter number
    match = re.match(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$', ref_str)
    if not match:
        return None

    book_raw, chapter_str, verse_start_str, verse_end_str = match.groups()

    book_info = parse_book_name(book_raw)
    if book_info is None:
        return None

    book_code, book_name = book_info
    chapter = int(chapter_str)
    verse_start = int(verse_start_str)
    verse_end = int(verse_end_str) if verse_end_str else None

    return {
        "book": book_name,
        "book_code": book_code,
        "chapter": chapter,
        "verse_start": verse_start,
        "verse_end": verse_end,
        "reference": ref_str,
    }

def parse_scripture_line(line: str) -> list[dict]:
    """
    Parse an italic scripture line like '*Psalm 19:1-2 | Psalm 8:3-4*'.
    Returns list of parsed scripture dicts. Logs failures.
    """
    # Strip leading/trailing * characters
    line = line.strip()
    if line.startswith('*') and line.endswith('*'):
        line = line[1:-1]
    elif line.startswith('*'):
        line = line[1:]

    refs = [r.strip() for r in line.split('|')]
    results = []
    for ref in refs:
        if not ref:
            continue
        parsed = parse_scripture_ref(ref)
        if parsed is None:
            print(f"  WARNING: Failed to parse scripture reference: '{ref}'")
            FAILED_REFS.append(ref)
        else:
            results.append(parsed)
    return results

# ─── Theme metadata lookup ─────────────────────────────────────────────────────

def get_theme_meta(theme_name: str) -> tuple[str, str]:
    """Return (icon, color_hex) for a theme name."""
    theme_name_lower = theme_name.lower()
    for key, val in THEME_META.items():
        if key.lower() in theme_name_lower:
            return val
    return DEFAULT_META

# ─── Markdown parser ───────────────────────────────────────────────────────────

def parse_md_file(filepath: Path) -> dict:
    """
    Parse a single markdown prayer file.
    Returns a dict with keys: theme_number, theme_name, topics.
    Each topic: { title, sort_order, prayers: [{title, scripture_line, bullets}] }
    """
    lines = filepath.read_text(encoding="utf-8").splitlines()

    result = {
        "theme_number": None,
        "theme_name": None,
        "topics": [],
    }

    current_topic = None
    current_prayer = None
    in_bullets = False

    i = 0
    while i < len(lines):
        line = lines[i]
        raw = line.rstrip()

        # ── Theme header ──────────────────────────────────────────────────
        m = re.match(r'^# Theme (\d+):\s*(.+)$', raw)
        if m:
            result["theme_number"] = int(m.group(1))
            result["theme_name"] = m.group(2).strip()
            i += 1
            continue

        # ── Topic header ──────────────────────────────────────────────────
        m = re.match(r'^## Topic \d+:\s*(.+)$', raw)
        if m:
            # Save any in-progress prayer
            if current_prayer is not None and current_topic is not None:
                current_topic["prayers"].append(current_prayer)
                current_prayer = None
                in_bullets = False

            topic_title = m.group(1).strip()
            current_topic = {
                "title": topic_title,
                "sort_order": len(result["topics"]) + 1,
                "prayers": [],
            }
            result["topics"].append(current_topic)
            i += 1
            continue

        # ── Prayer header ─────────────────────────────────────────────────
        m = re.match(r'^\*\*Prayer (\d+)\s*[—–-]+\s*(.+)\*\*$', raw)
        if m:
            # Save any in-progress prayer
            if current_prayer is not None and current_topic is not None:
                current_topic["prayers"].append(current_prayer)

            prayer_num = int(m.group(1))
            prayer_title = m.group(2).strip()
            current_prayer = {
                "number": prayer_num,
                "title": prayer_title,
                "scripture_line": None,
                "bullets": [],
            }
            in_bullets = False
            i += 1
            # Look ahead for scripture line (skip blank lines)
            while i < len(lines):
                ahead = lines[i].strip()
                if not ahead:
                    i += 1
                    continue
                if ahead.startswith('*') and not ahead.startswith('**'):
                    current_prayer["scripture_line"] = ahead
                    i += 1
                    break
                # Not a scripture line — stop looking ahead
                break
            continue

        # ── Bullet lines ──────────────────────────────────────────────────
        if raw.startswith('- ') and current_prayer is not None:
            bullet_text = raw[2:].strip()
            current_prayer["bullets"].append(bullet_text)
            in_bullets = True
            i += 1
            continue

        # ── Separator ─────────────────────────────────────────────────────
        if raw == '---':
            # Separator doesn't end a prayer — we detect end by next prayer/topic header
            in_bullets = False
            i += 1
            continue

        # Everything else (subtitle lines, blank lines) — skip
        i += 1

    # Flush the last prayer
    if current_prayer is not None and current_topic is not None:
        current_topic["prayers"].append(current_prayer)

    return result

# ─── Main generation logic ─────────────────────────────────────────────────────

def generate_seeds():
    global FAILED_REFS
    FAILED_REFS = []

    md_files = sorted(CONTENT_DIR.glob("prayers-*.md"))
    if not md_files:
        print("ERROR: No prayer markdown files found.")
        return

    print(f"Found {len(md_files)} markdown files.")

    themes_out = []
    topics_out = []
    prayers_out = []
    scriptures_map = {}   # scripture_key -> scripture dict (deduplicated)
    scripture_links_out = []  # {prayer_id, scripture_id}

    for filepath in md_files:
        parsed = parse_md_file(filepath)

        theme_num = parsed["theme_number"]
        theme_name = parsed["theme_name"]

        if theme_num is None or theme_name is None:
            print(f"  WARNING: Could not parse theme from {filepath.name} — skipping.")
            continue

        icon, color = get_theme_meta(theme_name)
        tid = theme_id(theme_num)

        themes_out.append({
            "id": tid,
            "name": theme_name,
            "description": "",
            "icon": icon,
            "color_hex": color,
            "sort_order": theme_num,
        })

        for topic in parsed["topics"]:
            top_sort = topic["sort_order"]
            top_id = topic_id(theme_num, top_sort)

            topics_out.append({
                "id": top_id,
                "theme_id": tid,
                "title": topic["title"],
                "description": None,
                "tags": [],
                "sort_order": top_sort,
            })

            for prayer in topic["prayers"]:
                p_num = prayer["number"]
                pid = prayer_id(theme_num, top_sort, p_num)
                body = "\n".join(prayer["bullets"])

                prayers_out.append({
                    "id": pid,
                    "topic_id": top_id,
                    "title": prayer["title"],
                    "body": body,
                    "author": None,
                    "is_classic": False,
                })

                # Parse scriptures
                if prayer["scripture_line"]:
                    parsed_scrips = parse_scripture_line(prayer["scripture_line"])
                    for scrip in parsed_scrips:
                        s_id = scripture_id(
                            scrip["book_code"],
                            scrip["chapter"],
                            scrip["verse_start"],
                            scrip["verse_end"],
                        )
                        if s_id not in scriptures_map:
                            scriptures_map[s_id] = {
                                "id": s_id,
                                "book": scrip["book"],
                                "book_code": scrip["book_code"],
                                "chapter": scrip["chapter"],
                                "verse_start": scrip["verse_start"],
                                "verse_end": scrip["verse_end"],
                                "reference": scrip["reference"],
                            }
                        scripture_links_out.append({
                            "prayer_id": pid,
                            "scripture_id": s_id,
                        })
                else:
                    print(f"  WARNING: No scripture line for prayer '{prayer['title']}' in {filepath.name}")

    # Sort themes by sort_order
    themes_out.sort(key=lambda x: x["sort_order"])
    scriptures_out = list(scriptures_map.values())

    # ── Write output files ────────────────────────────────────────────────────
    SEED_DIR.mkdir(exist_ok=True)

    def write_json(filename, data):
        path = SEED_DIR / filename
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  Wrote {path.name} ({len(data)} records)")

    print("\nWriting seed files...")
    write_json("themes.json", themes_out)
    write_json("topics.json", topics_out)
    write_json("prayers.json", prayers_out)
    write_json("scriptures.json", scriptures_out)
    write_json("scripture_links.json", scripture_links_out)

    # ── Summary ───────────────────────────────────────────────────────────────
    print("\n" + "="*60)
    print("GENERATION SUMMARY")
    print("="*60)
    print(f"  Themes:           {len(themes_out)}")
    print(f"  Topics:           {len(topics_out)}")
    print(f"  Prayers:          {len(prayers_out)}")
    print(f"  Scriptures:       {len(scriptures_out)} (deduplicated)")
    print(f"  Scripture links:  {len(scripture_links_out)}")

    if FAILED_REFS:
        print(f"\n  FAILED to parse {len(FAILED_REFS)} scripture reference(s):")
        for ref in FAILED_REFS:
            print(f"    - '{ref}'")
    else:
        print("\n  All scripture references parsed successfully.")

    # ── Sanity check: first entry from each file ──────────────────────────────
    print("\n" + "="*60)
    print("SANITY CHECK — First entry from each file:")
    print("="*60)

    def show_first(label, data):
        print(f"\n  [{label}]")
        if data:
            print(json.dumps(data[0], indent=4, ensure_ascii=False))
        else:
            print("  (empty)")

    show_first("themes.json", themes_out)
    show_first("topics.json", topics_out)
    show_first("prayers.json", prayers_out)
    show_first("scriptures.json", scriptures_out)
    show_first("scripture_links.json", scripture_links_out)


if __name__ == "__main__":
    generate_seeds()
