/* configuration params for .js-files */

import logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/https";
import { setGlobalOptions } from "firebase-functions";
import admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";
import { getFirestore } from "firebase-admin/firestore";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import dotenv from "dotenv";

// Load .env file for local development
dotenv.config();

// Check if running locally (env vars set) or in production (use Secret Manager)
const isLocal = process.env.GEMINI_API_KEY || process.env.SERP_API_KEY;

// max number of containers
setGlobalOptions({ maxInstances: 10 });

// firebase Admin
admin.initializeApp();
export { admin };

// firestore - mock for local development without Firebase
let searchCollection;
if (isLocal && !process.env.FIRESTORE_EMULATOR_HOST) {
  // Mock collection for local dev without Firestore
  const mockDocs = [];
  searchCollection = {
    add: async (data) => {
      const id = `mock-${Date.now()}`;
      mockDocs.push({ id, data: { ...data, createdAt: { toMillis: () => Date.now() } } });
      logger.info("Mock Firestore add:", data);
      return { id };
    },
    where: () => ({
      get: async () => ({
        forEach: (fn) => mockDocs.forEach((doc) => fn({ id: doc.id, data: () => doc.data }))
      })
    }),
    doc: (id) => ({
      get: async () => {
        const doc = mockDocs.find((d) => d.id === id);
        return {
          exists: !!doc,
          data: () => doc?.data
        };
      },
      delete: async () => {
        const idx = mockDocs.findIndex((d) => d.id === id);
        if (idx >= 0) mockDocs.splice(idx, 1);
      }
    })
  };
} else {
  const db = getFirestore("wine-data");
  searchCollection = db.collection("/search-history");
}
export { searchCollection };

/**
 * gemini-/serApi-key access - uses .env locally, Secret Manager in production
 * */
const client = new SecretManagerServiceClient();
const secretCache = {};
async function getSecret(name) {
  // Check .env first (local development)
  if (process.env[name]) {
    return process.env[name];
  }

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

async function getAi() {
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

/**
 * Create a wine request that verifies the user and sets the appropriate headers.
 * @param {fun} function to execute on a valid request
 */
export function onWineRequest(fun) {
  return onRequest({cors: true}, async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'GET');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.set('Access-Control-Max-Age', '3600');
      return res.status(204).send('');
    }
    res.set('Access-Control-Allow-Origin', '*');
    const token = req.query.token;
    let user;
    try {
      user = await admin.auth().verifyIdToken(token);
    } catch (e) {
      logger.info("Wrong token", {token: token, error: e});
      return res.status(401).send("Wrong token");
    }
    return await fun(req, res, user);
  });
}

export async function generateContentRetry(obj) {
  async function asyncSleep(delay) {
    return new Promise(resolve => setTimeout(resolve, delay));
  }
  const ai = await getAi();
  for (let i = 0; ; i++) {
    try {
      return await ai.models.generateContent(obj);
    } catch (e) {
      if (e?.status != 503 || i >= 5)
        throw e;
      logger.info("Got 503 from Gemini, retrying");
      await asyncSleep(5000);
    }
  }
}
