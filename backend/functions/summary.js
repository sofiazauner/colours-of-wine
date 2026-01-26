/* summarize descriptions from web */

import logger from "firebase-functions/logger";
import {
  GeminiModel,
  admin,
  onWineRequest,
  searchCollection,
  generateContentRetry,
} from "./config.js";
import { generateImage } from "./image.js";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";

/**
 * Generate summary with loop of Writer and Reviewer until approved or max iterations reached.
 * Requires the client to send selected descriptions in the request body.
 * No fallback: if no descriptions are provided, no summary is generated.
 */
export const generateSummary = onWineRequest(async (req, res, user) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method not allowed. Use POST.");
  }

  const q = req.body?.q;
  const descriptionsFromClient = req.body?.descriptions;
  const wineInfo = req.body?.wineInfo; // complete wine data from frontend

  if (!q) {
    logger.info("Missing q in generateSummary", { q });
    return res.status(400).send("Query missing");
  }

  if (
    !Array.isArray(descriptionsFromClient) ||
    descriptionsFromClient.length === 0
  ) {
    logger.info("No descriptions provided for generateSummary", {
      descriptions: descriptionsFromClient,
    });
    return res
      .status(400)
      .send("At least one description must be provided to generate a summary.");
  }

  const descriptionTexts = descriptionsFromClient
    .map((d) => {
      if (!d) return "";
      if (
        typeof d.articleText === "string" &&
        d.articleText.trim().length > 0
      ) {
        return d.articleText.trim();
      }
      console.log("description", JSON.stringify(d));
      if (typeof d.snippet === "string" && d.snippet.trim().length > 0) {
        return d.snippet.trim();
      }
      return "";
    })
    .filter((t) => t.length > 0);

  if (descriptionTexts.length === 0) {
    logger.info("All provided descriptions were empty", { q });
    return res
      .status(400)
      .send("Provided descriptions do not contain usable text.");
  }

  let result;
  try {
    result = await buildValidatedSummaryFromDescriptions(descriptionTexts);
  } catch (e) {
    console.error(e);
    logger.error("Failed to generate validated summary", { error: e });
    return res.status(500).send("Failed to generate summary");
  }
  // Log what Gemini gave us
  console.log("=== GEMINI VISUALIZATION DATA ===");
  console.log("Wine Type:", result.wineType);
  console.log("Base Color:", JSON.stringify(result.baseColor));
  console.log("Acidity:", result.acidity);
  console.log("Residual Sugar:", result.residualSugar);
  console.log("Depth:", result.depth);
  console.log("Body:", result.body);
  console.log("Fruit Notes:", JSON.stringify(result.fruitNotes, null, 2));
  console.log(
    "Non-Fruit Notes:",
    JSON.stringify(result.nonFruitNotes, null, 2),
  );
  console.log("Barrel Material:", result.barrelMaterial);
  console.log("Barrel Intensity:", result.barrelIntensity);
  console.log("Minerality Notes:", JSON.stringify(result.mineralityNotes, null, 2));
  console.log("Spritz:", result.spritz);
  console.log("=================================");

  // generate image based on wine data
  let imageBase64 = null;
  const image = await generateImage({
    wineType: result.wineType,
    baseColor: result.baseColor,
    acidity: result.acidity,
    residualSugar: result.residualSugar / 100,
    depth: result.depth,
    body: result.body,
    fruitNotes: result.fruitNotes,
    nonFruitNotes: result.nonFruitNotes,
    barrelMaterial: result.barrelMaterial,
    barrelIntensity: result.barrelIntensity,
    mineralityNotes: result.mineralityNotes,
    spritz: result.spritz,
  });
  imageBase64 = image.toString("base64");
  result.image = imageBase64;

  /*
   * Adjust summary structure. (We could generate it like this in the first
   * place, but that might confuse the LLM.)
   */
  for (const it of ["nose", "palate", "finish", "vinification", "foodPairing"])
    result[it] = result.summary[it];
  delete result.summary;

  // save complete wine data to database
  if (wineInfo) {
    const uid = user.uid;
    const wineName = wineInfo.name || "No Name";
    const descriptions = Array.isArray(wineInfo.descriptions)
      ? wineInfo.descriptions
      : [];

    const old = await searchCollection
      .where("uid", "==", uid)
      .where("name", "==", wineName)
      .where("year", "==", wineInfo.year)
      .where("producer", "==", wineInfo.producer)
      .where("region", "==", wineInfo.region)
      .where("country", "==", wineInfo.country)
      .get();
    old.forEach(async wine => {
      const doc = await searchCollection.doc(wine.id);
      await doc.delete();
    });

    await searchCollection.add({
      uid: uid,
      name: wineName,
      year: wineInfo.year || "",
      producer: wineInfo.producer || "",
      region: wineInfo.region || "",
      country: wineInfo.country || "",
      nose: result.nose,
      palate: result.palate,
      finish: result.finish,
      foodPairing: result.foodPairing,
      alcohol: wineInfo.alcohol || 0.0,
      restzucker: result.residualSugar || null,
      saure: wineInfo.saure || null,
      fromImported: wineInfo.fromImported || null,
      vinification: result.vinification,
      imageUrl: imageBase64 ? `data:image/png;base64,${imageBase64}` : null,
      descriptions: descriptions,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return res.status(200).send(JSON.stringify(result));
});

/**
 * Operate the agentic writer/reviewer loop. Each iteration asks the reviewer to review the writer's output.
 * If MaxIterationCount is exceeded, the loop is stopped.
 */
const MaxIterationCount = 5;
export async function buildValidatedSummaryFromDescriptions(descriptions) {
  if (!Array.isArray(descriptions) || descriptions.length === 0) {
    throw new TypeError("No descriptions available to summarize");
  }

  const start = new Date();
  let obj, review, prev;
  let iteration = 1;

  do {
    prev = obj;
    obj = await runWriterModel(descriptions, review?.feedback, prev);
    review = await runReviewerModel(descriptions, obj);
    logger.info("review", review);
    // Increase the iteration count by one. This prevents us from getting into an infinite loop.
    iteration++;
  } while (!review.approved && iteration < MaxIterationCount);

  const end = new Date();
  logger.info(
    `Wasted ${(end - start) / 1000} seconds of the user's time in ${iteration} iterations`,
  );

  return obj;
}

// Wine type enum - determines base color of visualization
const WineTypes = [
  "red", // deep red wines
  "white", // white/yellow wines
  "rose", // pink wines
  "orange", // orange/amber wines (skin-contact whites)
  "sparkling", // champagne, prosecco, etc.
  "dessert", // sweet dessert wines (sauternes, tokaji)
  "fortified", // port, sherry, madeira
];

// HSV color schema for tasting notes
const HSVColorZod = z.object({
  h: z.number().min(0).max(360).describe("Hue (0-360)"),
  s: z.number().min(0).max(1).describe("Saturation (0-1)"),
  v: z.number().min(0).max(1).describe("Value/Brightness (0-1)"),
});

// Tasting note with name, color, and intensity
const TastingNoteZod = z.object({
  name: z.string().describe("Name of the flavor/aroma note"),
  color: HSVColorZod.describe("HSV color representing this note"),
  intensity: z
    .number()
    .min(0)
    .max(1)
    .describe("How prominent/intense this note is (0=subtle hint, 1=dominant)"),
});

const WriterModelZod = z.object({
  summary: z.object({
    nose: z.string().describe("Nase (Aromatik)"),
    palate: z.string().describe("Gaumen (Geschmack/Mundgefühl)"),
    finish: z.string().describe("Finish (Abgang)"),
    vinification: z.string().describe("Vinifikation (Vinifikation/Ausbau)"),
    foodPairing: z.string().describe("Speiseempfehlung"),
  }),
  wineType: z.enum(WineTypes).describe("Type of wine"),
  baseColor: HSVColorZod.describe(
    "Base wine color in HSV, adjusted from predefined colors based on wine description",
  ),
  acidity: z
    .number()
    .min(0)
    .max(1)
    .describe("Perceived acidity level (0=flat, 1=very high)"),
  residualSugar: z
    .number()
    .min(0)
    .max(100)
    .describe("Sweetness level (0=bone dry, 100=very sweet)"),
  depth: z
    .number()
    .min(0)
    .max(1)
    .describe("Depth/complexity/persistence (0=simple/light, 1=deep/complex)"),
  body: z
    .number()
    .min(0)
    .max(1)
    .describe("Body/structure/texture (0=light/delicate, 1=full/opulent)"),
  fruitNotes: z
    .array(TastingNoteZod)
    .max(5)
    .describe("Fruit-based flavor/aroma notes with colors"),
  nonFruitNotes: z
    .array(TastingNoteZod)
    .max(5)
    .describe(
      "Non-fruit flavor/aroma notes (earth, oak, mineral, etc.) with colors",
    ),
  barrelMaterial: z
    .enum(["oak", "stainless", "both", "none"])
    .describe(
      "Barrel material: oak (Holzfass/Barrique), stainless (Edelstahlfass), both (beide), oder none (kein Ausbau erwähnt)",
    ),
  barrelIntensity: z
    .number()
    .min(0)
    .max(1)
    .describe(
      "Intensity of barrel influence (0=no influence, 1=strong influence from oak/stainless steel barrel)",
    ),
  mineralityNotes: z
    .array(
      z.object({
        name: z.string().describe("Name of the minerality note"),
        color: HSVColorZod.describe("HSV color representing this minerality"),
        intensity: z
          .number()
          .min(0)
          .max(1)
          .describe("How prominent this minerality is (0=subtle, 1=dominant)"),
        placement: z
          .number()
          .min(0)
          .max(1)
          .describe("Where the minerality appears (0=finish/inner, 0.5=palate/middle, 1=nose/outer)"),
      }),
    )
    .max(3)
    .describe("Minerality notes with colors, intensity and placement"),
  spritz: z
    .number()
    .min(0)
    .max(1)
    .describe(
      "Effervescence/carbonation level (0=still wine, 0.2=perlend/lightly sparkling, 0.5=spritzig/sparkling, 1=highly effervescent like Champagne)",
    ),
});
const WriterModelSchema = zodToJsonSchema(WriterModelZod);

// Export for image.js
export { WineTypes };

/** Writer-AI Agent: generate a summary of descriptions and colors, optionally taking feedback from the Reviewer Agent. */
async function runWriterModel(descriptions, feedback, prevObj) {
  const sourcesText = descriptions
    .map((d, i) => `Quelle ${i + 1}:\n${d}`)
    .join("\n\n");
  const prompt = `
Du bist ein Wein- und Farbassoziationsexperte und Profi darin, gute, akkurate Weinbeschreibungen zu erstellen.

Hier sind mehrere Beschreibungen eines Weins aus dem Internet:${sourcesText}
${prevObj ? `Hier ist der vorheriger Draft der erstellten Zusammenfassung und Farbassoziationen dieser Weine:\n${JSON.stringify(prevObj)}\n` : ""}
${feedback ? `Hier hast du Feedback von einer Qualitätskontrolle-KI, das du zur Verbesserung des vorherigen Drafts nutzen sollst:\n${feedback}\n` : ""}

Deine Aufgabe ist es, eine einheitliche, konsistente Zusammenfassung der bereitgestellten Weinbeschreibungen zu erstellen.
Zusätzlich musst du Farbassoziationen im HSV-Format für die Geschmacksnoten erstellen.

WICHTIG:
- Der Zusammenfassung besteht aus folgenden Feldern: "nose" (Nase/Aromatik), "palate" (Geschmack/Mundgefühl), "finish" (Abgang), "vinification" (Vinifikation/Ausbau) und "foodPairing" (Speiseempfehlung). Falls keine Info für ein Feld vorhanden, schreibe "N/A".
- Nutze die bereitgestellten Quellen als einzige Informationsquelle. Erfinde keine Fakten.
- Die Zusammenfassung MUSS auf Deutsch sein.

## Weintyp (wineType)
Wähle den passenden Typ: "red", "white", "rose", "orange", "sparkling", "dessert", "fortified"

## Grundfarbe (baseColor) - HSV
Wähle eine passende Grundfarbe basierend auf dem Weintyp und passe sie an die Beschreibung an.
Hier sind die Referenzfarben pro Weintyp - passe H/S/V leicht an basierend auf Alter, Rebsorte, Ausbau:

RED (Rotwein):
- Jung/leicht (Pinot Noir, Beaujolais): { h: 355, s: 0.75, v: 0.50 } - helleres Rubinrot
- Klassisch (Merlot, Tempranillo): { h: 345, s: 0.85, v: 0.45 } - Rubinrot/Granat
- Kräftig/gereift (Cabernet, Barolo): { h: 335, s: 0.90, v: 0.35 } - dunkles Granat

WHITE (Weißwein):
- Jung/leicht (Pinot Grigio): { h: 55, s: 0.20, v: 0.98 } - blassgelb
- Klassisch (Chardonnay, Riesling): { h: 48, s: 0.35, v: 0.95 } - strohgelb
- Gereift/Holz (Burgundy): { h: 42, s: 0.50, v: 0.90 } - goldgelb

ROSE (Roséwein):
- Provence-Stil (blass): { h: 15, s: 0.30, v: 0.92 } - Zwiebelschale
- Klassisch: { h: 355, s: 0.45, v: 0.88 } - Lachsrosa
- Kräftig: { h: 350, s: 0.55, v: 0.80 } - kräftiges Pink

ORANGE (Orange Wine):
- Leicht: { h: 30, s: 0.50, v: 0.90 } - helles Bernstein
- Klassisch: { h: 25, s: 0.65, v: 0.85 } - Kupfer/Bernstein
- Intensiv: { h: 20, s: 0.75, v: 0.75 } - dunkles Bernstein

SPARKLING (Schaumwein):
- Blanc de Blancs: { h: 55, s: 0.10, v: 0.98 } - fast farblos
- Champagner: { h: 52, s: 0.15, v: 0.98 } - blassgelb
- Rosé Champagner: { h: 5, s: 0.25, v: 0.95 } - zartrosa

DESSERT (Dessertwein):
- Sauternes, Tokaji: { h: 38, s: 0.75, v: 0.75 } - tiefes Gold/Bernstein
- Eiswein: { h: 45, s: 0.60, v: 0.85 } - goldgelb

FORTIFIED (Verstärkte Weine):
- Fino Sherry: { h: 45, s: 0.40, v: 0.85 } - helles Bernstein
- Ruby Port: { h: 350, s: 0.85, v: 0.40 } - dunkelrot
- Tawny Port: { h: 15, s: 0.80, v: 0.30 } - mahagonibraun

## Säure (acidity) - Skala 0 bis 1
Bewerte die wahrgenommene Säure:
- 0.0-0.2: Sehr niedrig (flach, weich, z.B. manche Merlots)
- 0.2-0.4: Niedrig bis mittel (rund, ausgewogen)
- 0.4-0.6: Mittel (frisch, lebhaft, typisch für viele Weißweine)
- 0.6-0.8: Hoch (knackig, spritzig, z.B. Riesling, Sauvignon Blanc)
- 0.8-1.0: Sehr hoch (stahlig, scharf, z.B. Chablis, Grüner Veltliner)

## Restzucker (residualSugar) - Skala 0 bis 100
- 0-5: Knochentrocken (brut nature, extra brut)
- 5-15: Trocken (brut, dry)
- 15-30: Halbtrocken (off-dry, extra dry bei Sekt)
- 30-50: Lieblich (demi-sec)
- 50-100: Süß (sweet, Dessert-/Eiswein)

## Tiefe/Komplexität (depth) - Skala 0 bis 1
Bewerte die Tiefe, Komplexität und den Nachhall des Weins:
- 0.0-0.2: Zart - einfacher, leichter Wein ohne viel Tiefe
- 0.2-0.4: Mittel - solide Struktur, moderate Komplexität
- 0.4-0.6: Ausgeprägt - gute Tiefe, vielschichtig
- 0.6-0.8: Tief - komplexe Aromen, langer Nachhall, Lagerpotential
- 0.8-1.0: Komplex - außergewöhnliche Tiefe, viele Schichten, großes Alterungspotential

Faktoren die für hohe Tiefe sprechen:
- Langer Abgang/Nachhall
- Vielschichtige, sich entwickelnde Aromen
- Konzentration und Intensität
- Lagerfähigkeit/Alterungspotential
- Komplexer Ausbau (Barrique, lange Hefelagerung, etc.)
- Herkunft von Spitzenlagen

## Körper/Struktur (body) - Skala 0 bis 1
Bewerte Körper, Balance, Textur und Struktur des Weins - eine haptische Wahrnehmung:
- 0.0-0.25: Leicht - zarter, filigraner Körper (z.B. leichter Riesling, Vinho Verde)
- 0.25-0.5: Mittel - ausgewogene Struktur (z.B. Pinot Noir, Grauburgunder)
- 0.5-0.75: Voll - kräftiger Körper, gute Fülle (z.B. Chardonnay mit Holz, Merlot)
- 0.75-1.0: Opulent - sehr voller Körper, dicht, konzentriert (z.B. Amarone, Châteauneuf-du-Pape)

Faktoren die für hohen Körper sprechen:
- Hoher Alkoholgehalt
- Hoher Extraktgehalt
- Dichte, Fülle, Volumen im Mund
- Samtiger oder cremiger Charakter
- Langer Ausbau in Barrique
- Reife Trauben, konzentrierter Stil

## Frucht-Noten (fruitNotes) - maximal 5
Identifiziere die Fruchtaromen und gib jedem eine HSV-Farbe und Intensität:
- intensity: Wie prominent/dominant ist diese Note? (0=dezenter Hauch, 0.5=deutlich wahrnehmbar, 1=sehr dominant)
Beispiele:
- Zitrone: { h: 55, s: 0.9, v: 1.0 }, intensity: 0.8
- Grüner Apfel: { h: 90, s: 0.6, v: 0.8 }, intensity: 0.6
- Pfirsich: { h: 35, s: 0.7, v: 0.95 }, intensity: 0.7
- Erdbeere: { h: 0, s: 0.8, v: 0.9 }, intensity: 0.5
- Schwarze Johannisbeere (Cassis): { h: 300, s: 0.7, v: 0.3 }, intensity: 0.9
- Kirsche: { h: 350, s: 0.85, v: 0.6 }, intensity: 0.7
- Passionsfrucht: { h: 45, s: 0.8, v: 0.9 }, intensity: 0.6
- Brombeere: { h: 280, s: 0.6, v: 0.25 }, intensity: 0.8

## Nicht-Frucht-Noten (nonFruitNotes) - maximal 5
Identifiziere Nicht-Frucht-Aromen (Erde, Holz, Mineral, Gewürze, etc.) mit HSV-Farbe und Intensität:
- intensity: Wie prominent/dominant ist diese Note? (0=dezenter Hauch, 0.5=deutlich wahrnehmbar, 1=sehr dominant)
Beispiele:
- Eiche/Vanille: { h: 35, s: 0.5, v: 0.7 }, intensity: 0.7
- Toast/Brioche: { h: 30, s: 0.6, v: 0.6 }, intensity: 0.5
- Mineralik/Feuerstein: { h: 200, s: 0.1, v: 0.7 }, intensity: 0.6
- Tabak/Leder: { h: 25, s: 0.6, v: 0.35 }, intensity: 0.4
- Pfeffer/Würze: { h: 15, s: 0.7, v: 0.4 }, intensity: 0.8
- Kräuter: { h: 120, s: 0.5, v: 0.5 }, intensity: 0.5
- Honig: { h: 45, s: 0.8, v: 0.85 }, intensity: 0.6
- Rauch: { h: 0, s: 0.0, v: 0.3 }, intensity: 0.3
- Erde/Pilze: { h: 30, s: 0.4, v: 0.35 }, intensity: 0.4

## Fassmaterial (barrelMaterial) und Intensität (barrelIntensity)
Identifiziere das Fassmaterial:
- "oak": Wenn der Wein im Holzfass/Barrique/Eiche erzeugt wird (z.B. "Barrique-Ausbau", "Eichenfass", "Holzfass", "oak-aged", "wood", "Holz")
- "stainless": Wenn der Wein im Edelstahlfass/Stainless Steel erzeugt wird (z.B. "Edelstahlfass", "stainless steel", "Stahltank", "Edelstahl")
- "both": Wenn beide Fassmaterialien erwähnt werden
- "none": Wenn kein spezifisches Fassmaterial erwähnt wird oder es unklar ist

Die Intensität (barrelIntensity: 0-1) bestimmt, wie stark das Fassmaterial den Wein beeinflusst:
- 0.0-0.2: Sehr subtil - kaum wahrnehmbarer Einfluss
- 0.2-0.4: Leicht - dezenter Einfluss des Ausbaus
- 0.4-0.6: Mittel - deutlicher Einfluss (z.B. "leicht von Eiche geprägt")
- 0.6-0.8: Stark - prägender Einfluss (z.B. "ausgeprägte Barrique-Noten", "stark von Holz geprägt")
- 0.8-1.0: Sehr stark - dominanter Einfluss (z.B. "intensive Eichennoten", "langer Barrique-Ausbau")

## Mineralik-Noten (mineralityNotes) - maximal 3
Identifiziere mineralische Eindrücke und gib jedem eine HSV-Farbe, Intensität und Platzierung.
Mineralität ist ein wichtiger Aspekt vieler Weine - achte besonders auf Begriffe wie "mineralisch", "steinig", "feuersteinig", "kreidige", "schiefrig", etc.

Beispiele mit HSV-Farben:
- Kreide/Kalk: { h: 45, s: 0.08, v: 0.95 } - fast weiß, leicht warm
- Feuerstein/Flint: { h: 35, s: 0.15, v: 0.6 } - grau mit warmem Unterton
- Schiefer/Slate: { h: 210, s: 0.15, v: 0.5 } - blau-grau
- Nasser Stein: { h: 220, s: 0.1, v: 0.55 } - kühles Grau
- Salz/Meer: { h: 190, s: 0.2, v: 0.85 } - helles Blau-Grün
- Graphit: { h: 0, s: 0.0, v: 0.3 } - dunkelgrau
- Eisen/Blut: { h: 0, s: 0.4, v: 0.4 } - rostrot
- Vulkanisch: { h: 15, s: 0.3, v: 0.25 } - dunkles Braun-Rot
- Erde/Lehm: { h: 25, s: 0.5, v: 0.45 } - erdbraun
- Pilze/Waldboden: { h: 30, s: 0.35, v: 0.4 } - braun

Intensität (intensity: 0-1):
- 0.0-0.3: Dezent - subtiler mineralischer Hauch
- 0.3-0.6: Mittel - deutlich wahrnehmbar
- 0.6-1.0: Dominant - prägendes Element

Platzierung (placement: 0-1) - wo die Mineralität am stärksten ist:
- 0.0-0.3: Nachhall/Finish - zeigt sich im Abgang (innen im Bild)
- 0.3-0.7: Gaumen - präsent im Mundgefühl (Mitte)
- 0.7-1.0: Nase - bereits in der Aromatik (außen im Bild)

Falls keine Mineralik erkennbar ist, lasse das Array leer [].

## Spritzigkeit (spritz) - Skala 0 bis 1
Bewerte die Kohlensäure/Perlage des Weins:
- 0.0-0.2: Still - keine oder kaum wahrnehmbare Kohlensäure (Stillweine)
- 0.2-0.45: Perlend - leichte Perlage (Perlwein, Frizzante, Vinho Verde)
- 0.45-0.75: Spritzig - deutliche Kohlensäure (Prosecco, Sekt, Cava)
- 0.75-1.0: Stark spritzig - intensive Perlage (Champagner, Crémant, hochwertige Schaumweine)

Begriffe die für hohe Spritzigkeit sprechen:
- "Schaumwein", "Sekt", "Champagner", "Crémant", "Cava", "Prosecco"
- "perlend", "moussierend", "spritzig", "prickelnd"
- "feine Perlage", "elegante Bläschen", "mousse"
- wineType="sparkling" → mindestens 0.5

Begriffe die für niedrige/keine Spritzigkeit sprechen:
- "Stillwein", "still", "ohne Kohlensäure"
- Alle normalen Rot-, Weiß-, Rosé-Weine ohne besondere Erwähnung von Perlage

Deine Ausgabe MUSS dem JSON-Schema entsprechen.`;
  const response = await generateContentRetry({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: WriterModelSchema,
    },
  });

  return WriterModelZod.parse(JSON.parse(response.text));
}

const ReviewerModelZod = z.object({
  approved: z.boolean(),
  feedback: z.string(),
});
const ReviewerModelSchema = zodToJsonSchema(ReviewerModelZod);

/** Reviewer-AI Agent: review a summary and colors and provide feedback. */
async function runReviewerModel(descriptions, obj) {
  const sourcesText = descriptions
    .map((d, i) => `Quelle ${i + 1}:\n${d}`)
    .join("\n\n");
  const prompt = `
Du bist eine unabhängige Qualitätskontrolle-KI für Weinzusammenfassungen und Farbassoziationen.

Hier sind die Quellen der Ursprungsbeschreibungen (Beschreibungen aus dem Web):${sourcesText}

Hier ist die Zusammenfassung mit Daten, die überprüft werden soll:
${JSON.stringify(obj, null, 2)}

Prüfe folgende Punkte:

## Zusammenfassung
- Spiegelt die Kernaussagen der Quellen korrekt wider.
- Keine erfundenen Fakten.
- Der Text ist auf Deutsch, nicht auf Englisch.

## Weintyp (wineType)
- Stimmt der Typ mit den Quellen überein? (red/white/rose/orange/sparkling/dessert/fortified)

## Säure (acidity: 0-1)
- Passt der Säurewert zur Beschreibung?
- 0.0-0.2: flach, weich | 0.4-0.6: frisch | 0.8-1.0: stahlig, scharf
- Begriffe wie "knackig", "lebhaft", "spritzig" → höhere Säure
- Begriffe wie "weich", "rund", "samtig" → niedrigere Säure

## Restzucker (residualSugar: 0-100)
- Passt zur Beschreibung? (trocken=0-15, halbtrocken=15-30, lieblich=30-50, süß=50+)

## Körper (body: 0-1)
- Passt der Körper zur Beschreibung?
- 0.0-0.25: leicht, filigran | 0.25-0.5: mittel | 0.5-0.75: voll | 0.75-1.0: opulent
- Begriffe wie "dicht", "konzentriert", "opulent", "samtig" → höherer Körper
- Begriffe wie "leicht", "filigran", "zart", "schlank" → niedrigerer Körper

## Frucht- und Nicht-Frucht-Noten
- Sind die genannten Aromen in den Quellen erwähnt oder impliziert?
- Passen die HSV-Farben zu den Aromen? (z.B. Zitrone sollte gelb sein, nicht blau)
- Maximal 5 pro Kategorie

## Fassmaterial (barrelMaterial) und Intensität (barrelIntensity)
- Wurde das Fassmaterial korrekt erkannt? (oak/stainless/both/none)
- Passt die Intensität zur Beschreibung? (0=kein Einfluss, 1=starker Einfluss)
- Begriffe wie "Barrique", "Eichenfass", "Holzfass" → oak
- Begriffe wie "Edelstahlfass", "Stahltank", "stainless steel" → stainless
- Beide werden erwähnt → both
- Wenn nichts erwähnt → none

## Mineralik-Noten (mineralityNotes)
- Wurden mineralische Eindrücke korrekt erkannt? (Kreide, Schiefer, Feuerstein, etc.)
- Passen die HSV-Farben zu den mineralischen Noten? (z.B. Schiefer sollte grau-blau sein)
- Ist die Platzierung sinnvoll? (0=Finish, 0.5=Gaumen, 1=Nase)
- Maximal 3 Mineralik-Noten

## Spritzigkeit (spritz: 0-1)
- Passt der Wert zur Beschreibung?
- 0.0-0.2: still | 0.2-0.45: perlend | 0.45-0.75: spritzig | 0.75-1.0: stark spritzig
- Schaumweine (Champagner, Sekt, Prosecco) → mindestens 0.5
- Stillweine ohne Erwähnung von Perlage → 0.0-0.1

WICHTIG:
- Sei nicht zu streng bei kleinen Abweichungen
- Lehne nur ab, wenn etwas grob falsch ist
- Deine Ausgabe MUSS dem JSON-Schema entsprechen.`;
  const response = await generateContentRetry({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: ReviewerModelSchema,
    },
  });

  return ReviewerModelZod.parse(JSON.parse(response.text));
}
