import mongoose from "mongoose";
import { config } from "../config/config";

export const connectDatabase = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(config.MONGO_URI);
    console.log(`📡 MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error("❌ MongoDB connection error:", error);
    process.exit(1);
  }
};
