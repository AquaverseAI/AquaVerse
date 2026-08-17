import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

class AlertRepository {
  final AppDatabase db;
  final ApiClient api;

  AlertRepository(this.db, this.api);

  Future<void> syncAlerts() async {
    try {
      final alerts = await api.getAlerts();
      
      final companions = alerts.map((a) => AlertsTableCompanion(
        id: Value(a.id),
        severity: Value(a.severity.index),
        title: Value(a.title),
        description: Value(a.description),
        what: Value(a.what),
        why: Value(a.why),
        action: Value(a.action),
        timestamp: Value(a.timestamp),
        acknowledged: Value(a.acknowledged),
        feedback: Value(a.feedback?.index),
        isLowConfidence: Value(a.isLowConfidence),
        hasSuppressionReason: Value(a.hasSuppressionReason),
      )).toList();

      await db.insertAlerts(companions);
    } catch (_) {}
  }

  Future<List<AlertItem>> getAlerts() async {
    await syncAlerts();
    final data = await db.getAllAlerts();
    return data.map((d) => AlertItem(
      id: d.id,
      severity: AlertSeverity.values[d.severity],
      title: d.title,
      description: d.description,
      what: d.what,
      why: d.why,
      action: d.action,
      timestamp: d.timestamp,
      acknowledged: d.acknowledged,
      feedback: d.feedback != null ? AlertFeedback.values[d.feedback!] : null,
      isLowConfidence: d.isLowConfidence,
      hasSuppressionReason: d.hasSuppressionReason,
    )).toList();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await db.markAlertAcknowledged(alertId);
    try {
      await api.ackAlert(alertId);
    } catch (_) {
      // Could queue this in outbox as well, but for simplicity assuming best-effort
    }
  }

  Future<void> sendFeedback(String alertId, AlertFeedback feedback) async {
    // Update local immediately
    await (db.update(db.alertsTable)..where((t) => t.id.equals(alertId))).write(AlertsTableCompanion(feedback: Value(feedback.index)));
    try {
      await api.sendAlertFeedback(alertId, {'feedback': feedback.name});
    } catch (_) {}
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return AlertRepository(db, api);
});
