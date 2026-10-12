# Task 16 & 17 — Pickup QR

## Implementation

Backend: ../UniPrint-Backend. Preserve API -> Business service -> UnitOfWork/repositories -> EF Core. Mobile preserves views -> providers -> services -> ApiClient.

The backend FEATURES_AND_USE_CASES sequence creates PickupQR with Payment when the order is created. Each token expires seven days after issuance. Reopening the mobile screen does not change expiry. EC04 rejects expired pickup while preserving ReadyForPickup and the shelf occupancy.

GET /api/printorders/my-orders returns qrToken and qrExpiresAt (UTC ISO 8601) in each order. The mobile displays QR only for ReadyForPickup with a nonempty token and future expiry. Missing expiry fails closed.

POST /api/printorders/scan-pickup-qr?qrToken=... requires Staff/Admin JWT. Success now returns ApiResponse<PrintOrderResponseDto> with status Completed, replacing the previous boolean payload. Existing Razor Pages only read Success/Message and remain compatible.

Business checks active staff/admin, token, unused state, expiry, ReadyForPickup, and a shelf with positive occupancy. One EF SaveChanges transaction consumes QR, completes the order and decrements occupancy. Existing IsUsed, Status and CurrentCount columns are concurrency tokens: stale writes roll back rather than decrementing twice. No new database columns are required.

Razor pickup now requires authenticated Staff/Admin and uses the authenticated user ID rather than a hardcoded demo account. Student order detail access is restricted to the student's own orders.

## Verification

Backend tests use SQLite for relational transaction rollback and stale updates, alongside the existing tests. Mobile tests cover expiry boundaries, invalid statuses, missing expiry, offline refresh and completed refresh. Build and automated tests do not replace device camera and deployment SQL Server verification.

Run backend tests: dotnet test UniPrint.Tests/UniPrint.Tests.csproj
Run mobile checks: dart analyze; flutter test --no-pub

## Run together

Start configured SQL Server, then run dotnet run --project UniPrint.API --launch-profile http in the backend. API launchSettings uses port 5045. Start mobile with API_BASE_URL pointing to that API (Windows localhost; Android emulator 10.0.2.2; physical phone the server LAN IP). Seed student/staff: student@uniprint.edu.vn / staff@uniprint.edu.vn, password 123456.

Pickup requires a shelf assigned through the existing assign-shelf operation. Shelf administration remains the existing group feature. Expired QR reissue is outside tasks 16/17; EC04 leaves the order waiting for reissue.