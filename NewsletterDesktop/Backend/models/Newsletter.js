import mongoose from "mongoose";

const quote = new mongoose.Schema({ attribution: String, quote: String, source: String }, { _id: false });
const question = new mongoose.Schema({ attribution: String, text: String }, { _id: false });
const schema = new mongoose.Schema({
  receivedDate: { type: Date, required: true, unique: true }, weekOf: { type: Date, required: true, index: true },
  issueUrl: { type: String, required: true }, topics: [String], ideas: [String], quotes: [quote], question
}, { timestamps: true });
schema.set("toJSON", { transform: (_doc, value) => { value.id = value._id.toString(); delete value._id; delete value.__v; return value; } });
export default mongoose.model("Newsletter", schema);
