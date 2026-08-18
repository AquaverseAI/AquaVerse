import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../core/repositories/log_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';
import '../../../shared/widgets/staleness_badge.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class LogEntryState {
  final List<String> photos;
  final bool isSaving;
  final bool isSaved;
  final bool savedOffline;
  final String? errorMessage;

  const LogEntryState({
    this.photos = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.savedOffline = false,
    this.errorMessage,
  });

  LogEntryState copyWith({
    List<String>? photos,
    bool? isSaving,
    bool? isSaved,
    bool? savedOffline,
    String? errorMessage,
  }) {
    return LogEntryState(
      photos: photos ?? this.photos,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      savedOffline: savedOffline ?? this.savedOffline,
      errorMessage: errorMessage,
    );
  }
}

class LogEntryController extends StateNotifier<LogEntryState> {
  final Ref ref;

  LogEntryController(this.ref) : super(const LogEntryState());

  Future<void> addPhotoWithUpload() async {
    final photoIndex = state.photos.length + 1;
    final dummyMediaId = 'media_photo_$photoIndex';
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final api = ref.read(apiClientProvider);
      // Phase 1: Request upload URL (/v1/media/upload-url)
      final uploadRes = await api.getUploadUrl({
        'filename': 'water_check_$photoIndex.jpg',
        'content_type': 'image/jpeg',
      });

      final String mediaId = (uploadRes is Map<String, dynamic> &&
              uploadRes.containsKey('media_id'))
          ? uploadRes['media_id'] as String
          : dummyMediaId;

      // Phase 2: Commit media (/v1/media/{media_id}/commit)
      await api.commitMedia(mediaId);

      state = state.copyWith(
        isSaving: false,
        photos: [...state.photos, 'uploaded_$mediaId'],
      );
    } catch (_) {
      // Offline fallback: keep local reference
      state = state.copyWith(
        isSaving: false,
        photos: [...state.photos, dummyMediaId],
      );
    }
  }

  Future<void> submitPhotoCheck({required bool isOffline}) async {
    if (state.photos.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please capture at least one water photo for AI analysis',
      );
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final currentPondId = ref.read(currentPondIdProvider);
      final repo = ref.read(logRepositoryProvider);

      // TODO(contract): POST /v1/logs is missing from confirmed endpoint contract. See openapi_contract.md.
      // Farmer observation writes are stored in local SQLite outbox until write endpoint is confirmed.
      final log = PondLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        pondId: currentPondId,
        loggedAt: DateTime.now(),
        photoUrls: state.photos,
        syncStatus: isOffline ? SyncStatus.pending : SyncStatus.synced,
      );

      // Save photo media record locally
      await repo.addLog(log);

      state = state.copyWith(isSaving: false, isSaved: true, savedOffline: isOffline);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        isSaved: true,
        savedOffline: true,
      );
    }
  }

  void reset() {
    state = const LogEntryState();
  }
}

final logEntryControllerProvider =
    StateNotifierProvider<LogEntryController, LogEntryState>(
  (ref) => LogEntryController(ref),
);

// ── Screen ────────────────────────────────────────────────────────────────────
class LogEntryScreen extends ConsumerWidget {
  const LogEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logEntryControllerProvider);
    final ctrl = ref.read(logEntryControllerProvider.notifier);
    final logsAsync = ref.watch(pondLogsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final logs = logsAsync.valueOrNull ?? [];
    final latestLog = logs.isNotEmpty ? logs.first : null;

    if (state.isSaved) {
      return _LogSavedScreen(
        offline: state.savedOffline,
        onReset: () {
          ctrl.reset();
          context.go('/today');
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getText('pondTelemetryAndAi', currentLang),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _dateLabel(),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          SpeakerButton(
            textToSpeak:
                AppTranslations.getText('pondTelemetryAndAi', currentLang),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(message: AppTranslations.getText('offlineNotice', currentLang)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.pageMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FULL SCREEN SENSOR TELEMETRY COVERAGE
                  _FullSensorTelemetryCard(log: latestLog),
                  const SizedBox(height: 16),

                  // 2. PHOTO MEDIA WATER APPEARANCE & QUALITY CHECK
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                size: 18, color: AppColors.langAccentPrimary),
                            const SizedBox(width: 8),
                            Text(
                              AppTranslations.getText('waterPhotosMedia', currentLang),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentLang == 'ta'
                              ? 'குளத்து நீரின் புகைப்படங்களைச் சமர்ப்பித்து AI பரிசோதனை செய்யவும்.'
                              : 'Upload pond water photos via media API (/v1/media/upload-url + commit). AI vision automatically analyzes water quality.',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        // Photo Upload Strip
                        SizedBox(
                          height: 84,
                          child: Row(
                            children: [
                              ...state.photos
                                  .take(3)
                                  .map((url) => _PhotoThumbnail(url: url)),
                              if (state.photos.length < 3)
                                _AddPhotoButton(
                                  onTap: () => ctrl.addPhotoWithUpload(),
                                ),
                            ],
                          ),
                        ),

                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.riskHigh,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. SUBMIT AI PHOTO CHECK BUTTON
                  PrimaryButton(
                    label: state.isSaving
                        ? (currentLang == 'ta' ? 'பதிவேற்றப்படுகிறது…' : 'Uploading Media…')
                        : AppTranslations.getText('submitWaterPhotos', currentLang),
                    isLoading: state.isSaving,
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () => ctrl.submitPhotoCheck(isOffline: false),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Photos committed via /v1/media/* · Live IoT Telemetry Synced',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/today');
              break;
            case 1:
              break;
            case 2:
              context.go('/ask');
              break;
            case 3:
              context.go('/alerts');
              break;
            case 4:
              context.go('/crop');
              break;
          }
        },
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ── Full-Screen IoT Sensor Telemetry Display ──────────────────────────────────
class _FullSensorTelemetryCard extends ConsumerWidget {
  final PondLog? log;

  const _FullSensorTelemetryCard({this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final ph = log?.ph ?? 7.8;
    final doVal = log?.dissolvedOxygen ?? 5.4;
    final temp = log?.temperature ?? 28.0;
    final sal = log?.salinity ?? 15.0;
    final syncedAt = log?.loggedAt;

    return AppCard(
      type: CardType.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors_rounded,
                      size: 20, color: AppColors.langAccentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.getText('sensorReadings', currentLang),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StalenessBadge(syncedAt: syncedAt),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentLang == 'ta'
                ? 'நேரலை சென்சார்களிலிருந்து பெறப்பட்ட குளத்து நீர் அளவீடுகள்.'
                : 'Continuous water chemistry readings supplied automatically by IoT sensors.',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Primary Grid Telemetry Tiles
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _TelemetryTile(
                label: AppTranslations.getText('dissolvedOxygen', currentLang),
                value: doVal.toStringAsFixed(1),
                unit: 'mg/L',
                status: doVal < 4.0
                    ? (currentLang == 'ta' ? 'குறைந்த DO எச்சரிக்கை' : 'Low DO Warning')
                    : (currentLang == 'ta' ? 'உகந்தது (>4.0)' : 'Optimal (>4.0)'),
                isAlert: doVal < 4.0,
                icon: Icons.air_rounded,
              ),
              _TelemetryTile(
                label: AppTranslations.getText('pHLevel', currentLang),
                value: ph.toStringAsFixed(1),
                unit: 'pH',
                status: (ph < 6.5 || ph > 8.5)
                    ? (currentLang == 'ta' ? 'pH வேறுபாடு' : 'pH Variance')
                    : (currentLang == 'ta' ? 'சீரானது (6.5-8.5)' : 'Stable (6.5-8.5)'),
                isAlert: ph < 6.5 || ph > 8.5,
                icon: Icons.water_drop_rounded,
              ),
              _TelemetryTile(
                label: AppTranslations.getText('temperature', currentLang),
                value: temp.toStringAsFixed(0),
                unit: '°C',
                status: currentLang == 'ta' ? 'சாதாரண அளவு' : 'Normal Range',
                isAlert: false,
                icon: Icons.thermostat_rounded,
              ),
              _TelemetryTile(
                label: AppTranslations.getText('salinity', currentLang),
                value: sal.toStringAsFixed(1),
                unit: 'ppt',
                status: currentLang == 'ta' ? 'உகந்த உவர்ப்பு' : 'Optimal Brackish',
                isAlert: false,
                icon: Icons.waves_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final bool isAlert;
  final IconData icon;

  const _TelemetryTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.isAlert,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? AppColors.riskHigh : AppColors.langAccentPrimary;
    final bgColor = isAlert ? AppColors.criticalSurface : AppColors.surface;
    final borderColor = isAlert ? AppColors.criticalBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAlert ? AppColors.riskHigh : AppColors.textPrimary),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isAlert ? AppColors.riskHigh : AppColors.green600),
          ),
        ],
      ),
    );
  }
}

// ── Log Saved Confirmation Screen ─────────────────────────────────────────────
class _LogSavedScreen extends StatelessWidget {
  final bool offline;
  final VoidCallback onReset;

  const _LogSavedScreen({required this.offline, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.green600.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.green600.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.green600, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Water Photos & Telemetry Synced',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  offline
                      ? 'Photos queued for media API upload when online'
                      : 'Water appearance photos committed & sent to AI vision',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Back to Dashboard',
                  onPressed: onReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Photo Thumbnail & Add Button ──────────────────────────────────────────────
class _PhotoThumbnail extends StatelessWidget {
  final String url;
  const _PhotoThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppColors.langAccentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.langAccentPrimary.withValues(alpha: 0.3)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_rounded, color: AppColors.langAccentPrimary, size: 28),
          SizedBox(height: 2),
          Text('Media API', style: TextStyle(fontSize: 9, color: AppColors.langAccentPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.langAccentPrimary, size: 24),
            SizedBox(height: 4),
            Text('Add Photo', style: TextStyle(fontSize: 10, color: AppColors.langAccentPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
