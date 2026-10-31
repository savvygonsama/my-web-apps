# ChatGPT 프롬프트 틀

매 화 이 순서로 준다: 콘티 표 → 사용 순서 → [0] → [1]~[N] → 다시 그리기 → 빈 말풍선 → 미리 알아 둘 점.
실례: 3화 「반반 식구」, 4화 「볼트 하나」(`episodes.md`).

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
- 고깃집(2화): `a cozy Korean BBQ restaurant: round table with a built-in grill, silver exhaust duct above, side dishes, lettuce basket, stainless water jug, plain warm beige wall` + `soft neutral lighting; characters keep their daytime colors`
