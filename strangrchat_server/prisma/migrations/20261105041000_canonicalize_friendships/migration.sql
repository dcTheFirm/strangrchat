ALTER TABLE "Friendship" ADD COLUMN "initiatedById" UUID;

UPDATE "Friendship" SET "initiatedById" = "user1Id";

WITH ranked AS (
  SELECT
    "id",
    ROW_NUMBER() OVER (
      PARTITION BY LEAST("user1Id", "user2Id"), GREATEST("user1Id", "user2Id")
      ORDER BY
        CASE "status"
          WHEN 'BLOCKED' THEN 0
          WHEN 'ACCEPTED' THEN 1
          ELSE 2
        END,
        "createdAt" ASC,
        "id" ASC
    ) AS position
  FROM "Friendship"
)
DELETE FROM "Friendship"
WHERE "id" IN (SELECT "id" FROM ranked WHERE position > 1);

UPDATE "Friendship"
SET ("user1Id", "user2Id") = ("user2Id", "user1Id")
WHERE "user1Id" > "user2Id";

ALTER TABLE "Friendship" ALTER COLUMN "initiatedById" SET NOT NULL;
ALTER TABLE "Friendship"
  ADD CONSTRAINT "Friendship_initiatedById_fkey"
  FOREIGN KEY ("initiatedById") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
