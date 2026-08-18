import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/models/models.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';

class MyPondsScreen extends ConsumerWidget {
  const MyPondsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final ponds = [DemoDataService.pond];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(currentLang == 'ta' ? 'என் குளங்கள்' : 'My Ponds'),
        actions: [
          IconButton(
            onPressed: () => _showAddPond(context, currentLang),
            icon: const Icon(Icons.add_rounded),
            tooltip: currentLang == 'ta' ? 'குளம் சேர்' : 'Add Pond',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ponds.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == ponds.length) {
            return PrimaryButton(
              label: currentLang == 'ta' ? '+ புதிய குளம் சேர்' : '+ Add Pond',
              onPressed: () => _showAddPond(context, currentLang),
            );
          }
          final pond = ponds[i];
          Color statusColor;
          String statusLabel;
          switch (pond.status) {
            case PondStatus.good:
              statusColor = AppColors.success;
              statusLabel = currentLang == 'ta' ? 'சீராக உள்ளது' : 'Good';
              break;
            case PondStatus.caution:
              statusColor = AppColors.warning;
              statusLabel = currentLang == 'ta' ? 'கவனம்' : 'Caution';
              break;
            case PondStatus.critical:
              statusColor = AppColors.critical;
              statusLabel = currentLang == 'ta' ? 'அபாயம்' : 'Critical';
              break;
          }

          return AppCard(
            onTap: () => context.push('/pond-details'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.water_rounded, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pond.id, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(pond.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(currentLang == 'ta' ? 'புதுப்பிக்கப்பட்டது ${_timeAgo(pond.lastUpdated, currentLang)}' : 'Updated ${_timeAgo(pond.lastUpdated, currentLang)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPond(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang == 'ta' ? 'புதிய குளம் சேர்க்க' : 'Add New Pond', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: lang == 'ta' ? 'குளத்து எண் (ID)' : 'Pond ID', hintText: 'e.g. TN-01-002')),
            const SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: lang == 'ta' ? 'குளத்தின் பெயர்' : 'Pond Name')),
            const SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: lang == 'ta' ? 'இடம் / மாவட்டம்' : 'Location')),
            const SizedBox(height: 16),
            PrimaryButton(
              label: lang == 'ta' ? 'குளத்தைச் சேமி' : 'Save Pond',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime t, String lang) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return lang == 'ta' ? '${diff.inMinutes} நிமிடம் முன்' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return lang == 'ta' ? '${diff.inHours} மணி நேரம் முன்' : '${diff.inHours}h ago';
    return lang == 'ta' ? '${diff.inDays} நாள் முன்' : '${diff.inDays}d ago';
  }
}
