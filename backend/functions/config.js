/* configuration params for .js-files */

import { onRequest } from "firebase-functions/https";
import { setGlobalOptions } from "firebase-functions";
import admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";
import { getFirestore } from "firebase-admin/firestore";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";


// max number of containers
setGlobalOptions({ maxInstances: 10 });

// firebase Admin
admin.initializeApp();
export { admin };

// firestore
const db = getFirestore("wine-data");
export const searchCollection = db.collection("/search-history");

// gemini-/serApi-key access via Google Cloud Secret Manager
const client = new SecretManagerServiceClient();
const secretCache = {};
async function getSecret(name) {
  if (secretCache[name]) return secretCache[name];

  const projectId = process.env.GCLOUD_PROJECT;
  const secretName = `projects/${projectId}/secrets/${name}/versions/latest`;

  const [version] = await client.accessSecretVersion({ name: secretName });
  const value = version.payload.data.toString("utf8");

  secretCache[name] = value;
  return value;
}

export const getGeminiKey = () => getSecret("GEMINI_API_KEY");
export const getSerpKey = () => getSecret("SERP_API_KEY");

// gemini
export const GeminiModel = "gemini-2.5-flash-lite";
export const GeminiURL = `https://generativelanguage.googleapis.com/v1beta/models/${GeminiModel}:generateContent`;
export async function getAi() {
  const apiKey = await getGeminiKey();
  return new GoogleGenAI({ apiKey });
}

// images
export const WineComponents = [
  "Holzeinsatz",
  "Mousseux",
  "Säure",
  "Fruchtcharacter",
  "Nicht-Frucht-Komponenten",
  "Körper",
  "Tannin",
  "Reifearomen",
];

// tokens
export function onWineRequest(fun) {
  return onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    const user = verifyToken(req, res);
    try {
      const user = await admin.auth().verifyIdToken(req.query.token);
      return await fun(req, res, user);
    } catch (e) {
      logger.info("Wrong token", {token: token, error: e});
      return res.status(401).send("Wrong token");
    }
  });
}
