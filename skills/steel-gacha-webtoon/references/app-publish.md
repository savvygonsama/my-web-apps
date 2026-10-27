# 완성 그림을 앱에 올리기

앱: `savvygonsama/steel-grade-gacha`. 웹툰 데이터는 `src/app_tpl.html`의 `TOON` 목록, 그림은 저장소 뿌리의 `webtoon/`.
뷰어는 `pages` 그림을 위에서 아래로 이어 붙이고, `note`가 있으면 맨 아래 각주로 보여 준다. 목록은 최신 화가 위, 안 본 화에는 NEW.

## 순서
1. **그림 순서 확인**: 사용자가 보낸 순서가 콘티 순서와 다를 수 있다(3화는 두 번에 나눠 섞여 왔다). 그림을 보고 콘티 표와 맞춘다. 추가 컷(콘티에 없던 장면)은 어디에 둘지 판단해 알리고, 사용자가 순서를 정하면 따른다.
2. **브랜치**: 앞 PR이 머지됐으면 `git fetch origin main && git checkout -B <작업 브랜치> origin/main`으로 새로 시작. 아직 열려 있으면 그 브랜치에 이어서 올린다.
3. **스크립트 실행**:
   ```
   python3 skills/steel-gacha-webtoon/scripts/add_episode.py \
     --app /home/user/steel-grade-gacha --ep 4 --title "볼트 하나" \
     --note "※ 자동차의 볼트·현가 스프링·타이어 속 강선(타이어코드)은 모두 선재로 만듭니다." \
     --thumb 6  컷1 컷2 ... 컷8
   ```
   - 컷을 1000px 폭 WebP로 저장, 썸네일 생성, TOON에 추가, `sw.js` 캐시 버전 +1, `src/build.sh` 실행.
   - 같은 화를 고쳐 올릴 땐 `--replace`(컷 수가 줄면 남는 파일도 지운다).
   - 업로드 파일은 `/root/.claude/uploads/<세션>/` 또는 `/tmp/.../images/`에 있다. 파일명이 아니라 **그림을 보고** 순서를 정한다.
4. **확인**: 로컬 서버(`python3 -m http.server`)를 띄우고 Playwright(Chromium `/opt/pw-browsers`)로 390px 화면에서 목록 → 해당 화 → 끝까지 스크롤. 모든 컷이 뜨는지, 콘솔 오류가 없는지, 각주가 보이는지. 스크린샷 세 장(목록·첫 화면·끝)을 이어 붙여 사용자에게 보낸다.
5. **커밋·PR**: 커밋 메시지에 화 번호·제목·컷 수. PR을 만들고 링크를 준다. **머지는 사용자가 한다**(Claude의 머지는 권한 검사에서 막힌다).

## 손으로 할 때 (스크립트를 못 쓸 때)
- `webtoon/epNN-1.webp`… 저장, `th-epNN.webp`(240px) 저장
- `TOON` 맨 끝에 `{ id: "epNN", no: "N화", title, date: "YYYY.MM.DD", thumb, note, pages: [{ img, w, h }, …] }`
- `sw.js`의 `steel-grade-gacha-vNN` +1, `bash src/build.sh`(목록이 가리키는 그림이 없으면 빌드가 멈춘다)

## 그 밖의 앱 웹툰 문구
- 등장인물 소개(`s00`)의 캐릭터 한 줄 소개는 TOON 첫 항목 `cap`에 있다. 캐릭터 설정이 바뀌면(예: 타래 '뾰잉' 삭제) 여기도 같이 고친다.
- 새 캐릭터가 연재에 합류하면 등장인물 소개에 시트를 추가할지 사용자에게 묻는다.
