import cron from "node-cron";
import Task from "../models/Task.js";

const monday = date => { const d = new Date(date); const day = d.getUTCDay(); d.setUTCDate(d.getUTCDate() - (day === 0 ? 6 : day - 1)); d.setUTCHours(0, 0, 0, 0); return d; };
export async function carryIncompleteTasks() {
  const current = monday(new Date()); const previous = new Date(current); previous.setUTCDate(previous.getUTCDate() - 7);
  const tasks = await Task.find({ weekOf: previous, completedAt: null, archived: false });
  await Promise.all(tasks.map(task => Task.create({ weekOf: current, carriedFrom: previous, quadrant: task.quadrant, content: task.content })));
  await Task.updateMany({ _id: { $in: tasks.map(task => task._id) } }, { archived: true });
}
export function startMondayReset() { cron.schedule("5 0 * * 1", () => carryIncompleteTasks().catch(console.error), { timezone: process.env.TASK_TIMEZONE || "Asia/Kolkata" }); }
