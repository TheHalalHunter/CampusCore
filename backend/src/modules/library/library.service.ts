import {
  Injectable,
  NotFoundException,
  ConflictException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { PersonalLibraryItem } from "./entities/personal-library.entity";
import { Resource } from "../resources/entities/resource.entity";

@Injectable()
export class LibraryService {
  constructor(
    @InjectRepository(PersonalLibraryItem)
    private readonly libraryRepository: Repository<PersonalLibraryItem>,
    @InjectRepository(Resource)
    private readonly resourceRepository: Repository<Resource>,
  ) {}

  async getSavedResources(userId: string): Promise<PersonalLibraryItem[]> {
    return this.libraryRepository.find({
      where: { userId },
      relations: ["resource"],
      order: { createdAt: "DESC" },
    });
  }

  async saveResource(
    userId: string,
    resourceId: string,
  ): Promise<PersonalLibraryItem> {
    // Verify resource exists
    const resource = await this.resourceRepository.findOne({
      where: { id: resourceId },
    });
    if (!resource) {
      throw new NotFoundException("Resource not found");
    }

    // Check if already saved (idempotent)
    const existing = await this.libraryRepository.findOne({
      where: { userId, resourceId },
      relations: ["resource"],
    });
    if (existing) {
      return existing;
    }

    const item = this.libraryRepository.create({ userId, resourceId });
    const saved = await this.libraryRepository.save(item);

    // Return with relation loaded
    return this.libraryRepository.findOne({
      where: { id: saved.id },
      relations: ["resource"],
    }) as Promise<PersonalLibraryItem>;
  }

  async removeResource(userId: string, resourceId: string): Promise<void> {
    const item = await this.libraryRepository.findOne({
      where: { userId, resourceId },
    });
    if (!item) {
      throw new NotFoundException("Item not found in your library");
    }
    await this.libraryRepository.remove(item);
  }
}
