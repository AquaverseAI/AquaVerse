import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../core/repositories/log_repository.dart';
import '../../../core/sync/outbox_processor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class LogEntryFormState {
  final double feedGivenKg;
  final int mortalityCount;
  final FeedTrayStatus? feedTray;
  final WaterAppearance? waterColor;
  final double? ph;
  final double? dissolvedOxygen;
  final double? temperature;
  final double? salinity;
  final List<String> photos;
  final String notes;
  final bool showAdvanced;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const LogEntryFormState({
    this.feedGivenKg = 20.0,
    this.mortalityCount = 0,
    this.feedTray = FeedTrayStatus.empty,
    this.waterColor = WaterAppearance.good,
    this.ph,
    this.dissolvedOxygen,
    this.temperature,
    this.salinity,
    this.photos = const [],
    this.notes = '',
    this.showAdvanced = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  LogEntryFormState copyWith({
    double? feedGivenKg,
    int? mortalityCount,
    FeedTrayStatus? feedTray,
    WaterAppearance? waterColor,
    double? ph,
    double? dissolvedOxygen,
    double? temperature,
    double? salinity,
    List<String>? photos,
    String? notes,
    bool? showAdvanced,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return LogEntryFormState(
      feedGivenKg: feedGivenKg ?? this.feedGivenKg,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      feedTray: feedTray ?? this.feedTray,
      waterColor: waterColor ?? this.waterColor,
      ph: ph ?? this.ph,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      temperature: temperature ?? this.temperature,
      salinity: salinity ?? this.salinity,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      showAdvanced: showAdvanced ?? this.showAdvanced,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class LogEntryController extends StateNotifier<LogEntryFormState> {
  final Ref ref;

  LogEntryController(this.ref) : super(const LogEntryFormState());

  void setFeedKg(double value) {
    state = state.copyWith(feedGivenKg: value.clamp(0.0, 500.0));
  }

  void addFeedKg(double delta) {
    state = state.copyWith(feedGivenKg: (state.feedGivenKg + delta).clamp(0.0, 500.0));
  }

  void setMortality(int value) {
    state = state.copyWith(mortalityCount: value.clamp(0, 5000));
  }

  void addMortality(int delta) {
    state = state.copyWith(mortalityCount: (state.mortalityCount + delta).clamp(0, 5000));
  }

  void setFeedTray(FeedTrayStatus status) {
    state = state.copyWith(feedTray: status);
  }

  void setWaterAppearance(WaterAppearance appearance) {
    state = state.copyWith(waterColor: appearance);
  }

  void setPh(double? val) => state = state.copyWith(ph: val);
  void setDissolvedOxygen(double? val) => state = state.copyWith(dissolvedOxygen: val);
  void setTemperature(double? val) => state = state.copyWith(temperature: val);
  void setSalinity(double? val) => state = state.copyWith(salinity: val);
  void setNotes(String val) => state = state.copyWith(notes: val);
  void toggleAdvanced() => state = state.copyWith(showAdvanced: !state.showAdvanced);

  Future<void> addPhoto() async {
    final nextIdx = state.photos.length + 1;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final api = ref.read(apiClientProvider);
      final pondId = ref.read(currentPondIdProvider);
      final uploadRes = await api.getUploadUrl({
        'pond_id': pondId,
        'filename': 'log_photo_$nextIdx.jpg',
        'mime_type': 'image/jpeg',
      });

      final mediaId = uploadRes.mediaId.isNotEmpty
          ? uploadRes.mediaId
          : 'local_photo_$nextIdx';

      await api.commitMedia(mediaId);

      state = state.copyWith(
        isSubmitting: false,
        photos: [...state.photos, mediaId],
      );
    } catch (_) {
      // Offline fallback: keep local media id
      state = state.copyWith(
        isSubmitting: false,
        photos: [...state.photos, 'local_photo_$nextIdx'],
      );
    }
  }

  void removePhoto(int index) {
    final updated = List<String>.from(state.photos)..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  Future<void> submitLog(String pondId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final clientLogId = const Uuid().v4();
      final now = DateTime.now();

      final log = PondLog(
        id: clientLogId,
        clientLogId: clientLogId,
        pondId: pondId,
        loggedAt: now,
        feedGivenKg: state.feedGivenKg,
        mortalityCount: state.mortalityCount,
        feedTray: state.feedTray,
        waterColor: state.waterColor,
        ph: state.ph,
        dissolvedOxygen: state.dissolvedOxygen,
        temperature: state.temperature,
        salinity: state.salinity,
        photoUrls: state.photos,
        syncStatus: SyncStatus.pending,
        notes: state.notes.isNotEmpty ? state.notes : null,
      );

      // Save to Drift local logs & outbox tables
      await ref.read(logRepositoryProvider).addLog(log);

      // Trigger background outbox sync
      Future.microtask(() => ref.read(outboxProcessorProvider).syncOutbox());

      // Refresh log provider
      ref.invalidate(pondLogsProvider);

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save log: $e',
      );
    }
  }

  void reset() {
    state = const LogEntryFormState();
  }
}

final logEntryControllerProvider =
    StateNotifierProvider<LogEntryController, LogEntryFormState>((ref) {
  return LogEntryController(ref);
});

// ── UI Screen ─────────────────────────────────────────────────────────────────
class LogEntryScreen extends ConsumerStatefulWidget {
  const LogEntryScreen({super.key});

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  late final TextEditingController _phCtrl;
  late final TextEditingController _doCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _salCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _phCtrl = TextEditingController();
    _doCtrl = TextEditingController();
    _tempCtrl = TextEditingController();
    _salCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _phCtrl.dispose();
    _doCtrl.dispose();
    _tempCtrl.dispose();
    _salCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logEntryControllerProvider);
    final ctrl = ref.read(logEntryControllerProvider.notifier);
    final currentLang = ref.watch(appLanguageProvider);
    final pondId = ref.watch(currentPondIdProvider);

    if (state.isSuccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(currentLang == 'ta' ? 'பதிவு சேமிக்கப்பட்டது' : 'Log Saved'),
        ),
        body: _buildSuccessView(context, currentLang),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Text(
          currentLang == 'ta' ? 'குளத்துப் பதிவு — $pondId' : 'Log Pond Check — $pondId',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          SpeakerButton(
            textToSpeak: currentLang == 'ta'
                ? 'இன்றைய குளத்துப் பதிவை முடிக்க தீவனம், இறப்பு மற்றும் நீர் நிறத்தை பதிவு செய்யவும்.'
                : 'Complete today pond log by entering feed, mortalities, and water appearance.',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target speed banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentLang == 'ta'
                          ? 'இலக்கு: 45 நொடிகளில் விரைவுப் பதிவு • ஆஃப்லைனில் செயல்படும்'
                          : 'Target: <45 seconds daily log • Works 100% offline',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 1. Feed Given (kg) ─────────────────────────────────────────
            _buildSectionCard(
              title: currentLang == 'ta' ? 'வழங்கப்பட்ட தீவனம் (கிலோ)' : 'Feed Given (kg)',
              icon: Icons.scale_rounded,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        icon: Icons.remove_rounded,
                        onTap: () => ctrl.addFeedKg(-1.0),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${state.feedGivenKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 20),
                      _buildCircleButton(
                        icon: Icons.add_rounded,
                        onTap: () => ctrl.addFeedKg(1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickChip('+1 kg', () => ctrl.addFeedKg(1.0)),
                      _buildQuickChip('+5 kg', () => ctrl.addFeedKg(5.0)),
                      _buildQuickChip('+10 kg', () => ctrl.addFeedKg(10.0)),
                      _buildQuickChip('+25 kg', () => ctrl.addFeedKg(25.0)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. Mortality Count ─────────────────────────────────────────
            _buildSectionCard(
              title: currentLang == 'ta' ? 'இறப்பு எண்ணிக்கை' : 'Mortality Count',
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        icon: Icons.remove_rounded,
                        onTap: () => ctrl.addMortality(-1),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${state.mortalityCount}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: state.mortalityCount > 0 ? AppColors.critical : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildCircleButton(
                        icon: Icons.add_rounded,
                        onTap: () => ctrl.addMortality(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickChip('0 (None)', () => ctrl.setMortality(0)),
                      _buildQuickChip('+1', () => ctrl.addMortality(1)),
                      _buildQuickChip('+5', () => ctrl.addMortality(5)),
                      _buildQuickChip('+10', () => ctrl.addMortality(10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 3. Feed Tray Observation ───────────────────────────────────
            _buildSectionCard(
              title: currentLang == 'ta' ? 'தீவனத் தட்டு நிலை' : 'Feed Tray Status',
              icon: Icons.restaurant_rounded,
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'காலி' : 'Empty',
                    sublabel: currentLang == 'ta' ? 'முழுதும் தின்றது' : '100% Consumed',
                    isSelected: state.feedTray == FeedTrayStatus.empty,
                    color: AppColors.green600,
                    onTap: () => ctrl.setFeedTray(FeedTrayStatus.empty),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'சிறிது' : 'Some Left',
                    sublabel: currentLang == 'ta' ? '20-30% மீதி' : '~25% Remains',
                    isSelected: state.feedTray == FeedTrayStatus.some,
                    color: AppColors.warning,
                    onTap: () => ctrl.setFeedTray(FeedTrayStatus.some),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'நிறைய' : 'Lots Left',
                    sublabel: currentLang == 'ta' ? '>50% மீதி' : '>50% Remains',
                    isSelected: state.feedTray == FeedTrayStatus.lots,
                    color: AppColors.critical,
                    onTap: () => ctrl.setFeedTray(FeedTrayStatus.lots),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 4. Water Appearance ────────────────────────────────────────
            _buildSectionCard(
              title: currentLang == 'ta' ? 'குளத்து நீர் நிறம்' : 'Water Appearance',
              icon: Icons.water_rounded,
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'தெளிந்த பச்சை' : 'Clear Green',
                    sublabel: currentLang == 'ta' ? 'சீராக உள்ளது' : 'Healthy Bloom',
                    isSelected: state.waterColor == WaterAppearance.good,
                    color: AppColors.green600,
                    onTap: () => ctrl.setWaterAppearance(WaterAppearance.good),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'பழுப்பு' : 'Brownish',
                    sublabel: currentLang == 'ta' ? 'கண்காணிக்கவும்' : 'Diatom Shift',
                    isSelected: state.waterColor == WaterAppearance.average,
                    color: AppColors.warning,
                    onTap: () => ctrl.setWaterAppearance(WaterAppearance.average),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceChip(
                    label: currentLang == 'ta' ? 'கலங்கலாக' : 'Murky / Turbid',
                    sublabel: currentLang == 'ta' ? 'அபாயம்' : 'Critical Bloom',
                    isSelected: state.waterColor == WaterAppearance.bad,
                    color: AppColors.critical,
                    onTap: () => ctrl.setWaterAppearance(WaterAppearance.bad),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 5. Photo Upload ────────────────────────────────────────────
            _buildSectionCard(
              title: currentLang == 'ta' ? 'புகைப்படம் (விரும்பினால்)' : 'Photo (Optional)',
              icon: Icons.camera_alt_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.photos.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary500.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_rounded, color: AppColors.primary500, size: 32),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => ctrl.removePhoto(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: ctrl.addPhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      side: const BorderSide(color: AppColors.primary500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                    label: Text(currentLang == 'ta' ? 'படம் சேர்' : 'Add Photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 6. Advanced Parameters (Collapsible) ────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: ctrl.toggleAdvanced,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary500),
                            const SizedBox(width: 8),
                            Text(
                              currentLang == 'ta'
                                  ? 'நீரின் வேதியியல் அளவீடுகள் (pH, DO, Temp)'
                                  : 'Water Chemistry (pH, DO, Temp, Salinity)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Icon(
                          state.showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (state.showAdvanced) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumericField(
                            controller: _phCtrl,
                            label: 'pH',
                            hint: '7.8',
                            onChanged: (v) => ctrl.setPh(double.tryParse(v)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumericField(
                            controller: _doCtrl,
                            label: 'DO (mg/L)',
                            hint: '5.4',
                            onChanged: (v) => ctrl.setDissolvedOxygen(double.tryParse(v)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumericField(
                            controller: _tempCtrl,
                            label: 'Temp (°C)',
                            hint: '28.5',
                            onChanged: (v) => ctrl.setTemperature(double.tryParse(v)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumericField(
                            controller: _salCtrl,
                            label: 'Salinity (ppt)',
                            hint: '15.0',
                            onChanged: (v) => ctrl.setSalinity(double.tryParse(v)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 7. Optional Notes ──────────────────────────────────────────
            AppCard(
              child: TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: currentLang == 'ta' ? 'குறிப்புகள் (விரும்பினால்)' : 'Observations / Notes (Optional)',
                  hintText: currentLang == 'ta' ? 'எ.கா. காலை வேளையில் நீரோட்டம் குறைவு' : 'e.g. Aerator #2 serviced this morning',
                  border: InputBorder.none,
                ),
                onChanged: ctrl.setNotes,
              ),
            ),
            const SizedBox(height: 18),

            // Error display
            if (state.errorMessage != null) ...[
              Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.critical, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],

            // Submit Button
            PrimaryButton(
              label: currentLang == 'ta' ? 'பதிவைச் சேமி' : 'Save Pond Check',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : () => ctrl.submitLog(pondId),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: FarmerBottomNavBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/today'); break;
            case 1: break;
            case 2: context.go('/ask'); break;
            case 3: context.go('/alerts'); break;
            case 4: context.go('/crop'); break;
          }
        },
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, String currentLang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green600.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.green600),
            ),
            const SizedBox(height: 20),
            Text(
              currentLang == 'ta' ? 'பதிவு வெற்றிகரமாகச் சேமிக்கப்பட்டது!' : 'Pond Check Recorded!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentLang == 'ta'
                  ? 'உங்கள் பதிவு உள்ளூர் சேமிப்பகத்தில் பாதுகாப்பாக உள்ளது. இணைப்பு கிடைத்ததும் தானாகவே ஒத்திசைக்கப்படும்.'
                  : 'Saved locally to SQLite outbox. Will sync automatically when online.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: currentLang == 'ta' ? 'டாஷ்போர்டுக்குத் திரும்பு' : 'Back to Today Dashboard',
              onPressed: () {
                ref.read(logEntryControllerProvider.notifier).reset();
                context.go('/today');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: AppColors.primary500, size: 22),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: onTap,
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String sublabel,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color.withValues(alpha: 0.8) : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }
}
