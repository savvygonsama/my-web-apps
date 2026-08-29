# 아티팩트 안을 들여다보는 방법

이 앱들은 Claude 아티팩트로 게시되어 있다. 회차를 고치거나 현재 상태를 확인하려면 안을 봐야 하는데,
평범한 방법이 대체로 막힌다. 아래는 실제로 통한 경로다. 위에서부터 시도하라.

## 1. Artifact 도구로 읽기 (되면 가장 간단하다)

```
Artifact { action: "read", url: "https://claude.ai/code/artifact/<uuid>" }
```

환경의 네트워크 허용 목록에 `*.frame.claudeusercontent.com`이 없으면 막힌다.
막히면 그 사실을 알려 주는 오류가 돌아온다. 두 번 시도하지 말고 다음으로 넘어가라.

## 2. WebFetch

같은 URL로 `WebFetch`. 1번과 같은 이유로 막히는 경우가 많다. 한 번만 시도한다.

## 3. 내장 브라우저 우회 (이게 실제로 통한다)

핵심은 **아티팩트 본문이 별도 출처(origin)의 프레임에 들어 있다**는 것이다.
그 출처 안에 발을 들여놓은 뒤 같은 출처로 `fetch`를 걸면 원문이 통째로 나온다.

**3-1. 뷰어 페이지를 열어 프레임 주소를 알아낸다**

```
Claude_Browser__preview_start { url: "https://claude.ai/code/artifact/<uuid>" }
Claude_Browser__javascript_tool {
  action: "javascript_exec", tabId: "<위에서 받은 id>",
  text: "JSON.stringify([...document.querySelectorAll('iframe')].map(f=>f.src))"
}
```

`https://<uuid>.frame.claudeusercontent.com/_f/<빌드번호>/?__frame_v=manifest.<해시>.json` 형태가 나온다.
이 주소는 아티팩트를 갱신하면 바뀐다. 매번 새로 알아내라.

**3-2. 그 출처에 자리를 잡는다**

```
Claude_Browser__request_access { url: "https://<uuid>.frame.claudeusercontent.com", scope: "site" }
Claude_Browser__preview_start   { url: "https://<uuid>.frame.claudeusercontent.com/nonexistent" }
```

없는 주소라 "not found"가 뜨는데, 그래도 된다. 필요한 건 페이지 내용이 아니라 **그 출처에 선 것**이다.
루트(`/`)도 "not found"를 돌려주므로 아무 경로나 좋다.

**3-3. 같은 출처에서 원문을 받아 온다**

```js
fetch('/_f/<빌드번호>/?__frame_v=manifest.<해시>.json')
  .then(r => r.text())
  .then(t => { window.__t = t; return JSON.stringify({len: t.length}); })
```

`window.__t`에 담아 두는 것이 요령이다. 이 앱들은 7MB를 넘어 한 번에 볼 수 없으므로,
이후 호출에서 필요한 조각만 잘라 본다.

## 4. 큰 파일에서 필요한 곳만 찾기

받아 온 원문은 대부분 **음성 데이터(base64)**다. 실제로 볼 코드는 아주 일부다.
전체를 출력하려 들지 말고 위치부터 찾아라.

```js
(() => { const t = window.__t;
  const decls = [...t.matchAll(/^\s*const\s+([A-Z_][A-Z_0-9]*)\s*=/gm)]
                  .map(m => m[1] + '@' + m.index);
  return JSON.stringify({ len: t.length, decls });
})()
```

`DATA`, `DAYS`, `CONTENT_BUILTIN`, `AUDIO_DATA` 같은 이름과 그 위치가 나온다.
다음 호출에서 `t.slice(시작, 끝)`으로 필요한 만큼만 꺼낸다. 한 번에 4000자 정도가 다루기 좋다.

회차 개수와 목록은 이런 식으로 센다.

```js
[...t.slice(dataStart, dataEnd).matchAll(/\n\s*no:\s*(\d+),/g)].map(m => m[1])
```

## 주의

- 프레임 주소는 아티팩트를 갱신할 때마다 바뀐다. 예전 대화에서 본 주소를 재사용하지 마라.
- 브라우저 접근 승인은 사용자에게 확인 창이 뜬다. 한 번에 필요한 출처만 요청하라.
- 이 경로는 **읽기용**이다. 고쳐서 다시 올리는 것은 Artifact 도구로 해야 하고,
  그 전에 원본을 반드시 백업해 둔다.
