#!/usr/bin/env python3
"""Generate offline language assets for Sesli.

Inputs (download separately, see README):
  * CMU Pronouncing Dictionary (BSD-2-Clause)
    https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict
  * Turkish frequency list (MIT)
    https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/tr/tr_50k.txt

Outputs:
  * assets/data/english_lexicon.json  word -> Turkish-friendly respelling
  * assets/data/turkish_words.txt     common Turkish words, one per line

The runtime only uses these generated files. Curated overrides for the most
common words live in lib/features/tts/domain/english_transliterator.dart.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# ARPAbet -> Turkish letters. Stress digits are stripped before lookup.
PHONE_MAP = {
    "AA": "a",
    "AE": "e",
    "AH": "a",
    "AO": "o",
    "AW": "au",
    "AY": "ay",
    "EH": "e",
    "ER": "ır",
    "EY": "ey",
    "IH": "i",
    "IY": "i",
    "OW": "o",
    "OY": "oy",
    "UH": "u",
    "UW": "u",
    "B": "b",
    "CH": "ç",
    "D": "d",
    "DH": "d",
    "F": "f",
    "G": "g",
    "HH": "h",
    "JH": "c",
    "K": "k",
    "L": "l",
    "M": "m",
    "N": "n",
    "NG": "ng",
    "P": "p",
    "R": "r",
    "S": "s",
    "SH": "ş",
    "T": "t",
    "TH": "t",
    "V": "v",
    "W": "v",
    "Y": "y",
    "Z": "z",
    "ZH": "j",
}

VOWELS = "aeıioöuü"


def convert(phones: list[str]) -> str:
    out: list[str] = []
    count = len(phones)

    for index, raw in enumerate(phones):
        phone = re.sub(r"\d$", "", raw)
        stressed = raw[-1] in "12" if raw[-1:].isdigit() else False
        next_phone = re.sub(r"\d$", "", phones[index + 1]) if index + 1 < count else ""

        if phone == "AH":
            if stressed:
                out.append("a")
            elif index == 0:
                out.append("a")
            elif index == count - 1:
                out.append("a")
            else:
                out.append("ı")
        elif phone == "AA":
            # /ɒ/ is closer to Turkish "o"; /ɑː/ before r or dh stays "a".
            if next_phone in {"R", "DH"} or index == count - 1:
                out.append("a")
            else:
                out.append("o")
        elif phone == "EH" and next_phone == "R":
            # "air", "software", "there": English /eə/ -> Turkish "eı".
            out.append("eı")
        elif phone == "IY" and next_phone == "R":
            out.append("i")
        elif phone in PHONE_MAP:
            out.append(PHONE_MAP[phone])

    text = "".join(out)

    # Collapse doubled vowels and consonants produced by adjacent phonemes.
    text = re.sub(r"([aeıioöuü])\1+", r"\1", text)
    text = re.sub(r"(ng)g+", r"\1", text)
    text = re.sub(r"([bcçdfgğhjklmnprsştvyz])\1+", r"\1", text)

    # Turkish needs a glide between two vowels.
    text = re.sub(r"i(?=[aeıioöuü])", "iy", text)
    text = re.sub(r"u(?=[aeıioöuü])", "uv", text)

    # Final -le after a consonant is a syllabic /əl/ in English.
    text = re.sub(r"(?<=[bcçdfgğhjklmnprsştvyz])le$", "ıl", text)

    # Final -er is the English schwa+r (unless already handled as /eə/).
    text = re.sub(r"(?<![eı])er$", "ır", text)

    # Keep only characters the Turkish model can pronounce.
    text = re.sub(r"[^a-zçğıöşüâîû]", "", text)
    return text


def load_english(path: Path) -> dict[str, str]:
    words: dict[str, str] = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith(";;;"):
                continue
            parts = line.split()
            if len(parts) < 2:
                continue
            word = parts[0].lower().replace("'", "")
            if not re.fullmatch(r"[a-z]+", word):
                continue
            if word in words:
                continue
            respelling = convert(parts[1:])
            if respelling:
                words[word] = respelling
    return words


def load_turkish(path: Path, limit: int) -> list[str]:
    words: list[str] = []
    seen: set[str] = set()
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            parts = line.split()
            if not parts:
                continue
            word = parts[0].strip().lower()
            if not re.fullmatch(r"[a-zçğıöşüâîû]+", word):
                continue
            if word in seen:
                continue
            seen.add(word)
            words.append(word)
            if len(words) >= limit:
                break
    return words


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cmudict", type=Path, required=True)
    parser.add_argument("--turkish", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path("assets/data"))
    parser.add_argument("--turkish-limit", type=int, default=20000)
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)

    english = load_english(args.cmudict)
    (args.out / "english_lexicon.json").write_text(
        json.dumps(english, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    turkish = load_turkish(args.turkish, args.turkish_limit)
    (args.out / "turkish_words.txt").write_text(
        "\n".join(turkish) + "\n",
        encoding="utf-8",
    )

    print(f"English words: {len(english)}")
    print(f"Turkish words: {len(turkish)}")


if __name__ == "__main__":
    main()
