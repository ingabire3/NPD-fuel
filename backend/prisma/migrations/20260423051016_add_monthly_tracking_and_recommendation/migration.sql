-- CreateEnum
CREATE TYPE "SystemRecommendation" AS ENUM ('APPROVE', 'FLAG', 'REJECT');

-- AlterTable
ALTER TABLE "fuel_allocations" ADD COLUMN     "fuelPricePerLitre" DOUBLE PRECISION,
ADD COLUMN     "monthlyExpectedFuel" DOUBLE PRECISION,
ADD COLUMN     "totalExpectedCost" DOUBLE PRECISION,
ADD COLUMN     "workingDays" INTEGER;

-- AlterTable
ALTER TABLE "fuel_requests" ADD COLUMN     "systemRecommendation" "SystemRecommendation";

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "dailyDistanceKm" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "monthly_odometer_readings" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "month" INTEGER NOT NULL,
    "year" INTEGER NOT NULL,
    "startOdometer" DOUBLE PRECISION,
    "endOdometer" DOUBLE PRECISION,
    "actualDistanceKm" DOUBLE PRECISION,
    "startImageUrl" TEXT,
    "endImageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "monthly_odometer_readings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "monthly_odometer_readings_userId_vehicleId_month_year_key" ON "monthly_odometer_readings"("userId", "vehicleId", "month", "year");

-- AddForeignKey
ALTER TABLE "monthly_odometer_readings" ADD CONSTRAINT "monthly_odometer_readings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "monthly_odometer_readings" ADD CONSTRAINT "monthly_odometer_readings_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
