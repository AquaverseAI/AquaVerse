# Offline Sync & Outbox Architecture

## Overview
AquaVerse AI is designed for remote aquaculture farms with intermittent or zero cellular connectivity. All user actions (logging water parameters, updating pond settings, marking alerts read) are persisted immediately to local SQLite storage via **Drift**.

---

## 🏗 Outbox Queue Flow

```
[ User Input / Form ]
         │
         ▼
[ Local Drift SQLite ] ──▶ Write Domain Record (Status: Pending)
         │
         ├──▶ Enqueue Outbox Task (HTTP Method, Endpoint, Payload, RetryCount)
         │
         ▼
[ Connectivity Monitor ] ──▶ Connection Restored?
         │
         ├── Yes ──▶ [ Sync Worker ] ──▶ Dispatch HTTP Request via Dio
         │                │
         │                ├── Success (200 OK) ──▶ Mark Outbox Task Synced & Remove
         │                └── Failure (5xx / Timeout) ──▶ Increment RetryCount (Exponential Backoff)
         │
         └── No ───▶ Wait for Network Event
```

---

## 🗄 Drift Outbox Table Schema

```dart
class SyncOutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get httpMethod => text()(); // POST, PUT, DELETE
  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, processing, failed
}
```

---

## 🔄 Sync Engine Lifecycle & Rules
1. **Immediate Write**: User actions update local state instantly; zero UI blocking.
2. **Exponential Backoff**: Failed requests retry after `2^retryCount * 5` seconds up to a max of 5 attempts.
3. **Idempotency**: Each payload includes a unique UUID `client_mutation_id` to prevent duplicate server entries during network retries.
