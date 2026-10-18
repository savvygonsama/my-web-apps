# 로컬 미리보기 서버 (Windows PowerShell). 저장소 루트(my-web-apps)를 http://localhost:8123/ 으로 연다.
param([int]$Port = 8123)
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$types = @{ ".html"="text/html; charset=utf-8"; ".js"="text/javascript; charset=utf-8"; ".css"="text/css; charset=utf-8";
  ".json"="application/json"; ".webmanifest"="application/manifest+json"; ".png"="image/png"; ".svg"="image/svg+xml";
  ".woff2"="font/woff2"; ".md"="text/plain; charset=utf-8"; ".mp3"="audio/mpeg" }
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
Write-Output "serving $root on http://localhost:$Port/"
while ($l.IsListening) {
  $ctx = $l.GetContext(); $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    $file = Join-Path $root ($path.TrimStart('/') -replace '/', '\')
    if (Test-Path $file -PathType Container) { $file = Join-Path $file "index.html" }
    if (Test-Path $file -PathType Leaf) {
      $bytes = [IO.File]::ReadAllBytes($file)
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $res.ContentType = if ($types[$ext]) { $types[$ext] } else { "application/octet-stream" }
      $res.Headers.Add("Cache-Control", "no-cache")
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.StatusCode = 404 }
  } catch { $res.StatusCode = 500 }
  $res.Close()
}
