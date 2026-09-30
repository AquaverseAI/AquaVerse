import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

const List<Map<String, String>> _helpFaqs = [
  {
    'q': 'How often should I log my pond data?',
    'a': 'Log at least once daily, preferably in the morning. Consistent logging improves AI forecast accuracy significantly.',
  },
  {
    'q': 'What is a safe dissolved oxygen level?',
    'a': 'Dissolved oxygen should be above 4.0 mg/L at all times. Below 3.0 mg/L is critical and requires immediate aeration.',
  },
  {
    'q': 'When should I use Ask Aqua?',
    'a': 'Ask Aqua any time you have a question about your pond. It works best when you have logged regularly and have recent data.',
  },
  {
    'q': 'What does the blind state warning mean?',
    'a': 'Blind state means AI cannot generate reliable advice because no log has been recorded for 3+ days. Log your data to resume alerts.',
  },
  {
    'q': 'How do I sync offline logs?',
    'a': 'Offline logs sync automatically when you reconnect to the internet. You can see pending logs in the Log screen.',
  },
];

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
    final faqs = _helpFaqs
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
