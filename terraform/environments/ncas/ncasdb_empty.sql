--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7
-- Dumped by pg_dump version 15.3

-- Started on 2023-10-23 15:18:15 BST

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
-- TOC entry 5 (class 2615 OID 16405)
-- Name: dbo; Type: SCHEMA; Schema: -; Owner: dbadmin
--

CREATE SCHEMA dbo;


ALTER SCHEMA dbo OWNER TO dbadmin;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: dbadmin
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO dbadmin;

--
-- TOC entry 210 (class 1259 OID 16406)
-- Name: adgroups_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.adgroups_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.adgroups_seq OWNER TO dbadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 16407)
-- Name: ADGroups; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ADGroups" (
    "ADGroupID" integer DEFAULT nextval('dbo.adgroups_seq'::regclass) NOT NULL,
    "Name" character varying(80) NOT NULL,
    "RoleStrength" integer NOT NULL
);


ALTER TABLE dbo."ADGroups" OWNER TO dbadmin;

--
-- TOC entry 212 (class 1259 OID 16411)
-- Name: actions_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.actions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.actions_seq OWNER TO dbadmin;

--
-- TOC entry 213 (class 1259 OID 16412)
-- Name: Actions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Actions" (
    "ActionID" integer DEFAULT nextval('dbo.actions_seq'::regclass) NOT NULL,
    "Name" character varying(7) NOT NULL
);


ALTER TABLE dbo."Actions" OWNER TO dbadmin;

--
-- TOC entry 214 (class 1259 OID 16416)
-- Name: audit_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.audit_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.audit_seq OWNER TO dbadmin;

--
-- TOC entry 215 (class 1259 OID 16417)
-- Name: Audits; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Audits" (
    "AuditID" integer DEFAULT nextval('dbo.audit_seq'::regclass) NOT NULL,
    "Date" timestamp without time zone NOT NULL,
    "UserID" integer NOT NULL,
    "ObjPrimaryKey" integer NOT NULL,
    "RootPrimaryKey" integer,
    "ActionID" integer NOT NULL,
    "Object" character varying(60) NOT NULL
);


ALTER TABLE dbo."Audits" OWNER TO dbadmin;

--
-- TOC entry 216 (class 1259 OID 16421)
-- Name: bulkimports_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.bulkimports_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.bulkimports_seq OWNER TO dbadmin;

--
-- TOC entry 217 (class 1259 OID 16422)
-- Name: BulkImports; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."BulkImports" (
    "BulkImportID" integer DEFAULT nextval('dbo.bulkimports_seq'::regclass) NOT NULL,
    "Uploaded" timestamp without time zone NOT NULL,
    "Filename" character varying(100),
    "CompanyID" integer NOT NULL,
    "UploadedByID" integer NOT NULL,
    "HashValue" bytea
);


ALTER TABLE dbo."BulkImports" OWNER TO dbadmin;

--
-- TOC entry 218 (class 1259 OID 16428)
-- Name: changes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.changes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.changes_seq OWNER TO dbadmin;

--
-- TOC entry 219 (class 1259 OID 16429)
-- Name: Changes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Changes" (
    "ChangeID" integer DEFAULT nextval('dbo.changes_seq'::regclass) NOT NULL,
    "AuditID" integer NOT NULL,
    "ColumnName" character varying(200) NOT NULL,
    "Was" character varying(200) NOT NULL,
    "Now" character varying(200) NOT NULL
);


ALTER TABLE dbo."Changes" OWNER TO dbadmin;

--
-- TOC entry 220 (class 1259 OID 16435)
-- Name: companies_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.companies_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.companies_seq OWNER TO dbadmin;

--
-- TOC entry 221 (class 1259 OID 16436)
-- Name: Companies; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Companies" (
    "CompanyID" integer DEFAULT nextval('dbo.companies_seq'::regclass) NOT NULL,
    "Name" character varying(50),
    "Add1" character varying(50),
    "Add2" character varying(50),
    "Add3" character varying(50),
    "Add4" character varying(50),
    "Add5" character varying(50),
    "Postcode" character varying(8),
    "DX" character varying(50),
    "Phone" character varying(20),
    "Fax" character varying(20),
    "Email1" character varying(80),
    "Email2" character varying(80),
    "Active" boolean NOT NULL
);


ALTER TABLE dbo."Companies" OWNER TO dbadmin;

--
-- TOC entry 222 (class 1259 OID 16442)
-- Name: courts_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.courts_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.courts_seq OWNER TO dbadmin;

--
-- TOC entry 223 (class 1259 OID 16443)
-- Name: Courts; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Courts" (
    "CourtID" integer DEFAULT nextval('dbo.courts_seq'::regclass) NOT NULL,
    "Name" character varying(50) NOT NULL,
    "Acronym" character varying(5) NOT NULL,
    "Active" boolean NOT NULL
);


ALTER TABLE dbo."Courts" OWNER TO dbadmin;

--
-- TOC entry 224 (class 1259 OID 16447)
-- Name: deletereasons_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.deletereasons_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.deletereasons_seq OWNER TO dbadmin;

--
-- TOC entry 225 (class 1259 OID 16448)
-- Name: DeleteReasons; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DeleteReasons" (
    id integer DEFAULT nextval('dbo.deletereasons_seq'::regclass) NOT NULL,
    "Description" character varying(30),
    "Deactivated" boolean NOT NULL,
    "deactivatedOn" timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."DeleteReasons" OWNER TO dbadmin;

--
-- TOC entry 226 (class 1259 OID 16452)
-- Name: divisions_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.divisions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.divisions_seq OWNER TO dbadmin;

--
-- TOC entry 227 (class 1259 OID 16453)
-- Name: Divisions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Divisions" (
    "DivisionID" integer DEFAULT nextval('dbo.divisions_seq'::regclass) NOT NULL,
    "CourtID" integer NOT NULL,
    "Acronym" character varying(10) NOT NULL,
    "Name" character varying(50) NOT NULL,
    "Active" boolean NOT NULL
);


ALTER TABLE dbo."Divisions" OWNER TO dbadmin;

--
-- TOC entry 228 (class 1259 OID 16457)
-- Name: judges_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.judges_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.judges_seq OWNER TO dbadmin;

--
-- TOC entry 229 (class 1259 OID 16458)
-- Name: Judges; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Judges" (
    "JudgeID" integer DEFAULT nextval('dbo.judges_seq'::regclass) NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Active" boolean NOT NULL,
    "Archive" boolean NOT NULL
);


ALTER TABLE dbo."Judges" OWNER TO dbadmin;

--
-- TOC entry 230 (class 1259 OID 16462)
-- Name: neutralcitations_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.neutralcitations_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.neutralcitations_seq OWNER TO dbadmin;

--
-- TOC entry 231 (class 1259 OID 16463)
-- Name: NeutralCitations; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."NeutralCitations" (
    "NeutralCitationID" integer DEFAULT nextval('dbo.neutralcitations_seq'::regclass) NOT NULL,
    "CitationNumber" integer NOT NULL,
    "Party1Name" character varying(75) NOT NULL,
    "Party2Name" character varying(75),
    "JudgmentYear" character varying(4),
    "CourtID" integer NOT NULL,
    "DivisionID" integer,
    "CaseNumber" character varying(75),
    "ContractedNumber" character varying(75),
    "JudgeID" integer NOT NULL,
    "JudgmentDate" timestamp without time zone,
    "CreatedByID" integer NOT NULL,
    "CreatedOn" timestamp without time zone NOT NULL,
    "Deleted" boolean NOT NULL,
    "DeletedReasonID" integer,
    "DeletedOn" timestamp without time zone,
    "DeletedByID" integer,
    "BulkImportID" integer,
    "Retention" boolean DEFAULT false
);


ALTER TABLE dbo."NeutralCitations" OWNER TO dbadmin;

--
-- TOC entry 232 (class 1259 OID 16468)
-- Name: Roles; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Roles" (
    strength integer NOT NULL,
    "Detail" character varying(20) NOT NULL
);


ALTER TABLE dbo."Roles" OWNER TO dbadmin;

--
-- TOC entry 233 (class 1259 OID 16471)
-- Name: users_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.users_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.users_seq OWNER TO dbadmin;

--
-- TOC entry 234 (class 1259 OID 16472)
-- Name: Users; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Users" (
    "UserID" integer DEFAULT nextval('dbo.users_seq'::regclass) NOT NULL,
    "Name" text,
    "DisplayName" character varying(150),
    "LastActive" timestamp without time zone,
    "RoleStrength" integer NOT NULL
);


ALTER TABLE dbo."Users" OWNER TO dbadmin;

--
-- TOC entry 235 (class 1259 OID 16478)
-- Name: __MigrationHistory; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."__MigrationHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ContextKey" character varying(300) NOT NULL,
    "Model" bytea NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);


ALTER TABLE dbo."__MigrationHistory" OWNER TO dbadmin;

--
-- TOC entry 4205 (class 2606 OID 16487)
-- Name: ADGroups ADGroups_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."ADGroups"
    ADD CONSTRAINT "ADGroups_pkey" PRIMARY KEY ("ADGroupID");


--
-- TOC entry 4207 (class 2606 OID 16489)
-- Name: Actions Actions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Actions"
    ADD CONSTRAINT "Actions_pkey" PRIMARY KEY ("ActionID");


--
-- TOC entry 4209 (class 2606 OID 16491)
-- Name: Audits Audits_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Audits"
    ADD CONSTRAINT "Audits_pkey" PRIMARY KEY ("AuditID");


--
-- TOC entry 4211 (class 2606 OID 16493)
-- Name: BulkImports BulkImports_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."BulkImports"
    ADD CONSTRAINT "BulkImports_pkey" PRIMARY KEY ("BulkImportID");


--
-- TOC entry 4213 (class 2606 OID 16495)
-- Name: Changes Changes_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Changes"
    ADD CONSTRAINT "Changes_pkey" PRIMARY KEY ("ChangeID");


--
-- TOC entry 4215 (class 2606 OID 16497)
-- Name: Companies Companies_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Companies"
    ADD CONSTRAINT "Companies_pkey" PRIMARY KEY ("CompanyID");


--
-- TOC entry 4217 (class 2606 OID 16499)
-- Name: Courts Courts_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Courts"
    ADD CONSTRAINT "Courts_pkey" PRIMARY KEY ("CourtID");


--
-- TOC entry 4219 (class 2606 OID 16501)
-- Name: DeleteReasons DeleteReasons_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DeleteReasons"
    ADD CONSTRAINT "DeleteReasons_pkey" PRIMARY KEY (id);


--
-- TOC entry 4221 (class 2606 OID 16503)
-- Name: Divisions Divisions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Divisions"
    ADD CONSTRAINT "Divisions_pkey" PRIMARY KEY ("DivisionID");


--
-- TOC entry 4223 (class 2606 OID 16505)
-- Name: Judges Judges_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Judges"
    ADD CONSTRAINT "Judges_pkey" PRIMARY KEY ("JudgeID");


--
-- TOC entry 4225 (class 2606 OID 16507)
-- Name: NeutralCitations NeutralCitations_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."NeutralCitations"
    ADD CONSTRAINT "NeutralCitations_pkey" PRIMARY KEY ("NeutralCitationID");


--
-- TOC entry 4231 (class 2606 OID 16509)
-- Name: __MigrationHistory PK_dbo.__MigrationHistory; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."__MigrationHistory"
    ADD CONSTRAINT "PK_dbo.__MigrationHistory" PRIMARY KEY ("MigrationId", "ContextKey");


--
-- TOC entry 4227 (class 2606 OID 16511)
-- Name: Roles Roles_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Roles"
    ADD CONSTRAINT "Roles_pkey" PRIMARY KEY (strength);


--
-- TOC entry 4229 (class 2606 OID 16513)
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY ("UserID");


--
-- TOC entry 4402 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: dbadmin
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2023-10-23 15:18:18 BST

--
-- PostgreSQL database dump complete
--
