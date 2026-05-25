import dotenv from "dotenv";
import path from "path";
import { z } from "zod";

// Load env variables
dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(5000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  MONGO_URI: z.string().min(1, "MONGO_URI is required"),
  JWT_SECRET: z.string().min(1, "JWT_SECRET is required"),
  JWT_EXPIRES_IN: z.string().default("7d"),
  R2_ENDPOINT: z.string().min(1, "R2_ENDPOINT is required"),
  R2_ACCESS_KEY: z.string().min(1, "R2_ACCESS_KEY is required"),
  R2_SECRET_KEY: z.string().min(1, "R2_SECRET_KEY is required"),
  R2_BUCKET_NAME: z.string().default("dcs-files"),
  R2_PUBLIC_URL: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error("❌ Environment configuration validation failed:");
  console.error(JSON.stringify(parsed.error.format(), null, 2));
  process.exit(1);
}

export const config = parsed.data;
export type EnvConfig = z.infer<typeof envSchema>;
