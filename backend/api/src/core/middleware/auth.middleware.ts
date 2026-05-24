import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { config } from "../config/config";
import { User, IUser } from "../../features/auth/data/models/user.model";

// Extend Request type to include user information
export interface AuthenticatedRequest extends Request {
  user?: IUser;
  token?: string;
}

interface JwtPayload {
  userId: string;
  role: string;
}

export const verifyToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Access Denied", message: "No token provided" });
    }

    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, config.JWT_SECRET) as JwtPayload;

    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ error: "Access Denied", message: "User not found" });
    }

    req.user = user;
    req.token = token;
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid Token", message: "Authentication failed" });
  }
};

export const requireRole = (roles: Array<"Admin" | "Reviewer" | "Approver" | "Employee">) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: "Access Denied", message: "Unauthorized" });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: "Forbidden",
        message: `Role '${req.user.role}' does not have permission to perform this action`,
      });
    }

    next();
  };
};
