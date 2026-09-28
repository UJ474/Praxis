import crypto from "crypto";
const key = () => Buffer.from(process.env.TOKEN_ENCRYPTION_KEY, "base64");
export function encrypt(value) { const iv = crypto.randomBytes(12); const cipher = crypto.createCipheriv("aes-256-gcm", key(), iv); return [iv.toString("base64"), Buffer.concat([cipher.update(value, "utf8"), cipher.final()]).toString("base64"), cipher.getAuthTag().toString("base64")].join("."); }
export function decrypt(value) { const [iv, text, tag] = value.split(".").map(x => Buffer.from(x, "base64")); const decipher = crypto.createDecipheriv("aes-256-gcm", key(), iv); decipher.setAuthTag(tag); return Buffer.concat([decipher.update(text), decipher.final()]).toString("utf8"); }
