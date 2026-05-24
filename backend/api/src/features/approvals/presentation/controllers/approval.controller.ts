import { Response } from "express";
import { z } from "zod";
import { DocumentModel } from "../../../documents/data/models/document.model";
import { AuditLog } from "../../data/models/audit-log.model";
import { AuthenticatedRequest } from "../../../../core/middleware/auth.middleware";

const actionSchema = z.object({
  action: z.enum(["Approved", "Rejected"]),
  comments: z.string().min(3, "Comments must be at least 3 characters long"),
});

export const submitDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const doc = await DocumentModel.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    // Owner checks
    if (doc.uploadedBy.toString() !== req.user._id.toString() && req.user.role !== "Admin") {
      return res.status(403).json({ error: "Forbidden", message: "Only the owner can submit this document" });
    }

    if (doc.status !== "Draft" && doc.status !== "Rejected") {
      return res.status(400).json({
        error: "Bad Request",
        message: `Cannot submit document in '${doc.status}' status. Must be in Draft or Rejected.`,
      });
    }

    // Transition status to Submitted
    doc.status = "Submitted";
    await doc.save();

    // Log Action
    const audit = new AuditLog({
      documentId: doc._id,
      action: "Submit",
      performedBy: req.user._id,
      comments: req.body.comments || "Document submitted for review",
      version: doc.version,
    });
    await audit.save();

    return res.status(200).json({
      message: "Document submitted successfully",
      document: doc,
    });
  } catch (error: any) {
    console.error("❌ Submit Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const reviewDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const doc = await DocumentModel.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    if (doc.status !== "Submitted") {
      return res.status(400).json({
        error: "Bad Request",
        message: `Cannot mark document as Under Review from '${doc.status}' status. Must be Submitted.`,
      });
    }

    // Transition status to Under Review
    doc.status = "Under Review";
    await doc.save();

    // Log Action
    const audit = new AuditLog({
      documentId: doc._id,
      action: "Review",
      performedBy: req.user._id,
      comments: req.body.comments || "Document marked as Under Review",
      version: doc.version,
    });
    await audit.save();

    return res.status(200).json({
      message: "Document is now under review",
      document: doc,
    });
  } catch (error: any) {
    console.error("❌ Review Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const actionDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const parsed = actionSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Validation Error", details: parsed.error.format() });
    }

    const { action, comments } = parsed.data;

    const doc = await DocumentModel.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    if (doc.status !== "Under Review") {
      return res.status(400).json({
        error: "Bad Request",
        message: `Cannot approve or reject document from '${doc.status}' status. Must be Under Review.`,
      });
    }

    // Update status to Approved or Rejected
    doc.status = action;
    
    // If approved, lock this version. If rejected, it can be updated and version will increment on next submission,
    // or we can increment version if user edits and re-submits.
    if (action === "Approved") {
      // Locking version
    }
    
    await doc.save();

    // Log Action
    const audit = new AuditLog({
      documentId: doc._id,
      action: action === "Approved" ? "Approve" : "Reject",
      performedBy: req.user._id,
      comments,
      version: doc.version,
    });
    await audit.save();

    return res.status(200).json({
      message: `Document has been ${action.toLowerCase()}`,
      document: doc,
    });
  } catch (error: any) {
    console.error("❌ Action Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const getAuditLogs = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const logs = await AuditLog.find({ documentId: req.params.documentId })
      .populate("performedBy", "name email role")
      .sort({ timestamp: -1 });

    return res.status(200).json({ logs });
  } catch (error: any) {
    console.error("❌ Get Audit Logs Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};
