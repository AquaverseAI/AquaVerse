import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

class MediaRepository {
  final ApiClient api;
  final Dio rawDio; // Raw Dio without auth header for PUT to pre-signed S3/GCS URL
  final AppDatabase db;
  static const _uuid = Uuid();

  MediaRepository({
    required this.api,
    required this.rawDio,
    required this.db,
  });

  /// Executes the full 2-phase upload protocol:
  /// 1. POST /v1/media/upload-url -> media_id + putUrl
  /// 2. PUT binary directly to putUrl
  /// 3. POST /v1/media/{media_id}/commit
  ///
  /// Offline safe: If network fails, persists in PendingMediaTable for background outbox sync.
  Future<String?> uploadMedia({
    required String filePath,
    String pondId = '00000000-0000-0000-0001-000000000001',
    String contentType = 'image/jpeg',
  }) async {
    final clientMediaId = _uuid.v4();
    final filename = path.basename(filePath);

    // Save in Drift
    await db.insertPendingMedia(PendingMediaTableCompanion(
      clientMediaId: Value(clientMediaId),
      localFilePath: Value(filePath),
      status: const Value('uploading'),
      createdAt: Value(DateTime.now()),
    ));

    try {
      // Phase 1: Request presigned upload URL
      final urlResponse = await api.getUploadUrl({
        'pond_id': pondId,
        'filename': filename,
        'mime_type': contentType,
      });

      final serverMediaId = urlResponse.mediaId;
      final putUrl = urlResponse.uploadUrl;

      await db.updatePendingMediaStatus(
        clientMediaId,
        'uploading',
        serverMediaId: serverMediaId,
        uploadUrl: putUrl,
      );

      // Phase 2: Binary PUT to storage URL (skipped for offline/standalone mode)
      if (!putUrl.startsWith('local://')) {
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await rawDio.put(
            putUrl,
            data: bytes,
            options: Options(
              headers: {
                'Content-Type': contentType,
              },
            ),
          );
        }
      }

      // Phase 3: Commit media
      await api.commitMedia(serverMediaId);

      await db.updatePendingMediaStatus(
        clientMediaId,
        'committed',
        serverMediaId: serverMediaId,
      );

      return serverMediaId;
    } catch (e) {
      // Offline fallback: keep in PendingMediaTable for background sync
      await db.updatePendingMediaStatus(clientMediaId, 'pending');
      return null;
    }
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  // Create a clean Dio instance for pre-signed direct PUT (must NOT include app Bearer token)
  final rawDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
  ));
  return MediaRepository(api: api, rawDio: rawDio, db: db);
});
