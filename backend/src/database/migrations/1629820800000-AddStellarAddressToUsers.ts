import { MigrationInterface, QueryRunner, TableColumn } from "typeorm";

export class AddStellarAddressToUsers1629820800000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      "users",
      new TableColumn({
        name: "stellar_address",
        type: "varchar",
        length: "56",
        isNullable: true,
        isUnique: true,
      }),
    );

    // Create index for stellar_address
    await queryRunner.query(
      `CREATE INDEX idx_users_stellar_address ON users(stellar_address);`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex("users", "idx_users_stellar_address");
    await queryRunner.dropColumn("users", "stellar_address");
  }
}
