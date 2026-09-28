import Setting from "../models/Setting.js";
import { decrypt } from "./security.js";
import { htmlToText, parseNewsletter } from "./emailParser.js";
const b64 = value => Buffer.from(value.replace(/-/g, "+").replace(/_/g, "/"), "base64").toString("utf8");
const header = (headers, name) => headers.find(h => h.name.toLowerCase() === name.toLowerCase())?.value || "";
function findPart(part, mime) { if (part.mimeType === mime) return part; for (const child of part.parts || []) { const found = findPart(child, mime); if (found) return found; } }
async function accessToken() { const row = await Setting.findOne({ key: "googleRefreshToken" }); if (!row) throw new Error("Connect Gmail from the app menu first."); const payload = new URLSearchParams({ client_id: process.env.GOOGLE_CLIENT_ID, client_secret: process.env.GOOGLE_CLIENT_SECRET, refresh_token: decrypt(row.value), grant_type: "refresh_token" }); const response = await fetch("https://oauth2.googleapis.com/token", { method: "POST", body: payload }); if (!response.ok) throw new Error("Google token refresh failed"); return (await response.json()).access_token; }
export async function fetchLatestNewsletter() {
  const token = await accessToken(); const search = encodeURIComponent('from:jamesclear.com subject:"3-2-1"');
  const list = await fetch(`https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${search}&maxResults=1`, { headers: { Authorization: `Bearer ${token}` } }); const messageId = (await list.json()).messages?.[0]?.id;
  if (!messageId) throw new Error("No James Clear 3-2-1 email found.");
  const response = await fetch(`https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}?format=full`, { headers: { Authorization: `Bearer ${token}` } }); const message = await response.json();
  const plain = findPart(message.payload, "text/plain")?.body?.data; const html = findPart(message.payload, "text/html")?.body?.data;
  const decodedPlain = plain ? b64(plain) : ""; const decodedHTML = html ? b64(html) : "";
  try { return parseNewsletter({ subject: header(message.payload.headers, "Subject"), date: header(message.payload.headers, "Date"), text: decodedPlain, html: decodedHTML }); }
  catch (error) { console.error("Newsletter parse failure", { plainLength: decodedPlain.length, htmlLength: decodedHTML.length, htmlTextLength: htmlToText(decodedHTML).length, message: error.message }); throw error; }
}
