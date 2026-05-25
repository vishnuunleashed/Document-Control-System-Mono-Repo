import { Response } from "express";
import { z } from "zod";
import { DocumentModel } from "../../data/models/document.model";
import { StorageService } from "../../../../core/services/storage.service";
import { AuthenticatedRequest } from "../../../../core/middleware/auth.middleware";
import { AuditLog } from "../../../approvals/data/models/audit-log.model";

const updateDocSchema = z.object({
  title: z.string().min(2, "Title must be at least 2 characters long"),
  description: z.string().optional(),
});

export const uploadDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "Upload Failed", message: "No file was uploaded" });
    }

    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const { title, description } = req.body;
    if (!title) {
      return res.status(400).json({ error: "Validation Error", message: "Title is required" });
    }

    const file = req.file;

    // Validate size (< 5MB)
    const MAX_SIZE = 5 * 1024 * 1024;
    if (file.size > MAX_SIZE) {
      return res.status(400).json({ error: "Validation Error", message: "File size exceeds 5MB limit" });
    }

    // Validate type (pdf, docx, png, jpg)
    const allowedMimeTypes = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/msword",
      "image/png",
      "image/jpeg",
      "image/jpg",
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
      return res.status(400).json({
        error: "Validation Error",
        message: "Only PDF, DOCX, PNG, and JPG files are allowed",
      });
    }

    // Upload using StorageService
    const uploadResult = await StorageService.uploadFile(file.buffer, file.originalname, file.mimetype);

    // Create DB entry
    const doc = new DocumentModel({
      title,
      description: description || "",
      fileName: uploadResult.fileName,
      fileUrl: uploadResult.fileUrl,
      fileSize: file.size,
      mimeType: file.mimetype,
      uploadedBy: req.user._id,
      version: 1,
      status: "Draft",
    });

    await doc.save();

    // Log Action in Audit Log
    const audit = new AuditLog({
      documentId: doc._id,
      action: "Create",
      performedBy: req.user._id,
      comments: "Document initial upload and draft created",
      version: 1,
    });
    await audit.save();

    return res.status(201).json({
      message: "Document uploaded successfully",
      document: doc,
    });
  } catch (error: any) {
    console.error("❌ Upload Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const getDocuments = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    // Filters
    const query: any = {};

    // If Employee, they can only see their own uploads
    if (req.user.role === "Employee") {
      query.uploadedBy = req.user._id;
    }

    // Status filter
    if (req.query.status) {
      query.status = req.query.status;
    }

    // Search filter
    if (req.query.search) {
      query.title = { $regex: req.query.search, $options: "i" };
    }

    const docs = await DocumentModel.find(query)
      .populate("uploadedBy", "name email role")
      .sort({ updatedAt: -1 });

    return res.status(200).json({ documents: docs });
  } catch (error: any) {
    console.error("❌ Get Documents Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const getDocumentById = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const doc = await DocumentModel.findById(req.params.id).populate("uploadedBy", "name email role");

    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    // Enforce Employee access boundaries
    if (req.user.role === "Employee" && doc.uploadedBy._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: "Forbidden", message: "You do not have access to this document" });
    }

    return res.status(200).json({ document: doc });
  } catch (error: any) {
    console.error("❌ Get Document By Id Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const updateDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const parsed = updateDocSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Validation Error", details: parsed.error.format() });
    }

    const doc = await DocumentModel.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    // Verify ownership
    if (doc.uploadedBy.toString() !== req.user._id.toString() && req.user.role !== "Admin") {
      return res.status(403).json({ error: "Forbidden", message: "Only the owner can update this document" });
    }

    // Verify document state
    if (doc.status !== "Draft" && doc.status !== "Rejected" && req.user.role !== "Admin") {
      return res.status(400).json({
        error: "Bad Request",
        message: "Documents can only be edited in Draft or Rejected status",
      });
    }

    doc.title = parsed.data.title;
    if (parsed.data.description !== undefined) {
      doc.description = parsed.data.description;
    }

    await doc.save();

    // Log Action in Audit Log
    const audit = new AuditLog({
      documentId: doc._id,
      action: "Update",
      performedBy: req.user._id,
      comments: "Document details updated",
      version: doc.version,
    });
    await audit.save();

    return res.status(200).json({
      message: "Document updated successfully",
      document: doc,
    });
  } catch (error: any) {
    console.error("❌ Update Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const deleteDocument = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }

    const doc = await DocumentModel.findById(req.params.id);
    if (!doc) {
      return res.status(404).json({ error: "Not Found", message: "Document not found" });
    }

    // Verify ownership or Admin role
    if (doc.uploadedBy.toString() !== req.user._id.toString() && req.user.role !== "Admin") {
      return res.status(403).json({ error: "Forbidden", message: "You do not have permission to delete this document" });
    }

    // Verification check for Draft state (unless Admin)
    if (doc.status !== "Draft" && req.user.role !== "Admin") {
      return res.status(400).json({
        error: "Bad Request",
        message: "Only Draft documents can be deleted",
      });
    }

    // Delete file using StorageService
    await StorageService.deleteFile(doc.fileName);

    // Delete Mongoose Document
    await DocumentModel.deleteOne({ _id: doc._id });

    // Clean up Audit Logs
    await AuditLog.deleteMany({ documentId: doc._id });

    return res.status(200).json({
      message: "Document deleted successfully",
    });
  } catch (error: any) {
    console.error("❌ Delete Document Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};
