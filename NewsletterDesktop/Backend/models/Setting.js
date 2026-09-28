import mongoose from "mongoose";
export default mongoose.model("Setting", new mongoose.Schema({ key: { type: String, unique: true }, value: String }));
