# NPD Fuel API Specification

Base URL: /api/v1
Auth: Bearer JWT in Authorization header

---

## AUTH
POST   /auth/login           { email, password } -> { accessToken, refreshToken, user }
POST   /auth/refresh         { refreshToken } -> { accessToken }
POST   /auth/logout          { refreshToken } -> { message }

## USERS
GET    /users                ?role= -> User[]           [ADMIN, MANAGER]
POST   /users                CreateUserDto -> User       [ADMIN]
GET    /users/:id            -> User                    [authenticated]
PATCH  /users/:id            UpdateUserDto -> User       [ADMIN]
DELETE /users/:id            -> { isActive: false }     [ADMIN]

## VEHICLES
GET    /vehicles             -> Vehicle[]               [authenticated]
POST   /vehicles             CreateVehicleDto -> Vehicle [ADMIN]
GET    /vehicles/:id         -> Vehicle                 [authenticated]
PATCH  /vehicles/:id         -> Vehicle                 [ADMIN]
PATCH  /vehicles/:id/assign/:driverId -> Vehicle        [ADMIN]

## ALLOCATIONS
GET    /allocations          ?month= &year= -> Allocation[]   [ADMIN, MANAGER, FINANCE]
POST   /allocations          CreateAllocationDto -> Allocation [ADMIN, MANAGER]
GET    /allocations/current/me -> Allocation                  [DRIVER]
GET    /allocations/current/:userId -> Allocation             [ADMIN, MANAGER]

## FUEL REQUESTS
GET    /requests             ?status= &driverId= &page= &limit= -> paginated
POST   /requests             CreateRequestDto -> FuelRequest   [DRIVER]
GET    /requests/:id         -> FuelRequest                    [authenticated]
PATCH  /requests/:id/approve -> FuelRequest                    [MANAGER, ADMIN]
PATCH  /requests/:id/reject  { reason } -> FuelRequest         [MANAGER, ADMIN]
PATCH  /requests/:id/fulfill { odometerAfter } -> FuelRequest  [MANAGER, ADMIN]

## RECEIPTS
POST   /receipts/:requestId/upload  multipart image -> FuelReceipt [authenticated]
GET    /receipts/:requestId         -> FuelReceipt                 [authenticated]

## ANOMALIES
GET    /anomalies            ?status= &userId= -> AnomalyLog[]     [MANAGER, ADMIN]
PATCH  /anomalies/:id/resolve { resolution } -> AnomalyLog        [MANAGER, ADMIN]

## NOTIFICATIONS
GET    /notifications        ?unread=true -> Notification[]        [authenticated]
GET    /notifications/unread-count -> { count }                    [authenticated]
PATCH  /notifications/:id/read -> updated                         [authenticated]
PATCH  /notifications/read-all -> updated                         [authenticated]

---

## Standard Response Format

Success:
{
  "success": true,
  "data": <payload>,
  "timestamp": "2025-01-01T00:00:00.000Z"
}

Error:
{
  "success": false,
  "statusCode": 401,
  "message": "Invalid credentials",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "path": "/api/v1/auth/login"
}

Paginated:
{
  "success": true,
  "data": {
    "data": [],
    "total": 0,
    "page": 1,
    "limit": 10
  }
}

---

## Request DTOs

### CreateUserDto
{
  fullName: string,
  email: string,
  password: string (min 8 chars),
  role: SUPER_ADMIN | MANAGER | DRIVER | FINANCE,
  department?: string,
  phone?: string,
  managerId?: string
}

### CreateVehicleDto
{
  plateNumber: string,
  make: string,
  model: string,
  year: number,
  fuelType: PETROL | DIESEL,
  tankCapacity: number,
  averageKmPerL?: number,
  assignedDriverId?: string
}

### CreateAllocationDto
{
  userId: string,
  vehicleId: string,
  month: number (1-12),
  year: number,
  allocatedLiters: number,
  allocatedAmount: number
}

### CreateRequestDto
{
  vehicleId: string,
  requestedLiters: number,
  requestedAmount: number,
  purpose: string,
  tripDescription?: string,
  odometerBefore?: number,
  odometerImageUrl?: string
}
