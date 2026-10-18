# 작화 프롬프트 (ChatGPT 이미지 생성용)

## 작화 원칙
1. 3D 비닐 피규어를 **2D 평면 캐릭터**로 단순화한다. 머리 모양·볏·조끼·가슴 엠블럼·벙어리장갑 손·뭉툭한 장화는 살리고, 금속 광택·무지개빛·질감·반사는 뺀다.
2. 선은 짙은 숯색 #2B2F36 한 가지. 바깥 윤곽은 중간 굵기, 안쪽 선은 가늘게.
3. 평면 채색만. 그러데이션·하이라이트 없음, 그림자는 발밑 납작한 타원 하나.
4. 2~2.5등신. 얼굴은 점 눈 + 짧은 입선. 표정은 눈꺼풀·눈썹·입 모양으로만.
5. 컷은 **2×2 세로 한 장(2:3)**, 읽는 순서 Z. 컷이 커서 얼굴이 덜 뭉개지고 휴대폰 한 화면에 들어온다.
6. 컷당 인물 2명 이하, 배경은 단색 + 소품 1~2개, 한 컷에 행동 하나. 한 컷에 공간 요구(클로즈업 + 큰 효과 + 다른 인물 전신 + 말풍선)를 겹치지 않는다.
7. 영어 프롬프트에서 캐릭터를 he/she로 부르지 않고 **이름**으로 부른다.
8. 금지: 실존 로고·브랜드, 특정 작가 화풍 지정, 사실적 금속 렌더링, 복잡한 공장 배경.

## 팔레트
| 용도 | 색 |
|---|---|
| 포오 빨강 조끼 | #BE473D |
| 씨알 파랑 조끼 | #2A6DA8 |
| 도금이 보라 조끼 | #7C5D91 (몸은 따뜻한 회색 #B9B2A8) |
| 이지 청록 / 무광 회색 | #2A8F96 / #A3A9B0 |
| 타래 철사 / 소용돌이 | #5F646B / #A0722A |
| 큐피 남색 / 리본 | #3F428F / #D9DEE3 |
| 꼿꼿이 몸 | #5B6675 |
| 은색 몸체 / 얼굴판 | #C5CBD2 / #EEF0F2 |
| 벽 / 테이블 / 바닥 / 노란 보행선 | #E3E9EF / #D8C9B0 / #D0D5DA / #E8C547 |
| 밤 벽 / 맑은 하늘 / 비 하늘 | #2E3A55 / #BFE0F2 / #9AA4AE |
| 기름 틴트 | #E7B65C (반투명, 물기는 흰 김 선으로만 표현해 구분) |

## 상대 키 (모든 에피소드 프롬프트 LAYOUT에 한 줄 넣기)
`PO, SSIAL and DOGEUM are the same height. EG is slightly shorter. The top of TARAE's head ring is level with the top of PO's crest. KKOTKKOT is half a head taller than PO.`

## 원본 그림 (시트 프롬프트에 첨부)
`steel-grade-gacha/src/img/` — 포오 `poo.jpg` · 씨알 `ssial.jpg` · 도금이 `dogeum.jpg` · 이지 `eg_secc.jpg` · 타래 `wr_swrm.jpg` · 꼿꼿이 `c_mart.jpg` · 큐피 `qp_1470.jpg` · 말랑이 `c_bh.jpg` · 동안이 `c_eddq.jpg`

## 캐릭터 시트
모두 새 메시지로 하나씩 보내고 원본 그림을 첨부한다. 마음에 드는 시트는 저장해 두고 이후 화마다 첨부한다.

공통 머리말(각 시트 맨 앞에 붙는 STYLE 블록):
```
STYLE: simple 2D webtoon character art, flattened from the attached vinyl toy figure. Clean uniform dark charcoal outlines (#2B2F36), flat colors only, no gradients, no metallic shine, no texture, no 3D rendering, only one flat oval shadow under the feet. Chibi proportions about 2.2 heads tall: big head, small body, rounded mitten hands, short stubby boots. Simple face: dot eyes and a short mouth line. No logos, no brand names, no text except the name label.
```

### 포오 (poo.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named PO. Landscape image (3:2), plain off-white background.

[STYLE block]

CHARACTER PO:
- Body: light silver-grey (#C5CBD2), smooth and simple.
- Head: hooded round head with a lighter rounded-rectangle face plate (#EEF0F2). On top sits ONE teardrop-shaped crest, like a water drop, whose tip curls slightly backward. This crest is PO's main identifier.
- Face: sleepy half-closed eyes (dot eyes with a flat eyelid line across the top), a flat straight mouth line. Calm, unbothered.
- Outfit: sleeveless red vest (#BE473D) with a V-shaped collar and a V-pointed bottom hem. Round chest emblem split vertically: left half dark charcoal with two small crack lines, right half silver, a small droplet shape in the center.
- Default pose: standing relaxed, arms hanging, slightly slouched.
Follow the attached photo's silhouette, crest shape and emblem, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view, side view (facing right, crest curl visible), back view, and one small front view WITHOUT the vest (silver body only, same crest, same sleepy face).
Bottom row, head-and-shoulders, 4 expressions: (1) sleepy deadpan, (2) relieved, eyes closed as soft arcs, a few steam lines, (3) mild surprise, eyes as small round dots, mouth still flat, (4) flat tired deadpan with a small towel on the head.
Small label "PO" at the top. Keep every view consistent.
```

### 씨알 (ssial.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named SSIAL. Landscape image (3:2), plain off-white background.

[STYLE block] Same height as PO.

CHARACTER SSIAL:
- Body: light silver-grey (#C5CBD2), neat and tidy looking.
- Head: round hooded head with a lighter rounded-rectangle face plate (#EEF0F2). On top, a low side-swept crest shaped like a swoop of bangs, sweeping from the front-left over to the back-right. This crest is SSIAL's main identifier, and it identifies SSIAL even without the vest.
- Face: dot eyes with short slanted determined eyebrows, a small confident smile.
- Outfit: sleeveless blue vest (#2A6DA8), V collar, V-pointed hem. Round chest emblem: four small circles (two on top, two on the bottom) with one horizontal bar through the middle, like rollers pressing a sheet.
- Default pose: BOTH HANDS ON HIPS, chest a little forward, proud.
Follow the attached photo's silhouette, crest shape and emblem, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view (hands on hips), side view (crest sweep visible), back view, and one small front view WITHOUT the vest (silver body, same crest, still hands on hips).
Bottom row, 4 expressions: (1) proud default, (2) overreaction panic: eyes as wide circles, mouth wide open, eyebrows high, (3) fired-up: small flames in the eyes, one sweat drop, (4) pleased but hiding it: eyes closed, mouth corners clearly up.
Small label "SSIAL" at the top. Keep every view consistent.
```

### 도금이 (dogeum.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named DOGEUM. Landscape image (3:2), plain off-white background.

[STYLE block] Same height as PO.

CHARACTER DOGEUM:
- Body: warm grey (#B9B2A8), a little warmer than the other silver characters.
- Head: a perfectly smooth round dome helmet with NO crest at all, and one raised band running around the forehead like a headband rim. A lighter rounded-rectangle face plate (#EEF0F2) below the band. The crest-less dome plus the band is DOGEUM's main identifier.
- Face: relaxed eyes with lowered lids, and a very wide U-shaped smile that spans most of the face plate.
- Outfit: sleeveless purple vest (#7C5D91), V collar, V-pointed hem. Chest emblem: a hexagon with THREE thin horizontal stripes inside (light, dark, light) like coating layers on both sides of a sheet.
- Default pose: standing calm, arms relaxed, leaning back slightly, unhurried.
Follow the attached photo's silhouette, helmet band and emblem, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view, side view, back view, and one small front view WITHOUT the vest.
Bottom row, 4 expressions: (1) relaxed big smile, (2) happy, eyes closed as upside-down arcs, (3) deeply moved: sparkly eyes, one small tear, hands clasped, (4) blank little "ah" face: dot eyes, small round mouth.
Small label "DOGEUM" at the top. Keep every view consistent.
```

### 이지 (eg_secc.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named EG. Landscape image (3:2), plain off-white background.

[STYLE block] No iridescence. About 2 heads tall, slightly shorter than PO.

CHARACTER EG:
- No vest. EG's whole body is split vertically down the exact middle into a flat TEAL half (#2A8F96) and a flat MATTE GREY half (#A3A9B0). In the front view the TEAL half is on the viewer's LEFT. This split is EG's main identifier and must be identical in every view.
- Head: rounded-square head split the same way, with a light face plate (#EEF0F2) across both halves. A small binder clip on top of the head.
- Face: the eye on the teal side is a teal oval, the eye on the grey side is a dark charcoal oval. A small polite smile.
- Body: round egg-shaped torso with two shallow diagonal groove lines, short legs (teal leg on the teal side, grey leg on the grey side). A small round fuel-cap shape on the TEAL-side shoulder.
- Default pose: polite, standing slightly turned so the teal side faces forward, one hand lightly raised.
Follow the attached photo's silhouette, clip, fuel cap and color split, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view, side view showing ONLY the teal side, side view showing ONLY the grey side, back view.
Bottom row, 4 expressions: (1) polite smile, (2) calm smile, eyes closed as arcs, (3) bright work-mode smile in 3/4 view with the teal side forward and a small sparkle, (4) off-duty face: grey side forward, calm soft eyes, a gentle comfortable smile, NOT sleepy.
Small label "EG" at the top. Keep the split, clip and fuel cap consistent.
```

### 타래 (wr_swrm.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named TARAE. Landscape image (3:2), plain off-white background.

STYLE: simple 2D webtoon character art, flattened from the attached bent-wire toy figure. Clean dark charcoal outlines (#2B2F36), flat colors only, no gradients, no metallic shine, no texture, one flat oval shadow under the feet. About 2.5 heads tall. No logos, no text except the name label.

CHARACTER TARAE:
- A little person made of bent steel wire, drawn as clean THICK wire lines in dark steel grey (#5F646B) so TARAE stays readable when small.
- Head: a small solid ball head (#C5CBD2) inside a much bigger thin wire RING, with two short antenna wires connecting the top of the ball to the top of the ring. The ring-around-the-head is TARAE's main identifier. The top of the ring is level with the top of PO's crest.
- Torso: a coil spring of 4 loops, with one small flat bronze spiral (#A0722A) on the belly.
- Arms: single wire sticks with small ball hands. Legs: single wire sticks ending in small ring loops as feet.
- Face: dot eyes, small happy smile.
- Default pose: cheerful, one arm raised in a wave.
Follow the attached photo's silhouette, ring, coil and spiral, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view, side view, back view, and a HANGER POSE: standing stiff with both arms stretched sideways and slanted down like the shoulders of a clothes hanger, the head ring on top acting as the hanger hook.
Bottom row, 4 expressions: (1) happy grin, (2) curious head tilt with a "?" above, (3) dizzy with spiral eyes and the coil a little tangled, (4) the top of the ball head slightly flattened, surprised but happy.
Small label "TARAE" at the top. Keep ring, coil, spiral and wire thickness consistent.
```

### 꼿꼿이 (c_mart.jpg)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named KKOTKKOT. Landscape image (3:2), plain off-white background.

[STYLE block] About 2.3 heads tall, half a head TALLER than PO.

CHARACTER KKOTKKOT:
- Perfectly rigid, ruler-straight posture: back, neck and arms never bend. Arms hang stiff and straight.
- Head: a faceted, angular helmet cut like a gem, with an octagonal light face plate (#EEF0F2). The gem-cut helmet is KKOTKKOT's main identifier.
- Body: dark slate grey (#5B6675) made of flat angular plates.
- Face: small dark oval eyes, two short THICK STRAIGHT EYEBROWS (the main expression tool), a tiny dash mouth. Serious but kind.
- Outfit: the same sleeveless blue vest (#2A6DA8) and roller emblem as SSIAL, plus a small rectangular badge on the CHEST reading "1470M".
Follow the attached photo's helmet and body shapes, redraw as flat 2D, and add the vest and badge.

SHEET LAYOUT:
Top row, full body: front view, side view (perfectly straight line from head to heels), back view, one small front view WITHOUT the vest.
Bottom row, 4 expressions: (1) neutral serious, (2) BIG SURPRISE in 3/4 view: both eyes large round circles AND both eyebrows shot up high together, innocent, (3) straining: red blush on the face plate, trembling lines, three sweat drops, (4) THE EYEBROW FLICK: one eyebrow raised a tiny amount, the rest of the face unchanged.
Small label "KKOTKKOT" at the top. Keep every view consistent.
```

### 큐피 (qp_1470.jpg · 나중용)
```
Create a CHARACTER SHEET for a 4-panel webtoon character named QP. Landscape image (3:2), plain off-white background.

[STYLE block] Slimmer chibi about 2.5 heads tall.

CHARACTER QP:
- Hood: deep indigo-navy (#3F428F) hood of flat folded angular plates, ending in a pointed tip that curls backward. Main identifier.
- Face: smooth light silver face (#EEF0F2), large dark oval eyes, one calm eyebrow, a gentle small smile.
- Body: angular indigo plate armor, a thin silver collar ring, a small blue diamond gem on the chest.
- Ribbon: one long flat silver ribbon (#D9DEE3) spiraling around the body, one end trailing and curling from the right hand. Second identifier.
Follow the attached photo's hood, plates, ribbon and gem, but redraw it as flat 2D.

SHEET LAYOUT:
Top row, full body: front view, side view, back view, and a CAMEO CROP: only the curling ribbon end peeking in from the edge of a blank panel.
Bottom row, 4 expressions: (1) calm gentle smile, (2) serene, eyes closed, (3) small knowing smile, one eyebrow raised, (4) politely puzzled.
Small label "QP" at the top. Keep every view consistent.
```

## 배경 3개
### 견본실 SAMPLE ROOM (대화 기본)
```
Create a background plate named SAMPLE ROOM for a 4-panel webtoon. Square image, no characters.
Style: same flat 2D style as the character sheets: clean dark charcoal outlines (#2B2F36), flat colors only, no gradients, no texture, no clutter.
Contents: a plain flat pale blue-grey wall (#E3E9EF) filling most of the frame, a simple floor line near the bottom (#D0D5DA). One small square table in light beige (#D8C9B0), seen from the front, slightly right of center. On the table, ONE small white electric kettle. Nothing else: no windows, no posters, no shelves, no logos, no text.
```

### 출하동 셔터 앞 SHIPPING BAY (계절·날씨)
```
Create a background plate named SHIPPING BAY for a 4-panel webtoon. Square image, no characters.
Style: same flat 2D style: clean dark charcoal outlines, flat colors only, no gradients, no texture, no clutter.
Contents: INSIDE a roofed shipping building. A flat light grey floor (#D0D5DA) with ONE straight yellow walkway line (#E8C547). In the back wall, one wide open roll-up shutter; through the opening only a flat patch of sky (#BFE0F2) is visible. Slightly left of center, ONE steel coil standing on its edge on a low V-shaped steel saddle (cradle) so it cannot roll: a light grey circle (#C5CBD2) with a few concentric lines and a hole in the middle. The coil is on the far side of the yellow line; characters will stand on the near side. Nothing else: no trucks, no cranes, no logos, no text.
Weather variant: same scene, but the sky patch through the shutter is grey (#9AA4AE) with simple diagonal rain strokes ONLY outside the opening; the floor and coil inside stay dry.
```

### 도감판 벽 COLLECTION BOARD (앱·큐피)
```
Create a background plate named COLLECTION BOARD for a 4-panel webtoon. Square image, no characters.
Style: same flat 2D style: clean dark charcoal outlines, flat colors only, no gradients, no texture.
Contents: a plain flat pale blue-grey wall (#E3E9EF) with ONE large rectangular board in the upper half (off-white #F2F5F8, frame #8593A2), divided into a 4 x 3 grid. Each cell holds a plain grey silhouette of a small round chibi figure. The bottom-right cell is empty except for one large "?" mark. Floor line near the bottom (#D0D5DA). No logos, no text other than the "?".
Night variant: same scene, wall flat deep navy (#2E3A55), board slightly dimmer.
```

## 에피소드 프롬프트 틀
```
Create EPISODE N of the 4-panel webtoon as ONE portrait image (2:3).

LAYOUT: 4 equal panels in a 2x2 grid, read left-to-right then top-to-bottom (panel 1 top-left, 2 top-right, 3 bottom-left, 4 bottom-right). Thin solid black panel borders, white gutters. Maximum 2 characters per panel. Background in every panel: the [PLATE NAME] plate (attached), nothing added. [상대 키 한 줄]
CHARACTERS: draw [NAMES] EXACTLY as in the attached character sheets: same head shape, crest, face, vest color, emblem and proportions.
STYLE: simple flat 2D webtoon, clean dark charcoal outlines, flat colors, no gradients, no metallic shine, no texture, one flat shadow under feet.
TEXT: write the Korean dialogue inside white oval speech bubbles (thin black outline, short tail) exactly as given, in clean rounded Korean lettering. [첫 등장 캐릭터가 있으면] Panel X also has one small white caption box with the text given. No other text anywhere.

PANEL 1: [누가 · 어디 · 동작 하나 · 표정]. Speech bubble [위치], tail to [NAME]: "[대사]" [Caption box: "이름 · 소재"]
PANEL 2: ...
PANEL 3: ...
PANEL 4 (PUNCH): ...
```
컷 지시는 카메라 기준을 분명히(누구 어깨 너머인지, 보는 사람 기준 왼쪽/오른쪽). 펀치 컷은 공간을 나눠 적는다(예: 얼굴 아래 2/3, 효과선 위 띠, 다른 인물은 가장자리 일부).

## 함께 주는 보조 문장
글자가 깨질 때(④ 끝에 붙여 다시 생성 → 대사는 편집 앱으로 직접):
```
Leave all speech bubbles and caption boxes completely empty: no letters, no scribbles. Do not draw any text anywhere.
```
한 컷만 다시:
```
Redraw only panel N. Keep the other panels exactly as they are. Make [NAME] match the attached character sheet exactly: [식별 키].
```
새 대화창에서 이어 할 때(저장한 시트·배경을 먼저 첨부):
```
These are the fixed character sheets and background. Use them exactly.
```

## ChatGPT 사용 순서
1. 새 대화창 하나. 그 화에 필요한 캐릭터 시트만 원본 그림을 첨부해 하나씩 뽑는다(화별 최소 경로).
2. 그 화의 배경판 하나를 뽑는다.
3. 에피소드 프롬프트를 보낸다. 새 창이면 저장한 시트·배경을 직접 첨부한다.
4. 얼굴이 흔들리면 '한 컷만 다시' 문장. 부분 선택 편집이 있으면 그 컷만 선택해서.
5. 대사는 이미지에 넣는 쪽을 먼저 시도하고, 깨지면 빈 말풍선으로 받아 둥근 고딕 하나로 직접 넣는다.

## 2026-10 확정판 메모
2~5화에 실제로 쓴 시트·배경·에피소드 프롬프트(출하동은 뒷벽 쪽문 + 방청지 포장 코일 + 결속 밴드 + V자 받침, 견본실 벽시계 변형, 이지 시트 표정 (4) 편안한 퇴근 얼굴, 도금이 BOW POSE, 타래 CROUCHING POSE)는 `references/prompts/ep2-5.md`가 정본이다. 배경 프롬프트에는 변형(밤·비) 줄을 함께 넣지 않는다. 함께 넣으면 여러 장이나 변형판이 뽑힌다.
