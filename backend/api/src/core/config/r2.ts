import { S3Client } from "@aws-sdk/client-s3";
import { config } from "./config";

// Detect region from AWS endpoint if applicable, default to "auto"
const isAws = config.R2_ENDPOINT.includes("amazonaws.com");
let region = "auto";
if (isAws) {
  const match = config.R2_ENDPOINT.match(/s3\.([a-z0-9-]+)\.amazonaws\.com/);
  if (match) {
    region = match[1];
  }
}

export const r2Client = new S3Client({
  region,
  endpoint: config.R2_ENDPOINT,
  credentials: {
    accessKeyId: config.R2_ACCESS_KEY,
    secretAccessKey: config.R2_SECRET_KEY,
  },
  forcePathStyle: !isAws, // AWS prefers virtual host style (false), R2 prefers path style (true)
});
