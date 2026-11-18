# 화풍 고정

## 1~3화에서 본 흔들림과 원인

| 증상 | 어디서 | 원인 |
|---|---|---|
| 선 굵기·채도가 확 다름 | 2화 전체(굵고 진함) vs 1·3화(가늘고 연함) | **도구를 바꿈**(2화만 Gemini) |
| 한 화 안에서 마지막 컷만 톤이 다름 | 2화 7·8컷(회색 톤, 굵은 선, 칸 나눔) | 대화가 길어지며 앞 장면을 덜 참고, '위·아래 반쪽' 지시가 칸 나누기로 읽힘 |
| 화마다 색온도가 다름 | 2화 밤 고깃집 노란 조명, 3화 낮 견본실 | 장면마다 조명을 따로 지시 |
| 인물 크기·여백이 들쭉날쭉 | 3화 넓은 방에 작은 인물, 2화 꽉 찬 클로즈업 | 화면에서 인물이 차지하는 비율을 정하지 않음 |
| 캐릭터 디자인이 바뀜(타래 더듬이에 공, 반짝이 눈) | 4화 초안 | 프롬프트의 캐릭터 문장을 원본 피규어가 아니라 흐트러진 시안 그림을 보고 씀 |
| 시간이 갈수록 조금씩 달라짐 | 화마다 '직전 화 그림'을 화풍 기준으로 첨부 | **복사의 복사**: 기준이 매번 바뀌어 차이가 쌓임 |

## 고정 방법 (위에서부터 효과 큼)

1. **도구 하나로 고정**: ChatGPT. Gemini·다른 도구로 바꾸지 않는다.
2. **화풍 기준판(스타일 앵커) 한 장을 영구 고정**: 주연 다섯이 견본실에 나란히 선 그림 + 아래 색 견본 띠. 매 화 [0] 메시지에 **이 한 장과 캐릭터 시트만** 첨부한다. 직전 화 그림은 기준으로 쓰지 않는다.
3. **ChatGPT 프로젝트에 넣어 두기**: ChatGPT 왼쪽 메뉴의 '프로젝트'로 「스틸가챠s 작화」를 만들고, 프로젝트 지침에 아래 STYLE LOCK 문단을, 프로젝트 파일에 기준판·캐릭터 시트를 넣는다. 매 화 그 프로젝트 안에서 새 채팅을 연다. (메뉴 이름은 바뀔 수 있으니 사용자 화면 기준으로 안내)
4. **STYLE LOCK 문단을 글자 그대로 재사용**: 화마다 문장을 고치지 않는다. 바꿔야 하면 여기서 고치고 판 번호를 올린다.
5. **조명·배경을 고정**: 실내는 늘 '맑은 낮, 부드러운 자연광'. 밤 장면은 창밖만 어둡게 하고 인물 색은 그대로("characters keep their daytime colors").
6. **인물 크기 고정**: 기본 '허리 위 미디엄 숏, 인물이 화면 높이의 55~70%'. 넓은 장면은 그 장면에만 "wide shot"을 쓴다.
7. **한 화 = 한 채팅**, 장면 1이 마음에 들면 이후 메시지에 "Same style as scene 1" 한 줄을 붙인다.
8. **캐릭터 문장은 원본에서**: 피규어 사진(`steel-grade-gacha/src/img/`)과 캐릭터 시트만 보고 쓴다. 완성 컷을 보고 고치지 않는다.
9. **무대는 이야기에 맞게, 어색한 소품 금지**: 실내에 자동차를 들이는 식의 어색한 배치는 피하고, 차·코일·트럭이 나오면 야외 마당이나 출하동에서.
10. **검수 후 다시 그리기**: 받은 장면을 기준판 옆에 놓고 아래 체크리스트로 본다. 하나라도 어긋나면 그 장면만 다시.

## STYLE LOCK v1 (글자 그대로 붙여 넣기)
```
STYLE LOCK v1 (never change between scenes or episodes):
- Match the attached STYLE ANCHOR image exactly: same line weight, same colors, same character proportions, same face style.
- Simple 2D webtoon art. One uniform dark charcoal outline (#2B2F36), medium weight, the SAME weight on characters and background.
- Flat cel colors only: no gradients, no metallic shine, no texture, no 3D rendering. Only one soft flat oval shadow under the feet.
- Soft, slightly muted colors. Background lighter and less saturated than the characters. Calm daylight; no colored mood lighting on the characters.
- Chibi proportions about 2.2 heads tall, big head, mitten hands, stubby legs. Faces: dot eyes, short mouth line, light face plate #EEF0F2.
- Default camera: waist-up medium shot, characters fill about 55-70% of the image height. Simple background with at most 5 props.
- One single full-bleed portrait image (2:3, 1024x1536). Never a comic page with multiple panels, no panel borders.
- Clean white rounded speech bubbles with black Korean text. No logos, no brand names, no other text.
```

## 화풍 기준판 만들기 (한 번만)
새 채팅(또는 프로젝트)에서 주연 다섯 시트 + 가장 마음에 드는 완성 컷 1~2장(현재 권장: 3화 9컷 중 '다 같이 차 한잔' 컷)을 첨부하고 보낸다. 결과를 `style_anchor.png`로 저장해 두고 이후 매 화 첨부한다.
```
Create an image: a STYLE ANCHOR reference for my webtoon. Use the attached character sheets and match the attached finished panel's art style exactly.
Portrait 2:3. Daytime cozy steel sample room (light beige walls, wooden shelves with small flat steel sample plates and mini coils, a window with soft daylight).
The five main characters stand side by side, front-facing, full body, same scale, friendly neutral expressions, left to right: PO, SSIAL, DOGEUM, EG (teal half on the viewer's LEFT), TARAE.
At the bottom, a simple row of flat color swatch squares (no text): #BE473D, #2A6DA8, #7C5D91, #B9B2A8, #2A8F96, #A3A9B0, #5F646B, #C5CBD2, #EEF0F2, #2B2F36.
[STYLE LOCK v1 문단을 여기 붙인다]
No text, no labels.
```

## 검수 체크리스트 (장면마다)
- [ ] 선 굵기가 기준판과 같다(눈에 띄게 굵거나 가늘지 않다)
- [ ] 배경 색온도가 기준판과 같다(노랗거나 회색으로 쏠리지 않았다)
- [ ] 캐릭터 디자인이 시트와 같다(타래: 머리와 고리를 잇는 직선 지지대 둘, 공 없음, 점 눈. 이지: 청록이 보는 사람 왼쪽)
- [ ] 캐릭터가 섞이지 않았다(포오 볏·씨알 앞머리 볏·도금이 볏 없는 헬멧·이지 청록 왼쪽·타래 철사 몸)
- [ ] 한 장에 한 장면, 칸 나누기·테두리 없음
- [ ] 말풍선 글자가 맞다(틀리면 빈 말풍선으로 다시 → 직접 입력)
- [ ] 인물 크기가 앞 장면과 비슷하다

## 앱 쪽에서 맞추는 것
`scripts/add_episode.py`가 모든 컷을 같은 폭(1000px)·WebP로 맞춘다. 비율이 다른 컷이 섞여도 뷰어는 세로로 이어 보여 주지만, 가능하면 모든 컷을 2:3으로 받는다.

## Gemini 무료판으로 그릴 때 (8화부터)
- **기준 이미지 묶음**(앱 저장소에서 만든 PNG): 01 다섯 단체(`webtoon/s00-1`), 02 완성 컷 견본실(`webtoon/ep07-1`), 03~07 캐릭터 시트(`webtoon/s00-po`·`ssial`·`dogeum`·`eg`·`tarae`), 08 빈 2:3 캔버스. Gemini는 글보다 첨부 이미지를 더 강하게 따른다. 매 화 새 채팅 첫 메시지에 01·02와 그 화 등장 캐릭터 시트를 첨부하고, 3~4장마다 01을 다시 첨부한다.
- **Gem**: 「스틸가챠s 작화」 Gem의 지침에 STYLE LOCK G1과 캐릭터 문장을 넣는다(무료 계정에 Gem이 없으면 매 채팅 첫 메시지에 붙여 넣는다).
- **Gemini에서 잘 생기는 흔들림과 막는 문장**: 선이 굵어짐 → "lines thinner, like the anchor"; 채도·대비 상승 → "tone colors down to the anchor's soft muted colors"; 광택·그림자·3D → "flat cel colors only, remove all shading and shine"; 정사각형 → 08 빈 캔버스를 첨부하고 "draw on this 2:3 canvas"; 한글 깨짐 → 빈 말풍선으로 받고 글자는 따로 넣는다.
- **한 메시지에 한 장면**: 무료판은 한 번에 한 장이 기본이고 하루 생성 횟수 제한이 있다. 한 화를 하루에 다 못 뽑을 수 있으니 일정을 넉넉히 잡는다.
- **첫 보정 테스트**: 새 Gem에서 01을 첨부해 "포오와 씨알이 견본실에서 차를 마시는 한 장"을 먼저 그려 보고, 아래 체크리스트로 02와 나란히 비교한다. 맞을 때까지 고친 뒤 본편을 시작한다.

- **첫 보정 결과(2026-11-18)**: 배경·선 굵기·채도·말풍선·한글 모두 02와 거의 같음(채도 평균 차 약 5%, 2:3 비율, 848×1264). 어긋난 곳은 **씨알 눈썹이 빠져 순한 얼굴이 됨** 하나 → Gem의 씨알 문장에 "ALWAYS two short slanted eyebrows above the eyes, even when smiling"을 넣는다. 해상도가 1024보다 작게 나오므로 받을 때 원본 크기로 내려받는다. 눈썹 보강 문장으로 다시 그린 결과 씨알 눈썹이 들어가 **보정 통과**. Gemini 프롬프트는 [0] 시작 메시지(이 화 전용 규칙, 이미지 만들지 말 것) + 장면별 메시지(한 메시지 한 장면, 핵심 규칙을 매번 짧게 반복) 형식으로 준다.

- **8화 2컷 흔들림(2026-11-18)**: 선 굵기·명암은 기준과 같았지만 채도가 51 → 65로 오르고, 꽃·반짝이·볼터치가 스티커 같은 다른 그림체로 붙고, 이지 눈에 애니메이션 하이라이트가 생겼다. 원인은 프롬프트의 장식 지시("sparkle in the eye", "tiny flowers", "pink blush"). **Gemini에서는 장식 단어를 쓰지 않는다.** 격차는 말풍선 모양(구름/네모)과 배경 톤, 표정으로만 낸다. 눈은 늘 단색 점(이지 청록 쪽 눈은 청록 점, 하이라이트 없음). 색은 "same muted saturation as the anchor, teal stays a muted dark teal #2A8F96"을 장면마다 반복. 장면마다 02와 그 화 핵심 캐릭터 시트를 다시 첨부한다. 이지 얼굴 참고는 `webtoon/ep03-6`(09번 파일).

### STYLE LOCK G1 (Gemini용, 글자 그대로 붙여 넣기)
```
STYLE LOCK G1 — apply to EVERY image in this webtoon.
1. REFERENCE FIRST: the attached STYLE ANCHOR images are the absolute standard. Copy their line weight, colors, proportions, face style and amount of detail exactly. If my words and the anchor disagree, follow the anchor.
2. LINES: one uniform, thin-to-medium dark charcoal outline (#2B2F36), about 4 px wide on a 1024 px image, the SAME weight on characters and background. NOT thick, NOT bold marker lines, no brush-pressure variation, no sketchy or double lines.
3. COLOR: flat cel colors only, soft and slightly muted, close to pastel. Do NOT raise saturation or contrast. No gradients, no gloss, no metallic shine, no highlights, no rim light, no airbrush, no texture or grain, no 3D rendering. The only shadow is one soft flat oval under the feet.
4. PALETTE (keep exactly): PO vest #BE473D, SSIAL vest #2A6DA8, DOGEUM vest #7C5D91, DOGEUM body #B9B2A8, EG teal #2A8F96, EG grey #A3A9B0, TARAE wire #5F646B, silver body #C5CBD2, face plate #EEF0F2, outline #2B2F36.
5. LIGHT: calm daylight. Background lighter and less saturated than the characters. No colored mood lighting on the characters; at night only the window gets dark.
6. PROPORTIONS: chibi about 2.2 heads tall, big head, mitten hands with no fingers, stubby legs. Faces: small solid black dot eyes, one short simple mouth line, light face plate. No realistic anatomy, no detailed shiny anime eyes.
7. CAMERA: default waist-up medium shot, characters fill 55-70% of the image height. Simple background with at most 5 props.
8. FORMAT: ONE single full-bleed PORTRAIT image, ratio 2:3 (1024x1536). Never square, never landscape, never several panels, no borders, no frames, no captions, no signature.
9. TEXT: clean white speech bubbles with black text only where I give it. No other text, logos or brand names. If you cannot write the Korean text exactly, leave the bubble EMPTY instead of writing wrong letters.
10. CHARACTERS: never redesign; copy the attached character sheets; never mix features between characters. All characters are genderless; refer to them only by name.
11. CONSISTENCY: every image must look like the next page of the same webtoon as the anchor, drawn by the same artist on the same day.
```

## 같은 사물이 여러 장면에 나올 때 (4화 우산에서 배운 것)
- **형태를 번호 매긴 문장으로 [0]에 못 박는다**: 손잡이 하나, 살 정확히 4개(좌 2·우 2), 천 없음, 머리는 꼭대기 한가운데. "LOCKED, IDENTICAL IN EVERY SCENE"을 대문자로 쓴다.
- **정의 장면을 하나 정한다**: 그 사물만 크게, 정면, 전신으로 그리는 장면(4화는 4컷). 이후 장면은 "copy it exactly from scene N"으로 그 장면을 가리킨다.
- **8장을 한 번에 요청**해도 되지만, 한 장씩만 나오면 "next scene" 문장으로 이어 가고, 정의 장면이 어긋나면 그 장면부터 다시 그린다.
- 결과: 4화 우산 4·5·7·8컷의 모양이 일치했다(화풍 기준판 + 캐릭터 시트 첨부, 비 장면 색 고정 문단 포함).
