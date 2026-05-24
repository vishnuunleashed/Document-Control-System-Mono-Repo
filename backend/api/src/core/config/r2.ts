import { S3Client } from "@aws-sdk/client-s3";
import { config } from "./config";

export const r2Client = new S3Client({
  region: "auto",
  endpoint: config.R2_ENDPOINT,
  credentials: {
    accessKeyId: config.R2_ACCESS_KEY,
    secretAccessKey: config.R2_SECRET_KEY,
  },
});
