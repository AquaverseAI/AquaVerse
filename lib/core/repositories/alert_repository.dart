import 'dart:convert';
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
      final response = await api.getAlerts();
      final alerts = response.items;
      
      final companions = alerts.map((a) => AlertsTableCompanion(
        id: Value(a.id),
        pondId: Value(a.pondId),
        pondName: Value(a.pondName),
        alertType: Value(a.alertType),
        severity: Value(a.severity),
        title: Value(a.title),
        message: Value(a.message),
        suppressed: Value(a.suppressed),
        suppressionReason: Value(a.suppressionReason),
        acked: Value(a.acked),
        ackedAt: Value(a.ackedAt),
        riskScore: Value(a.riskScore),
        createdAt: Value(a.createdAt),
        feedback: Value(a.feedback?.index),
      )).toList();

      await db.insertAlerts(companions);
    } catch (_) {}
  }

  Future<List<AlertItem>> getAlerts() async {
    await syncAlerts();
    final data = await db.getAllAlerts();
    return data.map((d) => AlertItem(
      id: d.id,
      pondId: d.pondId,
      pondName: d.pondName,
      alertType: d.alertType,
      severity: d.severity,
      title: d.title,
      message: d.message,
      suppressed: d.suppressed,
      suppressionReason: d.suppressionReason,
      acked: d.acked,
      ackedAt: d.ackedAt,
      riskScore: d.riskScore,
      createdAt: d.createdAt,
      feedback: d.feedback != null ? AlertFeedback.values[d.feedback!] : null,
    )).toList();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await db.markAlertAcknowledged(alertId);
    try {
      await api.ackAlert(alertId);
    } catch (_) {
      // Outbox retry queue
      await db.insertOutboxItem(OutboxTableCompanion(
        id: Value('ack-$alertId'),
        clientLogId: Value(alertId),
        entityType: const Value('alert_ack'),
        payloadJson: Value(jsonEncode({'alert_id': alertId})),
        createdAt: Value(DateTime.now()),
        status: const Value('pending'),
      ));
    }
  }

  Future<void> sendFeedback(String alertId, AlertFeedback feedback) async {
    // Update local immediately
    await (db.update(db.alertsTable)..where((t) => t.id.equals(alertId)))
        .write(AlertsTableCompanion(feedback: Value(feedback.index)));
    final payload = {
      'useful': feedback == AlertFeedback.correct,
      'false_positive': feedback == AlertFeedback.incorrect,
    };
    try {
      await api.sendAlertFeedback(alertId, payload);
    } catch (_) {
      await db.insertOutboxItem(OutboxTableCompanion(
        id: Value('fb-$alertId-${feedback.name}'),
        clientLogId: Value('$alertId-${feedback.name}'),
        entityType: const Value('alert_feedback'),
        payloadJson: Value(jsonEncode({'alert_id': alertId, ...payload})),
        createdAt: Value(DateTime.now()),
        status: const Value('pending'),
      ));
    }
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return AlertRepository(db, api);
});
