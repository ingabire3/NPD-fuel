import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('\n🗑️  Cleaning database...\n');

  // Delete in FK-safe order (children before parents)
  await prisma.monthlyOdometerReading.deleteMany({});
  await prisma.notification.deleteMany({});
  await prisma.anomalyLog.deleteMany({});
  await prisma.fuelReceipt.deleteMany({});
  await prisma.fuelRequest.deleteMany({});
  await prisma.fuelAllocation.deleteMany({});
  await prisma.routeCache.deleteMany({});
  await prisma.vehicle.deleteMany({});
  await prisma.refreshToken.deleteMany({});
  await prisma.user.deleteMany({});

  console.log('  ✅ All tables cleared\n');

  // Create only admin + finance (drivers self-register via POST /auth/register)
  const [adminHash, financeHash] = await Promise.all([
    bcrypt.hash('Admin@1234', 12),
    bcrypt.hash('Finance@1234', 12),
  ]);

  const admin = await prisma.user.create({
    data: {
      fullName: 'System Admin',
      email: 'admin@npd.rw',
      phone: '0780000001',
      passwordHash: adminHash,
      role: Role.SUPER_ADMIN,
      department: 'IT',
      isActive: true,
      // SUPER_ADMIN needs no approvalStatus — null means "not subject to approval"
    },
  });

  const finance = await prisma.user.create({
    data: {
      fullName: 'Finance Officer',
      email: 'finance@npd.rw',
      phone: '0780000002',
      passwordHash: financeHash,
      role: Role.FINANCE,
      department: 'Finance',
      isActive: true,
    },
  });

  console.log('═══════════════════════════════════════════════');
  console.log('  DATABASE RESET COMPLETE');
  console.log('═══════════════════════════════════════════════');
  console.log(`  SUPER_ADMIN  ${admin.email}    / Admin@1234`);
  console.log(`  FINANCE      ${finance.email}  / Finance@1234`);
  console.log('═══════════════════════════════════════════════');
  console.log(`\n  Admin ID:   ${admin.id}`);
  console.log(`  Finance ID: ${finance.id}`);
  console.log('\n  ⚠️  No drivers, vehicles, or allocations.');
  console.log('  Drivers must self-register via POST /auth/register');
  console.log('  Admin approves via PATCH /users/:id/approve\n');
}

main()
  .catch((e) => {
    console.error('Reset failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
