/* handle previous wine storage */

import { onRequest } from "firebase-functions/https";
import logger from "firebase-functions/logger";
import { admin, searchCollection } from "./config.js";


// retrieves the search history for a user based on their token
export const searchHistory = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  const token = req.query.token;
  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
  const uid = user.uid;
  const queryResult = await searchCollection.where("uid", "==", uid).get();
  let docs = [];
  queryResult.forEach((doc) => {
    const data = doc.data();
    docs.push({
      id: doc.id,
      name: data.name ?? "",
      descriptions: Array.isArray(data.descriptions) ? data.descriptions : [],
      createdAt: data.createdAt ? data.createdAt.toMillis() : null,
    });
  });
  return res.status(200).send(JSON.stringify(docs));
});


// deletes a previous wine search from the user's history
export const deleteSearch = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method !== "POST") {
    return res.status(405).send("Only POST allowed");
  }

  const token = req.query.token;
  const id = req.query.id;

  if (!id) return res.status(400).send("Missing document id");

  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    return res.status(401).send("Wrong token");
  }

  const uid = user.uid;

  const docRef = searchCollection.doc(id);
  const docSnap = await docRef.get();

  if (!docSnap.exists || docSnap.data().uid !== uid) {
    return res.status(403).send("Forbidden");
  }

  await docRef.delete();
  return res.status(200).send("Deleted");
});