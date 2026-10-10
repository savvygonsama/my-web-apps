# 이미지 생성 프롬프트

자동차강판 부품 지도에 들어갈 그림을 다른 이미지 AI(ChatGPT, Gemini, Midjourney 등)로 만들 때 쓰는 프롬프트입니다.

## 한 번에 붙여넣는 통합 프롬프트 (2판, 16장)

1판에서 생긴 문제를 고친 판입니다.
- 15장이 한 장에 격자로 묶여 나와 해상도가 낮았음 → 한 번에 한 장만, 격자 금지
- 크래시박스·대시 패널·스트럿 타워·C필러·스태빌라이저 등 핀을 못 찍은 부품이 있었음 → 부품 목록을 늘리고, 부품끼리 띄워서 그리게 함
- 차체 골격을 측면(5)·프론트 엔드(6)·바닥과 뒤쪽(7) 세 장으로 나눔

붙여 넣으면 1번이 나오고, `next`라고 칠 때마다 다음 장이 나옵니다. 다시 뽑을 때는 `redo 5`처럼 칩니다.

```
I need 16 technical illustrations for a steel sales training course. Rules for this whole conversation:
- Make exactly ONE image per reply, as a single full-size picture. Never combine several items into a grid, collage, contact sheet or panels.
- Start with image 1 right now without asking me questions. After each image, wait. When I reply "next", make the next number. If I reply "redo N", make image N again following all rules.

STYLE FOR EVERY IMAGE (identical across all 16 so they look like one set):
Clean technical illustration, flat vector style with subtle shading, consistent dark graphite outlines of even weight. Palette only: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C, white. Plain pure white background. Landscape 3:2, highest resolution available. Even soft lighting. Generic car with no brand features. Bare unpainted metal look. Whenever a car or car body is shown, its front points to the LEFT.
Layout: every listed part must be clearly visible, drawn large, and separated from the others by a clear white gap so each one can be pointed at. No overlapping between listed parts. Keep a white margin around the edges; nothing touches the border.
ABSOLUTELY NO text, labels, letters, numbers, arrows, leader lines, callouts, logos or watermarks anywhere.
Color rule: ultra high strength reinforcements = warm red, crash-absorbing members and outer skin panels = steel blue, other sheet metal = light steel gray, cast/forged/mechanical parts = graphite.

1. Whole car overview: three-quarter front cutaway of a mid-size electric sedan. Upper body shell in steel blue with semi-transparent outer panels showing pillars and roof rails; chassis in graphite underneath (front and rear suspension, subframes, four wheels, steering rack); bare metal front seat frames visible through the windows; flat battery pack under the floor between the axles, clearly visible from the side.
2. Body in white, exploded isometric: main body structure in the center (light steel gray); four doors, hood, two front fenders and trunk lid pulled far outward and floating apart (steel blue). No glass, no wheels.
3. Front door exploded isometric, six parts in a row from left to right with wide even gaps: smooth outer skin panel (steel blue); horizontal beltline reinforcement strip (light steel gray); long diagonal side impact beam (warm red); small thick hinge reinforcement plate (light steel gray); deep-drawn inner panel with speaker and window regulator cut-outs (light steel gray); thin window frame loop (door sash, graphite).
4. Closure parts in two neat rows with wide gaps. Top row: hood outer panel (steel blue), hood inner panel with lattice ribs (light steel gray), a pair of small hood hinges (graphite), front fender with wheel arch (steel blue). Bottom row: trunk lid outer panel (steel blue), trunk lid inner panel (light steel gray), small round fuel filler door (steel blue).
5. Body side structure exploded sideways, seen from the outside, front to the left, layers pulled apart from the outside in: (a) the large one-piece body side outer panel with door openings (steel blue); (b) the reinforcements, each floating separately: A-pillar reinforcement, B-pillar reinforcement, C-pillar reinforcement, roof side rail, side sill (rocker) reinforcement (all warm red); (c) the inner layer: A-pillar inner, B-pillar inner, side sill inner, rear wheelhouse inner (light steel gray). Above them, floating: the roof panel (steel blue), two roof bows and the front and rear roof headers (light steel gray).
6. Front end structure exploded isometric, front to the left, parts pulled apart from front to back with wide gaps: front bumper beam (warm red); two short crash boxes (steel blue); radiator support frame (light steel gray); two long front side members (steel blue) with their rear extensions that bend down under the floor (warm red); two strut towers (shock absorber housings) and two fender aprons (light steel gray); cowl panel below the windshield line (light steel gray); dash panel / firewall wall (light steel gray) with a dash cross member along its bottom (warm red).
7. Underbody floor and rear end, isometric from above, front to the left, parts slightly separated: flat front floor panels split by a raised center tunnel (light steel gray); two seat cross members across the floor (warm red); floor side members running front to back under the floor (steel blue); rear floor with a deep round spare tire well (light steel gray); rear side members (steel blue); rear cross member (light steel gray); at the far right end, the back panel (light steel gray), rear quarter / tailgate opening reinforcements (steel blue) and the rear bumper beam (warm red), each pulled slightly away.
8. Chassis seen from directly underneath, front to the left, body floor as a faint light gray outline: front subframe with two lower control arms; steering rack with tie rods running across in front of the front wheels; front brake discs; rear subframe with multi-link arms; coil springs and shock absorbers at each corner; front and rear stabilizer bars; four wheels; fuel tank ahead of the rear axle (steel blue); exhaust pipe to a rear muffler (warm red).
9. Suspension parts, isometric, three groups with wide gaps, each slightly exploded. Left group, front MacPherson strut corner: pressed steel lower control arm (steel blue), cast steering knuckle (graphite), coil spring (warm red) around the shock absorber tube (graphite), stabilizer bar (graphite). Center group, rear multi-link corner: lower spring arm (steel blue) with its spring seat bracket, two thin lateral links, a long trailing arm and a small upper arm (graphite). Right group: twist beam rear axle with a U-shaped cross beam joining two trailing arms (steel blue).
10. Two welded pressed steel subframes side by side, isometric, wide gap between: front subframe (engine cradle) with four corner mounting brackets and one engine mount bracket on top pulled slightly upward; rear multi-link subframe with its mounting brackets. Graphite with steel blue brackets.
11. Stamped steel car wheel, exploded three-quarter view: wheel disc with bolt and vent holes (steel blue) pulled forward out of the cylindrical wheel rim (light steel gray), tire as a faint gray outline behind.
12. Steering system without dashboard, isometric: long tubular cross car beam (cowl cross bar, steel blue) spanning left to right; steering column tube with its tilt mounting bracket (light steel gray) attached to the beam; steering wheel outline; intermediate shaft down to the steering rack housing (graphite) with tie rods reaching out to both sides.
13. Three groups left to right with wide gaps, isometric: disc brake corner with cast iron brake disc (graphite), caliper and thin pressed steel dust shield behind the disc (steel blue); pressed steel fuel tank with edge seam welds (steel blue); exhaust pipe into an oval muffler (warm red) with a thin embossed heat shield plate floating above it (light steel gray).
14. Bare front car seat skeleton without foam or fabric, three-quarter view, parts slightly separated: seat back frame (steel blue), seat cushion frame and pan (light steel gray), round recliner mechanism at the back-cushion joint (warm red), two long seat rails underneath (graphite).
15. Left two thirds: electric vehicle battery pack exploded vertically with clear gaps: thin top cover (light steel gray), rows of battery modules (graphite), internal cross members between the modules (warm red), strong side frame around the edge (warm red), flat bottom plate (steel blue). Right third: electric traction motor cutaway showing stator and rotor made of many thin stacked laminated steel sheets (steel blue).
16. Engine block outline in light gray with a deep-drawn sheet steel oil pan pulled slightly downward from its underside (steel blue), and a thin embossed heat shield plate (steel blue) floating next to the exhaust manifold (graphite).
```

아래 개별 프롬프트는 특정 그림만 다시 뽑을 때 씁니다.

---

## 쓰는 법

1. 아래 프롬프트를 **한 장씩 통째로** 복사해 붙여 넣습니다. 앞부분 스타일 문장이 모든 프롬프트에 똑같이 들어 있어서, 그림들의 화풍이 맞춰집니다.
2. 그림 속에 **글자·숫자·로고가 생기면 다시 뽑아 주세요.** 부품 이름은 나중에 그림 위에 누를 수 있는 핀으로 붙입니다. AI가 쓴 글자는 대개 엉터리입니다.
3. 각 프롬프트 아래의 **"꼭 보여야 할 부품"** 이 그림에서 구분되는지 확인하세요. 핀을 그 위치에 찍습니다. 안 보이는 부품이 있으면 다시 뽑습니다.
4. 파일 이름을 번호대로 붙여(`01_root.png` 등) 대화창에 올려 주시면 됩니다. 크기 조정, 압축, 핀 배치, HTML 삽입은 제가 합니다.

> AI 그림은 부품 경계선을 그럴듯하게만 그리는 경우가 많습니다. 교육용 "위치 감 잡기"로는 충분하지만, 정확한 분할선은 아닙니다. 완성본은 실무자가 한 번 훑어봐 주세요.

**Midjourney** 를 쓰면 끝에 `--ar 16:9 --no text, letters, numbers, logo, watermark` 를 붙이세요. ChatGPT·Gemini 는 그대로 붙여 넣으면 됩니다.

## 우선순위

- **1차 (꼭 필요, 8장)**: 01 ~ 08. 첫 화면, BIW, 개폐부, 차체 골격, 섀시
- **2차 (있으면 좋음, 7장)**: 09 ~ 15. 세부 그룹

---

## 01 · 첫 화면: 자동차 전체 → `01_root.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, generic modern mid-size battery-electric sedan with no brand features, engineering cutaway style, even soft lighting, wide 16:9 composition.
Subject: three-quarter front view of the whole car shown as a cutaway. The upper part shows the welded steel body shell (body in white) in steel blue with outer panels semi-transparent so the pillars, roof rails and door frames are visible. The lower part shows the chassis in graphite beneath the body: front and rear suspension, subframes, four wheels and the steering rack. Front seats are visible through the windows as bare metal seat frames, and a flat battery pack sits under the floor between the axles. Clear visual separation between body (top), chassis (bottom), seats and battery.
```
꼭 보여야 할 부품: 차체(위쪽 껍데기), 섀시(아래 바퀴·서스펜션), 시트 프레임, 바닥 아래 배터리 팩

## 02 · BIW: 개폐부와 차체 골격 → `02_biw.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, generic modern mid-size sedan with no brand features, even soft lighting, wide 16:9 composition.
Subject: exploded isometric view of an automotive body in white. The main body structure (pillars, roof, floor, engine compartment) stays in the center in light steel gray. The closures are pulled outward and floating apart from it, colored steel blue: four doors pulled out sideways, the hood lifted above the front, both front fenders pulled out to the sides, and the trunk lid lifted above the rear. Bare unpainted sheet metal look, no glass, no trim, no wheels.
```
꼭 보여야 할 부품: 가운데 차체 골격 / 떨어져 나온 도어 4개, 후드, 펜더 2개, 트렁크리드

## 03 · 개폐부 ①: 도어 분해도 → `03_door.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: exploded isometric view of a front car door made of sheet steel, parts separated from left to right in assembly order with even gaps: the smooth outer skin panel (steel blue), the beltline reinforcement strip under the window line, the side impact beam as a long diagonal bar (warm red), the hinge reinforcement plate near the front edge, the deep-drawn inner panel with cut-outs for speaker and window regulator (light steel gray), and the window frame (door sash) as a thin metal loop on top. No glass, no trim, no handle.
```
꼭 보여야 할 부품: 도어 아우터, 벨트라인 보강, 임팩트빔, 힌지 보강, 도어 이너, 도어 프레임(새시)

## 04 · 개폐부 ②: 후드·펜더·트렁크 → `04_closures.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: a neat layout of separate sheet steel car closure parts arranged in two rows with even spacing, isometric view. Top row: the hood outer panel (steel blue) next to the hood inner panel with its lattice of stiffening ribs (light steel gray), and a front fender with its wheel arch curve (steel blue). Bottom row: the trunk lid outer panel (steel blue) next to the trunk lid inner panel (light steel gray), and a small round fuel filler door. Bare unpainted metal look.
```
꼭 보여야 할 부품: 후드 아우터·이너, 펜더, 트렁크리드 아우터·이너, 주유구 도어

## 05 · 차체 골격 ①: 측면·루프·엔진룸 → `05_frame.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, generic modern mid-size sedan with no brand features, even soft lighting, wide 16:9 composition.
Subject: three-quarter front isometric view of a car body in white structure with doors, hood, fenders and trunk lid removed, and the near-side outer side panel removed to reveal the reinforcements. Ultra high strength reinforcements in warm red: A-pillar, B-pillar, side sill (rocker), roof side rail, front and rear bumper beams. Crash-absorbing members in steel blue: front side members (rails) running forward through the engine compartment, crash boxes behind the front bumper beam. Everything else in light steel gray: roof panel, roof bows, C-pillar, strut towers (shock absorber housings), fender aprons, dash panel (firewall), cowl, radiator support at the very front.
```
꼭 보여야 할 부품: A·B·C필러, 사이드실, 루프 사이드 레일, 루프·루프 보우, 프론트 사이드멤버, 크래시박스, 범퍼빔(앞·뒤), 스트럿 타워, 에이프런, 대시 패널, 카울, 라디에이터 서포트

## 06 · 차체 골격 ②: 바닥(언더바디) → `06_underbody.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: isometric view from above of an isolated car underbody floor assembly made of pressed sheet steel, front of the car on the left. Large flat front floor panels (light steel gray) split by a raised center tunnel, seat cross members running left to right across the floor (warm red), floor side members running front to back under the floor (steel blue), the rear floor panel with a deep round spare tire well, rear side members (steel blue) and a rear cross member at the back. Front side member extensions bending down under the front of the floor (warm red).
```
꼭 보여야 할 부품: 프론트 플로어, 센터 터널, 시트 크로스멤버, 플로어 사이드멤버, 리어 플로어(스페어타이어 자리), 리어 사이드멤버, 리어 크로스멤버, 사이드멤버 리어(킥업)

## 07 · 섀시 전체: 아래에서 본 모습 → `07_chassis.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, generic modern mid-size sedan with no brand features, even soft lighting, wide 16:9 composition.
Subject: bottom-up view of a sedan seen from directly underneath, front of the car on the left. The body floor is drawn as a faint light gray outline. Chassis parts are clearly drawn in graphite and steel blue: front subframe with two lower control arms, steering rack with tie rods between the front wheels, front brake discs, rear subframe with multi-link rear suspension arms, coil springs and shock absorbers at each corner, front and rear stabilizer bars, four wheels, a fuel tank in front of the rear axle (steel blue), and an exhaust pipe running to a muffler at the rear (warm red).
```
꼭 보여야 할 부품: 프론트·리어 서브프레임, 로어암, 스티어링 랙, 브레이크 디스크, 스프링·댐퍼, 스태빌라이저, 휠, 연료탱크, 배기관·머플러

## 08 · 서스펜션 → `08_suspension.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: three automotive suspension units shown side by side in isometric view, each slightly exploded. Left: a front MacPherson strut corner with the pressed steel lower control arm (steel blue), the cast steering knuckle (graphite), the coil spring (warm red) around the shock absorber tube, and a stabilizer bar. Center: a rear multi-link corner with a pressed steel lower spring arm, two thin lateral links, a trailing arm and an upper arm. Right: a twist beam rear axle (coupled torsion beam) with its U-shaped cross beam joining two trailing arms.
```
꼭 보여야 할 부품: 프론트 로어암, 너클, 코일 스프링, 쇼크업소버, 스태빌라이저, 리어 로어암, 래터럴 링크, 트레일링암, 어퍼암, 토션빔(CTBA)

---

## 09 · 서브프레임 → `09_subframe.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: isometric view of two automotive subframes made of welded pressed steel, shown side by side. Left: a front subframe (engine cradle) with its mounting brackets at the four corners and an engine mount bracket on top. Right: a rear subframe for multi-link suspension with its mounting brackets. Thick sheet steel with visible weld seams.
```
꼭 보여야 할 부품: 프론트 서브프레임, 리어 서브프레임, 마운팅 브라켓, 엔진 마운트 브라켓

## 10 · 휠 → `10_wheel.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: exploded three-quarter view of a stamped steel car wheel: the round wheel disc with bolt holes and ventilation holes (steel blue) pulled forward out of the cylindrical wheel rim (light steel gray), and a tire drawn only as a faint gray outline behind them.
```
꼭 보여야 할 부품: 휠 디스크, 휠 림

## 11 · 스티어링 → `11_steering.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: isometric view of a car steering system without the dashboard: a long tubular cross car beam (cowl cross bar) spanning left to right (steel blue), the steering column tube with its mounting bracket attached to the beam, a steering wheel outline, the intermediate shaft going down to the steering rack housing (graphite) with tie rods reaching out to both sides.
```
꼭 보여야 할 부품: 카울 크로스바, 스티어링 컬럼과 브라켓, 랙 하우징, 타이로드

## 12 · 제동·연료·배기 → `12_brake_fuel_exhaust.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: three automotive component groups arranged left to right in isometric view. Left: a disc brake corner with the cast iron brake disc (graphite), the caliper, and the thin pressed steel dust shield behind the disc (steel blue). Center: a pressed steel fuel tank with seam welds around its edge (steel blue). Right: an exhaust pipe running into an oval muffler (warm red) with a thin embossed heat shield plate above it.
```
꼭 보여야 할 부품: 브레이크 디스크, 더스트 커버, 연료탱크, 배기관, 머플러, 차열판

## 13 · 시트 → `13_seat.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: three-quarter view of a bare car front seat skeleton without foam or fabric: the seat back frame (steel blue), the seat cushion frame and pan (light steel gray), the round recliner mechanism at the joint between back and cushion (warm red), and two long seat rails (tracks) underneath (graphite).
```
꼭 보여야 할 부품: 시트백 프레임, 쿠션 프레임, 리클라이너, 시트 레일

## 14 · EV 배터리·모터 → `14_ev.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342, warm red #B8463C and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: left two thirds: exploded isometric view of an electric vehicle battery pack, layers separated vertically: the thin top cover (light steel gray), rows of battery modules (graphite), internal cross members between the modules (warm red), the strong side frame around the edge (warm red), and the flat bottom plate (steel blue). Right third: an electric traction motor shown as a cutaway revealing the stator and rotor made of many thin stacked laminated steel sheets (steel blue).
```
꼭 보여야 할 부품: 상부 커버, 크로스멤버, 사이드 프레임, 하부 플레이트, 모터 코어(적층 철심)

## 15 · 파워트레인·기타 → `15_powertrain.png`

```
Clean technical illustration in flat vector style with subtle shading, consistent dark graphite outlines of even weight, limited palette: steel blue #1F5C99, light steel gray #D3DDE6, graphite #243342 and white, plain pure white background, no text, no labels, no numbers, no logos, no watermark, even soft lighting, wide 16:9 composition.
Subject: isometric view of a car engine block outline in light gray with a deep-drawn sheet steel oil pan attached underneath (steel blue), and a thin embossed heat shield plate (steel blue) next to the exhaust manifold.
```
꼭 보여야 할 부품: 오일팬, 차열판
