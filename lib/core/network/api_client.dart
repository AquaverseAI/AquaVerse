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

  // -- Ponds --
  @GET('/v1/ponds')
  Future<List<Pond>> getPonds();

  @GET('/v1/ponds/{pond_id}')
  Future<Pond> getPondDetails(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/risk')
  Future<dynamic> getPondRisk(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/forecast/do')
  Future<List<DOForecastPoint>> getDOForecast(@Path('pond_id') String pondId);

  // -- Logs --
  @GET('/v1/logs')
  Future<List<PondLog>> getLogs();

  @POST('/v1/logs')
  Future<void> createLog(@Body() PondLog log);

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
