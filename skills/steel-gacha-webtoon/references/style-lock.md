# 화풍 고정

## 1~3화에서 본 흔들림과 원인

| 증상 | 어디서 | 원인 |
|---|---|---|
| 선 굵기·채도가 확 다름 | 2화 전체(굵고 진함) vs 1·3화(가늘고 연함) | **도구를 바꿈**(2화만 Gemini) |
| 한 화 안에서 마지막 컷만 톤이 다름 | 2화 7·8컷(회색 톤, 굵은 선, 칸 나눔) | 대화가 길어지며 앞 장면을 덜 참고, '위·아래 반쪽' 지시가 칸 나누기로 읽힘 |
| 화마다 색온도가 다름 | 2화 밤 고깃집 노란 조명, 3화 낮 견본실 | 장면마다 조명을 따로 지시 |
| 인물 크기·여백이 들쭉날쭉 | 3화 넓은 방에 작은 인물, 2화 꽉 찬 클로즈업 | 화면에서 인물이 차지하는 비율을 정하지 않음 |
| 시간이 갈수록 조금씩 달라짐 | 화마다 '직전 화 그림'을 화풍 기준으로 첨부 | **복사의 복사**: 기준이 매번 바뀌어 차이가 쌓임 |

## 고정 방법 (위에서부터 효과 큼)

1. **도구 하나로 고정**: ChatGPT. Gemini·다른 도구로 바꾸지 않는다.
2. **화풍 기준판(스타일 앵커) 한 장을 영구 고정**: 주연 다섯이 견본실에 나란히 선 그림 + 아래 색 견본 띠. 매 화 [0] 메시지에 **이 한 장과 캐릭터 시트만** 첨부한다. 직전 화 그림은 기준으로 쓰지 않는다.
3. **ChatGPT 프로젝트에 넣어 두기**: ChatGPT 왼쪽 메뉴의 '프로젝트'로 「스틸가챠s 작화」를 만들고, 프로젝트 지침에 아래 STYLE LOCK 문단을, 프로젝트 파일에 기준판·캐릭터 시트를 넣는다. 매 화 그 프로젝트 안에서 새 채팅을 연다. (메뉴 이름은 바뀔 수 있으니 사용자 화면 기준으로 안내)
4. **STYLE LOCK 문단을 글자 그대로 재사용**: 화마다 문장을 고치지 않는다. 바꿔야 하면 여기서 고치고 판 번호를 올린다.
5. **조명·배경을 고정**: 실내는 늘 '맑은 낮, 부드러운 자연광'. 밤 장면은 창밖만 어둡게 하고 인물 색은 그대로("characters keep their daytime colors").
6. **인물 크기 고정**: 기본 '허리 위 미디엄 숏, 인물이 화면 높이의 55~70%'. 넓은 장면은 그 장면에만 "wide shot"을 쓴다.
7. **한 화 = 한 채팅**, 장면 1이 마음에 들면 이후 메시지에 "Same style as scene 1" 한 줄을 붙인다.
8. **검수 후 다시 그리기**: 받은 장면을 기준판 옆에 놓고 아래 체크리스트로 본다. 하나라도 어긋나면 그 장면만 다시.

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
- [ ] 캐릭터가 섞이지 않았다(포오 볏·씨알 앞머리 볏·도금이 볏 없는 헬멧·이지 청록 왼쪽·타래 철사 몸)
- [ ] 한 장에 한 장면, 칸 나누기·테두리 없음
- [ ] 말풍선 글자가 맞다(틀리면 빈 말풍선으로 다시 → 직접 입력)
- [ ] 인물 크기가 앞 장면과 비슷하다

## 앱 쪽에서 맞추는 것
`scripts/add_episode.py`가 모든 컷을 같은 폭(1000px)·WebP로 맞춘다. 비율이 다른 컷이 섞여도 뷰어는 세로로 이어 보여 주지만, 가능하면 모든 컷을 2:3으로 받는다.
