import { Router } from "express"; import Task from "../models/Task.js";
const router = Router();
router.get("/", async (req, res, next) => { try { const week = req.query.weekOf ? new Date(req.query.weekOf) : new Date(); res.json(await Task.find({ weekOf: week, archived: false }).sort({ createdAt: 1 })); } catch (error) { next(error); } });
router.post("/", async (req, res, next) => { try { const body = { ...req.body }; delete body._id; const item = await Task.create(body); res.status(201).json(item); } catch (error) { next(error); } });
router.patch("/:id", async (req, res, next) => { try { const item = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true }); if (!item) return res.sendStatus(404); res.json(item); } catch (error) { next(error); } });
export default router;
