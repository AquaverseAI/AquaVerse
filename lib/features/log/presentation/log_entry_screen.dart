import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class LogEntryState {
  final double feedKg;
  final int mortalityCount;
  final FeedTrayStatus? feedTray;
  final WaterAppearance? waterColor;
  final double? ph;
  final double? doMgL;
  final double? tempC;
  final double? salinity;
  final List<String> photos;
  final bool isSaving;
  final bool isSaved;
  final bool savedOffline;

  const LogEntryState({
    this.feedKg = 18.0,
    this.mortalityCount = 0,
    this.feedTray,
    this.waterColor,
    this.ph,
    this.doMgL,
    this.tempC,
    this.salinity,
    this.photos = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.savedOffline = false,
  });

  LogEntryState copyWith({
    double? feedKg,
    int? mortalityCount,
    FeedTrayStatus? feedTray,
    WaterAppearance? waterColor,
    double? ph,
    double? doMgL,
    double? tempC,
    double? salinity,
    List<String>? photos,
    bool? isSaving,
    bool? isSaved,
    bool? savedOffline,
  }) {
    return LogEntryState(
      feedKg: feedKg ?? this.feedKg,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      feedTray: feedTray ?? this.feedTray,
      waterColor: waterColor ?? this.waterColor,
      ph: ph ?? this.ph,
      doMgL: doMgL ?? this.doMgL,
      tempC: tempC ?? this.tempC,
      salinity: salinity ?? this.salinity,
      photos: photos ?? this.photos,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      savedOffline: savedOffline ?? this.savedOffline,
    );
  }
}

class LogEntryController extends StateNotifier<LogEntryState> {
  LogEntryController() : super(const LogEntryState());

  void setFeed(double v) => state = state.copyWith(feedKg: v.clamp(0, 100));
  void incrementFeed() => setFeed(state.feedKg + 1);
  void decrementFeed() => setFeed(state.feedKg - 1);
  void setMortality(int v) => state = state.copyWith(mortalityCount: v.clamp(0, 9999));
  void setFeedTray(FeedTrayStatus v) => state = state.copyWith(feedTray: v);
  void setWaterColor(WaterAppearance v) => state = state.copyWith(waterColor: v);
  void setPh(double? v) => state = state.copyWith(ph: v);
  void setDo(double? v) => state = state.copyWith(doMgL: v);
  void setTemp(double? v) => state = state.copyWith(tempC: v);
  void setSalinity(double? v) => state = state.copyWith(salinity: v);
  void addPhoto(String url) => state = state.copyWith(photos: [...state.photos, url]);

  Future<void> saveLog({required bool isOffline}) async {
    state = state.copyWith(isSaving: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isSaving: false, isSaved: true, savedOffline: isOffline);
  }
}

final logEntryControllerProvider =
    StateNotifierProvider<LogEntryController, LogEntryState>(
  (ref) => LogEntryController(),
);

// ── Screen ────────────────────────────────────────────────────────────────────
class LogEntryScreen extends ConsumerWidget {
  const LogEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logEntryControllerProvider);
    final ctrl  = ref.read(logEntryControllerProvider.notifier);

    if (state.isSaved) {
      return _LogSavedScreen(offline: state.savedOffline);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/today')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log Entry', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _dateLabel(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          const SpeakerButton(textToSpeak: 'Log Entry. Record your pond data.'),
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
                  // Feed Given
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

                  // Mortality
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

                  // Water Color
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Water Color / Appearance', icon: Icons.opacity_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: WaterAppearance.values.map((w) {
                            Color color;
                            switch (w) {
                              case WaterAppearance.good: color = AppColors.green600; break;
                              case WaterAppearance.average: color = AppColors.warning; break;
                              case WaterAppearance.bad: color = AppColors.critical; break;
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

                  // Sensor readings
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Optional Readings', icon: Icons.sensors_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _NumericField(label: 'pH', hint: '7.8', onChanged: (v) => ctrl.setPh(double.tryParse(v)))),
                            const SizedBox(width: 8),
                            Expanded(child: _NumericField(label: 'DO (mg/L)', hint: '5.2', onChanged: (v) => ctrl.setDo(double.tryParse(v)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _NumericField(label: 'Temp (°C)', hint: '28', onChanged: (v) => ctrl.setTemp(double.tryParse(v)))),
                            const SizedBox(width: 8),
                            Expanded(child: _NumericField(label: 'Salinity', hint: '5.2', onChanged: (v) => ctrl.setSalinity(double.tryParse(v)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Photos
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(label: 'Add Photos', icon: Icons.camera_alt_rounded),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: Row(
                            children: [
                              ...state.photos.take(3).map((url) => _PhotoThumbnail(url: url)),
                              if (state.photos.length < 3)
                                _AddPhotoButton(onTap: () {
                                  // Demo: add placeholder photo
                                  ctrl.addPhoto('photo_${state.photos.length + 1}');
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  PrimaryButton(
                    label: state.isSaving ? 'Saving…' : 'Save Log',
                    isLoading: state.isSaving,
                    icon: Icons.save_rounded,
                    onPressed: () => ctrl.saveLog(isOffline: false),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Saved offline — will sync when online',
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

  String _dateLabel() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ── Log Saved screen ──────────────────────────────────────────────────────────
class _LogSavedScreen extends StatelessWidget {
  final bool offline;
  const _LogSavedScreen({required this.offline});

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
                  'Log Saved Successfully',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  offline
                      ? 'Saved offline — will sync when online'
                      : 'Your data is safe and synced',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/today'),
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

class _NumericField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  const _NumericField({required this.label, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint, 
            isDense: true, 
            filled: true, 
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.inputRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
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
