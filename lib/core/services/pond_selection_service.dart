import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_preferences_provider.dart';

const String _kSelectedPondKey = 'aquaverse_selected_pond_id';

class PondSelectionNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  PondSelectionNotifier(this._prefs)
      : super(_prefs.getString(_kSelectedPondKey) ?? '') {
    // Initial load
  }

  void selectPond(String pondId) {
    if (pondId.isEmpty || pondId == state) return;
    state = pondId;
    _prefs.setString(_kSelectedPondKey, pondId);
  }

  void ensureSelection(List<String> availablePondIds) {
    if (availablePondIds.isEmpty) return;
    if (state.isEmpty || !availablePondIds.contains(state)) {
      selectPond(availablePondIds.first);
    }
  }
}

final activePondIdProvider =
    StateNotifierProvider<PondSelectionNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PondSelectionNotifier(prefs);
});
