# 글꼴을 base64로 심어 단일 HTML 파일을 만듭니다.
# 사용법 (저장소 최상위에서):  powershell -ExecutionPolicy Bypass -File app/build.ps1

$root     = Split-Path -Parent $PSScriptRoot
$template = Join-Path $PSScriptRoot "app-template.html"
$fonts    = Join-Path $PSScriptRoot "fonts"
$outDir   = Join-Path $root "dist"
$out      = Join-Path $outDir "철강일본어_트레이닝.html"

$map = @{
  "__NJP400__" = "notojp-400.woff2"
  "__NJP700__" = "notojp-700.woff2"
  "__ZOM400__" = "zenold-400.woff2"
  "__PRE400__" = "pretendard-400.woff2"
  "__PRE700__" = "pretendard-700.woff2"
}

if (-not (Test-Path $template)) { throw "템플릿을 찾을 수 없습니다: $template" }
if (-not (Test-Path $outDir))   { New-Item -ItemType Directory -Force $outDir | Out-Null }

$html = [IO.File]::ReadAllText($template, [Text.Encoding]::UTF8)

foreach ($key in $map.Keys) {
  $path = Join-Path $fonts $map[$key]
  if (-not (Test-Path $path)) { throw "글꼴 파일이 없습니다: $path" }
  $html = $html.Replace($key, [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)))
}

if ($html -match "__[A-Z0-9]+__") { throw "치환되지 않은 자리표시자가 남아 있습니다." }

# BOM 없는 UTF-8로 저장 — 브라우저가 한글·일본어를 바르게 읽도록
[IO.File]::WriteAllText($out, $html, (New-Object Text.UTF8Encoding($false)))

"완료: $out  ({0:N2} MB)" -f ((Get-Item $out).Length / 1MB)
