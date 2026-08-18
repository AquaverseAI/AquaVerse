import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';

class OfficerSendAdviceScreen extends ConsumerStatefulWidget {
  const OfficerSendAdviceScreen({super.key});

  @override
  ConsumerState<OfficerSendAdviceScreen> createState() => _OfficerSendAdviceScreenState();
}

class _OfficerSendAdviceScreenState extends ConsumerState<OfficerSendAdviceScreen> {
  String _selectedPond = 'TN-01-001';
  String _selectedCategory = 'Feed Adjustment';
  final _titleController = TextEditingController();
  final _adviceController = TextEditingController();
  bool _isUrgent = false;
  bool _isSending = false;
  bool _isSent = false;

  static const List<Map<String, String>> _farmerPonds = [
    {'id': 'TN-01-001', 'farmer': 'M. Selvam (Pond 1)'},
    {'id': 'TN-01-002', 'farmer': 'R. Kumar (Pond 2)'},
    {'id': 'TN-01-003', 'farmer': 'K. Priya (Pond 3)'},
    {'id': 'TN-01-004', 'farmer': 'S. Murugan (Pond 4)'},
    {'id': 'TN-01-005', 'farmer': 'A. Ramesh (Pond 5)'},
  ];

  static const List<String> _categories = [
    'Feed Adjustment',
    'Aeration Schedule',
    'Water Quality Warning',
    'Disease Treatment',
    'Harvest Timing',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  Future<void> _sendAdvice(String lang) async {
    final title = _titleController.text.trim();
    final advice = _adviceController.text.trim();

    if (title.isEmpty || advice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang == 'ta' ? 'தலைப்பு மற்றும் பரிந்துரையை உள்ளிடவும்' : 'Please enter both title and recommendation text')),
      );
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isSending = false;
      _isSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(appLanguageProvider);

    if (_isSent) {
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
                        color: AppColors.green600, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentLang == 'ta' ? 'ஆலோசனை வெற்றிகரமாக அனுப்பப்பட்டது' : 'Advisory Sent Successfully',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentLang == 'ta'
                        ? 'குளம் $_selectedPond விவசாயிக்கு பயன்பாடு மற்றும் SMS மூலம் அறிவிக்கப்பட்டது.'
                        : 'Pond $_selectedPond farmer notified via app & SMS broadcast.',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: currentLang == 'ta' ? 'முகப்பிற்குத் திரும்பு' : 'Back to Dashboard',
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
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        title: Text(
          currentLang == 'ta' ? 'விவசாயிக்கு ஆலோசனை அனுப்பு' : 'Send Farmer Advice',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Target Pond Selection ───────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentLang == 'ta' ? 'இலக்கு விவசாயி மற்றும் குளம்' : 'Target Farmer & Pond',
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
                    items: _farmerPonds.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text('${p['id']} · ${p['farmer']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPond = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Category Chips ──────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentLang == 'ta' ? 'ஆலோசனை வகை' : 'Advisory Category',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final selected = _selectedCategory == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        selectedColor:
                            AppColors.langAccentPrimary.withValues(alpha: 0.15),
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? AppColors.langAccentPrimary
                              : AppColors.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = c),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Title & Advice Body ─────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentLang == 'ta' ? 'ஆலோசனைத் தலைப்பு' : 'Advisory Title',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: currentLang == 'ta'
                          ? 'எ.கா. இன்று இரவு தீவனத்தை 20% குறைக்கவும்'
                          : 'e.g. Reduce Feed Portion by 20% Tonight',
                      filled: true,
                      fillColor: AppColors.surface,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.inputRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(currentLang == 'ta' ? 'விரிவான பரிந்துரை' : 'Detailed Recommendation',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _adviceController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: currentLang == 'ta'
                          ? 'விவசாயிக்கான துல்லியமான வழிமுறைகளை எழுதவும் (காற்றுப்பான் இயக்கம், மருந்து அளவு, நீர் மாற்றம்…)'
                          : 'Explain exact steps for the farmer (aerator runtime, dosing, water exchange…)',
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

            // ── Priority Flag ───────────────────────────────────────────────
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(currentLang == 'ta' ? 'முக்கிய எச்சரிக்கையாகக் குறிக்க' : 'Mark as High Priority Alert',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                subtitle: Text(
                    currentLang == 'ta'
                        ? 'உடனடியாக மொபைல் அறிவிப்பு மற்றும் SMS அனுப்பப்படும்'
                        : 'Sends push notification & SMS alert immediately',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                value: _isUrgent,
                activeThumbColor: AppColors.critical,
                onChanged: (val) => setState(() => _isUrgent = val),
              ),
            ),
            const SizedBox(height: 20),

            // ── Submit Button ───────────────────────────────────────────────
            PrimaryButton(
              label: _isSending
                  ? (currentLang == 'ta' ? 'அனுப்பப்படுகிறது…' : 'Transmitting…')
                  : (currentLang == 'ta' ? 'பரிந்துரையை அனுப்பு' : 'Send Recommendation'),
              isLoading: _isSending,
              icon: Icons.send_rounded,
              onPressed: () => _sendAdvice(currentLang),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
