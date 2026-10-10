import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { LibraryService } from "./library.service";
import { SaveResourceDto } from "./dto/save-resource.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Library")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("library")
export class LibraryController {
  constructor(private readonly libraryService: LibraryService) {}

  @Get()
  @ApiOperation({ summary: "Get current user's saved resources" })
  getLibrary(@CurrentUser("id") userId: string) {
    return this.libraryService.getSavedResources(userId);
  }

  @Post()
  @ApiOperation({ summary: "Save a resource to personal library" })
  saveResource(
    @CurrentUser("id") userId: string,
    @Body() dto: SaveResourceDto,
  ) {
    return this.libraryService.saveResource(userId, dto.resourceId);
  }

  @Delete(":resourceId")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Remove a resource from personal library" })
  async removeResource(
    @CurrentUser("id") userId: string,
    @Param("resourceId") resourceId: string,
  ) {
    await this.libraryService.removeResource(userId, resourceId);
    return { removed: true };
  }
}
