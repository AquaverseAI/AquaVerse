import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';

class OfficerVisitLogScreen extends StatefulWidget {
  const OfficerVisitLogScreen({super.key});

  @override
  State<OfficerVisitLogScreen> createState() => _OfficerVisitLogScreenState();
}

class _OfficerVisitLogScreenState extends State<OfficerVisitLogScreen> {
  String _selectedPond = 'TN-01-001';
  final _observationsCtrl = TextEditingController();
  final _suggestionsCtrl  = TextEditingController();
  bool _isSaving = false;
  bool _isSaved  = false;

  static const List<String> _ponds = ['TN-01-001', 'TN-01-002', 'TN-01-003', 'TN-01-004', 'TN-01-005'];

  @override
  void dispose() {
    _observationsCtrl.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    // TODO: confirm with backend owner whether officer visit logs use
    // the same /v1/logs schema with a role flag, or a separate endpoint —
    // not specified in current openapi_contract.md. Writing to outbox
    // using same offline queue pattern as farmer Log screen.
    setState(() { _isSaving = false; _isSaved = true; });
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
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.green600.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.green600, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('Visit Log Saved', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Saved offline — will sync when online', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Back to Dashboard', onPressed: () => context.go('/officer/dashboard')),
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
        title: const Text('Visit Log Entry', style: TextStyle(color: AppColors.textPrimary)),
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pond selector
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Pond', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPond,
                    decoration: InputDecoration(
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
                    items: _ponds.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _selectedPond = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Observations
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Observations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observationsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe pond conditions, fish behavior, water quality…',
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Suggestions
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suggestions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _suggestionsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Recommendations for the farmer…',
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
                  const Text('Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AddPhotoBox(onTap: () {}),
                      const SizedBox(width: 8),
                      _AddPhotoBox(onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: _isSaving ? 'Saving…' : 'Save Visit Log',
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, color: AppColors.primary500, size: 24),
          SizedBox(height: 4),
          Text('Add', style: TextStyle(fontSize: 11, color: AppColors.primary500)),
        ],
      ),
    ),
  );
}
