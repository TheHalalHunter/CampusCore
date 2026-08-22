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

    this.app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: this.config.get<string>("FIREBASE_PROJECT_ID"),
        privateKey: this.config
          .get<string>("FIREBASE_PRIVATE_KEY")
          ?.replace(/\\n/g, "\n"),
        clientEmail: this.config.get<string>("FIREBASE_CLIENT_EMAIL"),
      }),
      storageBucket: this.config.get<string>("FIREBASE_STORAGE_BUCKET"),
    });

    this.logger.log("Firebase Admin SDK initialized");
  }

  getApp(): admin.app.App {
    return this.app;
  }

  auth(): admin.auth.Auth {
    return this.app.auth();
  }

  storage(): admin.storage.Storage {
    return this.app.storage();
  }
}
