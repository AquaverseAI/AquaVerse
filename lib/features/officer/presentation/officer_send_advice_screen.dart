import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';

class OfficerSendAdviceScreen extends StatefulWidget {
  const OfficerSendAdviceScreen({super.key});

  @override
  State<OfficerSendAdviceScreen> createState() => _OfficerSendAdviceScreenState();
}

class _OfficerSendAdviceScreenState extends State<OfficerSendAdviceScreen> {
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

  Future<void> _sendAdvice() async {
    final title = _titleController.text.trim();
    final advice = _adviceController.text.trim();

    if (title.isEmpty || advice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and recommendation text')),
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
                  const Text(
                    'Advisory Sent Successfully',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pond $_selectedPond farmer notified via app & SMS broadcast.',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Back to Dashboard',
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
        title: const Text('Send Farmer Advice',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                  const Text('Target Farmer & Pond',
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
                  const Text('Advisory Category',
                      style: TextStyle(
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
                  const Text('Advisory Title',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Reduce Feed Portion by 20% Tonight',
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
                  const Text('Detailed Recommendation',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _adviceController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Explain exact steps for the farmer (aerator runtime, dosing, water exchange…)',
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
                title: const Text('Mark as High Priority Alert',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                subtitle: const Text(
                    'Sends push notification & SMS alert immediately',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                value: _isUrgent,
                activeColor: AppColors.critical,
                onChanged: (val) => setState(() => _isUrgent = val),
              ),
            ),
            const SizedBox(height: 20),

            // ── Submit Button ───────────────────────────────────────────────
            PrimaryButton(
              label: _isSending ? 'Transmitting…' : 'Send Recommendation',
              isLoading: _isSending,
              icon: Icons.send_rounded,
              onPressed: _sendAdvice,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
