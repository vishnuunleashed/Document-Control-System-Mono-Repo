import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { z } from "zod";
import { User } from "../../data/models/user.model";
import { config } from "../../../../core/config/config";
import { AuthenticatedRequest } from "../../../../core/middleware/auth.middleware";

// Zod schemas for input validation
const registerSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long"),
  email: z.string().email("Invalid email address"),
  password: z.string().min(6, "Password must be at least 6 characters long"),
  role: z.enum(["Admin", "Reviewer", "Approver", "Employee"]).default("Employee"),
});

const loginSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(1, "Password is required"),
});

const generateToken = (userId: string, role: string): string => {
  return jwt.sign({ userId, role }, config.JWT_SECRET, {
    expiresIn: config.JWT_EXPIRES_IN as any,
  });
};

export const register = async (req: Request, res: Response) => {
  try {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Validation Error", details: parsed.error.format() });
    }

    const { name, email, password, role } = parsed.data;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: "Register Failed", message: "Email is already registered" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = new User({
      name,
      email,
      password: hashedPassword,
      role,
    });

    await user.save();

    // Generate JWT token
    const token = generateToken(user._id.toString(), user.role);

    return res.status(201).json({
      message: "User registered successfully",
      user,
      token,
    });
  } catch (error: any) {
    console.error("❌ Register Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Validation Error", details: parsed.error.format() });
    }

    const { email, password } = parsed.data;

    // Find user
    const user = await User.findOne({ email }).select("+password"); // In case we excluded it globally, load it
    if (!user) {
      return res.status(401).json({ error: "Login Failed", message: "Invalid email or password" });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password || "");
    if (!isMatch) {
      return res.status(401).json({ error: "Login Failed", message: "Invalid email or password" });
    }

    // Generate JWT token
    const token = generateToken(user._id.toString(), user.role);

    // Prepare clean user data response (JSON transform will clean password anyway)
    const userJson = user.toJSON();

    return res.status(200).json({
      message: "Login successful",
      user: userJson,
      token,
    });
  } catch (error: any) {
    console.error("❌ Login Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};

export const getMe = async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized", message: "User not authenticated" });
    }
    return res.status(200).json({ user: req.user });
  } catch (error: any) {
    console.error("❌ Me Error:", error);
    return res.status(500).json({ error: "Internal Server Error", message: error.message });
  }
};
