"""Compose the Full Disk Access guide frames (assets/guide/step{1..5}.png, 1200x750)
from raw screenshots in ~/Downloads/broom. Re-run after replacing screenshots."""
from PIL import Image, ImageDraw, ImageFilter
import os

SRC = os.path.expanduser('~/Downloads/broom')
OUT = 'assets/guide'
W, H = 1200, 750
BG0, BG1 = (14, 17, 38), (30, 22, 70)
PINK = (233, 97, 255)

def canvas():
    im = Image.new('RGBA', (W, H)); px = im.load()
    for y in range(H):
        t = y / H
        c = tuple(int(BG0[i] + (BG1[i] - BG0[i]) * t) for i in range(3)) + (255,)
        for x in range(W): px[x, y] = c
    return im

def load(n): return Image.open(f'{SRC}/step{n}.png').convert('RGBA')

def fit(im, w, h):
    s = min(w / im.width, h / im.height)
    return im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS), s

def rounded(im, r=18):
    m = Image.new('L', im.size, 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    out = im.copy(); out.putalpha(m); return out

def paste_shadow(cv, im, x, y):
    sh = Image.new('RGBA', (im.width + 80, im.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((40, 52, 40 + im.width, 52 + im.height), 18, fill=(0, 0, 0, 170))
    sh = sh.filter(ImageFilter.GaussianBlur(22))
    cv.alpha_composite(sh, (x - 40, y - 40))
    cv.alpha_composite(im, (x, y))

def ring(cv, box, pad=10):
    x0, y0, x1, y1 = box
    glow = Image.new('RGBA', cv.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle((x0 - pad, y0 - pad, x1 + pad, y1 + pad), 14, outline=PINK + (255,), width=14)
    cv.alpha_composite(glow.filter(ImageFilter.GaussianBlur(10)))
    ImageDraw.Draw(cv).rounded_rectangle((x0 - pad, y0 - pad, x1 + pad, y1 + pad), 14, outline=PINK + (255,), width=5)

def save(cv, n): cv.convert('RGB').save(f'{OUT}/step{n}.png', optimize=True)

# 1 ── Settings page: header + first rows
s1 = load(1)
im = rounded(s1.crop((0, 0, 970, 760))); im, s = fit(im, 1120, 680)
cv = canvas(); paste_shadow(cv, im, (W - im.width) // 2, (H - im.height) // 2)
save(cv, 1)

# 2 ── "+" button (bottom of the list) + the Touch ID / password prompt
cv = canvas()
lst = rounded(s1.crop((0, 1090, 970, 1384))); lst, s = fit(lst, 620, 400)
lx, ly = 40, (H - lst.height) // 2
paste_shadow(cv, lst, lx, ly)
# "+" sits at ~(58,1329) in the original
px, py = lx + (58 - 0) * s, ly + (1329 - 1090) * s
ring(cv, (px - 22 * s, py - 22 * s, px + 22 * s, py + 22 * s), pad=8)
dlg = rounded(load(2)); dlg, _ = fit(dlg, 480, 620)
paste_shadow(cv, dlg, W - dlg.width - 50, (H - dlg.height) // 2)
save(cv, 2)

# 3 ── File picker: search for MacBroom, pick it
s3 = load(3); im = rounded(s3); im, s = fit(im, 1120, 680)
cv = canvas(); ox, oy = (W - im.width) // 2, (H - im.height) // 2
paste_shadow(cv, im, ox, oy)
ring(cv, (ox + 1020 * s, oy + 4 * s, ox + 1410 * s, oy + 50 * s))          # search field
ring(cv, (ox + 40 * s, oy + 250 * s, ox + 170 * s, oy + 420 * s))          # MacBroom.app
save(cv, 3)

# 4 ── Quit & Reopen prompt
s4 = load(4); im = rounded(s4); im, s = fit(im, 760, 560)
cv = canvas(); ox, oy = (W - im.width) // 2, (H - im.height) // 2
paste_shadow(cv, im, ox, oy)
ring(cv, (ox + 38 * s, oy + 218 * s, ox + 492 * s, oy + 272 * s))          # 종료 및 다시 열기
save(cv, 4)

# 5 ── Granted: MacBroom row with the switch on
s5 = load(5); im = rounded(s5.crop((0, 470, 934, 920))); im, s = fit(im, 1120, 680)
cv = canvas(); ox, oy = (W - im.width) // 2, (H - im.height) // 2
paste_shadow(cv, im, ox, oy)
ring(cv, (ox + 826 * s, oy + (688 - 470) * s, ox + 906 * s, oy + (722 - 470) * s))   # MacBroom toggle
save(cv, 5)
print('guide frames written to', OUT)
