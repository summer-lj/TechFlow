CREATE TYPE "ClientPlatform" AS ENUM ('WEB', 'H5', 'MINI_PROGRAM', 'APP');

CREATE TYPE "LeadStatus" AS ENUM ('NEW', 'CONTACTED', 'QUALIFIED', 'ARCHIVED');

CREATE TABLE "Lead" (
  "id" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "email" TEXT NOT NULL,
  "company" TEXT,
  "platform" "ClientPlatform" NOT NULL,
  "message" TEXT,
  "source" TEXT NOT NULL DEFAULT 'demo-page',
  "status" "LeadStatus" NOT NULL DEFAULT 'NEW',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "Lead_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Lead_createdAt_idx" ON "Lead"("createdAt" DESC);
CREATE INDEX "Lead_email_idx" ON "Lead"("email");
