import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

class OfficerVisitLogScreen extends ConsumerStatefulWidget {
  const OfficerVisitLogScreen({super.key});

  @override
  ConsumerState<OfficerVisitLogScreen> createState() => _OfficerVisitLogScreenState();
}

class _OfficerVisitLogScreenState extends ConsumerState<OfficerVisitLogScreen> {
  String _selectedPond = 'TN-01-001';
  final _observationsCtrl = TextEditingController();
  final _suggestionsCtrl = TextEditingController();
  final List<String> _photos = [];
  bool _isSaving = false;
  bool _isSaved = false;

  static const List<Map<String, String>> _ponds = [
    {'id': 'TN-01-001', 'name': 'M. Selvam (Pond 1)'},
    {'id': 'TN-01-002', 'name': 'R. Kumar (Pond 2)'},
    {'id': 'TN-01-003', 'name': 'K. Priya (Pond 3)'},
    {'id': 'TN-01-004', 'name': 'S. Murugan (Pond 4)'},
    {'id': 'TN-01-005', 'name': 'A. Ramesh (Pond 5)'},
  ];

  @override
  void dispose() {
    _observationsCtrl.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final nextIdx = _photos.length + 1;
    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getUploadUrl({
        'filename': 'visit_photo_$nextIdx.jpg',
        'content_type': 'image/jpeg',
      });
      final String mediaId = (res is Map<String, dynamic> && res.containsKey('media_id'))
          ? res['media_id']
          : 'visit_media_$nextIdx';

      await api.commitMedia(mediaId);

      setState(() {
        _isSaving = false;
        _photos.add(mediaId);
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _photos.add('visit_media_$nextIdx');
      });
    }
  }

  Future<void> _save() async {
    if (_observationsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter field visit observations')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaved) {
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.green600.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.green600.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.green600, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('Field Visit Log Saved',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Pond $_selectedPond visit report queued for sync.',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Back to Officer Dashboard',
                    onPressed: () => context.go('/officer/dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Field Visit Log Entry',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        actions: [
          const SpeakerButton(
            textToSpeak: 'Extension Officer Visit Log. Record observations and farmer advice.',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Pond selector
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Target Pond',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPond,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: _ponds
                        .map((p) => DropdownMenuItem(
                              value: p['id'],
                              child: Text('${p['id']} · ${p['name']}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPond = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Field Observations
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Field Observations',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observationsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Describe pond water condition, feeding vigor, aeration checks…',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Farmer Recommendations
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Action Recommendations for Farmer',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _suggestionsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Specific action steps given to farmer during visit…',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Visit Photos (Media API)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Visit Photos (Media API)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ..._photos.map((id) => Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.langAccentPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.langAccentPrimary.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.image_rounded,
                                color: AppColors.langAccentPrimary, size: 24),
                          )),
                      if (_photos.length < 3)
                        _AddPhotoBox(onTap: _addPhoto),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: _isSaving ? 'Submitting…' : 'Save Visit Report',
              isLoading: _isSaving,
              icon: Icons.save_rounded,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoBox extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoBox({required this.onTap});

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
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded,
                color: AppColors.langAccentPrimary, size: 22),
            SizedBox(height: 4),
            Text('Add',
                style: TextStyle(fontSize: 10, color: AppColors.langAccentPrimary)),
          ],
        ),
      ),
    );
  }
}
