# Pickup QR: backend integration pending

The backend source is not present in the inspected UniPrint checkout. The mobile changes do not implement server token issuance, expiry enforcement, or shelf release.

## Required response

GET /api/printorders/my-orders must return qrToken and qrExpiresAt (ISO 8601 with UTC offset) for eligible orders. The client only displays QR for status 5 (ReadyForPickup), a nonempty token, and a future deadline. Missing expiry fails closed. The field name qrExpiresAt is proposed and must be aligned with the actual backend DTO.

## EC04

Confirm the expiry starting event against the full EC04 specification. Proposed behavior: issue an unpredictable token when an order becomes eligible for pickup with an assigned shelf slot, and set expiry to issuance plus seven days. Reopening the mobile screen must not extend expiry. Expiry must be enforced by the server clock; the mobile clock only controls display.

## Existing pickup endpoint

POST /api/printorders/scan-pickup-qr?qrToken=... with Bearer authentication. Validate staff authorization, token, expiry, unused state, order readiness, and assigned slot. Atomically consume the token, mark order Completed (6), and release only the slot assigned to this order. Roll back all writes on failure. Concurrent scans must not complete twice. Return the completed order after commit. Prevent generic status update APIs from bypassing this operation.

Use distinguishable errors for forbidden, invalid token, expired token, already collected, and invalid order state. Do not log pickup tokens. Shelf release is not claimed in the mobile success message because its server implementation is unverified.

## Integration acceptance

- Valid pickup commits Completed, token consumption, and shelf release together.
- Before expiry succeeds; at or after expiry fails without mutations.
- Student callers, invalid tokens, cancelled orders, and repeat scans fail without mutations.
- Concurrent scans have one successful transition; a mid-transaction failure leaves all state unchanged.
- Verify camera permissions and denial recovery on physical Android/iOS devices.
