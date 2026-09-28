import "dotenv/config";
import express from "express";
import cors from "cors";
import mongoose from "mongoose";
import crypto from "crypto";
import Newsletter from "./models/Newsletter.js";
import Setting from "./models/Setting.js";
import newsletterRoutes from "./routes/newsletter.js";
import taskRoutes from "./routes/tasks.js";
import { encrypt } from "./services/security.js";
import { startMondayReset } from "./jobs/mondayReset.js";
import { startThursdayNewsletterRefresh } from "./jobs/thursdayNewsletterRefresh.js";

const app = express();
app.use(cors()); app.use(express.json());
const authorized = (req, res, next) => {
  const supplied = Buffer.from(req.get("Authorization") || ""); const expected = Buffer.from(`Bearer ${process.env.API_TOKEN || "missing"}`);
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected) ? next() : res.sendStatus(401);
};
app.get("/health", (_req, res) => res.json({ ok: true }));
app.get("/auth/google/start", (_req, res) => {
  const params = new URLSearchParams({ client_id: process.env.GOOGLE_CLIENT_ID, redirect_uri: process.env.GOOGLE_REDIRECT_URI, response_type: "code", access_type: "offline", prompt: "consent", scope: "https://www.googleapis.com/auth/gmail.readonly" });
  res.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params}`);
});
app.get("/auth/google/callback", async (req, res, next) => { try {
  const params = new URLSearchParams({ code: req.query.code, client_id: process.env.GOOGLE_CLIENT_ID, client_secret: process.env.GOOGLE_CLIENT_SECRET, redirect_uri: process.env.GOOGLE_REDIRECT_URI, grant_type: "authorization_code" });
  const response = await fetch("https://oauth2.googleapis.com/token", { method: "POST", body: params }); const data = await response.json(); if (!response.ok || !data.refresh_token) throw new Error("Google did not return a refresh token. Revoke the app then reconnect.");
  await Setting.findOneAndUpdate({ key: "googleRefreshToken" }, { value: encrypt(data.refresh_token) }, { upsert: true });
  res.type("html").send("<main style='font: 18px -apple-system; padding: 48px'>Gmail connected. You can close this window and choose Refresh from the 3-2-1 menu.</main>");
} catch (error) { next(error); } });
app.use("/api", authorized); app.use("/api/newsletter", newsletterRoutes); app.use("/api/tasks", taskRoutes);
app.use((error, _req, res, _next) => { console.error(error); res.status(500).json({ error: error.message || "Server error" }); });
await mongoose.connect(process.env.MONGODB_URI); startMondayReset(); startThursdayNewsletterRefresh();
app.listen(process.env.PORT || 3000, () => console.log("3-2-1 API ready"));
