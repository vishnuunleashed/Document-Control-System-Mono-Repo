import { PutObjectCommand } from "@aws-sdk/client-s3";
import { r2Client } from "../config/r2";
import { config } from "../config/config";
import fs from "fs";
import path from "path";

export interface UploadResult {
  fileUrl: string;
  fileName: string;
}

export class StorageService {
  private static localUploadsDir = path.join(__dirname, "../../../uploads");

  /**
   * Check if R2 is configured and not using mock credentials
   */
  private static isR2Configured(): boolean {
    const accessKey = config.R2_ACCESS_KEY || "";
    const secretKey = config.R2_SECRET_KEY || "";
    const endpoint = config.R2_ENDPOINT || "";

    if (
      !accessKey ||
      !secretKey ||
      !endpoint ||
      accessKey.includes("mock_") ||
      accessKey.includes("your_") ||
      secretKey.includes("mock_") ||
      secretKey.includes("your_")
    ) {
      return false;
    }
    return true;
  }

  /**
   * Upload a file from memory buffer to Cloudflare R2, falling back to local storage if R2 is not configured
   */
  public static async uploadFile(
    fileBuffer: Buffer,
    originalName: string,
    mimeType: string
  ): Promise<UploadResult> {
    // Generate unique name: uuid_timestamp.ext
    const ext = path.extname(originalName) || ".bin";
    const baseNameWithoutExt = path.basename(originalName, ext).replace(/[^a-zA-Z0-9]/g, "_");
    const uniqueFileName = `${baseNameWithoutExt}_${Date.now()}${ext}`;

    // Try Cloudflare R2 first
    if (this.isR2Configured()) {
      try {
        console.log(`☁️ Uploading ${uniqueFileName} to Cloudflare R2...`);
        const command = new PutObjectCommand({
          Bucket: config.R2_BUCKET_NAME,
          Key: uniqueFileName,
          Body: fileBuffer,
          ContentType: mimeType,
        });

        await r2Client.send(command);

        const fileUrl = config.R2_PUBLIC_URL
          ? `${config.R2_PUBLIC_URL}/${uniqueFileName}`
          : `${config.R2_ENDPOINT}/${config.R2_BUCKET_NAME}/${uniqueFileName}`;
        return { fileUrl, fileName: uniqueFileName };
      } catch (error) {
        console.error("❌ Cloudflare R2 Upload failed, falling back to local storage:", error);
      }
    }

    // Fallback: Local filesystem storage
    console.log(`📁 Saving ${uniqueFileName} to local storage fallback...`);
    if (!fs.existsSync(this.localUploadsDir)) {
      fs.mkdirSync(this.localUploadsDir, { recursive: true });
    }

    const filePath = path.join(this.localUploadsDir, uniqueFileName);
    fs.writeFileSync(filePath, fileBuffer);

    // Return the local URL served statically by our express server
    const fileUrl = `http://localhost:${config.PORT}/uploads/${uniqueFileName}`;
    return { fileUrl, fileName: uniqueFileName };
  }

  /**
   * Delete a file (optional helper)
   */
  public static async deleteFile(fileName: string): Promise<void> {
    if (this.isR2Configured()) {
      // In production, we'd delete from S3
      // For this portfolio model, we skip errors here to avoid blocking
    }

    // Always check if local file exists and delete it
    const localPath = path.join(this.localUploadsDir, fileName);
    if (fs.existsSync(localPath)) {
      try {
        fs.unlinkSync(localPath);
      } catch (err) {
        console.error(`❌ Failed to delete local file ${fileName}:`, err);
      }
    }
  }
}
