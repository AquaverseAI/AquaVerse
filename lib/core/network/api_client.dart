import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.aquaverse.ai')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ── AUTHENTICATION ───────────────────────────────────────────────────────
  @POST('/v1/auth/otp/request')
  Future<OtpRequestResponse> requestOtp(
    @Body() Map<String, dynamic> body,
  );

  @POST('/v1/auth/otp/verify')
  Future<AuthTokenResponse> verifyOtp(
    @Body() Map<String, dynamic> body,
  );

  @POST('/v1/auth/token')
  Future<AuthTokenResponse> staffTokenLogin(
    @Body() Map<String, dynamic> body,
  );

  @GET('/v1/auth/me')
  Future<User> getMe();

  // ── PONDS ────────────────────────────────────────────────────────────────
  @GET('/v1/ponds')
  Future<PondListResponse> getPonds([
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('district') String? district,
  ]);

  @GET('/v1/ponds/{pond_id}')
  Future<Pond> getPondDetails(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/events')
  Future<PondEventListResponse> getPondEvents(
    @Path('pond_id') String pondId, [
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  ]);

  @GET('/v1/ponds/{pond_id}/risk')
  Future<PondRisk> getPondRisk(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/forecast/do')
  Future<DOForecast> getDOForecast(@Path('pond_id') String pondId);

  @GET('/v1/ponds/{pond_id}/timeseries')
  Future<PondTimeseriesOut> getTimeseries(
    @Path('pond_id') String pondId, [
    @Query('parameter') String? parameter,
    @Query('from_ts') String? fromTs,
    @Query('to_ts') String? toTs,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  ]);

  // ── DATA QUALITY ─────────────────────────────────────────────────────────
  @GET('/v1/data-quality')
  Future<DataQualitySignal> getDataQuality([
    @Query('pond_id') String? pondId,
  ]);

  // ── LOGS ─────────────────────────────────────────────────────────────────
  @GET('/v1/logs')
  Future<LogListResponse> getLogs([
    @Query('pond_id') String? pondId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  ]);

  @POST('/v1/logs')
  Future<PondLog> createLog(@Body() Map<String, dynamic> body);

  // ── MEDIA ────────────────────────────────────────────────────────────────
  @POST('/v1/media/upload-url')
  Future<MediaUploadUrlResponse> getUploadUrl(
    @Body() Map<String, dynamic> body,
  );

  @POST('/v1/media/{media_id}/commit')
  Future<MediaCommitResponse> commitMedia(@Path('media_id') String mediaId);

  // ── ALERTS ───────────────────────────────────────────────────────────────
  @GET('/v1/alerts')
  Future<AlertListResponse> getAlerts([
    @Query('pond_id') String? pondId,
    @Query('severity') String? severity,
    @Query('acked') bool? acked,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  ]);

  @POST('/v1/alerts/{alert_id}/ack')
  Future<AlertAckOut> ackAlert(
    @Path('alert_id') String alertId, [
    @Body() AlertAckIn body = const AlertAckIn(),
  ]);

  @POST('/v1/alerts/{alert_id}/feedback')
  Future<AlertFeedbackOut> sendAlertFeedback(
    @Path('alert_id') String alertId,
    @Body() Map<String, dynamic> body,
  );

  // ── ADVISORIES & ASK ─────────────────────────────────────────────────────
  @GET('/v1/advisories')
  Future<AdvisoryListResponse> getAdvisories([
    @Query('district') String? district,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  ]);

  @POST('/v1/ask')
  Future<AskResponse> askAqua(@Body() AskRequest request);

  // ── TRANSLATION ──────────────────────────────────────────────────────────
  @POST('/v1/translate')
  Future<TranslationResponse> translate(@Body() TranslationRequest request);
}
