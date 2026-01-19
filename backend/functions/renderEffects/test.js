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
import { applyBarrel } from "./applyBarrel.js";
import { applyBubbles } from "./applyBubbles.js";
import { applyMinerality } from "./applyMinerality.js";
import { applySugarBar } from "./applySugarBar.js";

// Test data
const testData = {
  baseColor: WineTypeBaseColors.red,
  acidity: 0.6,
  depth: 0.7,
  body: 0.8,
  residualSugar: 0.3,
  spritz: 0.75,
  fruitNotes: [
    { name: "Cherry", color: { h: 350, s: 0.85, v: 0.6 }, intensity: 0.8 },
    { name: "Blackberry", color: { h: 280, s: 0.6, v: 0.25 }, intensity: 0.6 },
  ],
  nonFruitNotes: [
    { name: "Oak", color: { h: 35, s: 0.5, v: 0.7 }, intensity: 0.7 },
    { name: "Tobacco", color: { h: 25, s: 0.6, v: 0.35 }, intensity: 0.4 },
  ],
  barrelMaterial: "oak",
  barrelIntensity: 0.5,
  mineralityMaterial: "slate",
  mineralityPlacement: 0.7,
  mineralityIntensity: 0.6,
  residualSugarValue: 25,
  residualSugarKnown: true,
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

  bubbles: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, testData.body);
    applyBubbles(ctx, centerX, centerY, maxRadius, width, height, testData.spritz, 1.0);
    saveCanvas(canvas, "bubbles");
  },

  "bubbles-range": () => {
    // Test all 4 spritz categories: still, perlend, spritzig, stark_spritzig
    const spritzLevels = [
      { value: 0.1, name: "still" },
      { value: 0.35, name: "perlend" },
      { value: 0.6, name: "spritzig" },
      { value: 0.9, name: "stark_spritzig" },
    ];
    spritzLevels.forEach(({ value, name }) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, testData.body);
      applyBubbles(ctx, centerX, centerY, maxRadius, width, height, value, 1.0);
      saveCanvas(canvas, `bubbles_${name}_${value}`);
    });
  },

  "body-range": () => {
    // Test all 4 structure categories: leicht, mittel, voll, opulent
    const bodyLevels = [
      { value: 0.1, name: "leicht" },
      { value: 0.35, name: "mittel" },
      { value: 0.6, name: "voll" },
      { value: 0.9, name: "opulent" },
    ];
    bodyLevels.forEach(({ value, name }) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyBody(ctx, centerX, centerY, maxRadius, width, height, testData.baseColor, value);
      saveCanvas(canvas, `body_${name}_${value}`);
    });
  },

  barrel: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyBarrel(ctx, centerX, centerY, width, height, testData.barrelMaterial, testData.barrelIntensity);
    saveCanvas(canvas, "barrel");
  },

  "barrel-oak": () => {
    const intensities = [0.3, 0.5, 0.7, 0.9];
    intensities.forEach((intensity) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyBarrel(ctx, centerX, centerY, width, height, "oak", intensity);
      saveCanvas(canvas, `barrel_oak_${intensity}`);
    });
  },

  "barrel-stainless": () => {
    const intensities = [0.3, 0.5, 0.7, 0.9];
    intensities.forEach((intensity) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyBarrel(ctx, centerX, centerY, width, height, "stainless", intensity);
      saveCanvas(canvas, `barrel_stainless_${intensity}`);
    });
  },

  minerality: () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applyMinerality(ctx, centerX, centerY, maxRadius, width, height,
      testData.mineralityMaterial, testData.mineralityPlacement, testData.mineralityIntensity);
    saveCanvas(canvas, "minerality");
  },

  "minerality-materials": () => {
    // Test all minerality materials
    const materials = ["chalk", "steel", "stone", "slate", "forest", "compost", "fungi"];
    materials.forEach((material) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applyMinerality(ctx, centerX, centerY, maxRadius, width, height, material, 0.7, 0.8);
      saveCanvas(canvas, `minerality_${material}`);
    });
  },

  "sugar-bar": () => {
    const { canvas, ctx } = createTestCanvas();
    applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
    applySugarBar(ctx, width, height, testData.residualSugarValue, testData.residualSugarKnown);
    saveCanvas(canvas, "sugar_bar");
  },

  "sugar-bar-range": () => {
    // Test different sugar levels (max 500)
    const levels = [0, 5, 15, 30, 50, 100, 150, 250, 500];
    levels.forEach((level) => {
      const { canvas, ctx } = createTestCanvas();
      applyBase(ctx, centerX, centerY, maxRadius, testData.baseColor);
      applySugarBar(ctx, width, height, level, true);
      saveCanvas(canvas, `sugar_bar_${level}`);
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
    applyBubbles(ctx, centerX, centerY, maxRadius, width, height, testData.spritz, 1.0);
    applyBarrel(ctx, centerX, centerY, width, height, testData.barrelMaterial, testData.barrelIntensity);
    applyMinerality(ctx, centerX, centerY, maxRadius, width, height,
      testData.mineralityMaterial, testData.mineralityPlacement, testData.mineralityIntensity);
    applySugarBar(ctx, width, height, testData.residualSugarValue, testData.residualSugarKnown);
    saveCanvas(canvas, "all");
  },
};

// Main
const arg = process.argv[2];

if (!arg || arg === "help" || arg === "--help") {
  console.log("Usage: node renderEffects/test.js <effect>");
  console.log("");
  console.log("Available effects:");
  console.log("  base              - Base wine color gradient");
  console.log("  notes             - Tasting note overlays");
  console.log("  acidity           - Acidity tint");
  console.log("  depth             - Depth darkness");
  console.log("  sugar             - Sugar pink glow");
  console.log("  body              - Body/texture cloudy noise");
  console.log("  barrel            - Barrel material vignette (default test is for oak barrel with medium intensity)");
  console.log("  barrel-oak        - Oak barrel at different intensities");
  console.log("  barrel-stainless  - Stainless steel barrel at different intensities");
  console.log("  bubbles           - Effervescence / bubbles (spritz)");
  console.log("  bubbles-range     - Bubbles at different spritz levels (still, perlend, spritzig, stark_spritzig)");
  console.log("  minerality        - Minerality dots (default: slate)");
  console.log("  minerality-materials - All minerality materials (chalk, steel, stone, slate, forest, compost, fungi)");
  console.log("  sugar-bar         - Residual sugar bar indicator");
  console.log("  sugar-bar-range   - Sugar bar at different levels (0, 5, 15, 30, 50, 75, 100)");
  console.log("  all               - Full pipeline");
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
