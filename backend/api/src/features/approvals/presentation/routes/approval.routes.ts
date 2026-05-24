import { Router } from "express";
import {
  submitDocument,
  reviewDocument,
  actionDocument,
  getAuditLogs,
} from "../controllers/approval.controller";
import { verifyToken, requireRole } from "../../../../core/middleware/auth.middleware";

const router = Router();

router.use(verifyToken as any);

router.post("/:id/submit", submitDocument as any);
router.post("/:id/review", requireRole(["Reviewer", "Admin"]) as any, reviewDocument as any);
router.post("/:id/action", requireRole(["Approver", "Admin"]) as any, actionDocument as any);
router.get("/logs/:documentId", getAuditLogs as any);

export default router;
