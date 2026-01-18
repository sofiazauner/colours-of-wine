function clamp(n, lo, hi) {
  return Math.max(Math.min(n, hi), lo);
}

export function applyMinerality(ctx, centerX, centerY, maxRadius, width, height,
    mineralityMaterial, mineralityPlacement, mineralityIntensity) {
  let color;
  console.log("material", mineralityMaterial);
  switch (mineralityMaterial) {
  case "chalk": color = "beige"; break;
  case "steel": color = "lightsteelblue"; break;
  case "stone": color = "gray"; break;
  case "slate": color = "lightslategray"; break;
  case "forest": color = "saddlebrown"; break;
  case "compost": color = "sienna"; break;
  case "fungi": color = "sandybrown"; break;
  default: return; /* "none" */
  }
  ctx.fillStyle = color;
  const n = Math.floor(mineralityIntensity * 25)
  for (let i = 0; i <= n; i++) {
    const r1 = Math.random() * 2 * Math.PI;
    const r2 = Math.random() - .5;
    const radius = clamp(mineralityPlacement * maxRadius + r2 * maxRadius / 3, 0, maxRadius);
    const x = Math.sin(r1) * radius;
    const y = Math.cos(r1) * radius;
    ctx.beginPath();
    ctx.arc(centerX + x, centerY + y, 2, 0, Math.PI * 2);
    ctx.fill();
  }
}
