import cron from "node-cron";
import Newsletter from "../models/Newsletter.js";
import { fetchLatestNewsletter } from "../services/gmail.js";

export async function syncThursdayNewsletter() {
  const parsed = await fetchLatestNewsletter();
  return Newsletter.findOneAndUpdate({ receivedDate: parsed.receivedDate }, parsed, { upsert: true, new: true });
}

// The issue's arrival time varies. Hourly Thursday checks are idempotent because receivedDate is unique.
export function startThursdayNewsletterRefresh() {
  cron.schedule("0 6-23 * * 4", () => syncThursdayNewsletter().catch(error => console.error("Thursday newsletter sync failed", error)), { timezone: process.env.NEWSLETTER_TIMEZONE || "Asia/Kolkata" });
}
