export interface paths {
    "/v1/auth/otp/request": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Request an OTP for farmer / staff login
         * @description Sends a 6-digit OTP to the farmer's registered phone number. In development mode the OTP is returned in the response as `dev_otp`. Rate-limited to 5 requests/minute per phone number.
         */
        post: operations["otp_request_v1_auth_otp_request_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/otp/verify": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Verify OTP and receive a JWT */
        post: operations["otp_verify_v1_auth_otp_verify_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/token": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Staff/admin login via username + password
         * @description Password-based login for staff and admin accounts. Farmers should use the OTP flow instead.
         */
        post: operations["token_v1_auth_token_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/me": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Return the current user's identity from the JWT */
        get: operations["me_v1_auth_me_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/logs": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List water quality logs
         * @description Keyset-paginated on `(recorded_at, id)` DESC. Pass the previous page's `next_cursor` back as `cursor` to fetch the next page; a `null` `next_cursor` means there is no further page.
         */
        get: operations["list_logs_v1_logs_get"];
        put?: never;
        /**
         * Submit a water quality log entry
         * @description Submit a water quality measurement for a pond. Accepts a `client_log_id` for idempotency — replays return `200` with the original record.
         */
        post: operations["create_log_v1_logs_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/media/upload-url": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Request a presigned upload URL
         * @description Returns a presigned S3/R2 PUT URL. The client uploads directly to object storage, then calls POST /v1/media/{media_id}/commit to finalise.
         */
        post: operations["media_upload_url_v1_media_upload_url_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/media/{media_id}/commit": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Commit an uploaded media file
         * @description Mark an upload as committed after the client has PUT the file to the presigned URL. HEADs the real object in S3/MinIO first — never marks `committed` without confirming the object actually exists. Returns 409 if it can't be found or the store is unreachable.
         */
        post: operations["media_commit_v1_media__media_id__commit_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ingest/sensor/{pond_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Push a reading from a pond's IoT sensor unit
         * @description Webhook for pond-side sensor hardware — accepts the device's raw JSON shape (`ph`, `air_temperature`, `humidity`, `water_temperature`, `turbidity`) directly, no farmer/staff login required. Persisted as a `Log` row with `source="sensor"`, timestamped at server receipt time, and immediately visible via GET /v1/logs and GET /v1/ponds/{pond_id}/timeseries. Optionally gated by a shared `X-Device-Key` header — see app/config.py.
         */
        post: operations["ingest_sensor_reading_v1_ingest_sensor__pond_id__post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List accessible ponds
         * @description Real keyset pagination — sorted by created_at DESC, id DESC.
         *
         *     Scoping:
         *       * admin — unrestricted, or filtered to `district` if given.
         *       * staff — filtered to `district` (validated via rbac.require_district)
         *         if given, else defaulted to the caller's own district claim; a
         *         staff token with no district claim gets an empty page (fail closed).
         *       * farmer — always scoped to ponds they own; `district` is ignored.
         */
        get: operations["list_ponds_v1_ponds_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get pond details */
        get: operations["get_pond_v1_ponds__pond_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}/timeseries": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get time-series data for a pond parameter
         * @description Returns hourly aggregated time-series for a single water quality parameter. 12-month, 6-parameter hourly queries must return in <300ms p95.
         */
        get: operations["get_pond_timeseries_v1_ponds__pond_id__timeseries_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}/events": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get event timeline for a pond
         * @description Synthesizes events from real Log rows.
         *
         *     There is no dedicated events table. `Alert` (app/db/models/alert.py) is a
         *     real table but nothing populates it yet — raising real alerts is P2.1's
         *     job. The alert-sourced half of this endpoint's `event_type` space is
         *     intentionally deferred, not forgotten; today every event is
         *     `event_type="log"`.
         */
        get: operations["get_pond_events_v1_ponds__pond_id__events_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}/risk": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get current risk score for a pond
         * @description Returns a composite risk score (0–1) from the real M2 LightGBM mortality-risk booster, with real per-feature SHAP attributions. This model predicts environmental-stress-driven mortality risk only — NOT a disease/pathogen classifier (see app/ml_inference/numeric/m2_risk_engine.py module docstring). Suppression state is always visible.
         */
        get: operations["get_pond_risk_v1_ponds__pond_id__risk_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/risk/worklist": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Risk worklist for staff — all ponds ranked by risk
         * @description Ranks every pond visible to the caller by the real M2 risk score, descending. Computed live, in-process, per request — fine at current demo scale, but does NOT scale to a large ward/district: a real deployment would need to pre-compute/cache these scores (e.g. a periodic job writing to a risk-scores table) rather than scoring every pond synchronously inside the request. Because ranking is computed fresh per request rather than sourced from a stable DB sort key, this endpoint uses a simple offset-encoded cursor (core.pagination.encode_cursor/decode_cursor) instead of the keyset-pagination convention used elsewhere in this module — keyset pagination requires a stable persisted ordering to page against, which an in-request live ranking doesn't have.
         */
        get: operations["get_risk_worklist_v1_risk_worklist_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}/forecast/do": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Dissolved oxygen forecast with uncertainty bands
         * @description Returns a dissolved oxygen forecast (default 24h, up to 168h) with 10th/50th/90th percentile bands computed from this pond's own real historical DO readings, bucketed by hour-of-day. This is an honest empirical seasonal-naive baseline, NOT a trained temporal model — no TCN/TFT/PatchTST exists anywhere in this repo (see app/ml_inference/numeric/do_forecast.py module docstring). RULE: Bare point estimates are forbidden — bands are always returned.
         */
        get: operations["get_do_forecast_v1_ponds__pond_id__forecast_do_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/models": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List registered ML models
         * @description Real keyset pagination over `model_registry`, same shape as
         *     `list_ponds`. `ensure_active_model_registered` keeps that table
         *     synced to whatever M2 bundle is actually loaded before every read —
         *     see app/ml_inference/model_registry_sync.py for why this can't just
         *     be a one-time seed.
         */
        get: operations["list_models_v1_models_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/models/metrics": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Operational metrics for the model serving layer
         * @description Exposes `rejected_attempts` — the count of LLM responses that were rejected because they contained a numeral not present in the quantitative tool-call payload. This MUST read 0 in steady state.
         */
        get: operations["get_model_metrics_v1_models_metrics_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/models/drift": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Model drift reports
         * @description Real PSI-based drift signal for the one actively-served model — see
         *     app/ml_inference/drift.py for what this does and doesn't measure.
         *     `cursor`/`limit` are accepted for response-shape compatibility; there
         *     is exactly one active model to report on, so this never actually
         *     paginates.
         */
        get: operations["get_model_drift_v1_models_drift_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/data-quality": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Data quality signals across all ponds
         * @description Real signals over real `Log` rows from the last 7 days, scoped the
         *     same way GET /v1/ponds is: a specific `pond_id` if given, else a
         *     staff caller's own district (fail closed if their token has none),
         *     else — for admin — every pond.
         *
         *     `sensor_offline_ponds` reuses `_STALE_LOG_THRESHOLD_HOURS`, the exact
         *     threshold Alerts' blind-state suppression already uses (see that
         *     constant's docstring) — one "how old is too old" answer per
         *     codebase, not a second invented number.
         */
        get: operations["get_data_quality_v1_data_quality_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ponds/{pond_id}/multimodal_risk": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Compute multimodal risk score using PyTorch Fusion (M2)
         * @description Fuses Tabular Sensor Data with Image Concept Bottleneck outputs.
         */
        post: operations["compute_multimodal_risk_v1_ponds__pond_id__multimodal_risk_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/alerts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List alerts
         * @description Returns alerts with their suppression state always visible. If suppressed=True, suppression_reason explains why (e.g. 'Sensor offline > 4h').
         */
        get: operations["list_alerts_v1_alerts_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/alerts/{alert_id}/ack": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Acknowledge an alert */
        post: operations["ack_alert_v1_alerts__alert_id__ack_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/alerts/{alert_id}/feedback": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Submit feedback on an alert */
        post: operations["alert_feedback_v1_alerts__alert_id__feedback_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reason": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * [INTERNAL] Generate a reasoned advisory from the LLM layer
         * @description Internal-only endpoint (requires X-Internal-Token header). The LLM output is validated by number_validator.py before being returned. Any numeral in the LLM response that was not present in the tool_call_payload causes rejection and regeneration (server-side, in the request path).
         */
        post: operations["reason_v1_reason_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/ask": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Ask a question about your pond (farmer-facing)
         * @description Farmer-facing conversational Q&A. Routes through the full two-layer pipeline: quantitative scores are fetched first, then the reasoning layer generates an explanation using only those numbers. Rate-limited to 30 requests/minute.
         */
        post: operations["ask_v1_ask_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/advisories": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List published advisories
         * @description Advisories that have not expired. target_district=None ('all-district') advisories are always included alongside any district filter — a state-wide advisory is still relevant to a farmer viewing their own district.
         */
        get: operations["list_advisories_v1_advisories_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/advisories/broadcast": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Broadcast an advisory to farmers (staff only) */
        post: operations["broadcast_advisory_v1_advisories_broadcast_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/advisories/multimodal_reason": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Generate farmer-facing reasoning from GMU output */
        post: operations["multimodal_reason_v1_advisories_multimodal_reason_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/twin/{pond_id}/state": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get the current digital twin state for a pond
         * @description Returns the current state vector. RULE: The response is identical whether backed by real sensors or the simulator. The source is never revealed in the response schema — only suppressed/suppression_reason hint at data quality, and are always populated when the pond is blind-state.
         */
        get: operations["get_twin_state_v1_twin__pond_id__state_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/twin/{pond_id}/view": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get a visual dashboard of the digital twin state */
        get: operations["get_twin_view_v1_twin__pond_id__view_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/twin/{pond_id}/whatif": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Run a what-if simulation
         * @description Applies the given scenario deltas to the current twin state and returns the simulated outcome. risk_delta is computed by re-running the real M2 risk-scoring model (app/ml_inference/numeric/m2_risk_engine.py) against the pond's actual recent chemistry with the scenario's deltas applied — not a hardcoded estimate. delta_feed_rate_pct currently has no effect: no feed-log ingestion pipeline exists to translate a feed-rate change into a chemistry or risk effect.
         */
        post: operations["whatif_v1_twin__pond_id__whatif_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/geo/ponds": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * GeoJSON FeatureCollection of all accessible ponds
         * @description Returns a GeoJSON FeatureCollection. Properties include risk_score and suppressed flag. Ponds with no recorded location (Pond.geom) are omitted — never plotted with a fabricated coordinate. Spatial queries use real PostGIS ST_DWithin (geography cast, so within_km is an accurate great-circle distance, not a planar approximation).
         */
        get: operations["geo_ponds_v1_geo_ponds_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/geo/clusters": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Spatial outbreak clusters
         * @description Detects spatial clusters of ponds with a recent alert using DBSCAN (real, standard density-based clustering — see app/geo/clustering.py's module docstring for why this is not literally the space-time scan statistic (SaTScan) the original spec named, and why no p_value is returned). Each cluster includes an approximate circular bounding polygon and the affected pond IDs.
         */
        get: operations["geo_clusters_v1_geo_clusters_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/translate": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Translate text using IndicTrans2 / Bhashini
         * @description Translate text between Indian languages via the real Bhashini ULCA pipeline. Results are cached in Redis by hash of (source_lang, target_lang, text).
         */
        post: operations["translate_v1_translate_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reports/export": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Export pond data as PDF or XLSX
         * @description Enqueues a real async export job on the ARQ worker (app/reporting/jobs.py). Poll GET /v1/reports/export/{job_id} for status and a download URL once it's ready.
         */
        get: operations["export_report_v1_reports_export_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reports/export/{job_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Poll a report export job
         * @description Real status of a previously queued export job, with a presigned download URL once it has completed.
         */
        get: operations["get_export_status_v1_reports_export__job_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Landing Page */
        get: operations["root__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/health": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Health check */
        get: operations["health_v1_health_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
}
export type webhooks = Record<string, never>;
export interface components {
    schemas: {
        /** AdvisoryOut */
        AdvisoryOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /** Title */
            title: string;
            /** Body */
            body: string;
            /** Language */
            language: string;
            /** Target District */
            target_district?: string | null;
            /** Target Species */
            target_species?: string | null;
            /** Severity */
            severity?: string | null;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Expires At */
            expires_at?: string | null;
        };
        /** AlertAckIn */
        AlertAckIn: {
            /** Note */
            note?: string | null;
            /** Client Log Id */
            client_log_id?: string | null;
        };
        /** AlertAckOut */
        AlertAckOut: {
            /**
             * Alert Id
             * Format: uuid
             */
            alert_id: string;
            /** Acked */
            acked: boolean;
            /**
             * Acked At
             * Format: date-time
             */
            acked_at: string;
            /** Message */
            message: string;
        };
        /** AlertFeedbackIn */
        AlertFeedbackIn: {
            /** Useful */
            useful: boolean;
            /** Comment */
            comment?: string | null;
            /**
             * False Positive
             * @default false
             */
            false_positive: boolean;
        };
        /** AlertFeedbackOut */
        AlertFeedbackOut: {
            /**
             * Alert Id
             * Format: uuid
             */
            alert_id: string;
            /** Feedback Recorded */
            feedback_recorded: boolean;
            /** Message */
            message: string;
        };
        /** AlertOut */
        AlertOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Pond Name */
            pond_name?: string | null;
            /** Alert Type */
            alert_type: string;
            /** Severity */
            severity: string;
            /** Title */
            title: string;
            /** Message */
            message: string;
            /** Parameter */
            parameter?: string | null;
            /** Measured Value */
            measured_value?: number | null;
            /** Threshold Value */
            threshold_value?: number | null;
            /**
             * Suppressed
             * @description True if this alert is suppressed due to blind state (e.g. sensor offline). Always surfaced — never hidden from the client.
             */
            suppressed: boolean;
            /**
             * Suppression Reason
             * @description Why the alert is suppressed. Always provided when suppressed=True.
             */
            suppression_reason?: string | null;
            /** Acked */
            acked: boolean;
            /** Acked At */
            acked_at?: string | null;
            /** Risk Score */
            risk_score?: number | null;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
        };
        /** AskIn */
        AskIn: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Question */
            question: string;
            /**
             * Language
             * @description BCP-47 language code
             * @default ta
             */
            language: string;
            /**
             * Include Tts
             * @description Return TTS audio URL in response
             * @default false
             */
            include_tts: boolean;
        };
        /** AskOut */
        AskOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Question */
            question: string;
            /** Answer */
            answer: string;
            /** Language */
            language: string;
            /** Tts Url */
            tts_url?: string | null;
            /**
             * Generated At
             * Format: date-time
             */
            generated_at: string;
            /** Rejected Attempts This Request */
            rejected_attempts_this_request: number;
        };
        /** Body_compute_multimodal_risk_v1_ponds__pond_id__multimodal_risk_post */
        Body_compute_multimodal_risk_v1_ponds__pond_id__multimodal_risk_post: {
            /** Image */
            image?: string | null;
        };
        /** BroadcastIn */
        BroadcastIn: {
            /** Title */
            title: string;
            /** Body */
            body: string;
            /**
             * Language
             * @default ta
             */
            language: string;
            /** Target District */
            target_district?: string | null;
            /** Target Species */
            target_species?: string | null;
            /**
             * Severity
             * @description info | warning | critical
             */
            severity?: string | null;
            /** Expires At */
            expires_at?: string | null;
            /** Client Log Id */
            client_log_id?: string | null;
        };
        /** CursorPage[AdvisoryOut] */
        CursorPage_AdvisoryOut_: {
            /** Items */
            items: components["schemas"]["AdvisoryOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[AlertOut] */
        CursorPage_AlertOut_: {
            /** Items */
            items: components["schemas"]["AlertOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[DriftReport] */
        CursorPage_DriftReport_: {
            /** Items */
            items: components["schemas"]["DriftReport"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[LogOut] */
        CursorPage_LogOut_: {
            /** Items */
            items: components["schemas"]["LogOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[ModelOut] */
        CursorPage_ModelOut_: {
            /** Items */
            items: components["schemas"]["ModelOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[PondEventOut] */
        CursorPage_PondEventOut_: {
            /** Items */
            items: components["schemas"]["PondEventOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[PondOut] */
        CursorPage_PondOut_: {
            /** Items */
            items: components["schemas"]["PondOut"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** CursorPage[WorklistItem] */
        CursorPage_WorklistItem_: {
            /** Items */
            items: components["schemas"]["WorklistItem"][];
            /**
             * Next Cursor
             * @description Opaque cursor for the next page. None when this is the last page.
             */
            next_cursor?: string | null;
            /**
             * Total Hint
             * @description Optional approximate total — use for progress bars only, not for exact counts (may be stale).
             */
            total_hint?: number | null;
        };
        /** DataQualityOut */
        DataQualityOut: {
            /** Pond Id */
            pond_id?: string | null;
            /** Total Logs Last 7D */
            total_logs_last_7d: number;
            /** Missing Parameter Rates */
            missing_parameter_rates: {
                [key: string]: number;
            };
            /** Sensor Offline Ponds */
            sensor_offline_ponds: number;
            /** Stale Threshold Hours */
            stale_threshold_hours: number;
            /**
             * Evaluated At
             * Format: date-time
             */
            evaluated_at: string;
        };
        /** DriftReport */
        DriftReport: {
            /** Model Name */
            model_name: string;
            /** Model Version */
            model_version: string;
            /** Feature Drift */
            feature_drift: {
                [key: string]: number;
            };
            /** Label Drift */
            label_drift?: number | null;
            /** Alert Threshold */
            alert_threshold: number;
            /** Drift Detected */
            drift_detected: boolean;
            /**
             * Evaluated At
             * Format: date-time
             */
            evaluated_at: string;
        };
        /** ForecastOut */
        ForecastOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Parameter */
            parameter: string;
            /** Horizon Hours */
            horizon_hours: number;
            /** Points */
            points: components["schemas"]["ForecastPoint"][];
            /** Model Version */
            model_version: string;
            /**
             * Generated At
             * Format: date-time
             */
            generated_at: string;
            /**
             * Uncertainty Note
             * @default Forecast bands represent the 10th–90th percentile range from the ensemble. Do not use the median alone for management decisions.
             */
            uncertainty_note: string;
        };
        /** ForecastPoint */
        ForecastPoint: {
            /**
             * Forecasted At
             * Format: date-time
             */
            forecasted_at: string;
            /**
             * P10
             * @description 10th percentile (lower bound)
             */
            p10: number;
            /**
             * P50
             * @description Median forecast
             */
            p50: number;
            /**
             * P90
             * @description 90th percentile (upper bound)
             */
            p90: number;
        };
        /** HTTPValidationError */
        HTTPValidationError: {
            /** Detail */
            detail?: components["schemas"]["ValidationError"][];
        };
        /** LogIn */
        LogIn: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * Recorded At
             * Format: date-time
             * @description ISO 8601 with timezone offset
             */
            recorded_at: string;
            /**
             * Client Log Id
             * @description Client-generated idempotency key. Replays with the same key return the original record with HTTP 200 instead of creating a duplicate.
             */
            client_log_id?: string | null;
            /** Temperature C */
            temperature_c?: number | null;
            /** Dissolved Oxygen Mgl */
            dissolved_oxygen_mgl?: number | null;
            /** Ph */
            ph?: number | null;
            /** Salinity Ppt */
            salinity_ppt?: number | null;
            /** Ammonia Nh3 Mgl */
            ammonia_nh3_mgl?: number | null;
            /** Turbidity Ntu */
            turbidity_ntu?: number | null;
            /** Nitrite Mgl */
            nitrite_mgl?: number | null;
            /** Nitrate Mgl */
            nitrate_mgl?: number | null;
            /** Alkalinity Mgl */
            alkalinity_mgl?: number | null;
            /** Hardness Mgl */
            hardness_mgl?: number | null;
            /** Notes */
            notes?: string | null;
        };
        /** LogOut */
        LogOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * Recorded At
             * Format: date-time
             */
            recorded_at: string;
            /** Temperature C */
            temperature_c?: number | null;
            /** Dissolved Oxygen Mgl */
            dissolved_oxygen_mgl?: number | null;
            /** Ph */
            ph?: number | null;
            /** Salinity Ppt */
            salinity_ppt?: number | null;
            /** Ammonia Nh3 Mgl */
            ammonia_nh3_mgl?: number | null;
            /** Turbidity Ntu */
            turbidity_ntu?: number | null;
            /** Nitrite Mgl */
            nitrite_mgl?: number | null;
            /** Nitrate Mgl */
            nitrate_mgl?: number | null;
            /** Alkalinity Mgl */
            alkalinity_mgl?: number | null;
            /** Hardness Mgl */
            hardness_mgl?: number | null;
            /** Air Temperature C */
            air_temperature_c?: number | null;
            /** Humidity Pct */
            humidity_pct?: number | null;
            /** Source */
            source: string;
            /** Client Log Id */
            client_log_id?: string | null;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
        };
        /** MediaCommitIn */
        MediaCommitIn: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Client Log Id */
            client_log_id?: string | null;
        };
        /** MediaOut */
        MediaOut: {
            /**
             * Media Id
             * Format: uuid
             */
            media_id: string;
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Filename */
            filename: string;
            /** Mime Type */
            mime_type: string;
            /** Size Bytes */
            size_bytes?: number | null;
            /** Status */
            status: string;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
        };
        /** MediaUploadUrlIn */
        MediaUploadUrlIn: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Filename */
            filename: string;
            /**
             * Mime Type
             * @description e.g. image/jpeg, video/mp4
             */
            mime_type: string;
            /** Size Bytes */
            size_bytes?: number | null;
            /** Client Log Id */
            client_log_id?: string | null;
        };
        /** MediaUploadUrlOut */
        MediaUploadUrlOut: {
            /**
             * Media Id
             * Format: uuid
             */
            media_id: string;
            /**
             * Upload Url
             * @description Presigned S3/R2 PUT URL, valid for 15 minutes
             */
            upload_url: string;
            /**
             * Expires At
             * Format: date-time
             */
            expires_at: string;
        };
        /**
         * ModelMetricsOut
         * @description Operational metrics for the serving layer.
         *
         *     rejected_attempts: number of LLM responses rejected because they contained
         *     a numeral not present in the quantitative tool-call payload.
         *     MUST read 0 in steady state.
         */
        ModelMetricsOut: {
            /**
             * Rejected Attempts
             * @description Count of LLM responses rejected due to numeral mismatch. Non-zero values indicate a problem with the reasoning layer.
             */
            rejected_attempts: number;
            /** Total Requests */
            total_requests: number;
            /** Avg Latency Ms */
            avg_latency_ms: number;
            /** P95 Latency Ms */
            p95_latency_ms: number;
            /** P99 Latency Ms */
            p99_latency_ms: number;
            /** Cache Hit Rate */
            cache_hit_rate: number;
            /**
             * As Of
             * Format: date-time
             */
            as_of: string;
        };
        /** ModelOut */
        ModelOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /** Name */
            name: string;
            /** Model Type */
            model_type: string;
            /** Version */
            version: string;
            /** Is Active */
            is_active: boolean;
            /** Dataset Hash */
            dataset_hash: string;
            /** Metrics */
            metrics?: {
                [key: string]: unknown;
            } | null;
            /** Promoted At */
            promoted_at?: string | null;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
        };
        /** MultimodalReasonIn */
        MultimodalReasonIn: {
            /** Calibrated Risk Score */
            calibrated_risk_score: number;
            /** Gate Vision */
            gate_vision: number;
            /** Gate Temporal */
            gate_temporal: number;
            /** Concept Activations */
            concept_activations: {
                [key: string]: number;
            };
            /** Stress Hours */
            stress_hours: number;
            /** Stocking Density */
            stocking_density?: number | null;
        };
        /** MultimodalReasonOut */
        MultimodalReasonOut: {
            /** Advisory Text */
            advisory_text: string;
        };
        /** OtpRequestIn */
        OtpRequestIn: {
            /**
             * Phone
             * @description E.164 format phone number, e.g. +919876543210
             */
            phone: string;
            /**
             * Purpose
             * @description login | register
             * @default login
             */
            purpose: string;
        };
        /** OtpRequestOut */
        OtpRequestOut: {
            /** Message */
            message: string;
            /** Expires In Seconds */
            expires_in_seconds: number;
            /** Request Id */
            request_id: string;
            /**
             * Dev Otp
             * @description Only present in development mode. Use this OTP to test without SMS.
             */
            dev_otp?: string | null;
        };
        /** OtpVerifyIn */
        OtpVerifyIn: {
            /** Request Id */
            request_id: string;
            /** Phone */
            phone: string;
            /** Otp */
            otp: string;
        };
        /** OtpVerifyOut */
        OtpVerifyOut: {
            /** Access Token */
            access_token: string;
            /**
             * Token Type
             * @default bearer
             */
            token_type: string;
            /** Expires In */
            expires_in: number;
            /** Role */
            role: string;
            /** Name */
            name: string;
            /** Is New User */
            is_new_user: boolean;
        };
        /** PondEventOut */
        PondEventOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /** Event Type */
            event_type: string;
            /** Title */
            title: string;
            /**
             * Occurred At
             * Format: date-time
             */
            occurred_at: string;
            /** Severity */
            severity?: string | null;
            /** Metadata */
            metadata?: {
                [key: string]: unknown;
            } | null;
        };
        /** PondOut */
        PondOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /** Name */
            name: string;
            /** District */
            district: string;
            /** Taluk */
            taluk?: string | null;
            /** Village */
            village?: string | null;
            /** Area Hectares */
            area_hectares?: number | null;
            /** Depth Meters */
            depth_meters?: number | null;
            /** Species */
            species?: string | null;
            /**
             * Owner User Id
             * Format: uuid
             */
            owner_user_id: string;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /**
             * Updated At
             * Format: date-time
             */
            updated_at: string;
        };
        /** PondTimeseriesOut */
        PondTimeseriesOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Parameter */
            parameter: string;
            /** Points */
            points: components["schemas"]["PondTimeseriesPoint"][];
            /** Next Cursor */
            next_cursor?: string | null;
        };
        /** PondTimeseriesPoint */
        PondTimeseriesPoint: {
            /**
             * Recorded At
             * Format: date-time
             */
            recorded_at: string;
            /** Temperature C */
            temperature_c?: number | null;
            /** Dissolved Oxygen Mgl */
            dissolved_oxygen_mgl?: number | null;
            /** Ph */
            ph?: number | null;
            /** Salinity Ppt */
            salinity_ppt?: number | null;
            /** Ammonia Nh3 Mgl */
            ammonia_nh3_mgl?: number | null;
            /** Turbidity Ntu */
            turbidity_ntu?: number | null;
            /** Air Temperature C */
            air_temperature_c?: number | null;
            /** Humidity Pct */
            humidity_pct?: number | null;
        };
        /** ReasonIn */
        ReasonIn: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * Adapter
             * @description LoRA adapter to use: m1_chemistry | m2_health | m3_production
             */
            adapter: string;
            tool_call_payload: components["schemas"]["ToolCallPayload"];
            /**
             * Context
             * @description Additional context text (farmer's question, recent observations)
             */
            context?: string | null;
            /**
             * Language
             * @description BCP-47 language code
             * @default ta
             */
            language: string;
            /**
             * Max Retries
             * @default 3
             */
            max_retries: number;
        };
        /** ReasonOut */
        ReasonOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Adapter */
            adapter: string;
            /**
             * Explanation
             * @description Explanation from the reasoning layer. Health/disease language uses 'consistent with X, confirm by Y' phrasing — never a confident diagnosis.
             */
            explanation: string;
            /**
             * Rejected Attempts This Request
             * @description Number of times the validator rejected a response for this request.
             */
            rejected_attempts_this_request: number;
            /** Model Version */
            model_version: string;
            /**
             * Generated At
             * Format: date-time
             */
            generated_at: string;
        };
        /** RiskOut */
        RiskOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * Risk Score
             * @description 0–1 composite risk score
             */
            risk_score: number;
            /** Risk Level */
            risk_level: string;
            /**
             * Components
             * @description Per-component risk scores: chemistry, health, production
             */
            components: {
                [key: string]: number;
            };
            /** Shap Contributions */
            shap_contributions: components["schemas"]["ShapContribution"][];
            /** Model Version */
            model_version: string;
            /**
             * Scored At
             * Format: date-time
             */
            scored_at: string;
            /**
             * Suppressed
             * @description True if sensor data is stale / in blind state. Score may be unreliable — always surface this to the user.
             */
            suppressed: boolean;
            /** Suppression Reason */
            suppression_reason?: string | null;
        };
        /**
         * SensorIngestIn
         * @description Raw payload shape as pushed by the pond sensor unit's firmware.
         *
         *     Field names intentionally mirror the device's own JSON keys (not the
         *     `_c` / `_mgl` / `_ntu`-suffixed DB column names used elsewhere in this
         *     module) — this schema accepts exactly what the hardware already sends,
         *     no firmware changes required.
         */
        SensorIngestIn: {
            /** Ph */
            ph: number;
            /**
             * Air Temperature
             * @description Ambient air temperature, °C
             */
            air_temperature: number;
            /**
             * Humidity
             * @description Relative humidity, %
             */
            humidity: number;
            /**
             * Water Temperature
             * @description Water temperature, °C
             */
            water_temperature: number;
            /**
             * Turbidity
             * @description Turbidity, NTU
             */
            turbidity: number;
        };
        /** SensorIngestOut */
        SensorIngestOut: {
            /**
             * Id
             * Format: uuid
             */
            id: string;
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * Recorded At
             * Format: date-time
             */
            recorded_at: string;
            /** Ph */
            ph?: number | null;
            /** Air Temperature C */
            air_temperature_c?: number | null;
            /** Humidity Pct */
            humidity_pct?: number | null;
            /** Water Temperature C */
            water_temperature_c?: number | null;
            /** Turbidity Ntu */
            turbidity_ntu?: number | null;
            /** Source */
            source: string;
        };
        /** ShapContribution */
        ShapContribution: {
            /** Feature */
            feature: string;
            /** Value */
            value: number;
            /** Shap Value */
            shap_value: number;
            /** Direction */
            direction: string;
        };
        /**
         * StateVector
         * @description Current state of the digital twin for a pond.
         *     Schema is identical whether backed by real sensors or the simulator.
         */
        StateVector: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /**
             * As Of
             * Format: date-time
             */
            as_of: string;
            /** Temperature C */
            temperature_c?: number | null;
            /** Dissolved Oxygen Mgl */
            dissolved_oxygen_mgl?: number | null;
            /** Ph */
            ph?: number | null;
            /** Salinity Ppt */
            salinity_ppt?: number | null;
            /** Ammonia Nh3 Mgl */
            ammonia_nh3_mgl?: number | null;
            /** Turbidity Ntu */
            turbidity_ntu?: number | null;
            /** Biomass Kg Estimated */
            biomass_kg_estimated?: number | null;
            /** Fcr Estimated */
            fcr_estimated?: number | null;
            /**
             * Suppressed
             * @description True if the state vector is in blind state. Always surfaced — never hidden.
             */
            suppressed: boolean;
            /** Suppression Reason */
            suppression_reason?: string | null;
        };
        /** TokenIn */
        TokenIn: {
            /**
             * Grant Type
             * @description password | refresh_token
             * @default password
             */
            grant_type: string;
            /** Username */
            username?: string | null;
            /** Password */
            password?: string | null;
            /** Refresh Token */
            refresh_token?: string | null;
        };
        /** TokenOut */
        TokenOut: {
            /** Access Token */
            access_token: string;
            /** Refresh Token */
            refresh_token?: string | null;
            /**
             * Token Type
             * @default bearer
             */
            token_type: string;
            /** Expires In */
            expires_in: number;
            /** Role */
            role: string;
            /** Name */
            name: string;
            /** District */
            district?: string | null;
        };
        /**
         * ToolCallPayload
         * @description Quantitative output that must be passed to the reasoning layer.
         *     Every numeral the LLM is allowed to mention must appear here.
         */
        ToolCallPayload: {
            /** Risk Score */
            risk_score: number;
            /** Risk Level */
            risk_level: string;
            /** Components */
            components: {
                [key: string]: number;
            };
            /** Shap Contributions */
            shap_contributions: {
                [key: string]: unknown;
            }[];
            /** Forecast P10 */
            forecast_p10?: number | null;
            /** Forecast P50 */
            forecast_p50?: number | null;
            /** Forecast P90 */
            forecast_p90?: number | null;
            /** Raw Measurements */
            raw_measurements?: {
                [key: string]: number | null;
            };
        };
        /** TranslateIn */
        TranslateIn: {
            /** Text */
            text: string;
            /**
             * Source Lang
             * @description BCP-47 language code, e.g. 'en', 'ta'
             * @default en
             */
            source_lang: string;
            /**
             * Target Lang
             * @description BCP-47 language code, e.g. 'ta', 'te', 'ml'
             */
            target_lang: string;
            /**
             * Include Tts
             * @description Return TTS audio URL for translated text
             * @default false
             */
            include_tts: boolean;
        };
        /** TranslateOut */
        TranslateOut: {
            /** Source Lang */
            source_lang: string;
            /** Target Lang */
            target_lang: string;
            /** Source Text */
            source_text: string;
            /** Translated Text */
            translated_text: string;
            /**
             * Cached
             * @description True if served from Redis translation cache
             */
            cached: boolean;
            /**
             * Tts Url
             * @description URL to TTS audio file (if requested)
             */
            tts_url?: string | null;
            /**
             * Translated At
             * Format: date-time
             */
            translated_at: string;
        };
        /** UserMeOut */
        UserMeOut: {
            /** Sub */
            sub: string;
            /** Role */
            role: string;
            /** Name */
            name?: string | null;
            /** District */
            district?: string | null;
            /**
             * Pond Ids
             * @default []
             */
            pond_ids: string[];
        };
        /** ValidationError */
        ValidationError: {
            /** Location */
            loc: (string | number)[];
            /** Message */
            msg: string;
            /** Error Type */
            type: string;
            /** Input */
            input?: unknown;
            /** Context */
            ctx?: Record<string, never>;
        };
        /**
         * WhatIfOut
         * @description Simulated state after applying the scenario.
         */
        WhatIfOut: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            scenario: components["schemas"]["WhatIfScenario"];
            simulated_state: components["schemas"]["StateVector"];
            /**
             * Risk Delta
             * @description Change in risk score relative to current baseline (positive = more risk)
             */
            risk_delta: number;
            /**
             * Generated At
             * Format: date-time
             */
            generated_at: string;
        };
        /**
         * WhatIfScenario
         * @description What-if simulation inputs.
         */
        WhatIfScenario: {
            /** Delta Temperature C */
            delta_temperature_c?: number | null;
            /** Delta Dissolved Oxygen Mgl */
            delta_dissolved_oxygen_mgl?: number | null;
            /** Delta Salinity Ppt */
            delta_salinity_ppt?: number | null;
            /** Delta Feed Rate Pct */
            delta_feed_rate_pct?: number | null;
            /**
             * Horizon Hours
             * @default 24
             */
            horizon_hours: number;
        };
        /** WorklistItem */
        WorklistItem: {
            /**
             * Pond Id
             * Format: uuid
             */
            pond_id: string;
            /** Pond Name */
            pond_name: string;
            /** District */
            district: string;
            /** Risk Score */
            risk_score: number;
            /** Risk Level */
            risk_level: string;
            /** Suppressed */
            suppressed: boolean;
            /** Suppression Reason */
            suppression_reason?: string | null;
            /** Last Log At */
            last_log_at?: string | null;
        };
    };
    responses: never;
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
}
export type $defs = Record<string, never>;
export interface operations {
    otp_request_v1_auth_otp_request_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OtpRequestIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OtpRequestOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    otp_verify_v1_auth_otp_verify_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OtpVerifyIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OtpVerifyOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    token_v1_auth_token_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TokenIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    me_v1_auth_me_get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UserMeOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    list_logs_v1_logs_get: {
        parameters: {
            query?: {
                pond_id?: string | null;
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_LogOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    create_log_v1_logs_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LogIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LogOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    media_upload_url_v1_media_upload_url_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MediaUploadUrlIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MediaUploadUrlOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    media_commit_v1_media__media_id__commit_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                media_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MediaCommitIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MediaOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    ingest_sensor_reading_v1_ingest_sensor__pond_id__post: {
        parameters: {
            query?: never;
            header?: {
                "x-device-key"?: string | null;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SensorIngestIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SensorIngestOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    list_ponds_v1_ponds_get: {
        parameters: {
            query?: {
                district?: string | null;
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_PondOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_pond_v1_ponds__pond_id__get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PondOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_pond_timeseries_v1_ponds__pond_id__timeseries_get: {
        parameters: {
            query?: {
                parameter?: string;
                from_ts?: string | null;
                to_ts?: string | null;
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PondTimeseriesOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_pond_events_v1_ponds__pond_id__events_get: {
        parameters: {
            query?: {
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_PondEventOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_pond_risk_v1_ponds__pond_id__risk_get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RiskOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_risk_worklist_v1_risk_worklist_get: {
        parameters: {
            query?: {
                district?: string | null;
                risk_level?: string | null;
                cursor?: string | null;
                limit?: number;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_WorklistItem_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_do_forecast_v1_ponds__pond_id__forecast_do_get: {
        parameters: {
            query?: {
                horizon_hours?: number;
            };
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ForecastOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    list_models_v1_models_get: {
        parameters: {
            query?: {
                cursor?: string | null;
                limit?: number;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_ModelOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_model_metrics_v1_models_metrics_get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ModelMetricsOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_model_drift_v1_models_drift_get: {
        parameters: {
            query?: {
                cursor?: string | null;
                limit?: number;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_DriftReport_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_data_quality_v1_data_quality_get: {
        parameters: {
            query?: {
                pond_id?: string | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DataQualityOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    compute_multimodal_risk_v1_ponds__pond_id__multimodal_risk_post: {
        parameters: {
            query?: {
                image_age_hours?: number;
            };
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: {
            content: {
                "multipart/form-data": components["schemas"]["Body_compute_multimodal_risk_v1_ponds__pond_id__multimodal_risk_post"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": unknown;
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    list_alerts_v1_alerts_get: {
        parameters: {
            query?: {
                pond_id?: string | null;
                district?: string | null;
                severity?: string | null;
                acked?: boolean | null;
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_AlertOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    ack_alert_v1_alerts__alert_id__ack_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                alert_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AlertAckIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AlertAckOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    alert_feedback_v1_alerts__alert_id__feedback_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                alert_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AlertFeedbackIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AlertFeedbackOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    reason_v1_reason_post: {
        parameters: {
            query?: never;
            header?: {
                "X-Internal-Token"?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ReasonIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReasonOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    ask_v1_ask_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AskIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AskOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    list_advisories_v1_advisories_get: {
        parameters: {
            query?: {
                district?: string | null;
                cursor?: string | null;
                limit?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CursorPage_AdvisoryOut_"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    broadcast_advisory_v1_advisories_broadcast_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["BroadcastIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdvisoryOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    multimodal_reason_v1_advisories_multimodal_reason_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MultimodalReasonIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MultimodalReasonOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_twin_state_v1_twin__pond_id__state_get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["StateVector"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_twin_view_v1_twin__pond_id__view_get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "text/html": string;
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    whatif_v1_twin__pond_id__whatif_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["WhatIfScenario"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WhatIfOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    geo_ponds_v1_geo_ponds_get: {
        parameters: {
            query?: {
                district?: string | null;
                risk_level?: string | null;
                /** @description Filter ponds within this many km of a given point (requires lat/lon params) */
                within_km?: number | null;
                lat?: number | null;
                lon?: number | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        [key: string]: unknown;
                    };
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    geo_clusters_v1_geo_clusters_get: {
        parameters: {
            query?: {
                district?: string | null;
                days_back?: number;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        [key: string]: unknown;
                    };
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    translate_v1_translate_post: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TranslateIn"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TranslateOut"];
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    export_report_v1_reports_export_get: {
        parameters: {
            query?: {
                pond_id?: string | null;
                district?: string | null;
                /** @description pdf | xlsx */
                format?: string;
                /** @description YYYY-MM-DD */
                from_date?: string | null;
                /** @description YYYY-MM-DD */
                to_date?: string | null;
            };
            header?: {
                authorization?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        [key: string]: unknown;
                    };
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    get_export_status_v1_reports_export__job_id__get: {
        parameters: {
            query?: never;
            header?: {
                authorization?: string;
            };
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        [key: string]: unknown;
                    };
                };
            };
            /** @description Validation Error */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HTTPValidationError"];
                };
            };
        };
    };
    root__get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "text/html": string;
                };
            };
        };
    };
    health_v1_health_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        [key: string]: string;
                    };
                };
            };
        };
    };
}
