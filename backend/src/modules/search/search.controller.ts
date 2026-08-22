import { Controller, Get, Query } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiQuery } from "@nestjs/swagger";
import { SearchService } from "./search.service";
import { Public } from "../../common/decorators/public.decorator";

@ApiTags("Search")
@Controller("search")
export class SearchController {
  constructor(private readonly service: SearchService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: "Global search across courses, resources and Q&A" })
  @ApiQuery({ name: "q", required: true, description: "Search query" })
  @ApiQuery({ name: "departmentId", required: false })
  @ApiQuery({ name: "limit", required: false, type: Number })
  search(
    @Query("q") q: string,
    @Query("departmentId") departmentId?: string,
    @Query("limit") limit = 10,
  ) {
    return this.service.search(q, departmentId, +limit);
  }
}
