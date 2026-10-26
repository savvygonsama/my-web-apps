"""스틸링고 입문 — 음성 파일 만들기 (VOICEVOX)

실행: python3 tools/make_audio.py <VOICEVOX 폴더>   (앱 폴더에서, tools/content.py 다음에)
  <VOICEVOX 폴더> 안에 아래 세 가지가 있어야 한다. 모두 github.com/VOICEVOX 공개 배포본.
    voicevox_onnxruntime-linux-x64-1.17.3/   (onnxruntime-builder 릴리스)
    open_jtalk_dic_utf_8-1.11/               (r9y9/open_jtalk 릴리스)
    vvm/6.vvm                                (voicevox_vvm 0.16.4 릴리스, No.7 목소리)
  파이썬 패키지: voicevox_core 0.16.4 휠 (voicevox_core 릴리스)

js/lessons.js 의 글자·단어·문장과 Lite 문장을 모두 읽어 audio/ 에 mp3로 저장하고 audio/manifest.js 를 쓴다.
목소리: VOICEVOX:No.7 (アナウンス). 앱 화면에 'VOICEVOX:No.7' 표기를 반드시 남긴다.

검수 기준 (어학 전문가 권고)
- 글자 하나는 글자 소리 그대로: は=ha, へ=he. を·ヲ는 お와 같은 소리. 가타카나 글자는 같은 소리의 히라가나 파일을 같이 쓴다.
- 단어는 한자로 넣어 억양을 맞추고, 엔진이 읽은 가나가 원래 단어와 같은지 대조한다. 다르면 멈춘다.
  대조할 때 긴소리(ー, おう, えい)와 조사 は·へ·を는 소리대로 바꿔서 비교한다.
- 같은 목소리·같은 속도(0.9배).
"""
import hashlib, json, os, re, subprocess, sys, tempfile
from voicevox_core.blocking import Onnxruntime, OpenJtalk, Synthesizer, VoiceModelFile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
VV = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/vv"
STYLE = 30  # No.7 アナウンス

# 엔진에 넣을 글: 한자로 넣어야 억양이 맞는다. 없으면 가나 그대로.
KANJI = {
 "あい":"愛","いえ":"家","うえ":"上","あお":"青","え":"絵","いい":"いい","あう":"会う","いいえ":"いいえ",
 "かお":"顔","あか":"赤","えき":"駅","いけ":"池","こえ":"声","きく":"聞く","いく":"行く","かく":"書く","ここ":"ここ","あかい":"赤い",
 "すし":"寿司","あさ":"朝","かさ":"傘","いす":"椅子","せき":"席","しお":"塩","あし":"足","かし":"菓子","すき":"好き","せかい":"世界",
 "て":"手","した":"下","くつ":"靴","そと":"外","ちかてつ":"地下鉄","つくえ":"机","あした":"明日","くち":"口","たかい":"高い","いと":"糸",
 "ねこ":"猫","いぬ":"犬","なつ":"夏","さかな":"魚","なに":"何","おかね":"お金","にく":"肉","なか":"中","くに":"国",
 "はな":"花","ひと":"人","ふね":"船","ほし":"星","はし":"箸","ひとつ":"一つ","ふたつ":"二つ","ふく":"服","へた":"下手",
 "まち":"町","みみ":"耳","むし":"虫","あめ":"雨","もも":"桃","なまえ":"名前","うみ":"海","かみ":"紙","あたま":"頭","もの":"物",
 "やま":"山","ゆき":"雪","よこ":"横","へや":"部屋","ゆめ":"夢","やさい":"野菜","ふゆ":"冬","よむ":"読む","やすみ":"休み",
 "さくら":"桜","そら":"空","はる":"春","いろ":"色","くるま":"車","とり":"鳥","くすり":"薬","よる":"夜",
 "わたし":"私","かわ":"川","ほん":"本","てんき":"天気","おんな":"女","にわ":"庭","ほんや":"本屋","ほんを よむ":"本を読む",
 "かぎ":"鍵","みず":"水","ゆび":"指","かぜ":"風","ひだり":"左","でぐち":"出口","ぶた":"豚","さんぽ":"散歩","てんぷら":"天ぷら","えんぴつ":"鉛筆","だれ":"誰",
 "きゃく":"客","しゃしん":"写真","おちゃ":"お茶","じしょ":"辞書","ひゃく":"百","いしゃ":"医者","でんしゃ":"電車","かいしゃ":"会社",
 "きって":"切手","きっぷ":"切符","ざっし":"雑誌","みっつ":"三つ","にっき":"日記",
 "おかあさん":"お母さん","おにいさん":"お兄さん","くうき":"空気","がっこう":"学校","せんせい":"先生","とけい":"時計","ひこうき":"飛行機",
 "わたしは":"私は","がっこうへ":"学校へ","みずを":"水を",
 "あかい ねこ":"赤い猫","ひとの かさ":"人の傘","あめの まち":"雨の町","やまの うえ":"山の上","さくらの いろ":"桜の色","わたしの ほん":"私の本",
 "ひだりの でぐち":"左の出口","でんしゃの きっぷ":"電車の切符","これは ほんです":"これは本です","がっこうへ いきます":"学校へ行きます","みずを のみます":"水を飲みます",
 "ネクタイを かいます":"ネクタイを買います","よろしくおねがいします":"よろしくお願いします","おつかれさまです":"お疲れ様です","ごくろうさまです":"ご苦労様です",
 "はじめまして。キムです。よろしくおねがいします。":"はじめまして。キムです。よろしくお願いします。",
}
# 엔진이 다르게 읽는 것은 가나 표기(AquesTalk식, ' 가 억양 자리)로 고정한다
FIXED = {"にほん": "ニホ'ン", "ヲ": "オ'"}
kata = lambda s: ''.join(chr(ord(c) + 0x60) if 'ぁ' <= c <= 'ゖ' else c for c in s)
hira = lambda s: ''.join(chr(ord(c) - 0x60) if 'ァ' <= c <= 'ヶ' else c for c in s)

VOW = {}
for row, v in zip(["アカサタナハマヤラワガザダバパァャヮ", "イキシチニヒミリギジヂビピィ", "ウクスツヌフムユルグズヅブプゥュヴ", "エケセテネヘメレゲゼデベペェ", "オコソトノホモヨロヲゴゾドボポォョ"], "アイウエオ"):
    for c in row: VOW[c] = v

def expected(t):
    """글을 실제로 들리는 가나로: 조사 は·へ·を, 긴소리(ー, おう, えい)를 소리대로."""
    s = re.sub(r"[。、？！\s]", " ", t).strip()
    words = s.split()
    out = []
    for i, w in enumerate(words):
        if len(words) > 1 or len(w) > 2:
            if w.endswith("は") and w not in ("は",): w = w[:-1] + "わ"
            elif w.endswith("へ") and len(w) > 1: w = w[:-1] + "え"
        w = w.replace("を", "お")
        res = []   # 긴소리는 단어 안에서만 본다
        for c in kata(w):
            pv = VOW.get(res[-1], "") if res else ""
            if c == "ー" and pv: c = pv
            elif c == "ウ" and pv == "オ": c = "オ"
            elif c == "イ" and pv == "エ": c = "エ"
            res.append(c)
        out.append("".join(res))
    return "".join(out)

ort = Onnxruntime.load_once(filename=f"{VV}/voicevox_onnxruntime-linux-x64-1.17.3/lib/libvoicevox_onnxruntime.so.1.17.3")
syn = Synthesizer(ort, OpenJtalk(f"{VV}/open_jtalk_dic_utf_8-1.11"))
with VoiceModelFile.open(f"{VV}/vvm/6.vvm") as m:
    syn.load_voice_model(m)

js = subprocess.run(["node", "-e", """
const fs=require('fs'),vm=require('vm');const c={};c.self=c;vm.createContext(c);
for (const f of process.argv.slice(1)) vm.runInContext(fs.readFileSync(f,'utf8'),c);
const N=c.NY;console.log(JSON.stringify({lessons:N.LESSONS,lite:N.LITE_LINE.audio}));
""", os.path.join(ROOT, "js/data.js"), os.path.join(ROOT, "js/lessons.js")], capture_output=True, text=True, check=True).stdout
D = json.loads(js)
units, texts = set(), set()
HIRA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
units.update(HIRA)
for L in D["lessons"]:
    units.update(L["new"])
    for a, b, _ in L.get("compare", []): units.update([a, b])
    for r in L.get("rows", []): units.update(r["units"]); texts.add(r["ex"][0])
    for g in L.get("groups", []): texts.update(i[0] for i in g["items"])
    texts.update(v[0] for v in L.get("cards", {}).values())
    for key in ("words", "read", "phrases"): texts.update(x[0] for x in L.get(key, []))
    if L.get("reward"): texts.add(L["reward"][0])

out = os.path.join(ROOT, "audio"); os.makedirs(out, exist_ok=True)
moras = lambda q: ''.join(m.text for ap in q.accent_phrases for m in ap.moras)
def save(q, name):
    q.speed_scale = 0.9; q.pre_phoneme_length = 0.12; q.post_phoneme_length = 0.15
    wav = syn.synthesis(q, STYLE)
    with tempfile.NamedTemporaryFile(suffix=".wav") as t:
        t.write(wav); t.flush()
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", t.name, "-ac", "1", "-ar", "24000", "-b:a", "48k", os.path.join(out, name)], check=True)

ROM = {}
def rom(s):
    """파일 이름: 가나를 로마자로 (겹치면 번호)"""
    base = "".join("%04x" % ord(c) if not c.isascii() else c for c in hira(s))
    return base
man, bad, made = {}, [], {}
def unit_file(u):
    h = hira(u)
    name = "k_" + rom(h) + ".mp3"
    if name not in made:
        spoken = {"を": "お", "ぢ": "じ", "づ": "ず"}.get(h, h)   # 소리가 같은 글자
        save(syn.create_audio_query_from_kana(kata(spoken) + "'", STYLE), name); made[name] = 1
    return name
for u in sorted(units):
    man["@" + u] = unit_file(u)
for t in sorted(texts):
    if t in FIXED: q = syn.create_audio_query_from_kana(FIXED[t], STYLE)
    else: q = syn.create_audio_query(KANJI.get(t, t), STYLE)
    got = moras(q)
    if t not in FIXED and got != expected(t): bad.append(f"{t}: 엔진 {got} / 기대 {expected(t)}")
    name = "w_" + rom(t.replace(" ", "_").replace("。", "")) + ".mp3"
    if len(name) > 80: name = "w_" + hashlib.md5(t.encode()).hexdigest()[:10] + ".mp3"
    save(q, name); man[t] = name
q = syn.create_audio_query(D["lite"], STYLE); save(q, "lite.mp3"); man[D["lite"]] = "lite.mp3"
if bad:
    print("❌ 읽기가 다른 글:\n" + "\n".join(bad)); sys.exit(1)

keep = set(man.values())
for f in os.listdir(out):
    if f.endswith(".mp3") and f not in keep: os.remove(os.path.join(out, f))
open(os.path.join(out, "manifest.js"), "w", encoding="utf-8").write(
    "/* 자동 생성 — tools/make_audio.py · VOICEVOX:No.7 */\nself.NY = self.NY || {};\nNY.AUDIO = " + json.dumps(man, ensure_ascii=False, indent=0) + ";\n")
print(len(units), "글자 단위 +", len(texts), "단어·문장 + Lite 1 → 파일", len(keep), "개, 읽기 대조 이상 없음")
