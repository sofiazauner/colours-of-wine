#!/usr/bin/env node
/* Test script for render effects - run with: node renderEffects/test.js [effect] */

import { createCanvas } from "canvas";
import { writeFileSync } from "fs";
import { hsvToHex, WineTypeBaseColors } from "./colorUtils.js";
import { applyBase } from "./applyBase.js";
import { applyNotes } from "./applyNotes.js";
import { applyAcidity } from "./applyAcidity.js";
import { applyDepth } from "./applyDepth.js";
import { applySugar } from "./applySugar.js";
import { applyBody } from "./applyBody.js";

// Test data
const testData = {
  baseColor: WineTypeBaseColors.red,
  acidity: 0.6,
  depth: 0.7,
  body: 0.8,
  residualSugar: 0.3,
  fruitNotes: [
    { name: "Cherry", color: { h: 350, s: 0.85, v: 0.6 }, intensity: 0.8 },
    { name: "Blackberry", color: { h: 280, s: 0.6, v: 0.25 }, intensity: 0.6 },
  ],
  nonFruitNotes: [
    { name: "Oak", color: { h: 35, s: 0.5, v: 0.7 }, intensity: 0.7 },
    { name: "Tobacco", color: { h: 25, s: 0.6, v: 0.35 }, intensity: 0.4 },
  ],
};

// Canvas setup
const width = 300;
const height = 300;
const centerX = width / 2;
const centerY = height / 2;
const maxRadius = 130;
const coreRadius = 35;

function createTestCanvas() {
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext("2d");
  // Light background
  ctx.fillStyle = hsvToHex(testData.baseColor.h, testData.baseColor.s * 0.08, 0.98);
  ctx.fillRect(0, 0, width, height);
  return { canvas, ctx };
}

function saveCanvas(canvas, name) {
  const filename = `test_${name}.png`;
  writeFileSync(filename, canvas.toBuffer("image/png"));
  console.log(`Saved: ${filename}`);
}

// Individual effect tests
const effects = {
  base: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    saveCanvas(canvas, "base");
  },

  notes: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyNotes(ctx, centerX, centerY, maxRadius, coreRadius, testData.fruitNotes, testData.nonFruitNotes);
    saveCanvas(canvas, "notes");
  },

  acidity: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyAcidity(ctx, centerX, centerY, coreRadius * 0.8, testData.baseColor, testData.acidity, 1.0);
    saveCanvas(canvas, "acidity");
  },

  depth: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyDepth(ctx, centerX, centerY, coreRadius, testData.depth, 1.0);
    saveCanvas(canvas, "depth");
  },

  sugar: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applySugar(ctx, centerX, centerY, maxRadius, width, height, testData.residualSugar);
    saveCanvas(canvas, "sugar");
  },

  body: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, testData.body);
    saveCanvas(canvas, "body");
  },

  "body-range": () => {
    [0, 0.1, 0.5, 0.8, 1].forEach((bodyVal) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, bodyVal);
      saveCanvas(canvas, `body_${bodyVal}`);
    });
  },

  all: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyNotes(ctx, centerX, centerY, maxRadius, coreRadius, testData.fruitNotes, testData.nonFruitNotes);
    applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, testData.body);
    applyAcidity(ctx, centerX, centerY, coreRadius * 0.8, testData.baseColor, testData.acidity, 0.3);
    applyDepth(ctx, centerX, centerY, coreRadius, testData.depth, 1.0);
    applySugar(ctx, centerX, centerY, maxRadius, width, height, testData.residualSugar);
    saveCanvas(canvas, "all");
  },
};

// Main
const arg = process.argv[2];

if (!arg || arg === "help" || arg === "--help") {
  console.log("Usage: node renderEffects/test.js <effect>");
  console.log("");
  console.log("Available effects:");
  console.log("  base     - Base wine color gradient");
  console.log("  notes    - Tasting note overlays");
  console.log("  acidity  - Acidity tint");
  console.log("  depth    - Depth darkness");
  console.log("  sugar    - Sugar pink glow");
  console.log("  body     - Body/texture cloudy noise");
  console.log("  all      - Full pipeline");
  console.log("");
  console.log("Example: node renderEffects/test.js depth");
  process.exit(0);
}

if (effects[arg]) {
  effects[arg]();
} else {
  console.error(`Unknown effect: ${arg}`);
  console.error("Run with --help to see available effects");
  process.exit(1);
}
