import mongoose from "mongoose";
const range = new mongoose.Schema({ start: Number, end: Number, bold: Boolean, highlight: String, fontSize: Number }, { _id: false });
const schema = new mongoose.Schema({
  weekOf: { type: Date, required: true, index: true }, completedAt: Date, carriedFrom: Date, archived: { type: Boolean, default: false },
  quadrant: { type: String, enum: ["do", "schedule", "delegate", "eliminate"], required: true },
  content: { text: { type: String, required: true }, ranges: [range] }
}, { timestamps: true });
schema.set("toJSON", { transform: (_doc, value) => { value.id = value._id.toString(); delete value._id; delete value.__v; return value; } });
export default mongoose.model("Task", schema);
