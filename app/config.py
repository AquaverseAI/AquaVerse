"""Application configuration — pydantic-settings driven, env-file backed."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    All configuration is read from environment variables (or .env file).
    Never commit .env — use .env.example as the template.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # -----------------------------------------------------------------------
    # Application
    # -----------------------------------------------------------------------
    app_env: Literal["development", "staging", "production"] = "development"
    app_debug: bool = False
    app_version: str = "0.1.0"
    app_secret_key: str = Field(..., min_length=32)
    internal_api_token: str = Field(..., min_length=32)
    # Extra LAN/staging origins (e.g. a dev machine's LAN IP) belong in the
    # CORS_ORIGINS env var, not hardcoded here — see .env.example.
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]

    # -----------------------------------------------------------------------
    # Database
    # -----------------------------------------------------------------------
    database_url: str = Field(
        ...,
        description="asyncpg DSN — must include +asyncpg driver prefix",
    )
    database_pool_size: int = 10
    database_max_overflow: int = 20
    database_echo: bool = False

    @field_validator("database_url")
    @classmethod
    def validate_db_url(cls, v: str) -> str:
        if "asyncpg" not in v and "aiosqlite" not in v:
            raise ValueError(
                "DATABASE_URL must use async driver (postgresql+asyncpg://... or sqlite+aiosqlite://...)"
            )
        return v

    # -----------------------------------------------------------------------
    # Redis
    # -----------------------------------------------------------------------
    redis_url: str = "redis://localhost:6379/0"
    redis_cache_ttl_seconds: int = 3600

    # -----------------------------------------------------------------------
    # Auth
    # -----------------------------------------------------------------------
    keycloak_url: str = "http://localhost:8080"
    keycloak_realm: str = "aquaverse"
    keycloak_client_id: str = "aquaverse-backend"
    keycloak_client_secret: str = ""
    jwt_algorithm: str = "RS256"
    jwt_public_key_path: str = "./certs/jwt_public.pem"
    otp_expiry_seconds: int = 300
    otp_length: int = 6
    sms_provider: Literal["mock", "fast2sms", "twilio"] = "mock"
    sms_api_key: str = ""

    # -----------------------------------------------------------------------
    # Rate limiting
    # -----------------------------------------------------------------------
    rate_limit_otp_per_minute: int = 5
    rate_limit_ask_per_minute: int = 30

    # -----------------------------------------------------------------------
    # IoT sensor ingest
    # -----------------------------------------------------------------------
    # Shared secret pond sensor units send back as `X-Device-Key`. Empty
    # (the default) leaves POST /v1/ingest/sensor/{pond_id} unauthenticated —
    # deliberately, so field devices that don't send any header aren't
    # blocked. Set this once devices are updated to send the header, before
    # exposing the ingest endpoint beyond a trusted LAN.
    iot_device_key: str = ""

    # -----------------------------------------------------------------------
    # Object storage
    # -----------------------------------------------------------------------
    s3_endpoint_url: str = "http://localhost:9000"
    s3_access_key_id: str = "minioadmin"
    s3_secret_access_key: str = ""
    s3_bucket_name: str = "aquaverse-media"
    s3_presign_expiry_seconds: int = 900

    # -----------------------------------------------------------------------
    # LLM / vLLM
    # -----------------------------------------------------------------------
    vllm_base_url: str = "http://localhost:8001"
    vllm_model: str = "Qwen/Qwen3-8B"
    vllm_lora_m1: str = "adapters/m1_chemistry"
    vllm_lora_m2: str = "adapters/m2_health"
    vllm_lora_m3: str = "adapters/m3_production"
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen3:8b-q4_K_M"

    # -----------------------------------------------------------------------
    # Numeric models
    # -----------------------------------------------------------------------
    model_artifacts_dir: str = "./ml/artifacts"
    default_model_version: str = "latest"

    # M3 production/feed decision engine (LightGBM, in-process — see
    # app/ml_inference/numeric/m3_engine.py). Directory containing
    # m3_decision_engine.py, its sim/ package, and models/*.txt boosters.
    m3_engine_dir: str = "./ml/serving/m3"

    # -----------------------------------------------------------------------
    # MLflow
    # -----------------------------------------------------------------------
    mlflow_tracking_uri: str = "http://localhost:5000"
    mlflow_experiment_name: str = "aquaverse-production"

    # -----------------------------------------------------------------------
    # Observability
    # -----------------------------------------------------------------------
    sentry_dsn: str = ""
    prometheus_metrics_path: str = "/metrics"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    log_format: Literal["json", "console"] = "json"

    # -----------------------------------------------------------------------
    # i18n
    # -----------------------------------------------------------------------
    bhashini_api_key: str = ""
    bhashini_user_id: str = ""
    bhashini_pipeline_id: str = ""
    ai4bharat_api_url: str = "https://api.ai4bharat.org/inference"

    # -----------------------------------------------------------------------
    # FCM
    # -----------------------------------------------------------------------
    fcm_service_account_path: str = "./certs/fcm_service_account.json"

    # -----------------------------------------------------------------------
    # Geo
    # -----------------------------------------------------------------------
    default_srid: int = 4326

    # -----------------------------------------------------------------------
    # Digital Twin
    # -----------------------------------------------------------------------
    # External 3D visualizer URL shown as a button on GET /v1/twin/{id}/view.
    # Empty by default — the button is omitted entirely when unset, rather
    # than rendering a link to a fixed dev-machine LAN IP. See .env.example.
    twin_visualizer_url: str = ""

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def is_development(self) -> bool:
        return self.app_env == "development"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return the cached Settings singleton. Use Depends(get_settings) in FastAPI."""
    return Settings()
