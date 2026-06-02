#!/usr/bin/env python3
"""把 pet sprite 內被「畫成」棋盤格 / 純色的假透明背景,改成真正的 alpha 透明。

gpt-image 產 sprite 時常把「transparent background」畫成不透明的灰色棋盤格,
導致 PNG 沒有 alpha(hasAlpha: no)。這支腳本用「從邊界往內 flood」的方式,
把與邊界相連、低飽和度的淺灰背景(棋盤格)挖成透明,角色內部的白色盔甲因為
被角色包住、不與邊界相連,會保留下來。
"""
import sys, glob, os
import numpy as np
from PIL import Image
from scipy import ndimage

PETS_DIR = os.path.join(os.path.dirname(__file__), "..",
                        "MacFocus", "Assets.xcassets", "pets")

def dealpha(path: str, tol: int = 60) -> bool:
    img = Image.open(path).convert("RGB")
    arr = np.asarray(img).astype(np.float32)
    h, w = arr.shape[:2]
    # 以四個角落取樣當「背景色種子」:能同時涵蓋純黑/純色背景,
    # 以及由兩種灰階方格組成的假棋盤格背景。
    seeds = [arr[0, 0], arr[0, w - 1], arr[h - 1, 0], arr[h - 1, w - 1]]
    bg_like = np.zeros(arr.shape[:2], dtype=bool)
    for s in seeds:
        dist = np.sqrt(((arr - s) ** 2).sum(axis=-1))
        bg_like |= dist < tol
    # 連通元件:只把「碰到邊界」的背景區塊挖透明,角色內部的同色像素保留。
    labels, n = ndimage.label(bg_like)
    border = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
    border.discard(0)
    transparent = np.isin(labels, list(border))
    # 邊緣羽化一格,避免鋸齒硬邊。
    alpha = np.where(transparent, 0, 255).astype(np.uint8)
    out = np.dstack([np.asarray(img), alpha])
    Image.fromarray(out, "RGBA").save(path)
    removed = transparent.mean() * 100
    print(f"  ✓ {os.path.basename(path)} — 透明背景 {removed:.0f}%")
    return True

def main():
    target = sys.argv[1] if len(sys.argv) > 1 else None
    pngs = sorted(glob.glob(os.path.join(PETS_DIR, "*.imageset", "*.png")))
    if target:
        pngs = [p for p in pngs if target in p]
    for p in pngs:
        dealpha(p)
    print(f"完成,共 {len(pngs)} 張。")

if __name__ == "__main__":
    main()
