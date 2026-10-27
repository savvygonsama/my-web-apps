#!/usr/bin/env python3
"""스틸가챠s 웹툰 한 화를 steel-grade-gacha 앱에 올린다.

하는 일
  1. 컷 그림을 순서대로 webtoon/epNN-1.webp ... 로 저장 (폭 1000px 이하, WebP)
  2. 목록용 썸네일 webtoon/th-epNN.webp 생성
  3. src/app_tpl.html 의 TOON 목록 맨 끝에 화 정보를 추가 (이미 있으면 --replace 일 때만 교체)
  4. sw.js 캐시 버전을 하나 올림
  5. src/build.sh 로 index.html 을 다시 만듦

쓰는 법
  python3 add_episode.py --app /path/to/steel-grade-gacha --ep 4 --title "볼트 하나" \
      --note "※ 자동차의 볼트·현가 스프링·타이어 속 강선은 모두 선재로 만듭니다." \
      컷1.png 컷2.png ... 컷8.png
  선택: --date 2026.10.28 (기본 오늘) --thumb 6 (썸네일로 쓸 컷 번호, 기본 2)
        --replace (같은 화를 다시 올릴 때) --no-build
"""
import argparse, datetime, json, re, subprocess, sys
from pathlib import Path

from PIL import Image

MAX_W = 1000


def save_webp(src, dst):
    im = Image.open(src).convert("RGB")
    if im.width > MAX_W:
        im = im.resize((MAX_W, round(im.height * MAX_W / im.width)), Image.LANCZOS)
    im.save(dst, "WEBP", quality=82, method=6)
    return im.size


def save_thumb(src, dst):
    # 목록 칸(76x64)에 맞춰 가운데 부분을 잘라 낸다
    im = Image.open(src).convert("RGB")
    w, h = im.size
    cw = int(w * 0.8)
    ch = int(cw * 64 / 76)
    x0, y0 = (w - cw) // 2, max(0, (h - ch) // 2)
    im.crop((x0, y0, x0 + cw, y0 + ch)).resize((240, round(240 * 64 / 76)), Image.LANCZOS) \
      .save(dst, "WEBP", quality=80)


def entry_js(ep_id, no, title, date, note, pages):
    q = lambda s: json.dumps(s, ensure_ascii=False)
    lines = [f'  {{ id: {q(ep_id)}, no: {q(no)}, title: {q(title)}, date: {q(date)}, thumb: {q("webtoon/th-" + ep_id + ".webp")},']
    if note:
        lines.append(f"    note: {q(note)},")
    lines.append("    pages: [")
    lines.append(",\n".join(f'      {{ img: {q(p)}, w: {w}, h: {h} }}' for p, w, h in pages))
    lines.append("    ] }")
    return "\n".join(lines)


def find_entry(s, ep_id):
    """TOON 안에서 id가 ep_id인 항목의 [시작, 끝) 위치. 없으면 None."""
    m = re.search(r'\n  \{ id: "' + re.escape(ep_id) + r'"', s)
    if not m:
        return None
    start = m.start() + 1
    ends = [i for i in (s.find("\n  { id:", start), s.find("\n];", start)) if i != -1]
    end = min(ends)
    if s[end - 1] == ",":  # 뒤에 다른 화가 이어지면 쉼표는 남긴다
        end -= 1
    return start, end


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", required=True, help="steel-grade-gacha 저장소 경로")
    ap.add_argument("--ep", type=int, required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--note", default="")
    ap.add_argument("--date", default=datetime.date.today().strftime("%Y.%m.%d"))
    ap.add_argument("--thumb", type=int, default=None)
    ap.add_argument("--replace", action="store_true")
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("images", nargs="+")
    a = ap.parse_args()

    app = Path(a.app)
    tpl = app / "src" / "app_tpl.html"
    sw = app / "sw.js"
    outdir = app / "webtoon"
    if not tpl.exists() or not sw.exists():
        sys.exit("!! 앱 저장소가 아닙니다: " + str(app))
    if a.thumb is None:
        a.thumb = min(2, len(a.images))
    if not (1 <= a.thumb <= len(a.images)):
        sys.exit("!! --thumb 는 1~컷 수 사이")

    ep_id = f"ep{a.ep:02d}"
    s = tpl.read_text(encoding="utf-8")
    if "var TOON = [" not in s:
        sys.exit("!! app_tpl.html 에 TOON 목록이 없습니다")
    old = find_entry(s, ep_id)
    if old and not a.replace:
        sys.exit(f"!! {ep_id} 가 이미 있습니다. 다시 올리려면 --replace")

    outdir.mkdir(exist_ok=True)
    for f in outdir.glob(f"{ep_id}-*.webp"):  # 컷 수가 줄었을 때 남는 파일 정리
        f.unlink()
    pages = []
    for i, src in enumerate(a.images, 1):
        rel = f"webtoon/{ep_id}-{i}.webp"
        w, h = save_webp(src, app / rel)
        pages.append((rel, w, h))
    save_thumb(a.images[a.thumb - 1], outdir / f"th-{ep_id}.webp")

    block = entry_js(ep_id, f"{a.ep}화", a.title, a.date, a.note, pages)
    if old:
        s = s[:old[0]] + block + s[old[1]:]
    else:
        t0 = s.index("var TOON = [")
        close = s.index("\n];", t0)
        s = s[:close] + ",\n" + block + s[close:]
    tpl.write_text(s, encoding="utf-8")

    v = sw.read_text(encoding="utf-8")
    m = re.search(r"steel-grade-gacha-v(\d+)", v)
    if m:
        nv = int(m.group(1)) + 1
        sw.write_text(v.replace(m.group(0), f"steel-grade-gacha-v{nv}"), encoding="utf-8")
        print(f"sw 캐시: v{m.group(1)} -> v{nv}")

    print(f"{ep_id} 「{a.title}」 {len(pages)}컷 저장")
    if not a.no_build:
        subprocess.run(["bash", str(app / "src" / "build.sh")], check=True)


if __name__ == "__main__":
    main()
