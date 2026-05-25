import { Router } from "express";
import { register, login, getMe } from "../controllers/auth.controller";
import { verifyToken } from "../../../../core/middleware/auth.middleware";

const router = Router();

router.post("/register", register as any);
router.post("/login", login as any);
router.get("/me", verifyToken as any, getMe as any);

export default router;
