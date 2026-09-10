import { Injectable, OnModuleInit, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as admin from "firebase-admin";

/**
 * Injectable wrapper around Firebase Admin SDK.
 * Supports two init strategies:
 *  1. FIREBASE_SERVICE_ACCOUNT_JSON — full service account JSON string (preferred, no \n issues)
 *  2. Individual vars: FIREBASE_PROJECT_ID + FIREBASE_PRIVATE_KEY + FIREBASE_CLIENT_EMAIL
 */
@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private app: admin.app.App;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    if (admin.apps.length > 0) {
      this.app = admin.apps[0];
      return;
    }

    let credential: admin.credential.Credential;

    // Strategy 1: full service account JSON (most reliable)
    const saJson = this.config.get<string>("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (saJson) {
      try {
        const sa = JSON.parse(saJson);
        credential = admin.credential.cert(sa);
        this.logger.log("Firebase: using FIREBASE_SERVICE_ACCOUNT_JSON");
      } catch (e) {
        this.logger.error("FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON", e);
        return;
      }
    } else {
      // Strategy 2: individual vars
      const projectId   = this.config.get<string>("FIREBASE_PROJECT_ID");
      const clientEmail = this.config.get<string>("FIREBASE_CLIENT_EMAIL");
      const rawKey      = this.config.get<string>("FIREBASE_PRIVATE_KEY") ?? "";
      const privateKey  = rawKey.includes("\\n")
        ? rawKey.replace(/\\n/g, "\n")
        : rawKey;

      if (!projectId || !privateKey || !clientEmail) {
        this.logger.error(
          "Firebase config incomplete — set FIREBASE_SERVICE_ACCOUNT_JSON or " +
          "FIREBASE_PROJECT_ID + FIREBASE_PRIVATE_KEY + FIREBASE_CLIENT_EMAIL",
        );
        return;
      }
      credential = admin.credential.cert({ projectId, privateKey, clientEmail });
      this.logger.log("Firebase: using individual FIREBASE_* vars");
    }

    this.app = admin.initializeApp({
      credential,
      storageBucket: this.config.get<string>("FIREBASE_STORAGE_BUCKET"),
    });

    this.logger.log("Firebase Admin SDK initialized successfully");
  }

  getApp(): admin.app.App {
    return this.app;
  }

  auth(): admin.auth.Auth {
    if (!this.app) throw new Error("Firebase not initialized — check FIREBASE_SERVICE_ACCOUNT_JSON or individual FIREBASE_* vars");
    return this.app.auth();
  }

  storage(): admin.storage.Storage {
    if (!this.app) throw new Error("Firebase not initialized");
    return this.app.storage();
  }
}
