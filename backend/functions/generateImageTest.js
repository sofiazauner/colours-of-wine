/* test image layout without LLM, just for formatting the generated image */

// to run this test, navigate to SoftwarePraktikum\backend\functions and execute: node generateImageTest.js

import fs from "fs";
import { generateImage } from "./image.js";

const mockColors = {
  "Holzeinsatz": "hotpink",
  "Mousseux": "aquamarine",
  "Säure": "hotpink",
  "Fruchtcharacter": "aquamarine",
  "Nicht-Frucht-Komponenten": "hotpink",
  "Körper": "aquamarine",
  "Tannin": "hotpink",
  "Reifearomen": "aquamarine",
};

(async () => {
  const buffer = await generateImage(mockColors, 0.5);
  fs.writeFileSync("test-output.jpg", buffer);
  console.log("✅ Image generated: test-output.jpg");
})();
