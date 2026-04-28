-- CreateEnum
CREATE TYPE "FuelVariance" AS ENUM ('NORMAL', 'WARNING', 'SUSPICIOUS');

-- AlterTable
ALTER TABLE "fuel_requests" ADD COLUMN     "estimatedDistance" DOUBLE PRECISION,
ADD COLUMN     "expectedFuel" DOUBLE PRECISION,
ADD COLUMN     "fuelVariance" "FuelVariance" NOT NULL DEFAULT 'NORMAL';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "homeLat" DOUBLE PRECISION,
ADD COLUMN     "homeLng" DOUBLE PRECISION,
ADD COLUMN     "workLat" DOUBLE PRECISION,
ADD COLUMN     "workLng" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "route_cache" (
    "id" TEXT NOT NULL,
    "cacheKey" TEXT NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "route_cache_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "route_cache_cacheKey_key" ON "route_cache"("cacheKey");
