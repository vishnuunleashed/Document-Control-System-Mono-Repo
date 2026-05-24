import { Router } from "express";
import multer from "multer";
import {
  uploadDocument,
  getDocuments,
  getDocumentById,
  updateDocument,
  deleteDocument,
} from "../controllers/document.controller";
import { verifyToken } from "../../../../core/middleware/auth.middleware";

const router = Router();

// Setup Multer memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

router.use(verifyToken as any);

router.post("/", upload.single("file"), uploadDocument as any);
router.get("/", getDocuments as any);
router.get("/:id", getDocumentById as any);
router.put("/:id", updateDocument as any);
router.delete("/:id", deleteDocument as any);

export default router;
