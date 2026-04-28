import {
  PrismaClient,
  Role,
  FuelType,
  RequestStatus,
  AnomalyType,
  AnomalySeverity,
  AnomalyStatus,
  VerificationStatus,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

// ─── helpers ──────────────────────────────────────────────────────────────────

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

function monthOffset(monthsBack: number): { month: number; year: number } {
  const d = new Date();
  d.setMonth(d.getMonth() - monthsBack);
  return { month: d.getMonth() + 1, year: d.getFullYear() };
}

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n🌱 Seeding NPD Fuel database with realistic test data...\n');

  // ── 1. HASH PASSWORDS ──────────────────────────────────────────────────────

  const [adminHash, managerHash, driverHash, financeHash] = await Promise.all([
    bcrypt.hash('Admin@1234', 12),
    bcrypt.hash('Manager@1234', 12),
    bcrypt.hash('Driver@1234', 12),
    bcrypt.hash('Finance@1234', 12),
  ]);

  // ── 2. SUPER ADMIN ─────────────────────────────────────────────────────────

  const admin = await prisma.user.upsert({
    where: { email: 'admin@npd.rw' },
    update: { passwordHash: adminHash, isActive: true },
    create: {
      fullName: 'NPD Super Admin',
      email: 'admin@npd.rw',
      phone: '0780000001',
      passwordHash: adminHash,
      role: Role.SUPER_ADMIN,
      department: 'IT',
      isActive: true,
    },
  });

  // ── 3. FINANCE USERS ───────────────────────────────────────────────────────

  const financeUsers = await Promise.all([
    prisma.user.upsert({
      where: { email: 'finance@npd.rw' },
      update: { passwordHash: financeHash, isActive: true },
      create: {
        fullName: 'Uwimana Marie',
        email: 'finance@npd.rw',
        phone: '0784584584',
        passwordHash: financeHash,
        role: Role.FINANCE,
        department: 'Finance',
        isActive: true,
      },
    }),
    prisma.user.upsert({
      where: { email: 'finance2@npd.rw' },
      update: { passwordHash: financeHash, isActive: true },
      create: {
        fullName: 'Mukamana Alice',
        email: 'finance2@npd.rw',
        phone: '0782345678',
        passwordHash: financeHash,
        role: Role.FINANCE,
        department: 'Finance',
        isActive: true,
      },
    }),
  ]);

  // ── 4. MANAGERS ────────────────────────────────────────────────────────────

  const managers = await Promise.all([
    prisma.user.upsert({
      where: { email: 'manager@npd.rw' },
      update: { passwordHash: managerHash, isActive: true },
      create: {
        fullName: 'Jean Pierre Nzeyimana',
        email: 'manager@npd.rw',
        phone: '0788001001',
        passwordHash: managerHash,
        role: Role.MANAGER,
        department: 'Operations',
        isActive: true,
      },
    }),
    prisma.user.upsert({
      where: { email: 'manager2@npd.rw' },
      update: { passwordHash: managerHash, isActive: true },
      create: {
        fullName: 'Karangwa David',
        email: 'manager2@npd.rw',
        phone: '0788001002',
        passwordHash: managerHash,
        role: Role.MANAGER,
        department: 'Logistics',
        isActive: true,
      },
    }),
    prisma.user.upsert({
      where: { email: 'manager3@npd.rw' },
      update: { passwordHash: managerHash, isActive: true },
      create: {
        fullName: 'Bizimana Robert',
        email: 'manager3@npd.rw',
        phone: '0788001003',
        passwordHash: managerHash,
        role: Role.MANAGER,
        department: 'Field Operations',
        isActive: true,
      },
    }),
  ]);

  const [mgr1, mgr2, mgr3] = managers;

  // ── 5. DRIVERS ─────────────────────────────────────────────────────────────

  const driverData = [
    { name: 'Mugisha Eric',          email: 'driver@npd.rw',     phone: '0722001001', dept: 'Logistics',   mgr: mgr1.id },
    { name: 'Hakizimana Emmanuel',   email: 'driver2@npd.rw',    phone: '0722001002', dept: 'Logistics',   mgr: mgr1.id },
    { name: 'Uwase Sarah',           email: 'driver3@npd.rw',    phone: '0722001003', dept: 'Logistics',   mgr: mgr1.id },
    { name: 'Niyonsaba Jean',        email: 'driver4@npd.rw',    phone: '0722001004', dept: 'Logistics',   mgr: mgr1.id },
    { name: 'Nsabimana François',    email: 'driver5@npd.rw',    phone: '0722001005', dept: 'Logistics',   mgr: mgr1.id },
    { name: 'Nikuze Celestine',      email: 'driver6@npd.rw',    phone: '0722001006', dept: 'Operations',  mgr: mgr2.id },
    { name: 'Habimana Patrick',      email: 'driver7@npd.rw',    phone: '0722001007', dept: 'Operations',  mgr: mgr2.id },
    { name: 'Umuhoza Grace',         email: 'driver8@npd.rw',    phone: '0722001008', dept: 'Operations',  mgr: mgr2.id },
    { name: 'Mutuyimana Claudine',   email: 'driver9@npd.rw',    phone: '0722001009', dept: 'Operations',  mgr: mgr2.id },
    { name: 'Ndayishimiye Claude',   email: 'driver10@npd.rw',   phone: '0722001010', dept: 'Operations',  mgr: mgr2.id },
    { name: 'Ingabire Josiane',      email: 'driver11@npd.rw',   phone: '0722001011', dept: 'Field Ops',   mgr: mgr3.id },
    { name: 'Kagabo Eric',           email: 'driver12@npd.rw',   phone: '0722001012', dept: 'Field Ops',   mgr: mgr3.id },
    { name: 'Uwingabire Vestine',    email: 'driver13@npd.rw',   phone: '0722001013', dept: 'Field Ops',   mgr: mgr3.id },
    { name: 'Mugabo Jean-Pierre',    email: 'driver14@npd.rw',   phone: '0722001014', dept: 'Field Ops',   mgr: mgr3.id },
    // Edge case: driver with no manager
    { name: 'Uwera Beatrice',        email: 'driver15@npd.rw',   phone: '0722001015', dept: 'General',     mgr: null },
  ];

  const drivers = await Promise.all(
    driverData.map((d) =>
      prisma.user.upsert({
        where: { email: d.email },
        update: { passwordHash: driverHash, isActive: true, managerId: d.mgr },
        create: {
          fullName: d.name,
          email: d.email,
          phone: d.phone,
          passwordHash: driverHash,
          role: Role.DRIVER,
          department: d.dept,
          isActive: true,
          managerId: d.mgr,
        },
      }),
    ),
  );

  console.log(`  ✅ Users: 1 admin, 2 finance, 3 managers, ${drivers.length} drivers`);

  // ── 6. VEHICLES ────────────────────────────────────────────────────────────

  const vehicleData = [
    { plate: 'RAB 001 A', make: 'Toyota',      model: 'Land Cruiser', year: 2022, fuel: FuelType.DIESEL, tank: 80,  kmL: 8.5,  driver: drivers[0] },
    { plate: 'RAB 002 A', make: 'Toyota',      model: 'Hilux',        year: 2021, fuel: FuelType.DIESEL, tank: 70,  kmL: 10.0, driver: drivers[1] },
    { plate: 'RAB 003 A', make: 'Mitsubishi',  model: 'Pajero',       year: 2020, fuel: FuelType.DIESEL, tank: 75,  kmL: 9.0,  driver: drivers[2] },
    { plate: 'RAB 004 A', make: 'Nissan',      model: 'Patrol',       year: 2022, fuel: FuelType.DIESEL, tank: 90,  kmL: 7.5,  driver: drivers[3] },
    { plate: 'RAB 005 A', make: 'Isuzu',       model: 'D-Max',        year: 2021, fuel: FuelType.DIESEL, tank: 65,  kmL: 11.0, driver: drivers[4] },
    { plate: 'RAC 001 A', make: 'Toyota',      model: 'Prado',        year: 2023, fuel: FuelType.DIESEL, tank: 80,  kmL: 9.5,  driver: drivers[5] },
    { plate: 'RAC 002 A', make: 'Toyota',      model: 'Fortuner',     year: 2022, fuel: FuelType.DIESEL, tank: 70,  kmL: 10.5, driver: drivers[6] },
    { plate: 'RAC 003 A', make: 'Mitsubishi',  model: 'L200',         year: 2021, fuel: FuelType.DIESEL, tank: 60,  kmL: 12.0, driver: drivers[7] },
    { plate: 'RAC 004 A', make: 'Ford',        model: 'Ranger',       year: 2022, fuel: FuelType.DIESEL, tank: 72,  kmL: 10.0, driver: drivers[8] },
    { plate: 'RAC 005 A', make: 'Volkswagen',  model: 'Amarok',       year: 2020, fuel: FuelType.DIESEL, tank: 80,  kmL: 9.0,  driver: drivers[9] },
    { plate: 'RAD 001 A', make: 'Toyota',      model: 'Corolla',      year: 2021, fuel: FuelType.PETROL, tank: 50,  kmL: 14.0, driver: drivers[10] },
    { plate: 'RAD 002 A', make: 'Toyota',      model: 'Camry',        year: 2022, fuel: FuelType.PETROL, tank: 55,  kmL: 13.0, driver: drivers[11] },
    { plate: 'RAD 003 A', make: 'Honda',       model: 'CR-V',         year: 2021, fuel: FuelType.PETROL, tank: 58,  kmL: 12.5, driver: drivers[12] },
    { plate: 'RAD 004 A', make: 'Nissan',      model: 'X-Trail',      year: 2020, fuel: FuelType.PETROL, tank: 60,  kmL: 12.0, driver: drivers[13] },
    // Unassigned vehicle (edge case)
    { plate: 'RAD 005 A', make: 'Toyota',      model: 'RAV4',         year: 2023, fuel: FuelType.PETROL, tank: 55,  kmL: 13.5, driver: null },
  ];

  const vehicles = await Promise.all(
    vehicleData.map((v) =>
      prisma.vehicle.upsert({
        where: { plateNumber: v.plate },
        update: { assignedDriverId: v.driver?.id ?? null },
        create: {
          plateNumber: v.plate,
          make: v.make,
          model: v.model,
          year: v.year,
          fuelType: v.fuel,
          tankCapacity: v.tank,
          averageKmPerL: v.kmL,
          isActive: true,
          assignedDriverId: v.driver?.id ?? null,
        },
      }),
    ),
  );

  console.log(`  ✅ Vehicles: ${vehicles.length} registered`);

  // ── 7. FUEL ALLOCATIONS ────────────────────────────────────────────────────

  const now     = monthOffset(0);
  const prev1   = monthOffset(1);
  const prev2   = monthOffset(2);

  // RWF per liter (approx)
  const DIESEL_PRICE = 1400;
  const PETROL_PRICE = 1350;

  type AllocInput = {
    driverIdx: number;
    vehicleIdx: number;
    liters: number;
    usedLiters: number;
    month: number;
    year: number;
  };

  const allocInputs: AllocInput[] = [
    // Current month — all active drivers
    { driverIdx: 0,  vehicleIdx: 0,  liters: 200, usedLiters: 80,  ...now },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 180, usedLiters: 120, ...now },
    { driverIdx: 2,  vehicleIdx: 2,  liters: 150, usedLiters: 50,  ...now },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 220, usedLiters: 180, ...now }, // nearly depleted
    { driverIdx: 4,  vehicleIdx: 4,  liters: 160, usedLiters: 160, ...now }, // fully depleted edge case
    { driverIdx: 5,  vehicleIdx: 5,  liters: 200, usedLiters: 40,  ...now },
    { driverIdx: 6,  vehicleIdx: 6,  liters: 175, usedLiters: 70,  ...now },
    { driverIdx: 7,  vehicleIdx: 7,  liters: 150, usedLiters: 100, ...now },
    { driverIdx: 8,  vehicleIdx: 8,  liters: 190, usedLiters: 60,  ...now },
    { driverIdx: 9,  vehicleIdx: 9,  liters: 200, usedLiters: 90,  ...now },
    { driverIdx: 10, vehicleIdx: 10, liters: 120, usedLiters: 30,  ...now },
    { driverIdx: 11, vehicleIdx: 11, liters: 130, usedLiters: 0,   ...now },
    { driverIdx: 12, vehicleIdx: 12, liters: 140, usedLiters: 110, ...now },
    { driverIdx: 13, vehicleIdx: 13, liters: 150, usedLiters: 45,  ...now },
    // drivers[14] (Uwera Beatrice) has NO allocation — edge case

    // Previous month — some drivers
    { driverIdx: 0,  vehicleIdx: 0,  liters: 200, usedLiters: 200, ...prev1 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 180, usedLiters: 165, ...prev1 },
    { driverIdx: 2,  vehicleIdx: 2,  liters: 150, usedLiters: 140, ...prev1 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 220, usedLiters: 210, ...prev1 },
    { driverIdx: 5,  vehicleIdx: 5,  liters: 200, usedLiters: 195, ...prev1 },
    { driverIdx: 6,  vehicleIdx: 6,  liters: 175, usedLiters: 160, ...prev1 },

    // Two months ago
    { driverIdx: 0,  vehicleIdx: 0,  liters: 200, usedLiters: 190, ...prev2 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 180, usedLiters: 175, ...prev2 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 220, usedLiters: 220, ...prev2 },
  ];

  const allocations = await Promise.all(
    allocInputs.map((a) => {
      const driver  = drivers[a.driverIdx];
      const vehicle = vehicles[a.vehicleIdx];
      const isBenzine = vehicle.fuelType === FuelType.PETROL;
      const pricePerL = isBenzine ? PETROL_PRICE : DIESEL_PRICE;
      const allocatedAmount = a.liters * pricePerL;
      const remainingLiters = Math.max(0, a.liters - a.usedLiters);

      return prisma.fuelAllocation.upsert({
        where: {
          userId_vehicleId_month_year: {
            userId: driver.id,
            vehicleId: vehicle.id,
            month: a.month,
            year: a.year,
          },
        },
        update: { usedLiters: a.usedLiters, remainingLiters },
        create: {
          userId: driver.id,
          vehicleId: vehicle.id,
          month: a.month,
          year: a.year,
          allocatedLiters: a.liters,
          allocatedAmount,
          usedLiters: a.usedLiters,
          remainingLiters,
        },
      });
    }),
  );

  console.log(`  ✅ Allocations: ${allocations.length} (current + 2 previous months)`);

  // Helper: find current-month allocation for a driver/vehicle
  const findAlloc = (driverIdx: number, vehicleIdx: number) =>
    allocations.find(
      (a) =>
        a.userId === drivers[driverIdx].id &&
        a.vehicleId === vehicles[vehicleIdx].id &&
        a.month === now.month &&
        a.year === now.year,
    ) ?? null;

  // ── 8. FUEL REQUESTS ───────────────────────────────────────────────────────

  const approver = financeUsers[0];

  type ReqInput = {
    driverIdx: number;
    vehicleIdx: number;
    liters: number;
    purpose: string;
    trip: string;
    status: RequestStatus;
    daysBack: number;
    rejReason?: string;
    odomBefore?: number;
    odomAfter?: number;
  };

  const purposes = [
    'Field inspection trip to Rwamagana district',
    'Materials delivery to Kigali construction site',
    'Staff transport to Musanze regional office',
    'Emergency fuel for standby generator',
    'District coordination meeting in Huye',
    'Supply chain delivery to Rubavu warehouse',
    'Monthly supervision trip to Nyagatare',
    'Fuel for water pump maintenance vehicle',
    'Site visit to Bugesera project zone',
    'Office supply transport to Kayonza',
    'Border clearance trip to Gatuna',
    'Medical supplies delivery to Nyanza hospital',
    'Executive transport to Kigali Convention Centre',
    'Airport transfer for international delegation',
    'Road condition assessment in Southern Province',
  ];

  const rejectionReasons = [
    'Allocation already exhausted for this month',
    'Trip purpose not approved by department head',
    'Vehicle scheduled for maintenance on requested date',
    'Duplicate request — already approved earlier this week',
    'Requested quantity exceeds trip requirements',
    'Missing trip authorization form',
  ];

  const reqInputs: ReqInput[] = [
    // FULFILLED — with odometer readings (current month)
    { driverIdx: 0,  vehicleIdx: 0,  liters: 40,  purpose: purposes[0],  trip: 'Kigali - Rwamagana (60km)',        status: RequestStatus.FULFILLED, daysBack: 2,  odomBefore: 45200, odomAfter: 45510 },
    { driverIdx: 0,  vehicleIdx: 0,  liters: 30,  purpose: purposes[6],  trip: 'Kigali - Nyagatare (200km)',       status: RequestStatus.FULFILLED, daysBack: 8,  odomBefore: 44700, odomAfter: 44970 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 50,  purpose: purposes[1],  trip: 'Kigali CBD - Kanombe',             status: RequestStatus.FULFILLED, daysBack: 3,  odomBefore: 32100, odomAfter: 32600 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 45,  purpose: purposes[9],  trip: 'Kigali - Kayonza (90km)',          status: RequestStatus.FULFILLED, daysBack: 10, odomBefore: 31600, odomAfter: 32050 },
    { driverIdx: 2,  vehicleIdx: 2,  liters: 35,  purpose: purposes[4],  trip: 'Kigali - Huye (200km)',            status: RequestStatus.FULFILLED, daysBack: 5,  odomBefore: 28400, odomAfter: 28730 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 60,  purpose: purposes[10], trip: 'Kigali - Gatuna (100km)',          status: RequestStatus.FULFILLED, daysBack: 6,  odomBefore: 61200, odomAfter: 61680 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 55,  purpose: purposes[5],  trip: 'Kigali - Rubavu (160km)',          status: RequestStatus.FULFILLED, daysBack: 14, odomBefore: 60700, odomAfter: 61150 },
    { driverIdx: 5,  vehicleIdx: 5,  liters: 40,  purpose: purposes[2],  trip: 'Kigali - Musanze (100km)',         status: RequestStatus.FULFILLED, daysBack: 4,  odomBefore: 18200, odomAfter: 18590 },
    { driverIdx: 6,  vehicleIdx: 6,  liters: 35,  purpose: purposes[8],  trip: 'Kigali - Bugesera (40km)',         status: RequestStatus.FULFILLED, daysBack: 7,  odomBefore: 22400, odomAfter: 22730 },
    { driverIdx: 7,  vehicleIdx: 7,  liters: 50,  purpose: purposes[11], trip: 'Kigali - Nyanza (110km)',          status: RequestStatus.FULFILLED, daysBack: 9,  odomBefore: 14600, odomAfter: 15010 },
    { driverIdx: 8,  vehicleIdx: 8,  liters: 30,  purpose: purposes[13], trip: 'Kigali - RIA (15km)',              status: RequestStatus.FULFILLED, daysBack: 3,  odomBefore: 38900, odomAfter: 39200 },
    { driverIdx: 10, vehicleIdx: 10, liters: 30,  purpose: purposes[12], trip: 'Kigali CBD circuit',               status: RequestStatus.FULFILLED, daysBack: 5,  odomBefore: 55200, odomAfter: 55620 },

    // FULFILLED — previous month
    { driverIdx: 0,  vehicleIdx: 0,  liters: 45,  purpose: purposes[14], trip: 'Southern Province road survey',   status: RequestStatus.FULFILLED, daysBack: 32, odomBefore: 44200, odomAfter: 44650 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 40,  purpose: purposes[3],  trip: 'Generator fuel — HQ',             status: RequestStatus.FULFILLED, daysBack: 35, odomBefore: 31100, odomAfter: 31420 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 60,  purpose: purposes[5],  trip: 'Rubavu warehouse delivery',       status: RequestStatus.FULFILLED, daysBack: 38, odomBefore: 60100, odomAfter: 60640 },
    { driverIdx: 5,  vehicleIdx: 5,  liters: 50,  purpose: purposes[0],  trip: 'Rwamagana inspection',            status: RequestStatus.FULFILLED, daysBack: 40, odomBefore: 17600, odomAfter: 18060 },

    // APPROVED — awaiting fulfillment
    { driverIdx: 0,  vehicleIdx: 0,  liters: 30,  purpose: purposes[2],  trip: 'Musanze staff transport',         status: RequestStatus.APPROVED,  daysBack: 1  },
    { driverIdx: 2,  vehicleIdx: 2,  liters: 25,  purpose: purposes[8],  trip: 'Bugesera site visit',             status: RequestStatus.APPROVED,  daysBack: 1  },
    { driverIdx: 6,  vehicleIdx: 6,  liters: 40,  purpose: purposes[5],  trip: 'Rubavu supply run',               status: RequestStatus.APPROVED,  daysBack: 2  },
    { driverIdx: 9,  vehicleIdx: 9,  liters: 50,  purpose: purposes[6],  trip: 'Nyagatare monthly supervision',  status: RequestStatus.APPROVED,  daysBack: 2  },
    { driverIdx: 11, vehicleIdx: 11, liters: 35,  purpose: purposes[1],  trip: 'Materials to construction site', status: RequestStatus.APPROVED,  daysBack: 1  },
    { driverIdx: 12, vehicleIdx: 12, liters: 40,  purpose: purposes[4],  trip: 'Huye coordination meeting',       status: RequestStatus.APPROVED,  daysBack: 3  },

    // PENDING — waiting for finance approval
    { driverIdx: 1,  vehicleIdx: 1,  liters: 20,  purpose: purposes[9],  trip: 'Kayonza office supplies',         status: RequestStatus.PENDING,   daysBack: 0  },
    { driverIdx: 4,  vehicleIdx: 4,  liters: 15,  purpose: purposes[7],  trip: 'Water pump maintenance',          status: RequestStatus.PENDING,   daysBack: 0  },
    { driverIdx: 5,  vehicleIdx: 5,  liters: 50,  purpose: purposes[0],  trip: 'Rwamagana district field work',  status: RequestStatus.PENDING,   daysBack: 0  },
    { driverIdx: 7,  vehicleIdx: 7,  liters: 40,  purpose: purposes[11], trip: 'Medical supplies to Nyanza',      status: RequestStatus.PENDING,   daysBack: 1  },
    { driverIdx: 8,  vehicleIdx: 8,  liters: 30,  purpose: purposes[13], trip: 'Airport delegation transfer',     status: RequestStatus.PENDING,   daysBack: 0  },
    { driverIdx: 10, vehicleIdx: 10, liters: 25,  purpose: purposes[12], trip: 'Executive transport KCC',         status: RequestStatus.PENDING,   daysBack: 1  },
    { driverIdx: 13, vehicleIdx: 13, liters: 45,  purpose: purposes[14], trip: 'Road assessment S. Province',     status: RequestStatus.PENDING,   daysBack: 0  },

    // REJECTED — with reasons
    { driverIdx: 3,  vehicleIdx: 3,  liters: 80,  purpose: purposes[5],  trip: 'Rubavu large delivery',          status: RequestStatus.REJECTED,  daysBack: 5,  rejReason: rejectionReasons[0] },
    { driverIdx: 4,  vehicleIdx: 4,  liters: 20,  purpose: purposes[1],  trip: 'Materials delivery',             status: RequestStatus.REJECTED,  daysBack: 7,  rejReason: rejectionReasons[4] },
    { driverIdx: 9,  vehicleIdx: 9,  liters: 60,  purpose: purposes[6],  trip: 'Nyagatare supervision',          status: RequestStatus.REJECTED,  daysBack: 12, rejReason: rejectionReasons[3] },
    { driverIdx: 2,  vehicleIdx: 2,  liters: 30,  purpose: purposes[3],  trip: 'Generator emergency',            status: RequestStatus.REJECTED,  daysBack: 15, rejReason: rejectionReasons[5] },
    { driverIdx: 11, vehicleIdx: 11, liters: 50,  purpose: purposes[10], trip: 'Gatuna border clearance',        status: RequestStatus.REJECTED,  daysBack: 20, rejReason: rejectionReasons[2] },
    { driverIdx: 13, vehicleIdx: 13, liters: 35,  purpose: purposes[2],  trip: 'Musanze staff trip',             status: RequestStatus.REJECTED,  daysBack: 25, rejReason: rejectionReasons[1] },

    // EDGE CASE: driver with fully depleted allocation still trying
    { driverIdx: 4,  vehicleIdx: 4,  liters: 10,  purpose: purposes[7],  trip: 'Urgent pump repair',             status: RequestStatus.PENDING,   daysBack: 0  },

    // EDGE CASE: old requests from 2 months ago
    { driverIdx: 0,  vehicleIdx: 0,  liters: 50,  purpose: purposes[0],  trip: 'Rwamagana – 2 months ago',       status: RequestStatus.FULFILLED, daysBack: 62, odomBefore: 43600, odomAfter: 44100 },
    { driverIdx: 1,  vehicleIdx: 1,  liters: 45,  purpose: purposes[4],  trip: 'Huye trip – 2 months ago',       status: RequestStatus.FULFILLED, daysBack: 65, odomBefore: 30500, odomAfter: 30950 },
    { driverIdx: 3,  vehicleIdx: 3,  liters: 60,  purpose: purposes[5],  trip: 'Rubavu – 2 months ago',          status: RequestStatus.FULFILLED, daysBack: 70, odomBefore: 59400, odomAfter: 59940 },
  ];

  // Delete in FK-safe order: children first
  await prisma.fuelReceipt.deleteMany({});
  await prisma.anomalyLog.deleteMany({});
  await prisma.fuelRequest.deleteMany({});

  const requests: any[] = [];

  for (const r of reqInputs) {
    const driver  = drivers[r.driverIdx];
    const vehicle = vehicles[r.vehicleIdx];
    const alloc   = findAlloc(r.driverIdx, r.vehicleIdx);

    const createdAt = daysAgo(r.daysBack);
    const isApproved  = r.status === RequestStatus.APPROVED || r.status === RequestStatus.FULFILLED;
    const isFulfilled = r.status === RequestStatus.FULFILLED;
    const isRejected  = r.status === RequestStatus.REJECTED;
    const approvedAt  = isApproved ? new Date(createdAt.getTime() + 3 * 60 * 60 * 1000) : null; // +3h
    const fulfilledAt = isFulfilled ? new Date(createdAt.getTime() + 8 * 60 * 60 * 1000) : null; // +8h

    const req = await prisma.fuelRequest.create({
      data: {
        driverId:         driver.id,
        vehicleId:        vehicle.id,
        allocationId:     alloc?.id ?? null,
        requestedLiters:  r.liters,
        requestedAmount:  r.liters * (vehicle.fuelType === FuelType.PETROL ? PETROL_PRICE : DIESEL_PRICE),
        purpose:          r.purpose,
        tripDescription:  r.trip,
        odometerBefore:   r.odomBefore ?? null,
        odometerAfter:    r.odomAfter ?? null,
        status:           r.status,
        approverId:       isApproved || isRejected ? approver.id : null,
        rejectionReason:  r.rejReason ?? null,
        approvedAt,
        fulfilledAt,
        createdAt,
        updatedAt: createdAt,
      },
    });

    requests.push(req);
  }

  console.log(`  ✅ Requests: ${requests.length} (fulfilled/approved/pending/rejected)`);

  // ── 9. RECEIPTS ────────────────────────────────────────────────────────────

  const fulfilledRequests = requests.filter(
    (r) => r.status === RequestStatus.FULFILLED,
  );

  const stations = [
    { name: 'Kobil Kigali CBD',    location: 'Kigali, CBD',         stationCode: 'KBL001' },
    { name: 'Total Energies Remera', location: 'Kigali, Remera',    stationCode: 'TTE002' },
    { name: 'Engen Nyabugogo',      location: 'Kigali, Nyabugogo',  stationCode: 'ENG003' },
    { name: 'Rubis Kimironko',      location: 'Kigali, Kimironko',  stationCode: 'RBS004' },
    { name: 'Total Huye',           location: 'Huye, Southern Prov', stationCode: 'TTE005' },
    { name: 'Kobil Musanze',        location: 'Musanze, Northern Prov', stationCode: 'KBL006' },
  ];

  for (let i = 0; i < fulfilledRequests.length; i++) {
    const req     = fulfilledRequests[i];
    const station = stations[i % stations.length];
    const liters  = req.requestedLiters;
    const fuelType = vehicles.find((v) => v.id === req.vehicleId)?.fuelType;
    const price   = fuelType === FuelType.PETROL ? PETROL_PRICE : DIESEL_PRICE;

    await prisma.fuelReceipt.create({
      data: {
        requestId:          req.id,
        stationName:        station.name,
        stationLocation:    station.location,
        litersDispensed:    liters,
        amountPaid:         liters * price,
        receiptDate:        req.fulfilledAt,
        imageUrl: `https://res.cloudinary.com/npd-fuel/image/upload/v1/npd/receipts/receipt_${req.id.slice(0, 8)}.jpg`,
        ocrConfidence:      0.85 + Math.random() * 0.12,
        verificationStatus: i % 5 === 0 ? VerificationStatus.FLAGGED : VerificationStatus.VERIFIED,
        verifiedAt:         new Date(),
        verifiedBy:         financeUsers[0].id,
        ocrRawData: {
          stationName:  station.name,
          liters,
          amount:       liters * price,
          stationCode:  station.stationCode,
        },
      },
    });
  }

  console.log(`  ✅ Receipts: ${fulfilledRequests.length} attached to fulfilled requests`);

  // ── 10. ANOMALY LOGS ───────────────────────────────────────────────────────

  const anomalyInputs = [
    {
      userId: drivers[3].id,
      requestId: requests.find((r) => r.driverId === drivers[3].id && r.status === RequestStatus.FULFILLED)?.id,
      type: AnomalyType.EXCESS_CONSUMPTION,
      severity: AnomalySeverity.HIGH,
      description: 'Fuel consumption of 12.5L/100km exceeds vehicle average of 9.0L/100km by 39%',
      status: AnomalyStatus.OPEN,
    },
    {
      userId: drivers[0].id,
      requestId: requests.find((r) => r.driverId === drivers[0].id && r.status === RequestStatus.FULFILLED)?.id,
      type: AnomalyType.ODOMETER_MISMATCH,
      severity: AnomalySeverity.MEDIUM,
      description: 'Odometer reading gap inconsistent with reported distance (reported 60km, odometer shows 310km)',
      status: AnomalyStatus.OPEN,
    },
    {
      userId: drivers[1].id,
      requestId: null,
      type: AnomalyType.FREQUENCY_ABUSE,
      severity: AnomalySeverity.MEDIUM,
      description: 'Driver submitted 4 fuel requests within 7 days — exceeds normal frequency threshold',
      status: AnomalyStatus.RESOLVED,
      resolvedAt: daysAgo(5),
      resolution: 'Verified with manager — driver was on extended field assignment. No abuse confirmed.',
    },
    {
      userId: drivers[4].id,
      requestId: null,
      type: AnomalyType.ALLOCATION_EXCEEDED,
      severity: AnomalySeverity.HIGH,
      description: 'Driver exhausted 160L allocation in 12 days (expected 30-day cycle)',
      status: AnomalyStatus.OPEN,
    },
    {
      userId: drivers[9].id,
      requestId: null,
      type: AnomalyType.FAKE_RECEIPT,
      severity: AnomalySeverity.HIGH,
      description: 'OCR confidence 42% — receipt image appears digitally altered. Station code not found in registry.',
      status: AnomalyStatus.DISMISSED,
      resolvedAt: daysAgo(10),
      resolution: 'Receipt re-submitted as original. Confirmed genuine by station manager call.',
    },
  ];

  for (const a of anomalyInputs) {
    await prisma.anomalyLog.create({
      data: {
        userId:      a.userId,
        requestId:   a.requestId ?? null,
        type:        a.type,
        severity:    a.severity,
        description: a.description,
        status:      a.status,
        resolvedAt:  (a as any).resolvedAt ?? null,
        resolvedBy:  (a as any).resolvedAt ? financeUsers[0].id : null,
        resolution:  (a as any).resolution ?? null,
        evidence:    { detectedAt: new Date().toISOString(), source: 'automated_checker' },
      },
    });
  }

  console.log(`  ✅ Anomalies: ${anomalyInputs.length} (open/resolved/dismissed)`);

  // ── 11. NOTIFICATIONS ──────────────────────────────────────────────────────

  const notifData = [
    { userId: financeUsers[0].id, title: 'New Fuel Request',      message: 'Mugisha Eric requested 20L for RAB 001 A',      type: 'FUEL_REQUEST_PENDING', isRead: false },
    { userId: financeUsers[0].id, title: 'New Fuel Request',      message: 'Hakizimana Emmanuel requested 15L for RAB 002 A', type: 'FUEL_REQUEST_PENDING', isRead: false },
    { userId: financeUsers[0].id, title: 'New Fuel Request',      message: 'Uwase Sarah requested 50L for RAB 003 A',       type: 'FUEL_REQUEST_PENDING', isRead: true  },
    { userId: financeUsers[0].id, title: 'High Severity Anomaly', message: 'Excess fuel consumption detected for driver Nsabimana François', type: 'ANOMALY_DETECTED', isRead: false },
    { userId: drivers[0].id,      title: 'Request Approved',      message: 'Your 30L request for RAB 001 A has been approved', type: 'REQUEST_APPROVED',       isRead: false },
    { userId: drivers[3].id,      title: 'Request Rejected',      message: 'Your 80L request was rejected: Allocation exhausted', type: 'REQUEST_REJECTED',    isRead: true  },
    { userId: drivers[1].id,      title: 'Request Approved',      message: 'Your 45L request for RAB 002 A has been approved', type: 'REQUEST_APPROVED',       isRead: true  },
    { userId: mgr1.id,            title: 'New Fuel Request',      message: 'Driver Mugisha Eric submitted a new fuel request',  type: 'FUEL_REQUEST_PENDING',   isRead: false },
    { userId: mgr2.id,            title: 'New Fuel Request',      message: 'Driver Nikuze Celestine submitted a new request',  type: 'FUEL_REQUEST_PENDING',   isRead: false },
    { userId: drivers[4].id,      title: 'Allocation Warning',    message: 'Your fuel allocation for this month is fully used',  type: 'ALLOCATION_DEPLETED',  isRead: false },
  ];

  await prisma.notification.deleteMany({});
  await Promise.all(
    notifData.map((n) =>
      prisma.notification.create({
        data: { ...n, createdAt: daysAgo(Math.floor(Math.random() * 3)) },
      }),
    ),
  );

  console.log(`  ✅ Notifications: ${notifData.length}`);

  // ── SUMMARY ────────────────────────────────────────────────────────────────

  console.log('\n═══════════════════════════════════════════════════');
  console.log('  SEED COMPLETE — Login credentials:');
  console.log('═══════════════════════════════════════════════════');
  console.log('  SUPER_ADMIN  admin@npd.rw        / Admin@1234');
  console.log('  FINANCE      finance@npd.rw       / Finance@1234');
  console.log('  FINANCE      finance2@npd.rw      / Finance@1234');
  console.log('  MANAGER      manager@npd.rw       / Manager@1234');
  console.log('  MANAGER      manager2@npd.rw      / Manager@1234');
  console.log('  MANAGER      manager3@npd.rw      / Manager@1234');
  console.log('  DRIVER       driver@npd.rw        / Driver@1234');
  console.log('  DRIVER       driver2@npd.rw  ...  / Driver@1234');
  console.log('  (driver3 through driver15 same pattern)');
  console.log('═══════════════════════════════════════════════════');
  console.log('\n  Edge cases included:');
  console.log('    • driver15@npd.rw — NO manager assigned');
  console.log('    • driver5@npd.rw  — allocation fully depleted');
  console.log('    • RAD 005 A       — vehicle with no assigned driver');
  console.log('    • 6 rejected requests with reasons');
  console.log('    • 5 anomaly logs (excess, odometer, frequency, allocation, fake receipt)');
  console.log('    • Receipts flagged by OCR verification\n');
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
