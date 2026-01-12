/* Apply body/texture as saturation boost + layered structure overlays */

import { hsvToRgb } from "./colorUtils.js";

/**
 * Body/Structure Categories:
 * - Leicht (0-0.25): Zart, filigran - seidige, feine Wellenlinien
 * - Mittel (0.25-0.5): Ausgewogen - weiche, samtartige Textur
 * - Voll (0.5-0.75): Kräftig - dichtes, cremiges Muster
 * - Opulent (0.75-1.0): Sehr voll - konzentrierte, strukturierte Oberfläche
 */

/**
 * Draw body/structure effect as layered textures:
 * 1. Saturation/darkness boost - intensifies the base color
 * 2. Texture overlay layers - based on body level (light/medium/full/opulent)
 * 3. Swirling movement patterns - liquid flow suggesting haptische quality
 *
 * @param {CanvasRenderingContext2D} ctx
 * @param {number} centerX
 * @param {number} centerY
 * @param {number} maxRadius
 * @param {number} width
 * @param {number} height
 * @param {object} baseColor - HSV base color
 * @param {number} body - 0-1 body/structure value
 */
export function applyBody(ctx, centerX, centerY, maxRadius, width, height, baseColor, body) {
  if (body <= 0.05) return;

  // === 1. SATURATION/DARKNESS BOOST ===
  // Fuller wines = more saturated, deeper color (intensiviert die Grundfarbe)
  const satBoost = body * 0.25;
  const darkBoost = body * 0.15;

  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const dx = x - centerX;
      const dy = y - centerY;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist > maxRadius) continue;

      const idx = (y * width + x) * 4;
      const r = data[idx];
      const g = data[idx + 1];
      const b = data[idx + 2];

      const gray = (r + g + b) / 3;
      const satFactor = 1 + satBoost;
      const darkFactor = 1 - darkBoost;

      data[idx] = Math.max(0, Math.min(255, (gray + (r - gray) * satFactor) * darkFactor));
      data[idx + 1] = Math.max(0, Math.min(255, (gray + (g - gray) * satFactor) * darkFactor));
      data[idx + 2] = Math.max(0, Math.min(255, (gray + (b - gray) * satFactor) * darkFactor));
    }
  }

  ctx.putImageData(imageData, 0, 0);

  // === 2. STRUCTURE TEXTURE OVERLAYS ===
  // Different textures for different body levels (halbtransparente Layer)
  applyStructureTexture(ctx, centerX, centerY, maxRadius, body);

  // === 3. MOVEMENT PATTERNS ===
  // Die Grundfarbe gerät in eine Art Bewegung
  applyMovementPatterns(ctx, centerX, centerY, maxRadius, body);
}

/**
 * Apply structure texture overlay based on body level
 * Creates a "haptische" (tactile) visual quality
 */
function applyStructureTexture(ctx, centerX, centerY, maxRadius, body) {
  ctx.save();
  
  // Clip to circular wine area
  ctx.beginPath();
  ctx.arc(centerX, centerY, maxRadius, 0, Math.PI * 2);
  ctx.clip();

  // Determine structure category
  if (body < 0.25) {
    // LEICHT: Zarte, seidige Textur - feine Wellenlinien
    drawSilkyTexture(ctx, centerX, centerY, maxRadius, body);
  } else if (body < 0.5) {
    // MITTEL: Weiche, samtartige Textur
    drawSilkyTexture(ctx, centerX, centerY, maxRadius, body);
    drawVelvetTexture(ctx, centerX, centerY, maxRadius, body);
  } else if (body < 0.75) {
    // VOLL: Dichtes, cremiges Muster
    drawVelvetTexture(ctx, centerX, centerY, maxRadius, body);
    drawCreamyTexture(ctx, centerX, centerY, maxRadius, body);
  } else {
    // OPULENT: Kräftige, strukturierte Oberfläche
    drawVelvetTexture(ctx, centerX, centerY, maxRadius, body);
    drawCreamyTexture(ctx, centerX, centerY, maxRadius, body);
    drawOpulentTexture(ctx, centerX, centerY, maxRadius, body);
  }

  ctx.restore();
}

/**
 * Leicht: Seidige, feine Wellenlinien - delicate, silky waves
 */
function drawSilkyTexture(ctx, centerX, centerY, maxRadius, body) {
  const opacity = 0.03 + body * 0.04; // Very subtle
  const numWaves = 8 + Math.floor(body * 6);
  
  ctx.globalCompositeOperation = "soft-light";
  ctx.strokeStyle = `rgba(255, 255, 255, ${opacity})`;
  ctx.lineWidth = 1 + body * 2;

  for (let i = 0; i < numWaves; i++) {
    const angle = (i / numWaves) * Math.PI * 2;
    const waveAmplitude = 5 + body * 10;
    
    ctx.beginPath();
    
    for (let t = 0; t <= 1; t += 0.02) {
      const baseRadius = t * maxRadius * 0.95;
      const wave = Math.sin(t * Math.PI * 6 + angle * 2) * waveAmplitude * t;
      const radius = baseRadius + wave;
      
      const px = centerX + Math.cos(angle + t * 0.3) * radius;
      const py = centerY + Math.sin(angle + t * 0.3) * radius;
      
      if (t === 0) {
        ctx.moveTo(px, py);
      } else {
        ctx.lineTo(px, py);
      }
    }
    
    ctx.stroke();
  }
  
  ctx.globalCompositeOperation = "source-over";
}

/**
 * Mittel: Samtartige Textur - velvet-like soft overlay
 */
function drawVelvetTexture(ctx, centerX, centerY, maxRadius, body) {
  const opacity = 0.04 + (body - 0.25) * 0.08;
  const numLayers = 3;
  
  ctx.globalCompositeOperation = "soft-light";
  
  for (let layer = 0; layer < numLayers; layer++) {
    const layerRadius = maxRadius * (0.4 + layer * 0.25);
    const gradient = ctx.createRadialGradient(
      centerX, centerY, layerRadius * 0.3,
      centerX, centerY, layerRadius
    );
    
    // Alternating subtle light/dark bands for velvet effect
    if (layer % 2 === 0) {
      gradient.addColorStop(0, `rgba(255, 255, 255, 0)`);
      gradient.addColorStop(0.3, `rgba(255, 255, 255, ${opacity * 0.5})`);
      gradient.addColorStop(0.6, `rgba(255, 255, 255, ${opacity})`);
      gradient.addColorStop(1, `rgba(255, 255, 255, 0)`);
    } else {
      gradient.addColorStop(0, `rgba(0, 0, 0, 0)`);
      gradient.addColorStop(0.3, `rgba(0, 0, 0, ${opacity * 0.3})`);
      gradient.addColorStop(0.6, `rgba(0, 0, 0, ${opacity * 0.5})`);
      gradient.addColorStop(1, `rgba(0, 0, 0, 0)`);
    }
    
    ctx.beginPath();
    ctx.arc(centerX, centerY, layerRadius, 0, Math.PI * 2);
    ctx.fillStyle = gradient;
    ctx.fill();
  }
  
  ctx.globalCompositeOperation = "source-over";
}

/**
 * Voll: Cremiges, dichtes Muster - creamy, dense pattern
 */
function drawCreamyTexture(ctx, centerX, centerY, maxRadius, body) {
  const opacity = 0.05 + (body - 0.5) * 0.1;
  const numBlobs = 12 + Math.floor(body * 8);
  
  ctx.globalCompositeOperation = "soft-light";
  
  // Draw soft, overlapping circular gradients for creamy effect
  for (let i = 0; i < numBlobs; i++) {
    const angle = (i / numBlobs) * Math.PI * 2 + (i % 2) * 0.2;
    const dist = maxRadius * (0.2 + Math.random() * 0.6);
    const blobX = centerX + Math.cos(angle) * dist;
    const blobY = centerY + Math.sin(angle) * dist;
    const blobRadius = maxRadius * (0.15 + body * 0.15);
    
    const gradient = ctx.createRadialGradient(
      blobX, blobY, 0,
      blobX, blobY, blobRadius
    );
    
    // Cream-colored soft blobs
    gradient.addColorStop(0, `rgba(255, 250, 240, ${opacity})`);
    gradient.addColorStop(0.4, `rgba(255, 248, 235, ${opacity * 0.6})`);
    gradient.addColorStop(1, `rgba(255, 245, 230, 0)`);
    
    ctx.beginPath();
    ctx.arc(blobX, blobY, blobRadius, 0, Math.PI * 2);
    ctx.fillStyle = gradient;
    ctx.fill();
  }
  
  ctx.globalCompositeOperation = "source-over";
}

/**
 * Opulent: Kräftige, strukturierte Oberfläche - bold, concentrated texture
 */
function drawOpulentTexture(ctx, centerX, centerY, maxRadius, body) {
  const opacity = 0.06 + (body - 0.75) * 0.12;
  
  ctx.globalCompositeOperation = "overlay";
  
  // Dense, concentrated center glow
  const coreGradient = ctx.createRadialGradient(
    centerX, centerY, 0,
    centerX, centerY, maxRadius * 0.6
  );
  coreGradient.addColorStop(0, `rgba(80, 40, 20, ${opacity * 1.5})`);
  coreGradient.addColorStop(0.3, `rgba(100, 50, 30, ${opacity})`);
  coreGradient.addColorStop(0.6, `rgba(60, 30, 15, ${opacity * 0.5})`);
  coreGradient.addColorStop(1, `rgba(40, 20, 10, 0)`);
  
  ctx.beginPath();
  ctx.arc(centerX, centerY, maxRadius * 0.6, 0, Math.PI * 2);
  ctx.fillStyle = coreGradient;
  ctx.fill();
  
  // Structured outer ring for "dicht, konzentriert" feel
  const ringGradient = ctx.createRadialGradient(
    centerX, centerY, maxRadius * 0.5,
    centerX, centerY, maxRadius
  );
  ringGradient.addColorStop(0, `rgba(0, 0, 0, 0)`);
  ringGradient.addColorStop(0.3, `rgba(60, 30, 20, ${opacity * 0.8})`);
  ringGradient.addColorStop(0.6, `rgba(40, 20, 10, ${opacity * 0.4})`);
  ringGradient.addColorStop(1, `rgba(0, 0, 0, 0)`);
  
  ctx.beginPath();
  ctx.arc(centerX, centerY, maxRadius, 0, Math.PI * 2);
  ctx.fillStyle = ringGradient;
  ctx.fill();
  
  ctx.globalCompositeOperation = "source-over";
}

/**
 * Apply movement patterns - flowing curves suggesting liquid movement
 * "Die Grundfarbe gerät in eine Art Bewegung"
 */
function applyMovementPatterns(ctx, centerX, centerY, maxRadius, body) {
  // Only add movement for medium+ body wines
  if (body < 0.2) return;
  
  const numSwirls = Math.floor(3 + body * 3); // 3-6 swirl arms
  const swirlOpacity = 0.03 + body * 0.07;
  const swirlWidth = 20 + body * 40;
  const rotations = 0.6 + body * 0.8; // More rotations for fuller wines

  ctx.globalCompositeOperation = "soft-light";

  for (let i = 0; i < numSwirls; i++) {
    const startAngle = (i / numSwirls) * Math.PI * 2;
    
    ctx.beginPath();

    // Draw spiral from center outward
    for (let t = 0; t <= 1; t += 0.01) {
      const angle = startAngle + t * Math.PI * 2 * rotations;
      const radius = t * maxRadius * 0.9;

      const px = centerX + Math.cos(angle) * radius;
      const py = centerY + Math.sin(angle) * radius;

      if (t === 0) {
        ctx.moveTo(px, py);
      } else {
        ctx.lineTo(px, py);
      }
    }

    // Create gradient along the swirl
    const gradient = ctx.createRadialGradient(
      centerX, centerY, 0,
      centerX, centerY, maxRadius
    );

    // Alternating light/dark swirls for depth
    if (i % 2 === 0) {
      gradient.addColorStop(0, `rgba(255, 255, 255, 0)`);
      gradient.addColorStop(0.3, `rgba(255, 255, 255, ${swirlOpacity})`);
      gradient.addColorStop(0.7, `rgba(255, 255, 255, ${swirlOpacity * 0.5})`);
      gradient.addColorStop(1, `rgba(255, 255, 255, 0)`);
    } else {
      gradient.addColorStop(0, `rgba(0, 0, 0, 0)`);
      gradient.addColorStop(0.3, `rgba(0, 0, 0, ${swirlOpacity})`);
      gradient.addColorStop(0.7, `rgba(0, 0, 0, ${swirlOpacity * 0.5})`);
      gradient.addColorStop(1, `rgba(0, 0, 0, 0)`);
    }

    ctx.strokeStyle = gradient;
    ctx.lineWidth = swirlWidth;
    ctx.lineCap = "round";
    ctx.stroke();
  }

  ctx.globalCompositeOperation = "source-over";
}
