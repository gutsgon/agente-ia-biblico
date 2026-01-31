--
-- PostgreSQL database dump
--

\restrict d3ooH5SWPd8BVeQ08Ai8zp4zaCX8NVrFXnEmdYsajX3EvhfxteK6nExI1PysqAj

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: llm_metrics; Type: SCHEMA; Schema: -; Owner: n8n_user
--

CREATE SCHEMA llm_metrics;


ALTER SCHEMA llm_metrics OWNER TO n8n_user;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: executions; Type: TABLE; Schema: llm_metrics; Owner: n8n_user
--

CREATE TABLE llm_metrics.executions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    model_id uuid NOT NULL,
    prompt text NOT NULL,
    started_at timestamp without time zone NOT NULL,
    finished_at timestamp without time zone NOT NULL,
    latency_ms integer NOT NULL,
    success boolean NOT NULL,
    prompt_tokens integer,
    completion_tokens integer,
    total_tokens integer
);


ALTER TABLE llm_metrics.executions OWNER TO n8n_user;

--
-- Name: models; Type: TABLE; Schema: llm_metrics; Owner: n8n_user
--

CREATE TABLE llm_metrics.models (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    parameters text NOT NULL
);


ALTER TABLE llm_metrics.models OWNER TO n8n_user;

--
-- Name: resource_metrics; Type: TABLE; Schema: llm_metrics; Owner: n8n_user
--

CREATE TABLE llm_metrics.resource_metrics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    execution_id uuid,
    cpu_percent real,
    memory_mb real,
    disk_read_mb real,
    disk_write_mb real,
    net_rx_mb real,
    net_tx_mb real,
    "timestamp" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


ALTER TABLE llm_metrics.resource_metrics OWNER TO n8n_user;

--
-- Name: response_accuracy; Type: TABLE; Schema: llm_metrics; Owner: n8n_user
--

CREATE TABLE llm_metrics.response_accuracy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    response_id uuid NOT NULL,
    is_correct boolean NOT NULL,
    score real,
    evaluation_method text NOT NULL,
    notes text,
    evaluated_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


ALTER TABLE llm_metrics.response_accuracy OWNER TO n8n_user;

--
-- Name: responses; Type: TABLE; Schema: llm_metrics; Owner: n8n_user
--

CREATE TABLE llm_metrics.responses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    execution_id uuid NOT NULL,
    model_id uuid NOT NULL,
    prompt text NOT NULL,
    response text NOT NULL,
    created_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC'::text)
);


ALTER TABLE llm_metrics.responses OWNER TO n8n_user;

--
-- Name: executions executions_pkey; Type: CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.executions
    ADD CONSTRAINT executions_pkey PRIMARY KEY (id);


--
-- Name: models models_pkey; Type: CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.models
    ADD CONSTRAINT models_pkey PRIMARY KEY (id);


--
-- Name: resource_metrics resource_metrics_pkey; Type: CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.resource_metrics
    ADD CONSTRAINT resource_metrics_pkey PRIMARY KEY (id);


--
-- Name: response_accuracy response_accuracy_pkey; Type: CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.response_accuracy
    ADD CONSTRAINT response_accuracy_pkey PRIMARY KEY (id);


--
-- Name: responses responses_pkey; Type: CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.responses
    ADD CONSTRAINT responses_pkey PRIMARY KEY (id);


--
-- Name: executions executions_model_id_fkey; Type: FK CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.executions
    ADD CONSTRAINT executions_model_id_fkey FOREIGN KEY (model_id) REFERENCES llm_metrics.models(id);


--
-- Name: response_accuracy fk_accuracy_response; Type: FK CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.response_accuracy
    ADD CONSTRAINT fk_accuracy_response FOREIGN KEY (response_id) REFERENCES llm_metrics.responses(id) ON DELETE CASCADE;


--
-- Name: responses fk_response_execution; Type: FK CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.responses
    ADD CONSTRAINT fk_response_execution FOREIGN KEY (execution_id) REFERENCES llm_metrics.executions(id) ON DELETE CASCADE;


--
-- Name: responses fk_response_model; Type: FK CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.responses
    ADD CONSTRAINT fk_response_model FOREIGN KEY (model_id) REFERENCES llm_metrics.models(id) ON DELETE CASCADE;


--
-- Name: resource_metrics resource_metrics_execution_id_fkey; Type: FK CONSTRAINT; Schema: llm_metrics; Owner: n8n_user
--

ALTER TABLE ONLY llm_metrics.resource_metrics
    ADD CONSTRAINT resource_metrics_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES llm_metrics.executions(id);


--
-- PostgreSQL database dump complete
--

\unrestrict d3ooH5SWPd8BVeQ08Ai8zp4zaCX8NVrFXnEmdYsajX3EvhfxteK6nExI1PysqAj

