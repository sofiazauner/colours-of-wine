/* applyBubbles.js
 *
 * Spritzigkeits-Stufen:
 * - Still (0.0 - 0.20): praktisch keine/kaum Bubbles
 * - Perlend (0.20 - 0.45): wenige, zarte Bubbles
 * - Spritzig (0.45 - 0.75): deutlich sichtbare Bubbles
 * - Stark spritzig (0.75 - 1.00): hohe Dichte, stärkerer Glow
 */

export function applyBubbles(
    ctx,
    centerX,
    centerY,
    maxRadius,
    width,
    height,
    spritz,
    intensity = 1,
    options = {}
) {
    const s = clamp01((spritz ?? 0) * (intensity ?? 1));
    if (s <= 0.02) return;

    const includeEdgeBokeh = options.includeEdgeBokeh !== false; // Standard: an
    const includeSparkle = options.includeSparkle !== false;     // Standard: an

    const seed =
        typeof options.seed === "number"
            ? options.seed
            : hashSeed(centerX, centerY, maxRadius, width, height, s);

    const rand = mulberry32(seed);

    // Parameter je Stufe bestimmen
    const stage = getSpritzStage(s);

    ctx.save();
    ctx.globalCompositeOperation = "source-over";

    if (includeEdgeBokeh) {
        drawEdgeBokehOutside(ctx, centerX, centerY, maxRadius, width, height, s, rand, stage);
        drawEdgeBokehOverRim(ctx, centerX, centerY, maxRadius, width, height, s, rand, stage);
    }

    if (includeSparkle) {
        drawMicroSparkle(ctx, centerX, centerY, maxRadius, s, rand, stage);
    }

    ctx.restore();
}

/* =========================
   Stufen-Logik (Kategorien)
   ========================= */

function getSpritzStage(s) {
    // Stufen wie bei applyBody: mehrere klar definierte Bereiche
    if (s < 0.20) {
        return {
            name: "still",
            outsideCountBase: 0,
            outsideCountMul: 40,
            rimCountBase: 0,
            rimCountMul: 25,
            outsideRMin: 1.8, outsideRMax: 6.0,
            rimRMin: 1.5, rimRMax: 5.0,
            outsideAlphaBase: 0.04, outsideAlphaMul: 0.10,
            rimAlphaBase: 0.04, rimAlphaMul: 0.12,
            glowBase: 0.01, glowMul: 0.04,
            innerR: 0.78, outerR: 1.04,
            keepout: 1.06,
            sparkleBase: 0, sparkleMul: 40,
            sparkleAlphaBase: 0.002, sparkleAlphaMul: 0.006,
        };
    } else if (s < 0.45) {
        return {
            name: "perlend",
            outsideCountBase: 35,
            outsideCountMul: 220,
            rimCountBase: 20,
            rimCountMul: 130,
            outsideRMin: 1.8, outsideRMax: 6.0,
            rimRMin: 1.5, rimRMax: 5.0,
            outsideAlphaBase: 0.10, outsideAlphaMul: 0.22,
            rimAlphaBase: 0.10, rimAlphaMul: 0.24,
            glowBase: 0.03, glowMul: 0.08,
            innerR: 0.74, outerR: 1.06,
            keepout: 1.04,
            sparkleBase: 10, sparkleMul: 90,
            sparkleAlphaBase: 0.003, sparkleAlphaMul: 0.010,
        };
    } else if (s < 0.75) {
        return {
            name: "spritzig",
            outsideCountBase: 80,
            outsideCountMul: 360,
            rimCountBase: 55,
            rimCountMul: 200,
            outsideRMin: 1.8, outsideRMax: 6.0,
            rimRMin: 1.5, rimRMax: 5.0,
            outsideAlphaBase: 0.14, outsideAlphaMul: 0.28,
            rimAlphaBase: 0.16, rimAlphaMul: 0.30,
            glowBase: 0.05, glowMul: 0.12,
            innerR: 0.70, outerR: 1.08,
            keepout: 1.02,
            sparkleBase: 16, sparkleMul: 120,
            sparkleAlphaBase: 0.004, sparkleAlphaMul: 0.012,
        };
    } else {
        return {
            name: "stark_spritzig",
            outsideCountBase: 140,
            outsideCountMul: 480,
            rimCountBase: 95,
            rimCountMul: 260,
            outsideRMin: 1.8, outsideRMax: 6.0,
            rimRMin: 1.5, rimRMax: 5.0,
            outsideAlphaBase: 0.16, outsideAlphaMul: 0.34,
            rimAlphaBase: 0.18, rimAlphaMul: 0.36,
            glowBase: 0.06, glowMul: 0.16,
            innerR: 0.66, outerR: 1.10,
            keepout: 1.01,
            sparkleBase: 22, sparkleMul: 150,
            sparkleAlphaBase: 0.004, sparkleAlphaMul: 0.014,
        };
    }
}

/* =========================
   Teil 1: Bubbles außen am Bildrand
   ========================= */

function drawEdgeBokehOutside(ctx, cx, cy, R, width, height, s, rand, stage) {
    const band = Math.max(26, Math.min(width, height) * 0.16);

    // Anzahl je Stufe
    const count = Math.floor(stage.outsideCountBase + stage.outsideCountMul * s);

    // Pastellpalette (gewichtete Auswahl)
    const palette = [
        [255, 255, 255, 0.20],
        [255, 230, 240, 0.20],
        [255, 205, 228, 0.30],
        [255, 170, 215, 0.30],
    ];
    const weightSum = palette.reduce((sum, p) => sum + p[3], 0);

    // Außen soll „außen“ bleiben (wie dein funktionierender Stand),
    // aber Stufe beeinflusst die Aggressivität minimal.
    const keepout = R * stage.keepout;
    const keepout2 = keepout * keepout;

    for (let placed = 0, attempts = 0, maxAttempts = count * 14; placed < count && attempts < maxAttempts; attempts++) {
        const p = rand();
        let x, y;

        if (p < 0.46) {
            x = lerp(0, band, Math.pow(rand(), 0.55));
            y = rand() * height;
        } else if (p < 0.92) {
            x = lerp(width - band, width, 1 - Math.pow(rand(), 0.55));
            y = rand() * height;
        } else {
            x = rand() < 0.5 ? rand() * band : width - rand() * band;
            y = rand() < 0.5 ? rand() * band : height - rand() * band;
        }

        const dx = x - cx;
        const dy = y - cy;
        if (dx * dx + dy * dy < keepout2) continue;

        // Größe & Alpha je Stufe
        const r = lerp(stage.outsideRMin, stage.outsideRMax, Math.pow(rand(), 0.6)) * (0.85 + s * 0.85);
        const a = (stage.outsideAlphaBase + stage.outsideAlphaMul * s) * (0.55 + 0.55 * rand());

        const c = pickWeightedColor(palette, weightSum, rand);
        drawBokehCircle(ctx, x, y, r, c[0], c[1], c[2], a, rand);

        placed++;
    }

    // Weicher Schimmer außen je Stufe
    const glowA = stage.glowBase + stage.glowMul * s;
    drawSideGlow(ctx, width, height, band, glowA);
}

/* =========================
   Teil 2: Bubbles über dem Kreisrand (Ring-Clip)
   ========================= */

function drawEdgeBokehOverRim(ctx, cx, cy, R, width, height, s, rand, stage) {
    const band = Math.max(26, Math.min(width, height) * 0.16);

    // Anzahl je Stufe
    const count = Math.floor(stage.rimCountBase + stage.rimCountMul * s);

    const palette = [
        [255, 255, 255, 0.20],
        [255, 230, 240, 0.20],
        [255, 205, 228, 0.30],
        [255, 170, 215, 0.30],
    ];
    const weightSum = palette.reduce((sum, p) => sum + p[3], 0);

    // Ringbereich je Stufe
    const innerR = R * stage.innerR;
    const outerR = R * stage.outerR;

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, outerR, 0, Math.PI * 2);
    ctx.arc(cx, cy, innerR, 0, Math.PI * 2, true);
    ctx.clip();

    for (let placed = 0, attempts = 0, maxAttempts = count * 14; placed < count && attempts < maxAttempts; attempts++) {
        const p = rand();
        let x, y;

        if (p < 0.46) {
            x = lerp(0, band, Math.pow(rand(), 0.55));
            y = rand() * height;
        } else if (p < 0.92) {
            x = lerp(width - band, width, 1 - Math.pow(rand(), 0.55));
            y = rand() * height;
        } else {
            x = rand() < 0.5 ? rand() * band : width - rand() * band;
            y = rand() < 0.5 ? rand() * band : height - rand() * band;
        }

        const r = lerp(stage.rimRMin, stage.rimRMax, Math.pow(rand(), 0.7)) * (0.85 + s * 0.85);
        const a = (stage.rimAlphaBase + stage.rimAlphaMul * s) * (0.60 + 0.55 * rand());

        const c = pickWeightedColor(palette, weightSum, rand);
        drawBokehCircle(ctx, x, y, r, c[0], c[1], c[2], a, rand);

        placed++;
    }

    ctx.restore();
}

/* =========================
   Rendering / Hilfen
   ========================= */

function pickWeightedColor(palette, total, rand) {
    let t = rand() * total;
    for (let i = 0; i < palette.length; i++) {
        t -= palette[i][3];
        if (t <= 0) return palette[i];
    }
    return palette[palette.length - 1];
}

function drawBokehCircle(ctx, x, y, r, rr, gg, bb, alpha, rand) {
    const inner = Math.max(0.5, r * (0.06 + 0.10 * rand()));
    const g = ctx.createRadialGradient(x, y, inner, x, y, r);

    g.addColorStop(0.0, `rgba(${rr}, ${gg}, ${bb}, ${clamp01(alpha * 0.65)})`);
    g.addColorStop(0.55, `rgba(${rr}, ${gg}, ${bb}, ${clamp01(alpha)})`);
    g.addColorStop(1.0, `rgba(${rr}, ${gg}, ${bb}, 0)`);

    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();

    // Dezenter Ring
    if (rand() < 0.55) {
        ctx.strokeStyle = `rgba(255,255,255,${clamp01(alpha * 0.28)})`;
        ctx.lineWidth = Math.max(0.8, r * 0.06);
        ctx.beginPath();
        ctx.arc(x, y, r * 0.82, 0, Math.PI * 2);
        ctx.stroke();
    }

    // Highlight-Punkt
    if (rand() < 0.65) {
        const hx = x - r * (0.18 + 0.18 * rand());
        const hy = y - r * (0.18 + 0.18 * rand());
        const hr = r * (0.10 + 0.10 * rand());
        const hg = ctx.createRadialGradient(hx, hy, 0, hx, hy, hr);

        hg.addColorStop(0, `rgba(255,255,255,${clamp01(alpha * 0.55)})`);
        hg.addColorStop(1, "rgba(255,255,255,0)");

        ctx.fillStyle = hg;
        ctx.beginPath();
        ctx.arc(hx, hy, hr, 0, Math.PI * 2);
        ctx.fill();
    }
}

function drawSideGlow(ctx, width, height, band, alpha) {
    {
        const gx = -band * 0.15;
        const gy = height * 0.5;
        const gr = band * 1.55;
        const g = ctx.createRadialGradient(gx, gy, 0, gx, gy, gr);

        g.addColorStop(0.0, `rgba(255, 210, 235, ${clamp01(alpha)})`);
        g.addColorStop(1.0, "rgba(255, 210, 235, 0)");

        ctx.fillStyle = g;
        ctx.fillRect(0, 0, band * 1.2, height);
    }

    {
        const gx = width + band * 0.15;
        const gy = height * 0.5;
        const gr = band * 1.55;
        const g = ctx.createRadialGradient(gx, gy, 0, gx, gy, gr);

        g.addColorStop(0.0, `rgba(200, 230, 255, ${clamp01(alpha * 0.9)})`);
        g.addColorStop(1.0, "rgba(200, 230, 255, 0)");

        ctx.fillStyle = g;
        ctx.fillRect(width - band * 1.2, 0, band * 1.2, height);
    }
}

/* =========================
   Subtiles „Sparkle“ im Wein
   ========================= */

function drawMicroSparkle(ctx, cx, cy, R, s, rand, stage) {
    // Still: praktisch kein Sparkle
    const n = Math.floor(stage.sparkleBase + stage.sparkleMul * s);
    if (n <= 0) return;

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, R * 0.98, 0, Math.PI * 2);
    ctx.clip();

    for (let i = 0; i < n; i++) {
        const rt = Math.pow(rand(), 0.6);
        const ang = rand() * Math.PI * 2;

        const x = cx + Math.cos(ang) * R * rt;
        const y = cy + Math.sin(ang) * R * rt;

        const size = (0.45 + rand() * 0.9) * (0.85 + s * 0.35);
        const a = (stage.sparkleAlphaBase + stage.sparkleAlphaMul * s) * (0.25 + 0.75 * rand());

        ctx.fillStyle = rand() < 0.18
            ? `rgba(170,220,150,${a})`
            : `rgba(255,255,255,${a})`;

        ctx.fillRect(x, y, size, size);
    }

    ctx.restore();
}

/* =========================
   Basis-Helfer
   ========================= */

function clamp01(v) {
    return Math.max(0, Math.min(1, v));
}

function lerp(a, b, t) {
    return a + (b - a) * t;
}

function mulberry32(seed) {
    let t = seed >>> 0;
    return function () {
        t += 0x6D2B79F5;
        let r = Math.imul(t ^ (t >>> 15), 1 | t);
        r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
        return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
    };
}

function hashSeed(centerX, centerY, maxRadius, width, height, s) {
    const a = Math.floor(centerX * 1000);
    const b = Math.floor(centerY * 1000);
    const c = Math.floor(maxRadius * 1000);
    const d = Math.floor(width * 10);
    const e = Math.floor(height * 10);
    const f = Math.floor(s * 1_000_000);

    let x = 0x811c9dc5;
    x = fnv1aMix(x, a);
    x = fnv1aMix(x, b);
    x = fnv1aMix(x, c);
    x = fnv1aMix(x, d);
    x = fnv1aMix(x, e);
    x = fnv1aMix(x, f);
    return x >>> 0;
}

function fnv1aMix(hash, value) {
    let h = hash >>> 0;
    let v = value >>> 0;

    for (let i = 0; i < 4; i++) {
        const octet = v & 0xff;
        h ^= octet;
        h = Math.imul(h, 0x01000193);
        v >>>= 8;
    }
    return h >>> 0;
}
