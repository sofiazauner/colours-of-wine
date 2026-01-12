/* Apply depth darkness in the center */

/**
 * Draw depth as a dark overlay creating illusion of looking into the wine
 * @param {number} intensity - How prominent the depth effect should be (0-1)
 */
export function applyDepth(ctx, centerX, centerY, coreRadius, depth, intensity) {
  const depthValue = (depth ?? 0) * intensity;
  if (depthValue <= 0.1) return;

  // How far the darkness extends (more depth = reaches further out)
  const depthReach = coreRadius * (0.8 + depthValue * 2.0);
  // How dark the center gets (more depth = darker, but subtle)
  const depthOpacity = 0.08 + depthValue * 0.35;

  const depthGradient = ctx.createRadialGradient(
    centerX, centerY, 0,
    centerX, centerY, depthReach
  );

  // Very smooth, gradual fade - almost gaussian-like falloff
  depthGradient.addColorStop(0, `rgba(0, 0, 0, ${depthOpacity})`);
  depthGradient.addColorStop(0.1, `rgba(0, 0, 0, ${depthOpacity * 0.9})`);
  depthGradient.addColorStop(0.2, `rgba(0, 0, 0, ${depthOpacity * 0.75})`);
  depthGradient.addColorStop(0.35, `rgba(0, 0, 0, ${depthOpacity * 0.55})`);
  depthGradient.addColorStop(0.5, `rgba(0, 0, 0, ${depthOpacity * 0.35})`);
  depthGradient.addColorStop(0.65, `rgba(0, 0, 0, ${depthOpacity * 0.2})`);
  depthGradient.addColorStop(0.8, `rgba(0, 0, 0, ${depthOpacity * 0.08})`);
  depthGradient.addColorStop(1, "rgba(0, 0, 0, 0)");

  ctx.globalCompositeOperation = "overlay";
  ctx.beginPath();
  ctx.arc(centerX, centerY, depthReach, 0, Math.PI * 2);
  ctx.fillStyle = depthGradient;
  ctx.fill();
  ctx.globalCompositeOperation = "source-over";
}
