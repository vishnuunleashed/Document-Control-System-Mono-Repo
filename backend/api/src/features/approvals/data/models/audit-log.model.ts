import mongoose, { Schema, Document } from "mongoose";

export interface IAuditLog extends Document {
  documentId: mongoose.Types.ObjectId;
  action: "Create" | "Update" | "Submit" | "Review" | "Approve" | "Reject";
  performedBy: mongoose.Types.ObjectId;
  comments?: string;
  version: number;
  timestamp: Date;
}

const AuditLogSchema: Schema = new Schema({
  documentId: { type: Schema.Types.ObjectId, ref: "Document", required: true },
  action: {
    type: String,
    enum: ["Create", "Update", "Submit", "Review", "Approve", "Reject"],
    required: true,
  },
  performedBy: { type: Schema.Types.ObjectId, ref: "User", required: true },
  comments: { type: String, trim: true },
  version: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now },
});

export const AuditLog = mongoose.model<IAuditLog>("AuditLog", AuditLogSchema);
