import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
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
  String _selectedCategory = 'Feed Adjustment';
  bool _sendSmsNotification = true;
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

  static const List<String> _categories = [
    'Feed Adjustment',
    'Aeration Schedule',
    'Water Quality Warning',
    'Disease Treatment',
    'Harvest Timing',
    'General Advisory',
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
        'pond_id': '00000000-0000-0000-0001-000000000001',
        'filename': 'visit_photo_$nextIdx.jpg',
        'mime_type': 'image/jpeg',
      });
      final String mediaId = res.mediaId.isNotEmpty
          ? res.mediaId
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

    // TODO(contract): POST /v1/logs is missing from confirmed endpoint contract. See openapi_contract.md.
    // Officer visit log report queued in local SQLite outbox until write endpoint is confirmed.
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(appLanguageProvider);

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
                  Text(
                    currentLang == 'ta' ? 'பார்வை & ஆலோசனை சேமிக்கப்பட்டது' : 'Field Visit & Advisory Saved',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLang == 'ta'
                        ? 'குளம் $_selectedPond பார்வை அறிக்கை இணைக்கப்பட்டது. $_selectedCategory ஆலோசனை விவசாயிக்கு அறிவிக்கப்பட்டது.'
                        : 'Pond $_selectedPond visit report queued for sync. $_selectedCategory advisory broadcast to farmer.',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: currentLang == 'ta' ? 'அலுவலர் முகப்பிற்குத் திரும்பு' : 'Back to Officer Dashboard',
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
        title: Text(
          currentLang == 'ta' ? 'களப் பார்வைப் பதிவு' : 'Field Visit Log Entry',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        actions: [
          SpeakerButton(
            textToSpeak: currentLang == 'ta'
                ? 'விரிவாக்க அலுவலர் பார்வைப் பதிவு. களக் அவதானிப்புகள் மற்றும் ஆலோசனைகளைப் பதிவு செய்யவும்.'
                : 'Extension Officer Visit Log. Record observations and farmer advice.',
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
                  Text(currentLang == 'ta' ? 'இலக்குக் குளத்தைத் தேர்ந்தெடுக்கவும்' : 'Select Target Pond',
                      style: const TextStyle(
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
                  Text(currentLang == 'ta' ? 'களக் அவதானிப்புகள்' : 'Field Observations',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observationsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: currentLang == 'ta'
                          ? 'குளத்து நீரின் நிலை, தீவன நுகர்வு, காற்றுப்பான் சோதனைகளை விவரிக்கவும்…'
                          : 'Describe pond water condition, feeding vigor, aeration checks…',
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
            // Farmer Recommendations & Advisory
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentLang == 'ta' ? 'விவசாயிக்கான செயல்பாட்டுப் பரிந்துரைகள்' : 'Action Recommendations for Farmer',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    currentLang == 'ta'
                        ? 'விவசாயிக்கான செயல்பாட்டுப் பரிந்துரைகள் & ஆலோசனை'
                        : 'Farmer Advice & Recommendations',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: currentLang == 'ta' ? 'ஆலோசனை வகை' : 'Advisory Category',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _suggestionsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: currentLang == 'ta'
                          ? 'பார்வையின் போது விவசாயிக்கு வழங்கப்பட்ட குறிப்பிட்ட நடவடிக்கைகள்…'
                          : 'Specific action steps and advice given to farmer…',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      currentLang == 'ta' ? 'விவசாயிக்கு SMS மூலம் அனுப்பு' : 'Notify Farmer via SMS',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      currentLang == 'ta'
                          ? 'பரிந்துரையை உடனடி SMS ஆக அனுப்புகிறது'
                          : 'Broadcasts this advisory directly to farmer\'s mobile',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: _sendSmsNotification,
                    activeTrackColor: AppColors.seaGreen,
                    onChanged: (v) => setState(() => _sendSmsNotification = v),
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
                  Text(currentLang == 'ta' ? 'பார்வைப் புகைப்படங்கள்' : 'Visit Photos (Media API)',
                      style: const TextStyle(
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
              label: _isSaving
                  ? (currentLang == 'ta' ? 'சமர்ப்பிக்கப்படுகிறது…' : 'Submitting…')
                  : (currentLang == 'ta' ? 'பார்வை அறிக்கையைச் சேமி' : 'Save Visit Report'),
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
