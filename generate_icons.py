#!/usr/bin/env python3
"""Generate all PWA icons for Trời Hôm Nay weather app."""

import math

try:
    from PIL import Image, ImageDraw, ImageFont
    USE_PILLOW = True
except ImportError:
    USE_PILLOW = False

def draw_icon_svg(size):
    """Generate SVG icon and save as PNG using cairosvg or basic method."""
    # Draw a beautiful weather icon
    half = size // 2
    
    # Background: deep night-sky gradient
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  <defs>
    <radialGradient id="bg" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#0d2244"/>
      <stop offset="100%" stop-color="#060d1a"/>
    </radialGradient>
    <radialGradient id="glow" cx="50%" cy="30%" r="40%">
      <stop offset="0%" stop-color="#4fc3f7" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#4fc3f7" stop-opacity="0"/>
    </radialGradient>
  </defs>
  
  <!-- Background -->
  <rect width="{size}" height="{size}" rx="{size*0.22}" fill="url(#bg)"/>
  <rect width="{size}" height="{size}" rx="{size*0.22}" fill="url(#glow)"/>
  
  <!-- Stars -->
  <circle cx="{size*0.18}" cy="{size*0.22}" r="{size*0.018}" fill="white" opacity="0.7"/>
  <circle cx="{size*0.75}" cy="{size*0.15}" r="{size*0.014}" fill="white" opacity="0.5"/>
  <circle cx="{size*0.85}" cy="{size*0.30}" r="{size*0.012}" fill="white" opacity="0.6"/>
  <circle cx="{size*0.12}" cy="{size*0.42}" r="{size*0.010}" fill="white" opacity="0.4"/>
  
  <!-- Cloud body -->
  <ellipse cx="{size*0.50}" cy="{size*0.52}" rx="{size*0.32}" ry="{size*0.20}" fill="#1a3a5c" opacity="0.9"/>
  <ellipse cx="{size*0.35}" cy="{size*0.55}" rx="{size*0.18}" ry="{size*0.15}" fill="#1a3a5c" opacity="0.9"/>
  <ellipse cx="{size*0.65}" cy="{size*0.53}" rx="{size*0.20}" ry="{size*0.14}" fill="#1a3a5c" opacity="0.9"/>
  
  <!-- Cloud highlight (lighter top) -->
  <ellipse cx="{size*0.50}" cy="{size*0.50}" rx="{size*0.30}" ry="{size*0.18}" fill="#1e4976" opacity="0.8"/>
  <ellipse cx="{size*0.37}" cy="{size*0.52}" rx="{size*0.17}" ry="{size*0.14}" fill="#1e4976" opacity="0.8"/>
  <ellipse cx="{size*0.63}" cy="{size*0.50}" rx="{size*0.18}" ry="{size*0.13}" fill="#1e4976" opacity="0.8"/>
  
  <!-- Moon (top left, partially behind cloud) -->
  <circle cx="{size*0.35}" cy="{size*0.32}" r="{size*0.15}" fill="#ffd54f" opacity="0.95"/>
  <circle cx="{size*0.42}" cy="{size*0.28}" r="{size*0.13}" fill="#0d2244"/>
  
  <!-- Rain drops -->
  <line x1="{size*0.35}" y1="{size*0.70}" x2="{size*0.32}" y2="{size*0.82}" stroke="#4fc3f7" stroke-width="{size*0.025}" stroke-linecap="round" opacity="0.9"/>
  <line x1="{size*0.50}" y1="{size*0.72}" x2="{size*0.47}" y2="{size*0.84}" stroke="#4fc3f7" stroke-width="{size*0.025}" stroke-linecap="round" opacity="0.85"/>
  <line x1="{size*0.65}" y1="{size*0.70}" x2="{size*0.62}" y2="{size*0.82}" stroke="#29b6f6" stroke-width="{size*0.025}" stroke-linecap="round" opacity="0.9"/>
  <line x1="{size*0.42}" y1="{size*0.76}" x2="{size*0.39}" y2="{size*0.88}" stroke="#81d4fa" stroke-width="{size*0.020}" stroke-linecap="round" opacity="0.7"/>
  <line x1="{size*0.57}" y1="{size*0.76}" x2="{size*0.54}" y2="{size*0.88}" stroke="#81d4fa" stroke-width="{size*0.020}" stroke-linecap="round" opacity="0.7"/>
</svg>'''
    return svg


def save_svg_as_png(svg_content, output_path, size):
    """Try multiple methods to save SVG as PNG."""
    # Method 1: cairosvg
    try:
        import cairosvg
        cairosvg.svg2png(bytestring=svg_content.encode(), write_to=output_path, output_width=size, output_height=size)
        return True
    except ImportError:
        pass
    
    # Method 2: Pillow-based drawing
    try:
        from PIL import Image, ImageDraw, ImageFilter
        
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Background with rounded corners
        r = int(size * 0.22)
        
        # Draw rounded rect background
        from PIL import ImageDraw
        # Dark background
        bg_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        bg_draw = ImageDraw.Draw(bg_img)
        bg_draw.rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=(6, 13, 26, 255))
        img.paste(bg_img, mask=bg_img)
        
        draw = ImageDraw.Draw(img)
        
        # Moon
        mx, my, mr = int(size*0.35), int(size*0.32), int(size*0.15)
        draw.ellipse([mx-mr, my-mr, mx+mr, my+mr], fill=(255, 213, 79, 240))
        # Moon shadow
        sx, sy = int(size*0.42), int(size*0.28)
        sr = int(size*0.13)
        draw.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(13, 34, 68, 255))
        
        # Cloud
        draw.ellipse([int(size*0.18), int(size*0.34), int(size*0.82), int(size*0.66)], fill=(30, 73, 118, 220))
        draw.ellipse([int(size*0.17), int(size*0.37), int(size*0.53), int(size*0.67)], fill=(30, 73, 118, 220))
        draw.ellipse([int(size*0.43), int(size*0.37), int(size*0.83), int(size*0.66)], fill=(30, 73, 118, 220))
        
        # Cloud highlight
        draw.ellipse([int(size*0.20), int(size*0.32), int(size*0.80), int(size*0.62)], fill=(40, 90, 140, 200))
        
        # Rain drops
        lw = max(2, int(size * 0.025))
        rain_color = (79, 195, 247, 230)
        draw.line([(int(size*0.35), int(size*0.70)), (int(size*0.32), int(size*0.82))], fill=rain_color, width=lw)
        draw.line([(int(size*0.50), int(size*0.72)), (int(size*0.47), int(size*0.84))], fill=rain_color, width=lw)
        draw.line([(int(size*0.65), int(size*0.70)), (int(size*0.62), int(size*0.82))], fill=rain_color, width=lw)
        draw.line([(int(size*0.42), int(size*0.76)), (int(size*0.39), int(size*0.88))], fill=(129, 212, 250, 180), width=max(1, lw-1))
        draw.line([(int(size*0.57), int(size*0.76)), (int(size*0.54), int(size*0.88))], fill=(129, 212, 250, 180), width=max(1, lw-1))
        
        img.save(output_path, 'PNG')
        return True
    except Exception as e:
        print(f"  Pillow method failed: {e}")
    
    return False


def main():
    import os
    import sys
    
    icons_dir = os.path.join(os.path.dirname(__file__), 'icons')
    os.makedirs(icons_dir, exist_ok=True)
    
    sizes = [72, 96, 128, 144, 152, 167, 180, 192, 512]
    
    for size in sizes:
        svg = draw_icon_svg(size)
        out = os.path.join(icons_dir, f'icon-{size}.png')
        ok = save_svg_as_png(svg, out, size)
        if ok:
            print(f"  ✓ icon-{size}.png")
        else:
            print(f"  ✗ icon-{size}.png - Failed")
    
    print("\nDone!")


if __name__ == '__main__':
    main()
