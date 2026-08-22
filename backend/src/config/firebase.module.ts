import { Module, Global } from "@nestjs/common";
import { FirebaseAdminService } from "./firebase.config";

/**
 * Global module — import once in AppModule and FirebaseAdminService
 * is available everywhere without re-importing.
 */
@Global()
@Module({
  providers: [FirebaseAdminService],
  exports: [FirebaseAdminService],
})
export class FirebaseModule {}
