/** API endpoint for wine expert image app (App for Anja). */

import { onRequest } from 'firebase-functions/https';
import { generateImage } from './image.js';
import { buildValidatedSummaryFromDescriptions } from './summary.js';

const acceptedCookie = "YldWbmMzcGxiblJ6WldkMFpXeGxibWww";
export const expertGenerateImage = onRequest(async (req, res) => {
  if (acceptedCookie != req.query.cookie) {
    return res.status(501).send("Internal server error");
  }
  if (req.method != "POST")
    return res.status(400).send("Need post");
  const desc = req.rawBody;
  const obj = await buildValidatedSummaryFromDescriptions([desc]);
  const colors = obj.colors;
  const residualSugar = obj.residualSugar / 100;
  console.log("sugar", obj.residualSugar);
  const image = await generateImage(colors, residualSugar);
  return res.status(200).send(image.toString('base64')); // meh
});
