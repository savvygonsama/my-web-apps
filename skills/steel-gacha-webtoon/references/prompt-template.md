# ChatGPT 프롬프트 틀

**기본 형식은 '한 번에 요청'이다**(사용자가 4화부터 요청). 매 화 이 순서로 준다:
콘티 표 → 사용 순서(첨부할 것) → **전체 장면을 담은 프롬프트 한 덩어리** → 보조 문장(next scene / 합쳐졌을 때 / 한 장 다시 / 빈 말풍선 + 직접 넣을 대사) → 받은 뒤 확인할 곳.
실례: 4화 「우산」, 5화 「실눈」(`episodes.md`).

## 한 번에 요청 (기본)
```
I am making a vertical-scroll Korean webtoon. Create {K} SEPARATE images for this episode, one per scene, in order from scene 1 to scene {K}. Each scene must be its own single full-bleed portrait image (2:3, 1024x1536). NEVER combine scenes into one image, never draw a comic page with multiple panels, no panel borders. If you can only make one image per reply, make scene 1 and wait; I will type "next" for each following scene.

ATTACHED: the STYLE ANCHOR image (copy its art style) and the character sheets for {영문명들}.

STYLE LOCK (never change between scenes):
{style-lock.md의 STYLE LOCK 항목 그대로 + "- Do NOT redesign any character. When unsure, copy the attached sheet exactly."}

{필요할 때만: RAIN RULE / FLASHBACK RULE / BLACKOUT RULE / {사물}-FORM LOCKED / BABY {캐릭터} — 아래 '특수 장면 규칙'}

CHARACTERS (DO NOT MIX CHARACTERS, follow the attached sheets):
{아래 '캐릭터 문장'에서 이 화에 나오는 캐릭터만}
All are genderless.

SET(S): {무대 문장. 무대가 둘 이상이면 이름을 붙이고 장면마다 어느 무대인지 적는다}. NO readable text anywhere.

SCENES:
Scene 1 of {K}. {누가 어디서 무엇을 — 한 동작, 카메라, 표정}
Speech bubble from {NAME}: "{대사}"
Only {인물}. No other text.
...
```
보조 문장:
```
next scene. Same style as the style anchor and the previous scenes, same characters{, and the SAME {사물}-FORM as scene N}.
```
```
Stop. Make ONLY scene {n} as ONE single full-bleed image, no panels, no borders, no multiple frames. Then wait.
```
```
Redraw scene {n}. Same style as the style anchor and the previous scenes, same characters. Fix: {고칠 점}
```
```
Create the same image again with the speech bubbles left EMPTY (white, no text).
```

## 특수 장면 규칙 (필요한 화에만 넣는다)
- **RAIN RULE**: `light rain. Soft light grey sky. Rain is only thin light-grey straight lines and small splashes. Characters keep EXACTLY the same colors as in the style anchor: no blue, grey or dark tint over the characters.`
- **FLASHBACK RULE**: `mark the flashback only with a soft cream rounded vignette around the image edges. {빛·불 색} may glow, but the characters keep their own flat colors; do not tint them.`
- **BLACKOUT RULE**: `the room becomes dark, a deep navy blue background. Characters are still readable as simple dark shapes with faint outlines. Only what the scene says glows.`
- **{사물}-FORM — LOCKED**: 번호 매긴 구성(손잡이 1, 살 정확히 4개 …), "Scene N DEFINES this form", 이후 장면은 "copy it exactly from scene N", 그리기 전 체크리스트 한 줄. (4화 우산)
- **BABY {캐릭터}**: 같은 디자인을 더 작고 둥글게(약 1.6등신), 같은 볏·조끼·엠블럼. 눈 모양 등 그 장면에서 달라야 할 점만 따로 적는다. (5화 아기 포오)

## (예전 방식) 한 장씩 보내기
한 번에 요청이 잘 안 될 때만 쓴다.

## 사용 순서 (사용자에게 그대로 안내)
1. ChatGPT 프로젝트 「스틸가챠s 작화」 안에서 새 채팅을 연다(없으면 새 채팅).
2. **화풍 기준판 + 그 화에 나오는 캐릭터 시트**를 첨부하고 [0]을 보낸다. 직전 화 그림은 첨부하지 않는다.
3. 같은 채팅에서 [1]~[N]을 하나씩 보낸다.
4. 그림 대신 글만 오면 "Please generate the image now."

## [0] 시작 메시지
```
I am making a vertical-scroll Korean webtoon. Episode {N} has {K} scenes. In each of my next messages I will ask for ONE image showing ONE single scene. Do not create any image now; just reply "ready".

ATTACHED: the STYLE ANCHOR image and the character sheets for {등장 캐릭터 영문명}.

{STYLE LOCK v1 문단 — style-lock.md에서 글자 그대로}

CHARACTERS (DO NOT MIX CHARACTERS, follow the attached sheets):
{아래 '캐릭터 문장'에서 이 화에 나오는 캐릭터만}
All characters are genderless.

SET for every image: {무대 문장}. NO readable text anywhere.
```

## 장면 메시지
```
Create an image. Scene {n} of {K}. Same style as the STYLE ANCHOR{n>1이면: " and scene 1"}.
{누가 어디서 무엇을 — 한 동작. 카메라(기본 waist-up medium shot). 표정.}
Speech bubble from {NAME}: "{대사}"
{첫 등장이면: A small rectangular name tag in a lower corner: "{이름 · 소재}".}
Only {등장 인물}. No other text.
```
- 대사 없는 컷: `NO speech bubbles, NO text at all.`
- 이지가 나오면 매번 `EG front-facing, TEAL half on the viewer's LEFT`.
- 위치 관계가 펀치에 중요하면 viewer's LEFT/RIGHT로 못 박는다.
- '위 절반/아래 절반' 같은 화면 분할 지시는 칸 나누기로 읽히니 쓰지 않는다.

## 다시 그리기·빈 말풍선
```
Create the image for scene {n} again. Same style as the STYLE ANCHOR, same set and characters. Fix: {고칠 점}
```
```
Create the same image again with the speech bubbles and name tag left EMPTY (white, no text).
```
빈 말풍선으로 받으면 사용자가 직접 넣을 대사 목록을 함께 준다.

## 캐릭터 문장 (영문, 그대로 재사용)
- PO: light silver-grey body, ONE teardrop-shaped crest on top whose tip curls backward, light face plate, sleepy half-closed eyes, flat mouth. Red vest with a round emblem.
- SSIAL: light silver-grey body, a low side-swept crest like a swoop of bangs, light face plate, determined slanted eyebrows. Blue vest with a round emblem of four small circles and one bar.
- DOGEUM: WARM grey body, smooth round dome helmet with NO crest and a raised headband rim, light face plate, relaxed lowered eyelids, very wide smile. Purple vest with a hexagon emblem with three horizontal stripes.
- EG: NO vest. Body split vertically down the exact middle into a flat TEAL half (#2A8F96) and a flat MATTE GREY half (#A3A9B0); in a front view the TEAL half is on the viewer's LEFT. Rounded-square head split the same way, light face plate, a small binder clip on top of the head, small round fuel cap on the teal-side shoulder. Polite smile. Slightly shorter than the others.
- TARAE: a wire-person made of dark charcoal wire (#5F646B) with a light-grey round head. The head floats in the CENTER of one large wire ring; TWO short STRAIGHT wire struts connect the top of the head to the top of the ring (they are struts, NOT antennae, and have NO balls on the ends). Plain small dot eyes and a small simple smile (no sparkles in the eyes). The ring sits on top of a coil-spring torso of about 4-5 stacked turns, with a small bronze spiral swirl (#A0722A) on the lower right of the coil. Each arm is ONE thin straight wire ending in a round light-grey ball hand. Two thin straight wire legs ending in flat round wire-ring feet. Same height as PO (top of the ring level with the top of PO's crest).

**캐릭터 문장은 원본 피규어와 캐릭터 시트에서만 가져온다.** 완성된 에피소드 그림(이미 조금 흐트러졌을 수 있음)을 보고 고치지 않는다. 4화 초안에서 타래가 '공 달린 더듬이·반짝이 눈'으로 그려진 건 3화 시안 그림을 보고 쓴 문장 탓이었다.

새 조연은 `art-prompts.md`의 시트 프롬프트로 시트를 먼저 만들고, 같은 형식의 한 줄을 여기에 추가한다.

## 무대 문장
- 야외 마당(새 기본 야외): `an outdoor yard between the flat-steel building and the wire-rod building in daytime: light grey concrete ground, a low wire-mesh fence dividing the two sides, the edge of a roofed shipping bay in the background with a few wrapped steel coils on V-shaped saddles, a few trees, soft natural light`
- 견본실(기본): `a small, cozy steel sample room in daytime: light beige walls, wooden wall shelves with small flat steel sample plates and a few mini coils, a wooden work table with a teapot and cups, a window with soft daylight, a plain door on the left wall`
- 사무실: `a bright office desk area in daytime: light grey-blue wall, wide window with pale blue sky, plain white desk with a light wood edge, black office chair`
- 컨벤션 홀 등록 로비(특별편 1): `the registration hall of a large international convention center in daytime: a tall high ceiling with rows of flat white panel lights, a huge floor-to-ceiling glass curtain wall with soft daylight, light grey polished floor with a plain pale carpet runner, a long white registration counter with lanyard name tags and a small coil decoration, tall blank roll-up banners and a plain white welcome gate with NO text, black stanchion posts with belt ropes forming a queue lane, a few tall green potted plants. Spacious and open. No cars.` 행사장 느낌이 필요하면 STYLE LOCK의 '소품 5개 이하'를 이 화만 7개까지 풀되 모두 단순하게. 실제 건물·간판·로고는 그리지 않는다.
- 고깃집(2화): `a cozy Korean BBQ restaurant: round table with a built-in grill, silver exhaust duct above, side dishes, lettuce basket, stainless water jug, plain warm beige wall` + `soft neutral lighting; characters keep their daytime colors`
