# Database Entity Model

## USER
| Field        | Type     | Notes |
|--------------|----------|-------|
| id           | UUID PK  | |
| fullName     | String   | |
| email        | String   | unique |
| phone        | String?  | |
| passwordHash | String   | bcrypt |
| role         | Enum     | SUPER_ADMIN, MANAGER, DRIVER, FINANCE |
| department   | String?  | |
| isActive     | Boolean  | default true |
| managerId    | UUID FK  | self-reference to USER |

## VEHICLE
| Field            | Type    | Notes |
|------------------|---------|-------|
| id               | UUID PK | |
| plateNumber      | String  | unique |
| make             | String  | |
| model            | String  | |
| year             | Int     | |
| fuelType         | Enum    | PETROL, DIESEL |
| tankCapacity     | Float   | liters |
| averageKmPerL    | Float?  | baseline for anomaly detection |
| assignedDriverId | UUID FK | to USER |

## FUEL_ALLOCATION
| Field           | Type    | Notes |
|-----------------|---------|-------|
| id              | UUID    | |
| userId          | UUID FK | to USER |
| vehicleId       | UUID FK | to VEHICLE |
| month           | Int     | 1-12 |
| year            | Int     | |
| allocatedLiters | Float   | |
| allocatedAmount | Float   | RWF |
| usedLiters      | Float   | default 0 |
| remainingLiters | Float   | |
| UNIQUE          |         | (userId, vehicleId, month, year) |

## FUEL_REQUEST
| Field            | Type      | Notes |
|------------------|-----------|-------|
| id               | UUID PK   | |
| driverId         | UUID FK   | to USER |
| vehicleId        | UUID FK   | to VEHICLE |
| allocationId     | UUID FK?  | to FUEL_ALLOCATION |
| requestedLiters  | Float     | |
| requestedAmount  | Float     | RWF |
| purpose          | String    | |
| tripDescription  | String?   | |
| odometerBefore   | Float?    | |
| odometerAfter    | Float?    | |
| odometerImageUrl | String?   | Cloudinary URL |
| status           | Enum      | PENDING, APPROVED, REJECTED, FULFILLED, CANCELLED |
| approverId       | UUID FK?  | to USER |
| rejectionReason  | String?   | |
| approvedAt       | DateTime? | |
| fulfilledAt      | DateTime? | |

## FUEL_RECEIPT
| Field              | Type           | Notes |
|--------------------|----------------|-------|
| id                 | UUID PK        | |
| requestId          | UUID FK UNIQUE | to FUEL_REQUEST |
| stationName        | String?        | from OCR |
| stationLocation    | String?        | |
| litersDispensed    | Float?         | from OCR |
| amountPaid         | Float?         | RWF, from OCR |
| receiptDate        | DateTime?      | |
| imageUrl           | String         | Cloudinary URL |
| ocrRawData         | JSON?          | raw OCR output |
| ocrConfidence      | Float?         | 0.0 to 1.0 |
| verificationStatus | Enum           | PENDING, VERIFIED, FLAGGED |

## ANOMALY_LOG
| Field       | Type      | Notes |
|-------------|-----------|-------|
| id          | UUID      | |
| userId      | UUID FK   | to USER |
| requestId   | UUID FK   | to FUEL_REQUEST |
| type        | Enum      | EXCESS_CONSUMPTION, FAKE_RECEIPT, ODOMETER_MISMATCH, FREQUENCY_ABUSE, ALLOCATION_EXCEEDED |
| severity    | Enum      | LOW, MEDIUM, HIGH |
| description | String    | |
| evidence    | JSON?     | supporting data |
| status      | Enum      | OPEN, RESOLVED, DISMISSED |
| resolvedAt  | DateTime? | |
| resolvedBy  | String?   | |
| resolution  | String?   | |

## NOTIFICATION
| Field    | Type    | Notes |
|----------|---------|-------|
| id       | UUID    | |
| userId   | UUID FK | to USER |
| title    | String  | |
| message  | String  | |
| type     | String  | REQUEST_APPROVED, ANOMALY_HIGH, etc. |
| isRead   | Boolean | default false |
| metadata | JSON?   | link to relevant entity |

## REFRESH_TOKEN
| Field     | Type     | Notes |
|-----------|----------|-------|
| id        | UUID     | |
| token     | String   | unique UUID |
| userId    | UUID FK  | to USER |
| expiresAt | DateTime | 7 days from creation |
