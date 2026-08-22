import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Connection, ConnectionStatus } from "./entities/connection.entity";
import { User } from "../users/entities/user.entity";

@Injectable()
export class ConnectionsService {
  constructor(
    @InjectRepository(Connection)
    private readonly repo: Repository<Connection>,
  ) {}

  /** Send a connection request */
  async sendRequest(requesterId: string, receiverId: string): Promise<Connection> {
    if (requesterId === receiverId) {
      throw new BadRequestException("You cannot connect with yourself");
    }

    // Check for existing connection in either direction
    const existing = await this.repo
      .createQueryBuilder("c")
      .where(
        "(c.requesterId = :a AND c.receiverId = :b) OR (c.requesterId = :b AND c.receiverId = :a)",
        { a: requesterId, b: receiverId },
      )
      .getOne();

    if (existing) {
      if (existing.status === ConnectionStatus.ACCEPTED) {
        throw new ConflictException("You are already connected");
      }
      throw new ConflictException("A connection request already exists");
    }

    const connection = this.repo.create({ requesterId, receiverId });
    return this.repo.save(connection);
  }

  /** Accept a pending connection request */
  async acceptRequest(connectionId: string, userId: string): Promise<Connection> {
    const connection = await this.repo.findOne({ where: { id: connectionId } });
    if (!connection) throw new NotFoundException("Connection request not found");

    if (connection.receiverId !== userId) {
      throw new ForbiddenException("Only the receiver can accept this request");
    }
    if (connection.status !== ConnectionStatus.PENDING) {
      throw new ConflictException("Request is not pending");
    }

    connection.status = ConnectionStatus.ACCEPTED;
    return this.repo.save(connection);
  }

  /** Reject or cancel / remove a connection */
  async removeConnection(connectionId: string, userId: string): Promise<void> {
    const connection = await this.repo.findOne({ where: { id: connectionId } });
    if (!connection) throw new NotFoundException("Connection not found");

    // Both requester (cancel) and receiver (reject/remove) can remove
    if (connection.requesterId !== userId && connection.receiverId !== userId) {
      throw new ForbiddenException("Not authorised to remove this connection");
    }

    await this.repo.delete(connectionId);
  }

  /** All accepted connections for a user */
  async getConnections(userId: string): Promise<Connection[]> {
    return this.repo
      .createQueryBuilder("c")
      .where(
        "(c.requesterId = :id OR c.receiverId = :id) AND c.status = :status",
        { id: userId, status: ConnectionStatus.ACCEPTED },
      )
      .orderBy("c.updatedAt", "DESC")
      .getMany();
  }

  /** Pending requests received by the user */
  getPendingReceived(userId: string): Promise<Connection[]> {
    return this.repo.find({
      where: { receiverId: userId, status: ConnectionStatus.PENDING },
      order: { createdAt: "DESC" },
    });
  }

  /** Pending requests sent by the user */
  getPendingSent(userId: string): Promise<Connection[]> {
    return this.repo.find({
      where: { requesterId: userId, status: ConnectionStatus.PENDING },
      order: { createdAt: "DESC" },
    });
  }

  /** Check connection status between two users */
  async getStatus(
    userId: string,
    otherUserId: string,
  ): Promise<{ status: string; connectionId: string | null; isSender: boolean }> {
    const connection = await this.repo
      .createQueryBuilder("c")
      .where(
        "(c.requesterId = :a AND c.receiverId = :b) OR (c.requesterId = :b AND c.receiverId = :a)",
        { a: userId, b: otherUserId },
      )
      .getOne();

    if (!connection) {
      return { status: "none", connectionId: null, isSender: false };
    }

    return {
      status: connection.status,
      connectionId: connection.id,
      isSender: connection.requesterId === userId,
    };
  }
}
