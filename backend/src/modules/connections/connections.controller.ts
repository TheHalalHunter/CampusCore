import {
  Controller,
  Post,
  Patch,
  Delete,
  Get,
  Param,
  Body,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { ConnectionsService } from "./connections.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Connections")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("connections")
export class ConnectionsController {
  constructor(private readonly service: ConnectionsService) {}

  @Post("request")
  @ApiOperation({ summary: "Send a connection request to another user" })
  sendRequest(
    @CurrentUser("id") userId: string,
    @Body("receiverId") receiverId: string,
  ) {
    return this.service.sendRequest(userId, receiverId);
  }

  @Patch(":id/accept")
  @ApiOperation({ summary: "Accept a pending connection request" })
  accept(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.service.acceptRequest(id, userId);
  }

  @Delete(":id")
  @ApiOperation({ summary: "Cancel, reject, or remove a connection" })
  remove(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.service.removeConnection(id, userId);
  }

  @Get()
  @ApiOperation({ summary: "Get all accepted connections for current user" })
  getConnections(@CurrentUser("id") userId: string) {
    return this.service.getConnections(userId);
  }

  @Get("pending/received")
  @ApiOperation({ summary: "Get pending requests received by current user" })
  getPendingReceived(@CurrentUser("id") userId: string) {
    return this.service.getPendingReceived(userId);
  }

  @Get("pending/sent")
  @ApiOperation({ summary: "Get pending requests sent by current user" })
  getPendingSent(@CurrentUser("id") userId: string) {
    return this.service.getPendingSent(userId);
  }

  @Get("status/:userId")
  @ApiOperation({ summary: "Get connection status with a specific user" })
  getStatus(
    @CurrentUser("id") currentUserId: string,
    @Param("userId") otherUserId: string,
  ) {
    return this.service.getStatus(currentUserId, otherUserId);
  }
}
