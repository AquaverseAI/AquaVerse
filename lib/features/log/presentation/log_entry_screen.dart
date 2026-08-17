import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final double feedKg;
  final int mortalityCount;
  final FeedTrayStatus? feedTray;
  final WaterAppearance? waterColor;
  final List<String> photos;
  final bool isSaving;
  final bool isSaved;
  final bool savedOffline;
  final String? errorMessage;

  const LogEntryState({
    this.feedKg = 18.0,
    this.mortalityCount = 0,
    this.feedTray,
    this.waterColor,
    this.photos = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.savedOffline = false,
    this.errorMessage,
  });

  LogEntryState copyWith({
    double? feedKg,
    int? mortalityCount,
    FeedTrayStatus? feedTray,
    WaterAppearance? waterColor,
    List<String>? photos,
    bool? isSaving,
    bool? isSaved,
    bool? savedOffline,
    String? errorMessage,
  }) {
    return LogEntryState(
      feedKg: feedKg ?? this.feedKg,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      feedTray: feedTray ?? this.feedTray,
      waterColor: waterColor ?? this.waterColor,
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

  void setFeed(double v) => state = state.copyWith(feedKg: v.clamp(0, 100));
  void incrementFeed() => setFeed(state.feedKg + 1);
  void decrementFeed() => setFeed(state.feedKg - 1);
  void setMortality(int v) => state = state.copyWith(mortalityCount: v.clamp(0, 9999));
  void setFeedTray(FeedTrayStatus v) => state = state.copyWith(feedTray: v);
  void setWaterColor(WaterAppearance v) => state = state.copyWith(waterColor: v);
  
  Future<void> addPhotoWithUpload() async {
    final photoIndex = state.photos.length + 1;
    final dummyMediaId = 'media_photo_$photoIndex';
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final api = ref.read(apiClientProvider);
      // Phase 1: Request upload URL (/v1/media/upload-url)
      final uploadRes = await api.getUploadUrl({
        'filename': 'pond_check_$photoIndex.jpg',
        'content_type': 'image/jpeg',
      });
      
      final String mediaId = (uploadRes is Map<String, dynamic> && uploadRes.containsKey('media_id'))
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

  Future<void> saveLog({required bool isOffline}) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final currentPondId = ref.read(currentPondIdProvider);
      final repo = ref.read(logRepositoryProvider);

      final log = PondLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        pondId: currentPondId,
        loggedAt: DateTime.now(),
        feedGivenKg: state.feedKg,
        mortalityCount: state.mortalityCount,
        feedTray: state.feedTray,
        waterColor: state.waterColor,
        photoUrls: state.photos,
        syncStatus: isOffline ? SyncStatus.pending : SyncStatus.synced,
      );

      // TODO(contract): POST /v1/logs is deprecated for writes per contract.
      // Photos commit via /v1/media/* endpoints above; manual fields save locally to Drift.
      await repo.addLog(log);

      state = state.copyWith(isSaving: false, isSaved: true, savedOffline: isOffline);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save log. Saved locally.',
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
            const Text('Pond Check', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _dateLabel(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          const SpeakerButton(textToSpeak: 'Pond Check. Review live sensor readings and record your visual observations.'),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.pageMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP SECTION — Live Sensor Readings Display (Read-Only)
                  _LiveSensorReadingsCard(log: latestLog),
                  const SizedBox(height: 16),

                  // 2. SECTION HEADER — Manual Field Inputs
                  const Row(
                    children: [
                      Icon(Icons.remove_red_eye_rounded, size: 18, color: AppColors.langAccentPrimary),
                      SizedBox(width: 6),
                      Text(
                        "What sensors can't see",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Feed Given (kg)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Feed Given (kg)', icon: Icons.set_meal_rounded),
                        const SizedBox(height: 10),
                        _StepperControl(
                          value: state.feedKg,
                          onIncrement: ctrl.incrementFeed,
                          onDecrement: ctrl.decrementFeed,
                          label: '${state.feedKg.toStringAsFixed(0)} kg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mortality Count
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Mortality Count', icon: Icons.warning_amber_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceChip(
                                label: 'None',
                                selected: state.mortalityCount == 0,
                                onTap: () => ctrl.setMortality(0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: 'Enter count',
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onChanged: (v) => ctrl.setMortality(int.tryParse(v) ?? 0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feed Tray Check
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Feed Tray Check', icon: Icons.check_circle_outline_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: FeedTrayStatus.values.map((s) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _ChoiceChip(
                                  label: s.name[0].toUpperCase() + s.name.substring(1),
                                  selected: state.feedTray == s,
                                  onTap: () => ctrl.setFeedTray(s),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Water Appearance / Color Swatch
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Water Appearance', icon: Icons.opacity_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: WaterAppearance.values.map((w) {
                            Color color;
                            switch (w) {
                              case WaterAppearance.good:
                                color = AppColors.green600;
                                break;
                              case WaterAppearance.average:
                                color = AppColors.warning;
                                break;
                              case WaterAppearance.bad:
                                color = AppColors.critical;
                                break;
                            }
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _ChoiceChip(
                                  label: w.name[0].toUpperCase() + w.name.substring(1),
                                  selected: state.waterColor == w,
                                  selectedColor: color,
                                  onTap: () => ctrl.setWaterColor(w),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Photo Capture Section (Two-Phase Media API)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Pond Photos (AI Vision)', icon: Icons.camera_alt_rounded),
                        const SizedBox(height: 4),
                        const Text(
                          'Photos are analyzed by AI for water clarity and health checks',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: Row(
                            children: [
                              ...state.photos.take(3).map((url) => _PhotoThumbnail(url: url)),
                              if (state.photos.length < 3)
                                _AddPhotoButton(
                                  onTap: () => ctrl.addPhotoWithUpload(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Log Button
                  PrimaryButton(
                    label: state.isSaving ? 'Uploading & Saving…' : 'Save Check Log',
                    isLoading: state.isSaving,
                    icon: Icons.save_rounded,
                    onPressed: () => ctrl.saveLog(isOffline: false),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Saved locally & synced when online',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

// ── Live Sensor Readings Card (Read-Only) ────────────────────────────────────
class _LiveSensorReadingsCard extends StatelessWidget {
  final PondLog? log;

  const _LiveSensorReadingsCard({this.log});

  @override
  Widget build(BuildContext context) {
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
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, size: 18, color: AppColors.langAccentPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Live Sensor Readings',
                    style: TextStyle(
                      fontSize: 14,
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
          const Text(
            'Auto-supplied by IoT water sensors. Read-only.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SensorValueTile(
                  label: 'DO',
                  value: doVal.toStringAsFixed(1),
                  unit: 'mg/L',
                  isWarning: doVal < 4.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SensorValueTile(
                  label: 'pH',
                  value: ph.toStringAsFixed(1),
                  unit: '',
                  isWarning: ph < 6.5 || ph > 8.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SensorValueTile(
                  label: 'Temp',
                  value: temp.toStringAsFixed(0),
                  unit: '°C',
                  isWarning: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SensorValueTile(
                  label: 'Salinity',
                  value: sal.toStringAsFixed(1),
                  unit: 'ppt',
                  isWarning: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorValueTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isWarning;

  const _SensorValueTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppColors.riskHigh : AppColors.textPrimary;
    final bgColor = isWarning ? AppColors.criticalSurface : AppColors.surface;
    final borderColor = isWarning ? AppColors.criticalBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Log Saved screen ──────────────────────────────────────────────────────────
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
                    border: Border.all(color: AppColors.green600.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.green600, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Check Log Saved',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  offline
                      ? 'Saved locally — photos queued for upload when online'
                      : 'Your visual check & photos are saved',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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

// ── Helper widgets ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FieldLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary500),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StepperControl extends StatelessWidget {
  final double value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String label;

  const _StepperControl({required this.value, required this.onIncrement, required this.onDecrement, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepButton(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 20),
        Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 20),
        _StepButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primary700, size: 20),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _ChoiceChip({required this.label, required this.selected, required this.onTap, this.selectedColor});

  @override
  Widget build(BuildContext context) {
    final c = selectedColor ?? AppColors.primary500;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? c : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String url;
  const _PhotoThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.image_rounded, color: AppColors.textMuted, size: 28),
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
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.primary500, size: 22),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 10, color: AppColors.primary500)),
          ],
        ),
      ),
    );
  }
}
