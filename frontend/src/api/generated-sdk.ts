export interface paths {
    "/v1/auth/token": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Staff login */
        post: operations["loginToken"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/otp/request": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Request OTP for farmer phone login */
        post: operations["requestOTP"];
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
        /** Verify OTP code and issue JWT token */
        post: operations["verifyOTP"];
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
        /** Paginated list of ponds */
        get: operations["listPonds"];
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
        /** Full pond detail */
        get: operations["getPondDetail"];
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
        /** Multi-parameter timeseries */
        get: operations["getPondTimeseries"];
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
        /** Annotation events stream */
        get: operations["getPondEvents"];
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
        get?: never;
        put?: never;
        /** Water-quality telemetry & manual log ingestion */
        post: operations["ingestLog"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/media/presign": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Generate MinIO / R2 presigned URL for pond imagery & sensor uploads */
        post: operations["presignMediaUpload"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/media/commit": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Commit uploaded media asset to pond metadata */
        post: operations["commitMediaUpload"];
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
        /** Current calibrated risk with explanation payload */
        get: operations["getPondRisk"];
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
        /** Fleet triage list sorted by risk x biomass-at-stake */
        get: operations["getRiskWorklist"];
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
        /** Dissolved oxygen forecast with 24-72h quantile ribbon */
        get: operations["getDOForecast"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/forecast/temporal": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Multi-variable temporal forecast (TFT / TCN / PatchTST) */
        get: operations["getTemporalForecast"];
        put?: never;
        post?: never;
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
        /** GeoJSON FeatureCollection of pond markers */
        get: operations["getGeoPonds"];
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
        /** Outbreak clusters with water-source topology */
        get: operations["getGeoClusters"];
        put?: never;
        post?: never;
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
        /** Digital twin state vector at time t */
        get: operations["getTwinState"];
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
        /** Re-run simulator server-side under intervention */
        post: operations["runTwinWhatIf"];
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
        /** Internal reasoning call using hot-swapped LoRA adapters */
        post: operations["getReasoning"];
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
        /** Farmer-facing conversational Q&A endpoint powered by vLLM (Qwen3-8B) */
        post: operations["askFarmerAssistant"];
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
        /** Alert feed including suppressed alerts */
        get: operations["getAlerts"];
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
        post: operations["ackAlert"];
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
        /** Ground truth feedback (correct | incorrect) */
        post: operations["alertFeedback"];
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
        /** Advisory history */
        get: operations["getAdvisories"];
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
        /** Broadcast advisory after human approval */
        post: operations["broadcastAdvisory"];
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
        /** Model registry and changelog */
        get: operations["getModels"];
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
        /** Calibration curves and performance metrics */
        get: operations["getModelMetrics"];
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
        /** Population stability index (PSI) feature & concept drift */
        get: operations["getModelDrift"];
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
        /** Per-pond data quality, stuck values, and blind-state register */
        get: operations["getDataQuality"];
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
        /** IndicTrans2 translation service (English -> Tamil/Telugu/Hindi) */
        post: operations["translateText"];
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
        /** Export PDF or XLSX in official government letterhead format */
        get: operations["exportReport"];
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
        PondRecord: {
            pond_id?: string;
            farmer_name?: string;
            district?: string;
            taluk?: string;
            species?: string;
            doc?: number;
            area_ha?: number;
            depth_m?: number;
            water_source?: string;
            biomass_kg?: number;
            current_risk?: number;
            risk_band?: string;
        };
        PondEvent: {
            event_id?: string;
            timestamp?: string;
            /** @enum {string} */
            type?: "feed" | "water_exchange" | "rain" | "mortality" | "treatment";
            title?: string;
            details?: string;
        };
        ExplanationPayload: {
            pond_id: string;
            as_of: string;
            model_version: {
                numeric?: string;
                adapter?: string;
            };
            risk: number;
            risk_delta_24h: number;
            calibration?: {
                brier_1m?: number;
                reliability?: string;
            };
            modality_gate?: {
                timeseries?: number;
                image?: number;
                static?: number;
            };
            top_temporal_features?: {
                feature?: string;
                value?: number;
                unit?: string;
                attribution?: number;
                window?: string;
            }[];
            concepts?: {
                [key: string]: number;
            };
            image_age_hours?: number;
            nearest_cases?: {
                pond?: string;
                outcome?: string;
                similarity?: number;
            }[];
            blind_state: boolean;
            suppression_reason?: string | null;
        };
        TriageItem: {
            pond_id?: string;
            farmer_name?: string;
            district?: string;
            species?: string;
            doc?: number;
            biomass_kg?: number;
            risk?: number;
            risk_delta_24h?: number;
            risk_biomass_score?: number;
            top_driver?: string;
            last_contact?: string;
            data_health?: string;
            blind_state?: boolean;
        };
        DOForecast: {
            pond_id?: string;
            timestamps?: string[];
            forecast_p50?: number[];
            forecast_p10?: number[];
            forecast_p90?: number[];
            overnight_minimum_0400?: number;
            confidence_level?: string;
        };
        TwinState: {
            pond_id?: string;
            timestamp?: string;
            do_mg_l?: number;
            ph?: number;
            temp_c?: number;
            tan_mg_l?: number;
            no2_mg_l?: number;
            salinity_ppt?: number;
            alkalinity_mg_l?: number;
            biomass_kg?: number;
            water_clarity_cm?: number;
        };
        AlertItem: {
            alert_id?: string;
            pond_id?: string;
            district?: string;
            timestamp?: string;
            severity?: string;
            title?: string;
            message?: string;
            suppressed?: boolean;
            suppression_reason?: string | null;
            acknowledged?: boolean;
        };
        AdvisoryItem: {
            advisory_id?: string;
            timestamp?: string;
            target_segment?: string;
            text_en?: string;
            text_ta?: string;
            approved_by?: string;
            delivered_count?: number;
            read_count?: number;
        };
        WaterQualityLog: {
            pond_id: string;
            timestamp?: string;
            do_mg_l: number;
            ph: number;
            temp_c: number;
            tan_mg_l?: number;
            salinity_ppt?: number;
            notes?: string;
            /** @enum {string} */
            source?: "manual" | "iot_sensor" | "drone_flyover";
        };
        PresignRequest: {
            pond_id: string;
            filename: string;
            content_type: string;
            /** @enum {string} */
            category?: "water_sample" | "microscopic_slide" | "pond_perimeter" | "disease_observation";
        };
        PresignResponse: {
            upload_url?: string;
            asset_key?: string;
            expires_at?: string;
        };
        MediaCommit: {
            pond_id: string;
            asset_key: string;
            caption?: string;
        };
        TemporalForecastPayload: {
            pond_id?: string;
            model_family?: string;
            horizon_hours?: number;
            timestamps?: string[];
            forecast_do?: number[];
            forecast_ph?: number[];
            forecast_temp?: number[];
            confidence_interval?: {
                do_p10?: number[];
                do_p90?: number[];
            };
        };
        AskQuery: {
            question: string;
            pond_id?: string;
            /**
             * @default en
             * @enum {string}
             */
            lang: "en" | "ta" | "te" | "hi";
            /** @default false */
            voice_tts: boolean;
        };
        AskResponse: {
            answer?: string;
            translated_answer?: string;
            audio_url?: string | null;
            confidence?: number;
            sources?: string[];
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
    loginToken: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    username: string;
                    password: string;
                };
            };
        };
        responses: {
            /** @description Keycloak role-scoped JWT token */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        access_token?: string;
                        token_type?: string;
                        role?: string;
                    };
                };
            };
        };
    };
    requestOTP: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    phone: string;
                };
            };
        };
        responses: {
            /** @description OTP request sent */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        status?: string;
                        txn_id?: string;
                    };
                };
            };
        };
    };
    verifyOTP: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    phone: string;
                    otp: string;
                    txn_id: string;
                };
            };
        };
        responses: {
            /** @description Verified farmer JWT token */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        access_token?: string;
                        token_type?: string;
                        role?: string;
                        farmer_name?: string;
                    };
                };
            };
        };
    };
    listPonds: {
        parameters: {
            query?: {
                cursor?: string;
                limit?: number;
                district?: string;
                taluk?: string;
                species?: string;
                doc_band?: string;
                risk_band?: string;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Paginated pond list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        items?: components["schemas"]["PondRecord"][];
                        next_cursor?: string | null;
                    };
                };
            };
        };
    };
    getPondDetail: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Full pond record */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PondRecord"];
                };
            };
        };
    };
    getPondTimeseries: {
        parameters: {
            query?: {
                from?: string;
                to?: string;
                params?: string;
                agg?: "raw" | "hourly" | "daily";
            };
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Multi-parameter series payload */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        timestamps?: string[];
                        series?: {
                            [key: string]: (number | null)[];
                        };
                    };
                };
            };
        };
    };
    getPondEvents: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of pond events */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PondEvent"][];
                };
            };
        };
    };
    ingestLog: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["WaterQualityLog"];
            };
        };
        responses: {
            /** @description Log ingested successfully */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        log_id?: string;
                        status?: string;
                        timestamp?: string;
                    };
                };
            };
        };
    };
    presignMediaUpload: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["PresignRequest"];
            };
        };
        responses: {
            /** @description Presigned upload URL generated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PresignResponse"];
                };
            };
        };
    };
    commitMediaUpload: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MediaCommit"];
            };
        };
        responses: {
            /** @description Media committed */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        asset_id?: string;
                        status?: string;
                    };
                };
            };
        };
    };
    getPondRisk: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Calibrated risk & explanation payload */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ExplanationPayload"];
                };
            };
        };
    };
    getRiskWorklist: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Sorted triage list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TriageItem"][];
                };
            };
        };
    };
    getDOForecast: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Forecast series with 04:00 minimum */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DOForecast"];
                };
            };
        };
    };
    getTemporalForecast: {
        parameters: {
            query: {
                pond_id: string;
                model_family?: "TFT" | "TCN" | "PatchTST";
                horizon_hours?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Temporal multi-variable forecast payload */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TemporalForecastPayload"];
                };
            };
        };
    };
    getGeoPonds: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description GeoJSON FeatureCollection */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    getGeoClusters: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Outbreak cluster features and topology edges */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    getTwinState: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Twin state vector */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TwinState"];
                };
            };
        };
    };
    runTwinWhatIf: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                pond_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    water_exchange_rate?: number;
                    aeration_hours?: number;
                    feed_reduction_pct?: number;
                };
            };
        };
        responses: {
            /** @description Updated state series under intervention */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TwinState"];
                };
            };
        };
    };
    getReasoning: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    pond_id: string;
                    /** @enum {string} */
                    adapter: "m1_chemistry" | "m2_health" | "m3_production";
                };
            };
        };
        responses: {
            /** @description M1/M2/M3 reasoning response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        explanation?: string;
                        reasoning_trace?: string;
                        recommendations?: string[];
                    };
                };
            };
        };
    };
    askFarmerAssistant: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AskQuery"];
            };
        };
        responses: {
            /** @description Farmer assistant response with optional Indic translation & audio TTS */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AskResponse"];
                };
            };
        };
    };
    getAlerts: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Alert list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AlertItem"][];
                };
            };
        };
    };
    ackAlert: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                alert_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Ack status */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        success?: boolean;
                    };
                };
            };
        };
    };
    alertFeedback: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                alert_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    /** @enum {string} */
                    feedback: "correct" | "incorrect";
                };
            };
        };
        responses: {
            /** @description Feedback recorded */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        recorded?: boolean;
                    };
                };
            };
        };
    };
    getAdvisories: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Advisory log */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdvisoryItem"][];
                };
            };
        };
    };
    broadcastAdvisory: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    target_segment: string;
                    text_en: string;
                    approved_by: string;
                };
            };
        };
        responses: {
            /** @description Advisory broadcast status */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        broadcast_id?: string;
                        status?: string;
                    };
                };
            };
        };
    };
    getModels: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Model registry state */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    getModelMetrics: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Calibration & metric payload */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    getModelDrift: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Drift payload */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    getDataQuality: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Data quality summary */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": Record<string, never>;
                };
            };
        };
    };
    translateText: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": {
                    text: string;
                    /** @enum {string} */
                    target_lang: "ta" | "te" | "hi";
                };
            };
        };
        responses: {
            /** @description Translated output with cache status */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        translated_text?: string;
                        cached?: boolean;
                    };
                };
            };
        };
    };
    exportReport: {
        parameters: {
            query?: {
                format?: "pdf" | "xlsx";
                district?: string;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description File download trigger */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        download_url?: string;
                    };
                };
            };
        };
    };
}
