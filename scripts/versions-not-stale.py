"""Сверяет каждую формулу с последним выпуском её же исходника.

Зачем. Хранилище формул — копия. Оно не ломается, оно ОТСТАЁТ, и это молчаливая
беда: `brew install` берёт формулу, формула исправна, архив по её адресу лежит,
отпечаток сходится — всё зелено, а ставится прошлогоднее. Так и вышло с flang:
кран стоял на 0.7.3, пока выходили 0.7.4—0.7.9, и шесть выпусков подряд человек
получал не то, что вышло. Заметили это не проверкой, а человеком.

Здесь спрашивается сам GitHub: какой выпуск у исходника последний — и совпадает ли
он с тем, что раздаёт формула.

Что проверяется у каждой формулы:

  1. `версии в формуле сходятся` — если у формулы есть поле `version`, оно равно
     версии в адресе архива. У flang эти два числа однажды разошлись с третьим —
     с `sha256`, оставшимся от прошлого выпуска.
  2. `кран не отстал`            — версия в адресе равна последнему выпуску
     исходного хранилища.

Формулы, чей адрес не ведёт на выпуск GitHub, пропускаются С УПОМИНАНИЕМ: пропуск
назван вслух, а не спрятан в зелёный ответ.

Коды возврата: 0 — всё догоняет; 1 — что-то отстало; 2 — до GitHub не достучались
(проверка НЕ состоялась, и это не то же самое, что «всё в порядке»).

Запуск::

    python3 scripts/versions-not-stale.py              # спросить GitHub
    python3 scripts/versions-not-stale.py --self-test  # проверить саму проверку
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FORMULA_DIR = ROOT / "Formula"

#: `url "…"` объявлением, а не словом в примечании.
URL_LINE = re.compile(r"^\s*url\s+\"([^\"]+)\"", re.MULTILINE)

#: `version "1.2.3"` объявлением.
VERSION_LINE = re.compile(r"^\s*version\s+\"([^\"]+)\"", re.MULTILINE)

#: Адрес выпуска GitHub — и ассетом, и архивом исходников тега.
#:
#: В ветке про архив номер берётся НЕжадно и упирается в `.tar.gz`. Жадный
#: `[0-9A-Za-z.]*` съедал бы и точку с расширением, и версия читалась бы как
#: `0.5.0.tar` — а сравнение с настоящим выпуском `0.5.0` после этого краснело
#: всегда. Так и было; поймал это не разбор кода, а прогон на живом кране, и
#: поэтому же в `--self-test` теперь разбираются настоящие адреса.
RELEASE_URL = re.compile(
    r"github\.com/([^/]+)/([^/]+)/"
    r"(?:releases/download/v([0-9][0-9A-Za-z.]*)/"
    r"|archive/refs/tags/v([0-9][0-9A-Za-z.]*?)\.tar\.gz)"
)

TIMEOUT = 30


class Unreachable(Exception):
    """До GitHub не достучались. Не «отстало» и не «догоняет»."""


def read_formulas() -> dict[str, str]:
    return {p.stem: p.read_text(encoding="utf-8") for p in sorted(FORMULA_DIR.glob("*.rb"))}


def parse(text: str) -> tuple[str, str, set[str], str | None]:
    """Владелец, хранилище, версии из адресов и объявленное поле `version`."""

    owner = repo = ""
    versions: set[str] = set()
    for url in URL_LINE.findall(text):
        m = RELEASE_URL.search(url)
        if not m:
            continue  # `head do` показывает на .git — там версии нет и быть не может
        owner, repo = m.group(1), m.group(2)
        versions.add(m.group(3) or m.group(4))
    declared = VERSION_LINE.findall(text)
    return owner, repo, versions, declared[0] if declared else None


def latest_release(owner: str, repo: str) -> str:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    headers = {"User-Agent": "digitable-tap-check", "Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        with urllib.request.urlopen(
            urllib.request.Request(url, headers=headers), timeout=TIMEOUT
        ) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 404:
            raise Unreachable(f"{owner}/{repo}: выпусков нет вовсе") from e
        raise Unreachable(f"{owner}/{repo}: GitHub ответил {e.code}") from e
    except (urllib.error.URLError, OSError) as e:
        raise Unreachable(f"{owner}/{repo}: {e}") from e
    tag = str(payload.get("tag_name", ""))
    return tag[1:] if tag.startswith("v") else tag


def judge(
    name: str,
    owner: str,
    repo: str,
    versions: set[str],
    declared: str | None,
    latest: str | None,
) -> list[str]:
    """Приговор по одной формуле. Ничего не спрашивает — только судит.

    Отделено от опроса нарочно: так `--self-test` может подсунуть заведомую порчу
    и убедиться, что проверка на ней краснеет, не трогая ни сети, ни GitHub.
    """

    bad: list[str] = []
    if len(versions) > 1:
        bad.append(f"{name}: адреса показывают на разные выпуски {sorted(versions)} — "
                   "часть ссылок обновили, часть забыли")
    if not versions:
        return bad
    version = sorted(versions)[0]
    if declared is not None and declared != version:
        bad.append(f"{name}: поле version {declared!r}, а в адресе архива {version!r} — "
                   "два числа про один выпуск разошлись")
    if latest is None:
        return bad
    if version != latest:
        bad.append(f"{name}: кран раздаёт {version}, а последний выпуск "
                   f"{owner}/{repo} — {latest}. brew ставит устаревшее и молчит: "
                   "формула исправна, она просто старая")
    return bad


def self_test() -> int:
    """Отрицательный контроль: проверка обязана краснеть на заведомой порче.

    Разбор адресов проверяется отдельно и настоящими строками. Первая же версия
    этой проверки судила правильно и разбирала неправильно — читала `0.5.0.tar`
    вместо `0.5.0` — и была при этом полностью зелёной, потому что до живого крана
    ни один её случай адреса в глаза не видел.
    """

    bad: list[str] = []

    # Разбор: настоящие адреса всех видов, что встречаются в этом хранилище.
    parse_cases: list[tuple[str, str, tuple[str, str, set[str], str | None]]] = [
        ("архив исходников тега",
         'class F < Formula\n'
         '  url "https://github.com/digitable-lol/ouroboros/archive/refs/tags/v0.5.0.tar.gz"\n'
         'end\n',
         ("digitable-lol", "ouroboros", {"0.5.0"}, None)),
        ("ассет выпуска",
         'class F < Formula\n'
         '  url "https://github.com/digitable-lol/flang/releases/download/v0.7.14/flang-0.7.14-c.tar.gz"\n'
         '  version "0.7.14"\n'
         'end\n',
         ("digitable-lol", "flang", {"0.7.14"}, "0.7.14")),
        ("ассеты под разные машины — один выпуск",
         'class F < Formula\n'
         '  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.9.0/d-linux-amd64.tar.gz"\n'
         '  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.9.0/d-linux-arm64.tar.gz"\n'
         '  version "0.9.0"\n'
         'end\n',
         ("digitable-lol", "digitdisk", {"0.9.0"}, "0.9.0")),
        ("head do — там версии нет и быть не может",
         'class F < Formula\n'
         '  url "https://github.com/digitable-lol/digitwm/releases/download/v0.1.0/w-darwin-arm64.tar.gz"\n'
         '  head do\n'
         '    url "https://github.com/digitable-lol/digitwm.git", branch: "main"\n'
         '  end\n'
         'end\n',
         ("digitable-lol", "digitwm", {"0.1.0"}, None)),
    ]
    for name, text, expected in parse_cases:
        got = parse(text)
        if got != expected:
            bad.append(f"разбор «{name}»: прочитано {got}, а должно {expected}")

    cases: list[tuple[str, list[str], bool]] = [
        ("догоняет",
         judge("x", "o", "r", {"1.2.3"}, "1.2.3", "1.2.3"), False),
        ("кран отстал",
         judge("x", "o", "r", {"0.7.3"}, None, "0.7.9"), True),
        ("поле version разошлось с адресом",
         judge("x", "o", "r", {"1.2.3"}, "1.2.2", "1.2.3"), True),
        ("адреса показывают на разные выпуски",
         judge("x", "o", "r", {"1.2.3", "1.2.2"}, None, None), True),
        ("не спросили GitHub — молчим, а не зеленеем",
         judge("x", "o", "r", {"1.2.3"}, "1.2.3", None), False),
        ("не выпуск GitHub — судить не о чем",
         judge("x", "", "", set(), None, None), False),
    ]
    for name, complaints, must_complain in cases:
        if must_complain and not complaints:
            bad.append(f"«{name}»: проверка промолчала — она ничего не проверяет")
        if not must_complain and complaints:
            bad.append(f"«{name}»: проверка ругается зря — {complaints[0]}")
    if bad:
        print("Проверка сломана:\n", file=sys.stderr)
        for b in bad:
            print(f"  - {b}", file=sys.stderr)
        return 1
    print(f"Проверка проверена: адресов разобрано {len(parse_cases)}, приговоров "
          f"{len(cases)}; краснеет на порче и молчит на неспрошенном.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--self-test", action="store_true", dest="self_test",
                        help="проверить саму проверку на заведомой порче")
    args = parser.parse_args()
    if args.self_test:
        return self_test()

    formulas = read_formulas()
    if not formulas:
        print(f"В {FORMULA_DIR} нет ни одной формулы — проверять нечего, а должно быть что",
              file=sys.stderr)
        return 1

    bad: list[str] = []
    missed: list[str] = []
    lines: list[str] = []
    for name, text in formulas.items():
        owner, repo, versions, declared = parse(text)
        if not versions:
            missed.append(f"{name}: адрес не ведёт на выпуск GitHub — версию сверить не с чем")
            continue
        latest: str | None = None
        try:
            latest = latest_release(owner, repo)
        except Unreachable as e:
            missed.append(str(e))
        bad += judge(name, owner, repo, versions, declared, latest)
        lines.append(f"  {name}: кран {sorted(versions)[0]}, выпуск {latest or '(не спросили)'}")

    print("\n".join(lines))
    if bad:
        print("\nХранилище формул отстало:\n", file=sys.stderr)
        for b in bad:
            print(f"  - {b}", file=sys.stderr)
        return 1
    if missed:
        print("\nПроверка НЕ состоялась для части формул:", file=sys.stderr)
        for m in missed:
            print(f"  - {m}", file=sys.stderr)
        print("Это не то же самое, что «всё догоняет».", file=sys.stderr)
        return 2
    print(f"\nВсе формулы раздают последний выпуск: проверено {len(formulas)}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
