import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';

/// Farmer bottom navigation bar — dynamic localized labels (Tamil / English).
class FarmerBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FarmerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(
        key: 'today',
        labelEn: 'Today',
        icon: Icons.wb_sunny_outlined,
        activeIcon: Icons.wb_sunny_rounded),
    _NavItem(
        key: 'log',
        labelEn: 'Log',
        icon: Icons.edit_note_outlined,
        activeIcon: Icons.edit_note_rounded),
    _NavItem(
        key: 'ask',
        labelEn: 'Ask',
        icon: Icons.mic_none_rounded,
        activeIcon: Icons.mic_rounded),
    _NavItem(
        key: 'alerts',
        labelEn: 'Alerts',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded),
    _NavItem(
        key: 'crop',
        labelEn: 'Crop',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;
              final localizedLabel = AppTranslations.getText(item.key, currentLang);

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.seaGreen.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive
                              ? AppColors.seaGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        localizedLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? AppColors.seaGreen
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String key;
  final String labelEn;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.key,
    required this.labelEn,
    required this.icon,
    required this.activeIcon,
  });
}
