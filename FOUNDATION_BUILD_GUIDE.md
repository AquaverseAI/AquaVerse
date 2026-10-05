# AquaVerse Flutter Farmer App - Foundation Build Implementation Guide

## Status Summary

### ✅ COMPLETED (Phase 1-2)
- Backend API contract verified against current backend implementation
- Dio client with auth/error/logging interceptors created
- Comprehensive API models defined (User, Pond, Risk, Forecast, Ask, Alerts, etc.)
- Secure token storage implemented
- ApiClient interface complete with all 16+ endpoints
- Build runner passing (code generation successful)

### ⚠️ IN PROGRESS - COMPILATION FIXES NEEDED

**Current Issues** (28 analysis warnings):
1. Existing repositories reference old API signatures - **QUICK FIX**: Update method calls to match new positional parameters
2. PondRisk/PondEvent custom fromJson not generated - **FIX**: Add `@JsonSerializable()` to those classes or use factory constructors
3. Map<String, dynamic> responses need repository conversion - **STRATEGY**: Convert in repository layer, expose typed models to UI
4. Existing screens reference old model fields - **FIX**: Update screen references incrementally

**Quick Fix Actions** (in order):
```dart
// 1. lib/core/models/models.dart - Add @JsonSerializable to custom classes
@JsonSerializable(explicitToJson: true)
class PondRisk { ... }

// 2. Update getPonds() calls - was getPonds() now getPonds(null, null, null)
// in lib/core/repositories/pond_repository.dart line 19
final response = await _apiClient.getPonds(null, null, null);
List<Pond> ponds = [];
if (response['items'] is List) {
  ponds = (response['items'] as List)
      .map((e) => Pond.fromJson(e as Map<String, dynamic>))
      .toList();
}

// 3. Similar pattern for getLogs, getAlerts, getAdvisories
```

---

## RECOMMENDED PHASE 3 IMPLEMENTATION: Authentication Flow

### Architecture
```
OnboardingScreen
  ↓
PhoneEntryScreen → POST /v1/auth/otp/request
  ↓
OtpVerifyScreen → POST /v1/auth/otp/verify → store tokens securely
  ↓
RoleSelectionScreen (if needed)
  ↓
SplashScreen → GET /v1/auth/me → get current user, set active pond
  ↓
TodayScreen (farmer) or OfficerDashboard (officer)
```

### Required Files to Create

#### 1. `lib/core/errors/app_exception.dart`
Map all API errors to user-friendly messages:
```dart
abstract class AppException implements Exception {
  String get message;
  String? get detail;
  int? get errorCode;
}

class NetworkException extends AppException {
  final String message;
  NetworkException(this.message);
}

class AuthException extends AppException {
  final String message;
  final String? detail;
  AuthException(this.message, {this.detail});
}
```

#### 2. `lib/data/repositories/auth_repository.dart`
```dart
class AuthRepository {
  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<OtpRequestResponse> requestOtp(String phoneNumber) async {
    try {
      final response = await _apiClient.requestOtp({
        'mobile_number': phoneNumber,
      });
      return response;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<User> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _apiClient.verifyOtp({
        'mobile_number': phoneNumber,
        'otp_code': otpCode,
      });
      
      // Store tokens securely
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken ?? '',
        expiresInSeconds: response.expiresIn ?? 3600,
      );
      
      return response.user;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      return await _apiClient.getMe();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}
```

#### 3. `lib/core/providers/auth_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(apiClient: ApiClient(dio), tokenStorage: secureStorage);
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  try {
    return await ref.watch(authRepositoryProvider).getCurrentUser();
  } catch (e) {
    return null;
  }
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user != null;
});
```

---

## DATABASE SCHEMA (Phase 6 - Drift)

**Critical Tables Needed:**

```dart
// User (cached from /v1/auth/me)
class UserTable extends Table {
  TextColumn get id => text().primary()();
  TextColumn get name => text()();
  TextColumn get phone => text().unique()();
  TextColumn get role => text()();
  TextColumn get district => text().nullable()();
  TextColumn get preferredLanguage => text().withDefault(const Constant('ta'))();
  DateTimeColumn get syncedAt => dateTime()();
}

// Outbox (pending operations for sync)
class OutboxTable extends Table {
  TextColumn get id => text().primary()();
  TextColumn get clientLogId => text().unique()(); // Idempotency key
  TextColumn get entityType => text()(); // 'log', 'media_commit', 'feedback'
  TextColumn get payload => text()(); // JSON serialized request body
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending/syncing/synced/failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

// PendingMedia (two-phase upload tracking)
class PendingMediaTable extends Table {
  TextColumn get clientMediaId => text().primary()();
  TextColumn get mediaId => text().nullable(); // Set after upload-url call
  TextColumn get filePath => text()(); // Local file path
  TextColumn get uploadUrl => text().nullable(); // Presigned URL from backend
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending/uploading/committed/failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get committedAt => dateTime().nullable()();
  TextColumn get metadata => text().nullable(); // JSON {bucket, type, etc}
}

// LocalLogs (observations entered offline)
class LocalLogTable extends Table {
  TextColumn get clientLogId => text().primary()();
  TextColumn get pondId => text()(); // Foreign key to ponds
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get feedGivenKg => text().nullable(); // JSON {value, unit}
  TextColumn get mortalityCount => text().nullable();
  TextColumn get feedTray => text().nullable(); // Enum: empty/some/lots
  TextColumn get waterColor => text().nullable(); // Enum or enum value
  TextColumn get notes => text().nullable();
  TextColumn get mediaIds => text().nullable(); // JSON array of pending media IDs
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending/synced/failed
  DateTimeColumn get createdAt => dateTime()();
}
```

---

## OUTBOX SYNC PATTERN (Phase 7)

**Critical for offline-first + idempotency:**

```dart
class OutboxProcessor {
  final ApiClient _apiClient;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<void> syncOutbox() async {
    if (!await _connectivity.isOnline) {
      return;
    }

    final pending = await _db.outboxDao.getPendingItems();
    
    for (final item in pending) {
      try {
        await _db.outboxDao.updateStatus(item.id, 'syncing');
        
        switch (item.entityType) {
          case 'log':
            final payload = jsonDecode(item.payload) as Map<String, dynamic>;
            final response = await _apiClient.createLog(payload);
            // Backend uses client_log_id for idempotency
            
            // Mark synced ONLY after successful response
            await _db.outboxDao.markSynced(item.id);
            break;
            
          case 'media_commit':
            final mediaId = (jsonDecode(item.payload) as Map)['media_id'];
            await _apiClient.commitMedia(mediaId);
            await _db.outboxDao.markSynced(item.id);
            break;
            
          case 'feedback':
            // ... handle feedback
            break;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          // Validation error - mark failed
          await _db.outboxDao.markFailed(item.id, e.message ?? 'Validation error');
        } else if (e.response?.statusCode == 409) {
          // Conflict - item already exists (idempotency key matched)
          // Treat as success
          await _db.outboxDao.markSynced(item.id);
        } else {
          // Network error - keep pending for retry
          await _db.outboxDao.incrementRetryCount(item.id);
        }
      }
    }
  }
}
```

---

## LOG ENTRY FLOW (Phase 8 - Most Critical User Feature)

**Key Requirement: Under 45 seconds**

```dart
class LogSubmitNotifier extends StateNotifier<LogSubmitState> {
  Future<void> submitLog({
    required String pondId,
    required double feedGivenKg,
    required int mortalityCount,
    required String feedTray,
    required String waterColor,
  }) async {
    state = LogSubmitState.loading();
    
    final clientLogId = Uuid().v4(); // STABLE THROUGHOUT RETRIES
    final nowUtc = DateTime.now().toUtc();
    
    try {
      // 1. SAVE TO LOCAL DATABASE IMMEDIATELY
      final localLog = LocalLog(
        clientLogId: clientLogId,
        pondId: pondId,
        loggedAt: nowUtc,
        feedGivenKg: feedGivenKg,
        mortalityCount: mortalityCount,
        feedTray: feedTray,
        waterColor: waterColor,
        status: SyncStatus.pending,
        createdAt: nowUtc,
      );
      
      await _db.localLogDao.insert(localLog);
      
      // 2. CREATE OUTBOX ENTRY
      final outboxItem = OutboxItem(
        id: Uuid().v4(),
        clientLogId: clientLogId, // IDEMPOTENCY KEY
        entityType: 'log',
        payload: jsonEncode({
          'client_log_id': clientLogId,
          'pond_id': pondId,
          'feed_given_kg': feedGivenKg,
          'mortality_count': mortalityCount,
          'feed_tray': feedTray,
          'water_color': waterColor,
          'logged_at': nowUtc.toIso8601String(),
        }),
        status: 'pending',
        createdAt: nowUtc,
      );
      
      await _db.outboxDao.insert(outboxItem);
      
      // 3. ATTEMPT SYNC IF ONLINE
      if (await _connectivity.isOnline) {
        await _outboxProcessor.syncOutbox();
      }
      
      // 4. ALWAYS SHOW SUCCESS (it's stored locally)
      state = LogSubmitState.success(
        message: 'Observation logged successfully',
        clientLogId: clientLogId,
      );
      
    } catch (e) {
      state = LogSubmitState.error('Failed to save log');
    }
  }
}
```

---

## KEY ARCHITECTURAL DECISIONS

### 1. **Server Wins / Client Wins Strategy**
- **Server Wins**: risk, forecast, advisories, translated text
- **Client Wins**: farmer entered observations (feed, mortality, photos, notes)
- **Conflict Resolution**: If sync fails, keep local copy; retry when online

### 2. **Pagination Handling**
- Use keyset pagination (cursor-based) from backend
- Store cursor in SharedPreferences for resuming loads
- Don't load all records at once

### 3. **Token Refresh**
- Currently not implemented in backend
- Implement gracefully: on 401, request fresh token or force re-login
- Store access_token + refresh_token separately

### 4. **Offline State Management**
```dart
enum ConnectivityState { online, offline, transitioning }

final connectivityProvider = StreamProvider<ConnectivityState>((ref) {
  return Connectivity().onConnectivityChanged
      .map((result) => result.contains(ConnectivityResult.none) 
          ? ConnectivityState.offline 
          : ConnectivityState.online);
});
```

### 5. **Stale Data Display**
```dart
class CachedDataState<T> {
  final T data;
  final DateTime fetchedAt;
  final bool isStale; // > 30 minutes old
  
  bool get isExpired => DateTime.now().difference(fetchedAt).inMinutes > 30;
}
```

---

## TESTING STRATEGY

### 1. **Unit Tests** (Mock Dio, test repositories)
```bash
flutter test test/repositories/auth_repository_test.dart
```

### 2. **Integration Test** (Real backend)
```bash
flutter test integration_test/auth_flow_test.dart --target=integration_test/auth_flow_test.dart
```

### 3. **Offline Test** (MANDATORY)
```bash
# Disable network, create log, verify local save
# Enable network, verify sync
# Repeat 3x, verify no duplicates
```

---

## NEXT IMMEDIATE ACTIONS

1. **Fix compilation errors** (5-10 min)
   - Update repository method calls to new signatures
   - Add @JsonSerializable to PondRisk/PondEvent

2. **Implement AuthRepository** (30-45 min)
   - Phone → OTP request → Verify → Store tokens
   - Get current user, set in Riverpod

3. **Setup Drift database** (45-60 min)
   - Create tables.dart with OutboxTable, LocalLogTable, PendingMediaTable
   - Generate DAOs

4. **Implement OutboxProcessor** (30-45 min)
   - Sync pending operations on connectivity change
   - Handle idempotency (client_log_id)

5. **Create Today screen** (60 min)
   - Fetch risk + forecast
   - Display with stale indicators
   - Show blind/suppression states

6. **Create Log screen** (90 min)
   - Quick entry form (< 45 sec target)
   - Offline save to Drift
   - Outbox sync on network

---

## IMPORTANT: NON-NEGOTIABLE RULES

✋ **STOP** before implementing:
- ❌ Don't create UI animations yet
- ❌ Don't optimize rendering without profiling
- ❌ Don't add features beyond the 5 main screens
- ❌ Don't hardcode any credentials
- ❌ Don't deploy without offline test

✅ **DO**:
- Always test offline → online sync
- Verify client_log_id never changes on retry
- Check for backend idempotency conflicts (409)
- Display fetch time + stale indicators
- Handle all error states with user-friendly messages

---

## BACKEND ASSUMPTIONS

These must be verified:

1. **POST /v1/logs request body** - must include `client_log_id` 
2. **GET /v1/ponds/{pond_id}/forecast/do** - returns what format?
3. **POST /v1/alerts/{id}/feedback** - accepts what feedback enum values?
4. **POST /v1/ask** - context format and response structure
5. **Token expiration** - does JWT include exp claim?

If any of these don't match, update the backend contract documentation immediately.
