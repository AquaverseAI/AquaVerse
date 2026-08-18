import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

class OfficerFarmerInfoScreen extends ConsumerWidget {
  final Map<String, dynamic>? farmerData;

  const OfficerFarmerInfoScreen({super.key, this.farmerData});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber, String farmerName) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening phone dialer for $farmerName ($phoneNumber)…'),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing $farmerName ($phoneNumber)…'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final name = farmerData?['farmerName'] ?? 'M. Selvam';
    final phone = farmerData?['phone'] ?? '+91 98765 43210';
    final pondId = farmerData?['pondId'] ?? 'TN-01-001';
    final location = farmerData?['location'] ?? 'Nagapattinam';
    final risk = farmerData?['risk'] ?? 'Low';
    final lastVisit = farmerData?['lastVisit'] ?? '12 Aug 2026';

    Color statusColor;
    switch (risk) {
      case 'High':
        statusColor = AppColors.critical;
        break;
      case 'Medium':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.green600;
    }

    final riskLabel = currentLang == 'ta'
        ? (risk == 'High' ? 'அதிக அபாயம்' : risk == 'Medium' ? 'நடுத்தர அபாயம்' : 'குறைந்த அபாயம்')
        : '$risk Risk';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/officer/dashboard')),
        title: Text(
          currentLang == 'ta' ? 'விவசாயி விவரங்கள்' : 'Farmer Information',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          SpeakerButton(textToSpeak: 'Farmer Profile for $name. Contact number $phone.'),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pageMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Farmer Profile Identity Header ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradient3DPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowTier2,
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0] : 'F',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentLang == 'ta' ? 'குளம் $pondId · $location' : 'Pond $pondId · $location',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CALL FARMER DIRECT ACTION BUTTON
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(context, phone, name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.langAccentPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 22),
                    label: Text(
                      currentLang == 'ta' ? '$name ஐ அழை ($phone)' : 'Call $name ($phone)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Culture & Pond Details ──────────────────────────────────────
            Text(
              currentLang == 'ta' ? 'பண்ணை மற்றும் குளத்து விவரங்கள்' : 'Farm & Pond Specification',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            AppCard(
              child: Column(
                children: [
                  _InfoRow(label: currentLang == 'ta' ? 'ஒதுக்கப்பட்ட குளத்து எண்' : 'Assigned Pond ID', value: pondId),
                  const Divider(height: 12),
                  _InfoRow(label: currentLang == 'ta' ? 'இடம்' : 'Location', value: currentLang == 'ta' ? '$location மாவட்டம் குழு 3' : '$location District Cluster 3'),
                  const Divider(height: 12),
                  _InfoRow(label: currentLang == 'ta' ? 'வளர்ப்பு இனம்' : 'Cultured Species', value: 'Litopenaeus vannamei'),
                  const Divider(height: 12),
                  _InfoRow(label: currentLang == 'ta' ? 'குளத்தின் பரப்பளவு' : 'Pond Water Area', value: currentLang == 'ta' ? '4,000 சதுர மீட்டர் (0.4 ஹெக்டேர்)' : '4,000 m² (0.4 Ha)'),
                  const Divider(height: 12),
                  _InfoRow(label: currentLang == 'ta' ? 'வளர்ப்பு அபாய நிலை' : 'Culture Risk Status', value: riskLabel, valueColor: statusColor),
                  const Divider(height: 12),
                  _InfoRow(label: currentLang == 'ta' ? 'கடைசி களப் பார்வை' : 'Last Field Visit', value: lastVisit),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions ───────────────────────────────────────────────────
            PrimaryButton(
              label: currentLang == 'ta' ? 'நேரடி ஆலோசனை அனுப்பு' : 'Send Direct Advisory',
              icon: Icons.send_rounded,
              onPressed: () => context.push('/officer/send-advice'),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: currentLang == 'ta' ? 'களப் பார்வை பதிவு செய்' : 'Log Field Visit',
              icon: Icons.add_location_alt_rounded,
              onPressed: () => context.push('/officer/visit-log'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
