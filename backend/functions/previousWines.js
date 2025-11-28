/* handle previous wine storage */

import logger from "firebase-functions/logger";
import { admin, searchCollection, onWineRequest } from "./config.js";

// retrieves the search history for a user based on their token
export const searchHistory = onWineRequest(async (req, res, user) => {
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
export const deleteSearch = onWineRequest(async (req, res, user) => {
  if (req.method !== "POST") {
    return res.status(405).send("Only POST allowed");
  }
  const id = req.query.id;

  if (!id)
    return res.status(400).send("Missing document id");

  const uid = user.uid;
  const docRef = searchCollection.doc(id);
  const docSnap = await docRef.get();

  if (!docSnap.exists || docSnap.data().uid !== uid) {
    return res.status(403).send("Forbidden");
  }

  await docRef.delete();
  return res.status(200).send("Deleted");
});
