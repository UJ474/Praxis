import { Router } from "express"; import Newsletter from "../models/Newsletter.js"; import { syncThursdayNewsletter } from "../jobs/thursdayNewsletterRefresh.js";
const router = Router();
router.get("/latest", async (_req, res, next) => { try { const item = await Newsletter.findOne().sort({ receivedDate: -1 }); if (!item) return res.status(404).json({ error: "No newsletter cached yet. Connect Gmail, then refresh." }); res.json(item); } catch (error) { next(error); } });
router.get("/history", async (_req, res, next) => { try { res.json(await Newsletter.find().sort({ receivedDate: -1 }).limit(52)); } catch (error) { next(error); } });
router.post("/sync", async (_req, res, next) => { try { res.json(await syncThursdayNewsletter()); } catch (error) { next(error); } });
export default router;
