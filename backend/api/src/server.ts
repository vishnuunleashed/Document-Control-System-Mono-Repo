import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import { config } from "./core/config/config";
import { connectDatabase } from "./core/database/db";

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors({
  origin: "*", // Adjust to specific domains in production
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

// Body Parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Root Route
app.get("/", (req: Request, res: Response) => {
  res.json({
    message: "Welcome to the Document Control System API",
    version: "1.0.0",
    environment: config.NODE_ENV
  });
});

// Health check endpoint
app.get("/health", (req: Request, res: Response) => {
  res.json({
    status: "OK",
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Global Error Middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error("🔥 Global Error Handler Caught:", err.stack || err.message);
  res.status(500).json({
    error: "Internal Server Error",
    message: config.NODE_ENV === "development" ? err.message : "An unexpected error occurred"
  });
});

// Start Server
const startServer = async () => {
  // Connect to the DB
  await connectDatabase();

  app.listen(config.PORT, () => {
    console.log(`🚀 Server running on port ${config.PORT} in ${config.NODE_ENV} mode`);
  });
};

startServer();
export default app;
