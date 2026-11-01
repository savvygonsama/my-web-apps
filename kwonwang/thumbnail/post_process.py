import sys
import numpy as np
from PIL import Image, ImageFilter
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
a = np.asarray(im).astype(np.float32) / 255.0
H, W = a.shape[:2]
# 빛 번짐: 밝은 곳만 뽑아 여러 크기로 흐려 더한다
lum = a.mean(axis=2, keepdims=True)
bright = np.clip((lum - 0.62) / 0.38, 0, 1) * a
b = Image.fromarray((bright * 255).astype(np.uint8))
bloom = np.zeros_like(a)
for r, wgt in [(6, 0.6), (18, 0.5), (48, 0.45), (110, 0.35)]:
    bloom += np.asarray(b.filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255.0 * wgt
a = a + bloom * 0.9
# 색감: 어두운 곳은 푸르게, 밝은 곳은 따뜻하게, 대비 조금
shadow = np.array([0.92, 0.97, 1.08]); high = np.array([1.06, 1.0, 0.92])
t = np.clip(lum, 0, 1)
a = a * (shadow * (1 - t) + high * t)
a = np.clip((a - 0.5) * 1.08 + 0.5, 0, None)
# 가장자리 어둡게
yy, xx = np.mgrid[0:H, 0:W]
d = np.sqrt(((xx - W * 0.52) / (W * 0.62)) ** 2 + ((yy - H * 0.5) / (H * 0.72)) ** 2)
a = a * np.clip(1.15 - 0.55 * d ** 2, 0.25, 1)[..., None]
# 필름 결
a += np.random.default_rng(2).normal(0, 0.008, a.shape)
out = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
out.save(dst)
print("ok", out.size)
