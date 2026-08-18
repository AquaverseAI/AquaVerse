import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.aquaverse.ai')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // -- Auth --
  @POST('/v1/auth/otp/request')
  Future<void> requestOtp(@Body() Map<String, dynamic> body);

  @POST('/v1/auth/otp/verify')
  Future<dynamic> verifyOtp(@Body() Map<String, dynamic> body);

  // TODO(contract): Revisit if staff/admin login (/v1/auth/token) is confirmed for Extension Officers
  @POST('/v1/auth/token')
  Future<dynamic> staffTokenLogin(@Body() Map<String, dynamic> body);

  @GET('/v1/auth/me')
  Future<dynamic> getMe();

  // -- Ponds --
  @GET('/v1/ponds')
  Future<List<Pond>> getPonds();

  @GET('/v1/ponds/{pond_id}')
  Future<Pond> getPondDetails(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/events')
  Future<dynamic> getPondEvents(@Path('pond_id') String pondId);

  // TODO(contract): Dedicated forecast endpoint is missing. Risk score/tier comes from /v1/ponds/{pond_id}/risk.
  @GET('/v1/ponds/{pond_id}/risk')
  Future<dynamic> getPondRisk(@Path('pond_id') String pondId);

  // -- Data Quality --
  @GET('/v1/data-quality')
  Future<dynamic> getDataQuality();

  // -- Logs --
  @GET('/v1/logs')
  Future<List<PondLog>> getLogs();

  // TODO(contract): POST /v1/logs is missing from confirmed endpoint contract. See openapi_contract.md.
  // Farmer & Extension Officer observation writes are stored in local SQLite outbox until write endpoint is confirmed.

  // -- Media --
  @POST('/v1/media/upload-url')
  Future<dynamic> getUploadUrl(@Body() Map<String, dynamic> body);

  @POST('/v1/media/{media_id}/commit')
  Future<void> commitMedia(@Path('media_id') String mediaId);

  // -- Alerts --
  @GET('/v1/alerts')
  Future<List<AlertItem>> getAlerts();

  @POST('/v1/alerts/{alert_id}/ack')
  Future<void> ackAlert(@Path('alert_id') String alertId);

  @POST('/v1/alerts/{alert_id}/feedback')
  Future<void> sendAlertFeedback(@Path('alert_id') String alertId, @Body() Map<String, dynamic> body);

  // -- Advisories & Ask --
  @GET('/v1/advisories')
  Future<List<Recommendation>> getAdvisories();

  @POST('/v1/ask')
  Future<dynamic> askAqua(@Body() Map<String, dynamic> body);

  // -- Utils --
  @POST('/v1/reason')
  Future<dynamic> getReasoning(@Body() Map<String, dynamic> body);

  @POST('/v1/translate')
  Future<dynamic> translate(@Body() Map<String, dynamic> body);
}
