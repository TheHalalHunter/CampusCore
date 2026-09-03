import { Injectable, OnModuleInit, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as admin from "firebase-admin";

/**
 * Injectable wrapper around Firebase Admin SDK.
 * Initializes exactly once and exposes the app instance.
 * Import FirebaseModule and inject FirebaseAdminService wherever Firebase is needed.
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

    const projectId = this.config.get<string>("FIREBASE_PROJECT_ID");
    const privateKey = this.config.get<string>("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n");
    const clientEmail = this.config.get<string>("FIREBASE_CLIENT_EMAIL");

    if (!projectId || !privateKey || !clientEmail) {
      this.logger.error(
        "Firebase config incomplete — missing FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, or FIREBASE_CLIENT_EMAIL",
      );
      // Don't crash the app — Firebase features will be unavailable
      return;
    }

    this.app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey,
        clientEmail,
      }),
      storageBucket: this.config.get<string>("FIREBASE_STORAGE_BUCKET"),
    });

    this.logger.log("Firebase Admin SDK initialized");
  }

  getApp(): admin.app.App {
    return this.app;
  }

  auth(): admin.auth.Auth {
    if (!this.app) throw new Error("Firebase not initialized — check FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL");
    return this.app.auth();
  }

  storage(): admin.storage.Storage {
    if (!this.app) throw new Error("Firebase not initialized");
    return this.app.storage();
  }
}
