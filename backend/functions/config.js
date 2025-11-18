/* configuration params for .js-files */

import { setGlobalOptions } from "firebase-functions";
import admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";
import { getFirestore } from "firebase-admin/firestore";


// max number of containers
setGlobalOptions({ maxInstances: 10 });

// firebase Admin
admin.initializeApp();
export { admin };

// firestore
const db = getFirestore("wine-data");
export const searchCollection = db.collection("/search-history");

// gemini
export const GeminiModel = "gemini-2.5-flash-lite";
export const GeminiURL = `https://generativelanguage.googleapis.com/v1beta/models/${GeminiModel}:generateContent`;
export const GeminiAPIKey = "AIzaSyC_u49bnxvaObp-2vVXSc0TvSLgQWqyT7c";
export const ai = new GoogleGenAI({ apiKey: GeminiAPIKey });

// serpAPI
export const serpApiKey = "ec05db9a150499c3e869cb95e63a146a5b1dce6257c1042bf89c340bf2c22d1a";