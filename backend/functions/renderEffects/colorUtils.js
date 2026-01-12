/* Color utility functions for wine visualization */

// Acidity color (greenish tinge)
export const AcidityColor = { h: 85, s: 0.5, v: 0.7 };

// Base colors for wine types (HSV) - fallback if Gemini doesn't provide
export const WineTypeBaseColors = {
  red: { h: 345, s: 0.85, v: 0.45 },
  white: { h: 48, s: 0.35, v: 0.95 },
  rose: { h: 355, s: 0.45, v: 0.88 },
  orange: { h: 25, s: 0.65, v: 0.85 },
  sparkling: { h: 52, s: 0.15, v: 0.98 },
  dessert: { h: 38, s: 0.75, v: 0.75 },
  fortified: { h: 15, s: 0.8, v: 0.3 },
};

/** Convert HSV to RGB hex string */
export function hsvToHex(h, s, v) {
  h = ((h % 360) + 360) % 360;

  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;

  let r, g, b;
  if (h < 60) {
    r = c; g = x; b = 0;
  } else if (h < 120) {
    r = x; g = c; b = 0;
  } else if (h < 180) {
    r = 0; g = c; b = x;
  } else if (h < 240) {
    r = 0; g = x; b = c;
  } else if (h < 300) {
    r = x; g = 0; b = c;
  } else {
    r = c; g = 0; b = x;
  }

  const toHex = (val) =>
    Math.round((val + m) * 255)
      .toString(16)
      .padStart(2, "0");
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/** Convert HSV to RGB object */
export function hsvToRgb(h, s, v) {
  const hex = hsvToHex(h, s, v);
  return {
    r: parseInt(hex.slice(1, 3), 16),
    g: parseInt(hex.slice(3, 5), 16),
    b: parseInt(hex.slice(5, 7), 16),
  };
}

/** Blend two HSV colors */
export function blendHSV(color1, color2, ratio) {
  let h1 = color1.h;
  let h2 = color2.h;

  // Handle hue wrapping
  if (Math.abs(h1 - h2) > 180) {
    if (h1 < h2) h1 += 360;
    else h2 += 360;
  }

  return {
    h: (h1 * (1 - ratio) + h2 * ratio) % 360,
    s: color1.s * (1 - ratio) + color2.s * ratio,
    v: color1.v * (1 - ratio) + color2.v * ratio,
  };
}
