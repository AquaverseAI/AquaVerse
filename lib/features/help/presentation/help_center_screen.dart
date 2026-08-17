import 'package:flutter/material.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  final Set<int> _expandedFaqs = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = DemoDataService.faqs
        .where((f) => _query.isEmpty || f['q']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Help Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search help articles…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _search.clear(); setState(() => _query = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),

            // Quick links
            Row(
              children: [
                Expanded(child: _QuickAction(icon: Icons.play_circle_rounded, label: 'Video Guides', color: AppColors.aqua, onTap: () {})),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(icon: Icons.headset_mic_rounded, label: 'WhatsApp Support', color: AppColors.success, onTap: () {})),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _QuickAction(icon: Icons.phone_rounded, label: 'Helpline', color: AppColors.seaGreen, onTap: () {})),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),

            if (faqs.isEmpty)
              const Center(child: Text('No results found.', style: TextStyle(color: AppColors.textSecondary)))
            else
              ...faqs.asMap().entries.map((e) {
                final i = e.key;
                final faq = e.value;
                final expanded = _expandedFaqs.contains(i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => setState(() {
                      if (expanded) {
                        _expandedFaqs.remove(i);
                      } else {
                        _expandedFaqs.add(i);
                      }
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(faq['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                            Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 8),
                          Text(faq['a']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    ),
  );
}
