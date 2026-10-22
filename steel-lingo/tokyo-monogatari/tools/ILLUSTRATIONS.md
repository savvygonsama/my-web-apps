# 東京物語 삽화 프롬프트 (제미나이용)

장면마다 들어가는 삽화 51장의 목록입니다. 각 항목의 **파일 이름**으로 저장해 주세요.

## 진행 방법
1. **그림체 고정:** 제미나이 대화 하나에서 계속 작업합니다. 맨 처음 아래 '공통 그림체'와 '인물 설정'을 붙여 넣고 "이 설정을 기억하고 앞으로 모든 그림에 적용해 줘"라고 말합니다.
2. **인물 기준 그림:** `ref-` 6장을 먼저 뽑습니다. 마음에 드는 그림을 고른 뒤, 이후 그 인물이 나오는 장면마다 기준 그림을 같이 첨부하면 얼굴이 덜 바뀝니다.
3. **장면 그림:** 각 장면의 영어 프롬프트를 붙여 넣습니다. 앞에 "공통 그림체로, 가로 3:2로"를 붙이면 됩니다.
4. **올리는 법:**
    - 이 대화에 그림 파일을 첨부해 주시면, 제가 파일 이름을 맞추고 가볍게 줄여서(webp) 넣고 앱에 연결하겠습니다.
    - 직접 올리시려면 GitHub의 `steel-lingo/tokyo-monogatari/img/` 폴더에 파일 이름 그대로 올리고 알려 주세요. 앱 목록(`data/index.js`의 `SH_PICS`)에 등록해야 화면에 나옵니다.
5. 일부만 먼저 보내셔도 됩니다. 그림이 없는 장면은 그림 없이 진행됩니다.

## 규칙
- **크기:** 가로 3:2(예: 1536×1024). 화면에서 위아래가 조금 잘릴 수 있으니 중요한 것은 가운데에 둡니다.
- **글자 금지:** 그림 안에 글자, 간판 글씨, 날짜, 워터마크를 넣지 않습니다. 간판은 '읽을 수 없는 흐린 글씨'로 둡니다. 날짜 도장과 설명은 앱이 그 위에 얹습니다.
- **주인공(김링고) 얼굴 금지:** 뒷모습, 어깨 너머, 사진을 든 손만 보이게 합니다. 성별을 정하지 않기 위해서입니다.
- **`p` 로 시작하는 그림 = 1995년 필름 사진.** 같은 그림체지만 빛바랜 필름 색감입니다. 앱이 흰 테두리와 주황 날짜 도장을 씌우므로, 그림에는 테두리와 날짜를 넣지 않습니다.
- **`c` 로 시작하는 그림 = 2026년 현재.**

---

## 공통 그림체 (맨 처음 한 번 붙여 넣기)

```
STYLE GUIDE — use for every image in this chat:
Warm hand-painted gouache and watercolor illustration, soft natural light, gentle paper grain,
muted warm palette with small accents of Tokyo Tower orange (#c2410c) and soft sky blue.
Calm slice-of-life Japanese animated-film mood, clean confident lines, detailed but uncluttered backgrounds,
accurate Tokyo landmarks. Horizontal 3:2 composition, main subject near the center.
No text, no letters, no signage lettering (blur any signs), no date stamps, no borders, no watermark.
The main character (the traveler) is NEVER shown from the front: only from behind, over the shoulder, or just hands.

FOR 1995 PHOTOS (file names starting with "p"):
same illustration style, but rendered like a casual 1995 35mm film snapshot:
faded warm colors, slightly yellowed whites, soft grain, mild flash glare at night, slightly tilted amateur framing,
1990s clothing and street details. No border, no date stamp.
```

## 인물 설정 (공통 그림체 다음에 붙여 넣기)

```
CHARACTERS — keep consistent:
- TRAVELER (the player): never show face. Seen from behind or over the shoulder. Beige light jacket, small backpack,
  short dark hair, holds old photo prints or a smartphone.
- MIYEONG 1995 (the traveler's mother, Korean, age 23): shoulder-length permed wavy dark hair, bright slightly shy smile,
  summer: denim overalls over a striped T-shirt; autumn/winter: oversized 90s camel coat and knitted scarf.
- YUMI 1995 (Japanese, age 23, architecture student): short black bob, big round tortoiseshell glasses,
  huge open-mouthed grin, energetic, oversized flannel shirt, high-waist jeans, white sneakers; often looking up at buildings.
- YUMI 2026 (age 54, structural engineer): short bob with silver streaks, same big round glasses, dark smart blazer,
  warm laugh lines, still looks up at buildings.
- MIYEONG 2026 (age 54): shoulder-length hair with a little gray, soft cardigan, gentle face, reading glasses pushed up on her head.
- MR. FUJITA (80s, Asakusa photo studio owner): bald top with white side hair, jeweler's loupe on his forehead,
  gray cardigan and dark apron, kind but stubborn face.
- KEN (age 50, Yumi's younger brother, Western-style diner chef in Ginza): white chef jacket, same round eye shape as Yumi,
  friendly crinkled eyes, short neat hair.
- JOJI (age 55, guitar shop owner, former street-band singer): long gray-streaked hair tied back, faded vintage band T-shirt,
  silver rings, a little stubble.
- SHIGE (age 78, retro kissaten coffee shop master): neat thin white hair, white shirt with black bow tie, gentle smile.
- AOI (age 25, Yumi's daughter, Tokyo Tower deck staff): staff uniform, ponytail, Yumi's round eyes but no glasses.
```

## 인물 기준 그림 (먼저 뽑아 두기)

| 파일 | 프롬프트 |
|---|---|
| ref-miyeong-1995 | `Character reference sheet of MIYEONG 1995: front view, side view, and a smiling close-up, summer outfit and winter coat outfit, plain light background.` |
| ref-yumi-1995 | `Character reference sheet of YUMI 1995: front view, side view, laughing close-up, flannel shirt outfit and winter coat outfit, plain light background.` |
| ref-yumi-2026 | `Character reference sheet of YUMI 2026: front view, side view, close-up with warm smile, blazer, plain light background.` |
| ref-miyeong-2026 | `Character reference sheet of MIYEONG 2026: front view, side view, close-up, cardigan, plain light background.` |
| ref-fujita-ken | `Character reference sheet of MR. FUJITA and KEN side by side, front views and close-ups, plain light background.` |
| ref-joji-shige-aoi | `Character reference sheet of JOJI, SHIGE and AOI side by side, front views and close-ups, plain light background.` |

`ref-` 그림은 앱에 쓰지 않습니다. 제미나이에서 얼굴을 맞추는 기준으로만 씁니다.

---

## 1장 아사쿠사 · 현상

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| c1-roll | 엄마가 건넨 필름 한 통 | `Close-up of a hand holding a small black 35mm film canister with "95" hand-written in marker (render the marker as a simple scribble), on a wooden kitchen table at night, warm lamp light, a passport and a boarding pass beside it, cozy Korean apartment kitchen softly blurred behind.` |
| c1-kaminari | 2026년 7월, 가미나리몬 | `Asakusa Kaminarimon gate in bright July afternoon, the giant red paper lantern, crowds of tourists taking photos, rickshaws waiting, the traveler seen from behind looking up at the lantern, blue summer sky.` |
| c1-shop | 후지타 사진관 | `A tiny old Showa-era photo studio in a narrow back alley behind Senso-ji, glass door with gold lettering (blurred), faded wedding portraits in the window display, potted plants, a bicycle, late afternoon light.` |
| c1-naka | 나카미세의 닌교야키 | `Close-up at a Nakamise street stall: a craftsman pouring batter into iron molds shaped like little faces to bake ningyo-yaki cakes, steam rising, rows of golden cakes, warm busy shopping street behind.` |
| c1-kuji | 센소지의 오미쿠지 | `At Senso-ji temple, the traveler's hands holding an omikuji fortune paper, wooden drawers of the fortune cabinet behind, incense smoke drifting, the main hall roof softly blurred.` |
| c1-river | 스미다강과 아즈마바시 | `The red Azuma Bridge over the Sumida River on a summer afternoon, a flat river cruise boat passing, the golden flame sculpture on the beer company building across the river, Tokyo Skytree rising behind, the traveler leaning on the railing seen from behind.` |
| p01 | 1995년, 가미나리몬 앞의 두 사람 | `1995 film snapshot: MIYEONG 1995 (summer overalls) and YUMI 1995 standing under the giant red Kaminarimon lantern, Yumi grinning widely with a peace sign, Miyeong smiling shyly, 1990s tourists around, summer light.` |
| c1-prints | 카운터 위에 펼친 36장 | `Over-the-shoulder view of the traveler's hands spreading many small developed photo prints across an old wooden shop counter, a white photo envelope, Mr. Fujita's hands and loupe at the edge of the frame, warm studio lamp. The photos show tiny blurred images of two young women.` |
| p36 | 1995년 12월 24일, 도쿄타워 전망대 | `1995 film snapshot at night inside the Tokyo Tower upper observatory: MIYEONG 1995 and YUMI 1995 in winter coats and scarves, hooking their pinky fingers together in a promise, facing the camera, the glittering night city through the big window behind them, flash glare on the glass.` |
| c1-remake | 1995년 사진을 들고, 같은 자리에서 | `Point-of-view shot: the traveler's hand holds up an old 1995 photo print of two young women in front of the real Kaminarimon gate, lined up so the lantern in the photo matches the real lantern behind, summer evening light.` |

## 2장 스카이트리가 없는 하늘

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| p04 | 1995년, 아즈마바시 위의 두 사람 | `1995 film snapshot: MIYEONG 1995 and YUMI 1995 leaning on the red railing of Azuma Bridge, Yumi resting her chin on Miyeong's shoulder making a peace sign, the golden flame sculpture across the river, and a wide empty sky on the right side (no Skytree, it did not exist yet).` |
| c2-bridge-now | 같은 다리, 2026년 | `Same viewpoint on Azuma Bridge at sunset in 2026: the golden flame sculpture across the river and now the tall Tokyo Skytree filling the right side of the sky, the traveler seen from behind holding the old photo up beside the view.` |
| c2-deck | 350미터 전망 데크에서 본 밤의 도쿄 | `Inside the Tokyo Skytree 350m observation deck at night, huge floor-to-ceiling windows, endless glittering city lights below, a small orange-lit Tokyo Tower far in the distance, the traveler's silhouette at the glass.` |
| c2-panel | 스카이트리 건설 기록 패널 | `A museum-like wall panel inside Tokyo Skytree showing construction photos of the steel lattice tower rising floor by floor and a long list of names (render the names as unreadable tiny lines), the traveler's finger pointing at one line.` |
| c2-bed | 호텔 침대 위에 펼친 36장 | `Top-down view of a small Tokyo business hotel bed covered with dozens of old photo prints laid out in rows from summer to winter, a notebook and smartphone, warm bedside lamp, night window with city lights.` |
| c2-clues | 세 장의 단서 | `Close-up of the traveler's hands holding three old photo prints fanned out: one of a young woman in an apron in front of a retro Western-style diner, one of a matchbox on a coffee shop table, one of a street band with a drum. Hotel room lamp light.` |

## 3장 긴자 · 그릴 나카무라

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| c3-ginza-now | 일요일 아침의 긴자 중앙거리 | `Ginza Chuo-dori on a Sunday morning during the pedestrian-paradise hours: no cars, people strolling in the middle of the wide street, parasols and chairs on the asphalt, the classic Wako building with its clock tower on the corner, bright clean light.` |
| p08 | 1995년, 시계탑 아래의 두 사람 | `1995 film snapshot at the Ginza 4-chome crossing under the Wako clock tower: MIYEONG 1995 holding many shopping bags smiling at the camera, YUMI 1995 next to her looking up at the clock tower, autumn, 1990s fashion.` |
| c3-hokoten | 차도 한가운데의 파라솔 | `A white parasol and folding chairs set in the middle of empty Ginza Chuo-dori asphalt, children walking on the lane markings, department store facades, the traveler sitting seen from behind.` |
| c3-grill | 1951년 창업 양식당 그릴 나카무라 | `Exterior of a small retro Western-style diner (yoshoku-ya) in a Ginza side street: red awning, glass display case of realistic plastic food samples like omurice and hayashi rice, polished wooden door, warm light, sign lettering blurred.` |
| c3-ken | 그릴 나카무라의 카운터 | `Inside the retro diner: KEN in a white chef jacket tossing a frying pan behind a wooden counter, copper pots, steam, the traveler seated at the counter seen from behind holding out an old photo.` |
| c3-hayashi | 그릴 나카무라의 점심 | `Close-up of a plate of glossy hayashi rice (thin beef in rich demi-glace sauce over white rice) with a silver spoon on a wooden counter, a glass of water, the old photo print leaning against the glass.` |

## 4장 메이지신궁에서 오모테산도로

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| c4-torii | 메이지신궁의 나무 도리이 | `The huge wooden torii gate of Meiji Jingu shrine in a deep green forest, a wide gravel path, dappled summer sunlight through tall trees, a few visitors, the traveler walking seen from behind.` |
| p12 | 1995년, 서로의 에마를 가리는 두 사람 | `1995 film snapshot at Meiji Jingu: MIYEONG 1995 and YUMI 1995 laughing while each covers the other's wooden ema wish plaque with a hand, hundreds of ema hanging around the sacred tree, autumn.` |
| c4-ema | 새로 건 에마 한 장 | `Close-up of the traveler's hand hanging a new wooden ema plaque among hundreds of others around the sacred tree at Meiji Jingu (handwriting rendered as illegible strokes), soft forest light.` |
| p15 | 1995년, 길거리 밴드 앞에서 춤추는 엄마 | `1995 film snapshot of the Harajuku pedestrian-paradise street performances: a young rock band with a drum kit and guitars playing on the closed street, a crowd, MIYEONG 1995 dancing in the front row with arms stretched out and eyes closed, YUMI 1995 laughing beside her, energetic 90s mood.` |
| c4-shop | 하라주쿠 뒷골목의 악기점 블루버드 | `A tiny guitar shop up a narrow stair in a Harajuku back street: walls covered with guitars, an old amp, vinyl records, a faded framed photo of a street band behind the counter, JOJI looking up from the counter.` |
| p18 | 1995년, 담쟁이 덮인 아파트 계단의 두 사람 | `1995 film snapshot on Omotesando: MIYEONG 1995 and YUMI 1995 sitting on the concrete steps of an old ivy-covered three-story 1920s apartment building, eating crepes, zelkova trees lining the avenue, autumn light.` |
| c4-omote-now | 쇼핑몰 끝에 남은 옛 아파트의 모습 | `Omotesando avenue in 2026 with tall zelkova trees: a long modern glass-and-concrete shopping complex, and at its far end a small ivy-covered three-story building recreated in the old apartment style, the traveler holding the old photo up to compare.` |
| p20 | 1995년, 대학 작업실의 유미 씨 | `1995 film snapshot inside a university architecture studio: YUMI 1995 proudly standing next to a one-meter-tall handmade steel-lattice tower model on a desk, holding a ruler, drafting tables and paper rolls around.` |

## 5장 시부야 · 다방 하치

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| p23 | 1995년, 하치코 앞에서 손을 흔드는 유미 씨 | `1995 film snapshot at the Hachiko statue in Shibuya: YUMI 1995 waving both arms high next to the bronze dog statue as if greeting a friend arriving, 1990s Shibuya crowd and billboards behind, winter coat.` |
| c5-hachi-now | 2026년, 같은 자리의 하치코 | `The bronze Hachiko dog statue in Shibuya in 2026, people waiting around it with smartphones, giant video screens of the station area behind, evening light, the traveler seen from behind holding the old photo.` |
| c5-scramble | 스크램블 교차로 | `High-angle view of the Shibuya scramble crossing at dusk, hundreds of people crossing in every direction, glowing billboards and screens, the traveler's small figure in the crowd.` |
| c5-kissa | 도겐자카 뒷골목의 다방 하치 | `Interior of a tiny retro underground kissaten coffee shop: red velvet sofas, stained-glass lamps, dark wood, a shelf full of identical old notebooks with years on their spines (as blurred labels), SHIGE behind the counter, two bright green cream sodas.` |
| c5-note95 | 1995년의 추억 노트 | `Close-up of an open old notebook on a coffee shop table: playful handwriting in two different scripts (render as illegible doodle-like strokes), a small ballpoint drawing of a lattice tower, a cream soda glass beside it.` |
| c5-note05 | 2005년 12월 24일의 한 페이지 | `Close-up of an open notebook page with a single short handwritten line in the middle (illegible strokes) and a small dried tear mark, the traveler's fingertip touching the page, warm lamp light, a melted cream soda nearby.` |
| p27 | 1995년, 다이칸야마의 옛 아파트 | `1995 film snapshot in Daikanyama: an old low-rise apartment complex hidden among big trees, YUMI 1995 leaning out of a second-floor window waving down at the camera, summer greenery.` |
| c5-daikan-now | 같은 언덕, 2026년의 다이칸야마 | `Daikanyama in 2026 on the same gentle hill: a stylish high-rise residential tower and small boutique shops, people walking dogs, a café terrace, calm evening light, the traveler sitting at the terrace seen from behind.` |

## 6장 롯폰기와 도쿄타워

| 파일 | 장면 | 프롬프트 |
|---|---|---|
| p30 | 1995년, 롯폰기 교차로의 밤 | `1995 film snapshot at night at the Roppongi crossing under the elevated expressway: neon signs, people in shoulder-padded 90s coats, MIYEONG 1995 and YUMI 1995 wrapping a scarf around each other, flash glare.` |
| c6-roppongi-now | 2026년의 롯폰기 교차로 | `The Roppongi crossing on a quiet morning in 2026: the same elevated expressway, and behind it the tall glass tower of Roppongi Hills, commuters walking, soft morning light.` |
| c6-office | 나카무라 구조설계 사무소 | `A small structural engineering office in Roppongi at 7 a.m.: steel-frame building models and rolled drawings on desks, big window with morning light, YUMI 2026 by the window turning around with a coffee cup, seen past the traveler's shoulder holding an old photo.` |
| c6-hills | 롯폰기힐스 52층에서 본 도쿄타워 | `View from the 52nd-floor observatory of Roppongi Hills: Tokyo Tower standing very close and large outside the floor-to-ceiling window, the city spreading behind, the traveler's silhouette at the glass.` |
| c6-mom-arrive | 30년 만에 도쿄에 온 엄마 | `MIYEONG 2026 coming up the stairs of a Roppongi subway exit with a small travel bag, waving and looking around in amazement at the changed city, bright midday light.` |
| c6-tower-dusk | 노을 속의 도쿄타워 | `Tokyo Tower seen from its base at sunset, red-orange and white steel lattice glowing against a pink and violet sky, the first lights turning on, people looking up.` |
| c6-maindeck | 150미터 메인 데크, 옛 대전망대 | `Inside the Tokyo Tower 150m main deck at dusk: wide windows, city lights, visitors, a quiet empty spot by the glass where someone once waited, the traveler standing there seen from behind.` |
| c6-topdeck | 250미터 탑 데크, 1995년의 그 자리 | `Inside the Tokyo Tower 250m top deck at night: geometric mirrored panels and soft lighting, the night city far below, the roof of the lower deck visible below the window, the traveler holding the 1995 photo up against the same window.` |
| c6-aoi | 탑 데크의 안내 직원 | `AOI in Tokyo Tower staff uniform at the top deck, holding the traveler's old photo with wide surprised eyes, night city behind the glass.` |
| c6-reunion | 30년 늦은 약속 | `At the Tokyo Tower top deck window at night: MIYEONG 2026 and YUMI 2026 hooking their pinky fingers together and laughing with teary eyes, the same pose as their 1995 photo, glittering city behind.` |
| c6-video | 휴대폰 화면 너머의 단짝 | `At the Tokyo Tower top deck: YUMI 2026 holding a smartphone showing a video call with MIYEONG 2026 on the screen, both crying and laughing, night city lights behind.` |
| c6-laugh | 100미터의 엇갈림 | `YUMI 2026 laughing so hard she sits on the floor by the top deck window, pointing down at the roof of the lower main deck visible far below, the traveler's legs and the old photo in frame.` |
| c6-shot37 | 서른일곱 번째 사진 | `The traveler, seen from behind, holding an old film camera up to photograph YUMI 2026 standing alone at the top deck window in the same spot as the 1995 photo, warm orange tower light reflecting on the glass.` |

---

### 그림 51장 한눈에
c1-roll · c1-kaminari · c1-shop · c1-naka · c1-kuji · c1-river · p01 · c1-prints · p36 · c1-remake ·
p04 · c2-bridge-now · c2-deck · c2-panel · c2-bed · c2-clues ·
c3-ginza-now · p08 · c3-hokoten · c3-grill · c3-ken · c3-hayashi ·
c4-torii · p12 · c4-ema · p15 · c4-shop · p18 · c4-omote-now · p20 ·
p23 · c5-hachi-now · c5-scramble · c5-kissa · c5-note95 · c5-note05 · p27 · c5-daikan-now ·
p30 · c6-roppongi-now · c6-office · c6-hills · c6-mom-arrive · c6-tower-dusk · c6-maindeck · c6-topdeck · c6-aoi · c6-reunion · c6-video · c6-laugh · c6-shot37

**먼저 만들면 좋은 10장**(모든 플레이에서 보이는 그림): c1-roll · c1-kaminari · c1-shop · p01 · c1-prints · p36 · p04 · c2-bridge-now · c6-tower-dusk · c6-topdeck
