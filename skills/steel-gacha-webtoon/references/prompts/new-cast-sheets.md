# 신캐릭터 2D 시트 프롬프트 (신입사원 3인방: 꼿꼿이 · 알시 · 후끈이)

- 도구: Gemini 「스틸가챠s 작화」 Gem (STYLE LOCK G1이 지침에 들어 있음).
- 첨부: 그 캐릭터의 `SHEETREF_*.jpg` **한 장만**. 보드 위쪽 = 앱 피규어(디자인 원본), 아래쪽 = 기존 가족 시트(배치·그림체 견본).
- 한 채팅에 한 캐릭터. 어긋나면 "Edit the attached image. Keep EVERYTHING exactly the same, and change ONLY this: …"로 한 가지씩 고친다.
- **신입사원 3인방(사용자 지시, 2026-11-28)**: 꼿꼿이·알시·후끈이만 신입으로 먼저 등장. **큐피는 나중에**(신입 아님, 사원증 없음, 시트도 그때 그린다). 앱 피규어에 조끼가 없으니 **조끼를 입히지 않는다.** 신입 표시는 목에 건 **사원증 하나**뿐(줄 색 = 집 색: 꼿꼿이 파랑, 알시 보라, 후끈이 빨강. 카드 글자 = 등급). **가슴 로고(엠블럼)는 셋 다 피규어 그대로 유지**하고 사원증은 그 아래 배 높이에 단다.
- 결과 파일 이름: `s00-kkot.webp`, `s00-alsi.webp`, `s00-hukkeun.webp`, `s00-qp.webp` (1200×800, 기존 시트와 같은 규격).

## 공통 머리말 (네 프롬프트 맨 앞에 똑같이 붙는다)

```
TASK: a 2D CHARACTER SHEET for a NEW character of my webtoon. This is a character sheet, not a webtoon page: for this image only, use LANDSCAPE 3:2 (1536x1024) instead of the 2:3 portrait rule. Every other STYLE LOCK G1 rule stays.

ATTACHED BOARD — read it like this:
- TOP PART = the official 3D figurine of the new character. It is the DESIGN SOURCE: copy its silhouette, helmet shape, body parts, chest emblem and colors. But do NOT copy its 3D look: no metal shine, no reflections, no scratches, no texture, no gradients, no photo lighting.
- BOTTOM PART = an existing 2D sheet of a DIFFERENT character. It is ONLY the LAYOUT and DRAWING-STYLE example: copy its cream background, line weight, flat colors, chibi proportions, label pills and grid. Do NOT draw that character, do NOT copy its vest, head or face. The new character wears NO VEST.

LAYOUT (copy the bottom example exactly):
- Background flat cream #F7F3EA. Top center: one rounded title pill with the name in bold dark capitals, thin lines on both sides.
- TOP ROW: 4 full-body views standing on one baseline, same size, each with a small rounded label pill under it.
- One thin grey divider line.
- BOTTOM ROW: 4 head-and-shoulders expression busts in 4 equal boxes split by thin grey lines, each with a small rounded label pill under it.
- The only text in the image: the title, the 8 labels, and the ID card text I give. Nothing else.

NEW EMPLOYEE ITEM (all new characters): the character is a NEW EMPLOYEE on its first weeks. It wears NO VEST — keep the figurine's own body design. Its only added item: a thin lanyard strap around the neck holding a small white rectangular employee ID card on the chest (card about the size of the face plate's width, a small flat grey square photo area at the top, the text I give below it). Strap color as I give. The card hangs straight and is visible in FRONT and SIDE views; in BACK view only the strap shows around the neck.

CHEST LOGO STAYS: the figurine's chest emblem (logo) is part of the character. Keep its exact shape and colors, flat, in the middle of the chest, FULLY VISIBLE in every front-facing view and in every expression bust (crop the busts low enough to show it). The ID card hangs LOWER, at belly level, and never covers or replaces the emblem.

DRAWING: flat 2D chibi, about 2.2 heads tall, mitten hands with no fingers, stubby legs, small solid black dot eyes (unless I say otherwise), one short mouth line, light face plate #EEF0F2. One uniform dark charcoal outline #2B2F36, thin-to-medium, same weight everywhere. Flat soft colors close to the bottom example's saturation. The only shadow is one soft flat oval under the feet.
```

## 1. 꼿꼿이 (씨알네 1470M) — 첨부 `SHEETREF_KKOTKKOTI.jpg`

```
[공통 머리말 붙이기]

CHARACTER: KKOTKKOTI — a new employee from the cold-rolled family. The strongest one, but its body cannot bend at all. It never bows at the waist; it bows with its eyebrows only. Serious, polite, stiff, very formal like a rookie on day one.

DESIGN (translate the top figurine into flat 2D):
- Body and helmet: dark steel navy #4A5A72, drawn as FLAT FACETS — the helmet and limbs are made of straight-edged flat planes separated by thin outline lines, like a cut gem. Two flat tones only: facets #4A5A72 and #5E6E86. No shine.
- Helmet: angular faceted dome that frames a RECTANGULAR light face plate #EEF0F2 with slightly rounded corners.
- Face: two small black dot eyes, one tiny straight mouth line, and TWO THICK STRAIGHT HORIZONTAL EYEBROWS (short black bars) above the eyes. The eyebrows are its key feature: always visible, always straight unless the label says otherwise.
- Chest: a round light-grey emblem #C5CBD2 with one horizontal bar and small dots (copy the figurine's emblem), drawn flat on the body.
- NO VEST. New employee lanyard: strap blue #2A6DA8, ID card text "1470M". The ID card hangs at belly level, well below the chest emblem; the emblem stays fully visible.
- Hands and feet: blocky mittens and blocky boots with flat facets.
- Pose rule: perfectly upright, back straight like a ruler, arms straight down at the sides, legs straight. Even in action it stays straight.

TITLE PILL: KKOTKKOTI

TOP ROW (left to right):
1. FRONT — standing at attention, arms straight down, ID card hanging perfectly straight.
2. SIDE (RIGHT) — facing the viewer's right, body a perfectly straight vertical line.
3. BACK — back view, faceted helmet back and faceted back, lanyard strap around the neck.
4. EYEBROW BOW — body exactly as straight as FRONT, NOT bent at all; only the two eyebrows tilt down toward the middle, eyes closed as two short lines.

BOTTOM ROW (left to right):
1. SERIOUS — straight eyebrows, straight mouth.
2. EYEBROW BOW — eyebrows tilted down, eyes closed lines.
3. SMALL SMILE — eyebrows raised just a little, tiny curved smile.
4. STUCK — eyes wide round dots, mouth a small wavy line, eyebrows pushed up high (it tried to bend and could not).

DO NOT: no vest, no bending at the waist anywhere, no round soft body, no rounded helmet, no metallic shine, no robot details (no bolts, antennas, screens), no extra text, no other characters.
```

## 2. 알시 (도금이네 1470H, Al-Si 핫프레스포밍) — 첨부 `SHEETREF_ALSI.jpg`

```
[공통 머리말 붙이기]

CHARACTER: ALSI — a new employee, cousin of the galvanized family. Same family, different outfit: its coating is aluminium-silicon, not zinc, and it is very proud of that "outfit". Confident, a little vain, cheerful: the rookie who cares most about its work outfit. It goes into a hot furnace and comes out dark bronze.

DESIGN (translate the top figurines into flat 2D):
- BEFORE HEATING (main look): round smooth body suit in flat light silver #C5CBD2, one flat tone, no shine. Round dome helmet in the same silver with THIN PURPLE SEAM LINES #7C5D91 (one line around the face opening, one line over the top). Round light face plate #EEF0F2.
- Face: small black dot eyes, small happy mouth. No eyebrows.
- Chest: a flat HEXAGON emblem (light grey #E3E6EA with one dark horizontal bar), copied from the figurine.
- NO VEST: the silver suit IS its outfit and must stay fully visible. New employee lanyard: strap purple #7C5D91, ID card text "1470H". The ID card hangs at belly level, well below the hexagon emblem; the emblem stays fully visible.
- Thin purple seam lines also at the wrists, waist and ankles.
- AFTER HEATING (only in pose 4): the same character and pose shape, but the suit and helmet become flat dark bronze #5A4E4B and every seam line becomes copper orange #C9733A. Lanyard stays purple, ID card stays white. Face plate stays light.

TITLE PILL: ALSI

TOP ROW (left to right):
1. FRONT — standing, one mitten hand lightly patting its own silver sleeve, proud small smile.
2. SIDE (RIGHT) — facing the viewer's right, chin slightly up.
3. BACK — back view, seam line over the helmet top and down the back, lanyard strap around the neck.
4. AFTER HEATING — the dark bronze version with copper seams, standing strong, both fists on its hips, hexagon emblem fully visible.

BOTTOM ROW (left to right):
1. PROUD — chin up, eyes closed as two happy curves, small smile.
2. SHOWING OFF — holding up one sleeve next to its face, wide smile.
3. POUTING — cheeks puffed, mouth a small pout (someone called its coating zinc).
4. CONFIDENT — dark bronze AFTER HEATING version, calm confident smile.

DO NOT: NO VEST, NO CAPE, NO CLOAK, NO SCARF, NO HOOD, nothing hanging from the shoulders or back except the thin lanyard strap. No zinc-grey body like the bottom example's character, no knit-cap helmet, no head band. No metallic shine, no sparkles, no extra text, no other characters.
```

## 3. 후끈이 (포오네 PHS) — 첨부 `SHEETREF_HUKKEUNI.jpg`

```
[공통 머리말 붙이기]

CHARACTER: HUKKEUNI — a new employee from the hot-rolled pickled family. Before heating it is soft, sleepy and slow, a rookie who is not awake yet. After passing through the furnace it wakes up and becomes very strong. "I only become myself after the fire."

DESIGN (translate the top figurines into flat 2D):
- BEFORE HEATING (main look): flat matte grey body #8E9196, slightly chunky and soft. Helmet with ONE RAISED RIDGE CREST running from the forehead over the top to the back (copy the figurine). Round light face plate #EEF0F2 framed by the helmet.
- Face: SLEEPY half-closed eyes drawn as two short heavy lines with a flat lid, small flat mouth. No eyebrows.
- Chest: a round emblem split vertically, left half dark #4A4D52, right half light #D9DCE0.
- NO VEST. New employee lanyard: strap red #BE473D, ID card text "PHS". The ID card hangs at belly level, well below the chest emblem; the emblem stays fully visible.
- AFTER HEATING (only in pose 4 and expression 3-4): body and helmet become flat sooty charcoal #3E3A38, all edges of helmet, shoulders, knees and boots get flat copper outlines-bands #B8693A, the eyes become two small round AMBER dots #D98A2B (this is the only exception to black eyes), the chest emblem's light half becomes copper. A few flat darker soot patches #2E2B2A on the body (flat shapes, not texture). Lanyard stays red, ID card stays white with one small flat soot patch on its corner.

TITLE PILL: HUKKEUNI

TOP ROW (left to right):
1. FRONT — before heating, standing a little slouched, arms hanging, sleepy face, ID card hanging slightly crooked.
2. SIDE (RIGHT) — before heating, facing the viewer's right, ridge crest clearly visible in profile.
3. BACK — before heating, back view, ridge crest running down the back of the helmet, lanyard strap around the neck.
4. AFTER HEATING — sooty charcoal with copper edges and amber eyes, standing tall and strong, fists at the sides.

BOTTOM ROW (left to right):
1. SLEEPY — before heating, half-closed eyes, small flat mouth.
2. YAWNING — before heating, eyes closed, mouth a small open oval.
3. AWAKENED — after heating, amber eyes, straight determined mouth.
4. SOOTY SMILE — after heating, amber eyes, small satisfied smile, one flat soot patch on the cheek of the face plate.

DO NOT: no vest, no flames, no fire, no glow, no smoke, no sparks, no glowing eyes (amber is a flat color dot). No knight armor details, no spikes, no weapons. No metallic shine, no extra text, no other characters.
```

## 나중에: 큐피 (Q&P, 히든) — 지금은 그리지 않음

신입 3인방 다음, 큐피 등장 화를 준비할 때 쓴다. 첨부 `SHEETREF_QP.jpg`. 큐피는 신입이 아니므로 사원증이 없다.

```
[공통 머리말 붙이기 — 단, NEW EMPLOYEE ITEM 문단은 지운다]

CHARACTER: QP — the hidden prototype from the research lab, nobody has met it yet. Calm, quiet, elegant, a little mysterious. It is hardened once and then treated once more, so it is strong AND stretchy. It always speaks in two beats.

DESIGN (translate the top figurine into flat 2D):
- Hood: an angular hood made of FOLDED FLAT PLATES, flat deep blue #255794 with a second flat tone #2F6AAD on some plates, with a pointed tip at the top that CURLS backward. The hood frames the face.
- Face: round silver face #D9DDE2, small black dot eyes, gentle small smile.
- Body: the same folded-plate blue #255794 suit, angular plates with straight edges.
- Ribbon: ONE flat silver ribbon #C5CBD2 with a thin outline that spirals around the body from the shoulder down to one leg, and ends in a small CURLED TIP floating near one hand.
- Chest: one small flat gem, pale blue #8FB8E0, a simple diamond shape.
- NO VEST, NO LANYARD, NO ID CARD, no badge text. The chest gem is its logo: keep it fully visible.
- Pose rule: elegant and light, one hand slightly raised, but still chibi 2.2 heads tall.

TITLE PILL: QP

TOP ROW (left to right):
1. FRONT — standing, one hand slightly raised, ribbon spiraling.
2. SIDE (RIGHT) — facing the viewer's right, hood tip curling back.
3. BACK — back view, hood folds and ribbon crossing the back.
4. RIBBON TIP ONLY — no character: only the curled silver ribbon tip peeking in from the left edge of its cell, as if the character just walked out of the frame.

BOTTOM ROW (left to right):
1. CALM SMILE — gentle smile.
2. TWO-BEAT NOD — head tilted slightly down, eyes closed as two calm curves.
3. THINKING — eyes looking up to one side, mouth a small straight line.
4. QUIET SURPRISE — eyes slightly bigger round dots, mouth a tiny "o".

DO NOT: no vest, no lanyard, no ID card, no cape, no cloak, no wizard robe, no magic effects, no sparkles, no glow, no anime eyes, no realistic proportions. No metallic shine, no extra text, no other characters.
```
