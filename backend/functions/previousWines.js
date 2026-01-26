/* handle previous wine storage */

import { searchCollection, onWineRequest } from "./config.js";

/** Retrieve the search history for a user. */
export const searchHistory = onWineRequest(async (req, res, user) => {
  const uid = user.uid;
  const queryResult = await searchCollection.where("uid", "==", uid).get();
  let docs = [];
  queryResult.forEach((doc) => {
    const data = doc.data();
    docs.push({
      id: doc.id,
      name: data.name ?? "",
      year: data.year ?? "",
      producer: data.producer ?? "",
      region: data.region ?? "",
      country: data.country ?? "",
      nose: data.nose ?? "",
      palate: data.palate ?? "",
      finish: data.finish ?? "",
      alcohol: data.alcohol ?? 0.0,
      restzucker: data.restzucker ?? null,
      saure: data.saure ?? null,
      vinification: data.vinification ?? "",
      foodPairing: data.foodPairing ?? "",
      imageUrl: data.imageUrl ?? null,
      fromImported: data.fromImported ?? null,
      descriptions: Array.isArray(data.descriptions) ? data.descriptions : [],
      createdAt: data.createdAt ? data.createdAt.toMillis() : null,
    });
  });
  return res.status(200).send(JSON.stringify(docs));
});


/** Delete a previous wine search from the user's history. */
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

/** Update wine information in the database. (to update descriptions) */
export const updateWineInfo = onWineRequest(async (req, res, user) => {
  if (req.method !== "POST") {
    return res.status(405).send("Only POST allowed");
  }

  const id = req.query.id;
  if (!id) {
    return res.status(400).send("Missing document id");
  }

  const wineInfo = req.body?.wineInfo;
  if (!wineInfo) {
    return res.status(400).send("Missing wineInfo in request body");
  }

  const uid = user.uid;
  const docRef = searchCollection.doc(id);
  const docSnap = await docRef.get();

  if (!docSnap.exists || docSnap.data().uid !== uid) {
    return res.status(403).send("Forbidden");
  }

  // Update only the descriptions field (and other wineInfo fields if provided)
  const updateData = {};
  
  // Update descriptions if provided
  if (Array.isArray(wineInfo.descriptions)) {
    updateData.descriptions = wineInfo.descriptions;
  }

  // Optionally update other fields if they are provided
  if (wineInfo.name !== undefined) updateData.name = wineInfo.name;
  if (wineInfo.year !== undefined) updateData.year = wineInfo.year;
  if (wineInfo.producer !== undefined) updateData.producer = wineInfo.producer;
  if (wineInfo.region !== undefined) updateData.region = wineInfo.region;
  if (wineInfo.country !== undefined) updateData.country = wineInfo.country;
  if (wineInfo.fromImported !== undefined) updateData.fromImported = wineInfo.fromImported;

  await docRef.update(updateData);
  return res.status(200).send("Updated");
});
