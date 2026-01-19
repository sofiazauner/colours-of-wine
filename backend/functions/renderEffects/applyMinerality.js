function clamp(n, lo, hi) {
  return Math.max(Math.min(n, hi), lo);
}

// Material colors with RGB for gradient effects
const materialColors = {
  chalk: { r: 245, g: 235, b: 220 },
  steel: { r: 176, g: 196, b: 222 },
  stone: { r: 140, g: 140, b: 140 },
  slate: { r: 119, g: 136, b: 153 },
  forest: { r: 139, g: 90, b: 43 },
  compost: { r: 160, g: 82, b: 45 },
  fungi: { r: 210, g: 180, b: 140 },
};

function drawSparkle(ctx, x, y, size, color, rotation) {
  const { r, g, b } = color;

  // Random variations
  const opacityMult = 0.5 + Math.random() * 0.5; // 0.5 - 1.0
  const colorShift = Math.floor((Math.random() - 0.5) * 30); // -15 to +15
  const sr = clamp(r + colorShift, 0, 255);
  const sg = clamp(g + colorShift, 0, 255);
  const sb = clamp(b + colorShift, 0, 255);

  ctx.save();
  const blendModes = ["screen", "overlay", "soft-light", "lighter"];
  ctx.globalCompositeOperation = blendModes[Math.floor(Math.random() * blendModes.length)];
  ctx.translate(x, y);
  ctx.rotate(rotation);

  // Soft glow behind
  const glow = ctx.createRadialGradient(0, 0, 0, 0, 0, size * 1.5);
  glow.addColorStop(0, `rgba(${sr}, ${sg}, ${sb}, ${0.15 * opacityMult})`);
  glow.addColorStop(0.5, `rgba(${sr}, ${sg}, ${sb}, ${0.05 * opacityMult})`);
  glow.addColorStop(1, `rgba(${sr}, ${sg}, ${sb}, 0)`);
  ctx.fillStyle = glow;
  ctx.fillRect(-size * 2, -size * 2, size * 4, size * 4);

  // 4-point star flare - sharp and pointy
  const flareLength = size * (0.5 + Math.random() * 1.0); // vary length
  const flareWidth = size * (0.08 + Math.random() * 0.06); // vary width

  ctx.fillStyle = `rgba(${Math.min(255, sr + 60)}, ${Math.min(255, sg + 60)}, ${Math.min(255, sb + 60)}, ${0.4 * opacityMult})`;

  // Vertical flare
  ctx.beginPath();
  ctx.moveTo(0, -flareLength);
  ctx.lineTo(flareWidth, 0);
  ctx.lineTo(0, flareLength);
  ctx.lineTo(-flareWidth, 0);
  ctx.closePath();
  ctx.fill();

  // Horizontal flare (slightly different length for asymmetry)
  const hFlareLength = flareLength * (0.8 + Math.random() * 0.4);
  ctx.beginPath();
  ctx.moveTo(-hFlareLength, 0);
  ctx.lineTo(0, flareWidth);
  ctx.lineTo(hFlareLength, 0);
  ctx.lineTo(0, -flareWidth);
  ctx.closePath();
  ctx.fill();

  // Diagonal flares (smaller) - only sometimes
  if (Math.random() > 0.3) {
    const diagLength = flareLength * (0.3 + Math.random() * 0.2);
    const diagWidth = flareWidth * 0.6;
    ctx.fillStyle = `rgba(${Math.min(255, sr + 40)}, ${Math.min(255, sg + 40)}, ${Math.min(255, sb + 40)}, ${0.25 * opacityMult})`;

    ctx.save();
    ctx.rotate(Math.PI / 4);
    // Diagonal 1
    ctx.beginPath();
    ctx.moveTo(0, -diagLength);
    ctx.lineTo(diagWidth, 0);
    ctx.lineTo(0, diagLength);
    ctx.lineTo(-diagWidth, 0);
    ctx.closePath();
    ctx.fill();
    // Diagonal 2
    ctx.beginPath();
    ctx.moveTo(-diagLength, 0);
    ctx.lineTo(0, diagWidth);
    ctx.lineTo(diagLength, 0);
    ctx.lineTo(0, -diagWidth);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  // Bright center dot
  const centerSize = size * (0.3 + Math.random() * 0.3);
  const center = ctx.createRadialGradient(0, 0, 0, 0, 0, centerSize);
  center.addColorStop(0, `rgba(255, 255, 255, ${0.7 * opacityMult})`);
  center.addColorStop(
    0.5,
    `rgba(${Math.min(255, sr + 80)}, ${Math.min(255, sg + 80)}, ${Math.min(255, sb + 80)}, ${0.3 * opacityMult})`,
  );
  center.addColorStop(1, `rgba(${sr}, ${sg}, ${sb}, 0)`);
  ctx.fillStyle = center;
  ctx.beginPath();
  ctx.arc(0, 0, centerSize, 0, Math.PI * 2);
  ctx.fill();

  ctx.restore();
}

export function applyMinerality(
  ctx,
  centerX,
  centerY,
  maxRadius,
  width,
  height,
  mineralityMaterial,
  mineralityPlacement,
  mineralityIntensity,
) {
  const color = materialColors[mineralityMaterial];
  if (!color) return; // "none" or unknown

  const n = Math.floor(mineralityIntensity * 500);

  for (let i = 0; i <= n; i++) {
    const angle = Math.random() * 2 * Math.PI;
    const radiusOffset = Math.random() - 0.5;
    const radius = clamp(
      mineralityPlacement * maxRadius + (radiusOffset * maxRadius) / 3,
      0,
      maxRadius,
    );
    const x = centerX + Math.sin(angle) * radius;
    const y = centerY + Math.cos(angle) * radius;

    const size = 1 + Math.random() * 1.5; // half size
    const rotation = Math.random() * Math.PI * 2;

    drawSparkle(ctx, x, y, size, color, rotation);
  }
}
