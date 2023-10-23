--
-- PostgreSQL database dump
--

-- Dumped from database version 10.23
-- Dumped by pg_dump version 15.2

-- Started on 2023-10-23 15:24:57 BST

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
-- TOC entry 8 (class 2615 OID 69520)
-- Name: dbo; Type: SCHEMA; Schema: -; Owner: dbadmin
--

CREATE SCHEMA dbo;


ALTER SCHEMA dbo OWNER TO dbadmin;

--
-- TOC entry 7 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: dbadmin
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO dbadmin;

--
-- TOC entry 260 (class 1255 OID 70163)
-- Name: insert_fm(); Type: FUNCTION; Schema: dbo; Owner: dbadmin
--

CREATE FUNCTION dbo.insert_fm() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
update dbo."Unions"
set "CourtID" = map."CourtID"
from dbo."CourtImportMaps" map
where dbo."Unions"."CourtCode" = map."FamilyManCourtCode"::text;
   --RETURN test;

INSERT INTO dbo."Proceedings" 
("MarriageDate", "DADate", "CourtID", "CaseNo", "FamilyManError", "UnionTypeID", "UnionID") 
 SELECT to_timestamp(U."DateofMarriage", 'DD/MM/YYYY'), to_timestamp(U."DateofDecreeAbsolute", 'DD/MM/YYYY'), U."CourtID" ,U."NumberofMatter", U."Error"
, CASE "UnionType"
		WHEN 'CP'  THEN 2
		WHEN 'SSM' THEN 3
		WHEN 'OSM' THEN 1
  ELSE null
END
,U."UnionID"
FROM dbo."Unions" U
where U."CourtID" is not null;

INSERT INTO dbo."Parties" 
("ProceedingID", "Forename", "Surname", "FMPetitionerOrRespondent") 
SELECT P."ProceedingID", U."ForenamesofPetitioner", U."SurnameAtMarriage", 'P'
FROM dbo."Unions" U
INNER JOIN dbo."Proceedings" P
ON P."UnionID" = U."UnionID";

INSERT INTO dbo."Parties" 
("ProceedingID", "Forename", "Surname", "FMPetitionerOrRespondent") 
SELECT P."ProceedingID", U."ForenamesofRespondent", U."SurnameAtMarriage", 'R'
FROM dbo."Unions" U
INNER JOIN dbo."Proceedings" P
ON P."UnionID" = U."UnionID";

DELETE FROM dbo."Unions"
where "CourtID" is not NULL;
RETURN null;
END;
$$;


ALTER FUNCTION dbo.insert_fm() OWNER TO dbadmin;

--
-- TOC entry 245 (class 1255 OID 70165)
-- Name: tri_dataseq_proc(); Type: FUNCTION; Schema: dbo; Owner: dbadmin
--

CREATE FUNCTION dbo.tri_dataseq_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	update dbo."Works" 
	set "daNO" = (SELECT CASE 
				WHEN (SELECT count(W."workID") FROM dbo."Works" W where W."Year" = date_part('year',current_date) Group by W."Year") > 0 
					THEN (NEW."workID")-(SELECT MIN(W."workID") FROM dbo."Works" W where W."Year" = date_part('year',current_date) Group by W."Year") 
				        ELSE 1 
				END )+ 1 
	WHERE "workID" = NEW."workID";
        return null;
END;

$$;


ALTER FUNCTION dbo.tri_dataseq_proc() OWNER TO dbadmin;

--
-- TOC entry 246 (class 1255 OID 70167)
-- Name: tri_insassignddate_proc(); Type: FUNCTION; Schema: dbo; Owner: dbadmin
--

CREATE FUNCTION dbo.tri_insassignddate_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	update dbo."Works"
        set "AssignedOn" = current_date
        where "AssignedOn" is null AND "AssignedToUserID" is not null AND "workID" = NEW."workID";
        return null;
END;

$$;


ALTER FUNCTION dbo.tri_insassignddate_proc() OWNER TO dbadmin;

--
-- TOC entry 247 (class 1255 OID 70169)
-- Name: upd_works_proc(); Type: FUNCTION; Schema: dbo; Owner: dbadmin
--

CREATE FUNCTION dbo.upd_works_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE dbo."Works" 
        SET "AssignedOn" = current_date 
        WHERE "workID" = NEW."workID" AND ((NEW."AssignedToUserID" <> OLD."AssignedToUserID" ) OR (NEW."AssignedToUserID" is not null and OLD."AssignedToUserID" is null )) ;
        return null;
END;

$$;


ALTER FUNCTION dbo.upd_works_proc() OWNER TO dbadmin;

--
-- TOC entry 222 (class 1259 OID 70068)
-- Name: alerts_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.alerts_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.alerts_seq OWNER TO dbadmin;

SET default_tablespace = '';

--
-- TOC entry 198 (class 1259 OID 69886)
-- Name: Alerts; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Alerts" (
    "AlertID" integer DEFAULT nextval('dbo.alerts_seq'::regclass) NOT NULL,
    "Live" boolean NOT NULL,
    "EventStart" timestamp without time zone NOT NULL,
    "RaisedHours" integer NOT NULL,
    "WarnStart" timestamp without time zone NOT NULL,
    "Message" character varying(200) NOT NULL
);


ALTER TABLE dbo."Alerts" OWNER TO dbadmin;

--
-- TOC entry 223 (class 1259 OID 70070)
-- Name: auditeventdatarows_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.auditeventdatarows_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.auditeventdatarows_seq OWNER TO dbadmin;

--
-- TOC entry 199 (class 1259 OID 69891)
-- Name: AuditEventDataRows; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEventDataRows" (
    "idAuditData" integer NOT NULL,
    "idAuditEvent" integer DEFAULT nextval('dbo.auditeventdatarows_seq'::regclass) NOT NULL,
    "ColumnName" character varying(200) NOT NULL,
    "Was" character varying(200) NOT NULL,
    "Now" character varying(200) NOT NULL
);


ALTER TABLE dbo."AuditEventDataRows" OWNER TO dbadmin;

--
-- TOC entry 224 (class 1259 OID 70072)
-- Name: auditeventdescriptions_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.auditeventdescriptions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.auditeventdescriptions_seq OWNER TO dbadmin;

--
-- TOC entry 200 (class 1259 OID 69899)
-- Name: AuditEventDescriptions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEventDescriptions" (
    "idAuditEventDescription" integer DEFAULT nextval('dbo.auditeventdescriptions_seq'::regclass) NOT NULL,
    "AuditDescription" character varying(40) NOT NULL
);


ALTER TABLE dbo."AuditEventDescriptions" OWNER TO dbadmin;

--
-- TOC entry 241 (class 1259 OID 70113)
-- Name: auditevents_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.auditevents_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.auditevents_seq OWNER TO dbadmin;

--
-- TOC entry 201 (class 1259 OID 69904)
-- Name: AuditEvents; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEvents" (
    "idAuditEvent" integer DEFAULT nextval('dbo.auditevents_seq'::regclass) NOT NULL,
    "EventDate" timestamp without time zone NOT NULL,
    "UserID" character varying(40) NOT NULL,
    "idAuditEventDescription" integer NOT NULL,
    "RecordChanged" character varying(256) NOT NULL,
    "RecordAddedTo" integer
);


ALTER TABLE dbo."AuditEvents" OWNER TO dbadmin;

--
-- TOC entry 225 (class 1259 OID 70074)
-- Name: courtimportmaps_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.courtimportmaps_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.courtimportmaps_seq OWNER TO dbadmin;

--
-- TOC entry 202 (class 1259 OID 69909)
-- Name: CourtImportMaps; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CourtImportMaps" (
    "CourtImportMapID" integer DEFAULT nextval('dbo.courtimportmaps_seq'::regclass) NOT NULL,
    "FamilyManCourtName" character varying(150) NOT NULL,
    "FamilyManCourtCode" integer NOT NULL,
    "CourtID" integer,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."CourtImportMaps" OWNER TO dbadmin;

--
-- TOC entry 226 (class 1259 OID 70076)
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
-- TOC entry 203 (class 1259 OID 69914)
-- Name: Courts; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Courts" (
    "CourtID" integer DEFAULT nextval('dbo.courts_seq'::regclass) NOT NULL,
    "CourtCode" integer NOT NULL,
    "CourtName" character varying(101) NOT NULL,
    "AddressLine1" character varying(50),
    "AddressLine2" character varying(50),
    "AddressLine3" character varying(50),
    "AddressLine4" character varying(50),
    "Town" character varying(30),
    "County" character varying(30),
    "Country" character varying(20),
    "Postcode" character varying(8),
    "DX" character varying(60),
    "Telephone" character varying(30),
    "SendToCourtCode" integer NOT NULL,
    "NoCourtLetter" boolean NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Courts" OWNER TO dbadmin;

--
-- TOC entry 227 (class 1259 OID 70078)
-- Name: dasearchcriterias_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.dasearchcriterias_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.dasearchcriterias_seq OWNER TO dbadmin;

--
-- TOC entry 204 (class 1259 OID 69922)
-- Name: DASearchCriterias; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DASearchCriterias" (
    "DASearchCriteriaID" integer DEFAULT nextval('dbo.dasearchcriterias_seq'::regclass) NOT NULL,
    "ApplicantName" character varying(100),
    "ApplicantAddr1" character varying(100),
    "ApplicantAddr2" character varying(100),
    "ApplicantAddr3" character varying(100),
    "ApplicantAddr4" character varying(100),
    "ApplicantPostCode" character varying(30),
    "SolicitorsRef" character varying(30),
    "AForename" character varying(30),
    "ASurname" character varying(30) NOT NULL,
    "BForename" character varying(30),
    "BSurname" character varying(30),
    "WeddingDate" timestamp without time zone,
    "DecreeDate" timestamp without time zone,
    "DARegistry" character varying(30),
    "DASearchBeginYear" integer,
    "DASearchFinalYear" integer,
    "CourtID" integer,
    "OPCSID" character varying(30),
    "WorkID" integer,
    "Certified" boolean NOT NULL,
    "UnionTypeID" integer
);


ALTER TABLE dbo."DASearchCriterias" OWNER TO dbadmin;

--
-- TOC entry 228 (class 1259 OID 70080)
-- Name: datypes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.datypes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.datypes_seq OWNER TO dbadmin;

--
-- TOC entry 206 (class 1259 OID 69938)
-- Name: DATypes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DATypes" (
    "DATypeID" integer DEFAULT nextval('dbo.datypes_seq'::regclass) NOT NULL,
    "DATypeLetter" character varying(1) NOT NULL,
    "Description" character varying(30) NOT NULL,
    "StartYear" integer NOT NULL,
    "EndYear" integer NOT NULL
);


ALTER TABLE dbo."DATypes" OWNER TO dbadmin;

--
-- TOC entry 229 (class 1259 OID 70082)
-- Name: datauploads_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.datauploads_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.datauploads_seq OWNER TO dbadmin;

--
-- TOC entry 205 (class 1259 OID 69930)
-- Name: DataUploads; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DataUploads" (
    "DataUploadID" integer DEFAULT nextval('dbo.datauploads_seq'::regclass) NOT NULL,
    "UploadStarted" timestamp without time zone NOT NULL,
    "UploadedBy" text,
    "FileName" text,
    "FullPathandName" text,
    "FileSize" integer NOT NULL,
    "UploadCompleted" timestamp without time zone,
    "NumberofRows" integer NOT NULL,
    "NumberOfErrs" integer NOT NULL
);


ALTER TABLE dbo."DataUploads" OWNER TO dbadmin;

--
-- TOC entry 242 (class 1259 OID 70117)
-- Name: deletedreasons_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.deletedreasons_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.deletedreasons_seq OWNER TO dbadmin;

--
-- TOC entry 207 (class 1259 OID 69943)
-- Name: DeletedReasons; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DeletedReasons" (
    "deletedReasonID" integer DEFAULT nextval('dbo.deletedreasons_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."DeletedReasons" OWNER TO dbadmin;

--
-- TOC entry 230 (class 1259 OID 70084)
-- Name: faqs_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.faqs_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.faqs_seq OWNER TO dbadmin;

--
-- TOC entry 208 (class 1259 OID 69948)
-- Name: FAQs; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."FAQs" (
    "faqID" integer DEFAULT nextval('dbo.faqs_seq'::regclass) NOT NULL,
    "loggedInUser" boolean NOT NULL,
    question character varying(150) NOT NULL,
    answer character varying(4000) NOT NULL
);


ALTER TABLE dbo."FAQs" OWNER TO dbadmin;

--
-- TOC entry 231 (class 1259 OID 70086)
-- Name: parties_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.parties_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.parties_seq OWNER TO dbadmin;

--
-- TOC entry 209 (class 1259 OID 69956)
-- Name: Parties; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Parties" (
    "PartyID" integer DEFAULT nextval('dbo.parties_seq'::regclass) NOT NULL,
    "ProceedingID" integer,
    "Forename" character varying(100),
    "Surname" character varying(100),
    "OPCSID" character varying(50),
    "FMPetitionerOrRespondent" character varying(1)
);


ALTER TABLE dbo."Parties" OWNER TO dbadmin;

--
-- TOC entry 243 (class 1259 OID 70119)
-- Name: proceedings_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.proceedings_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.proceedings_seq OWNER TO dbadmin;

--
-- TOC entry 210 (class 1259 OID 69961)
-- Name: Proceedings; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Proceedings" (
    "ProceedingID" integer DEFAULT nextval('dbo.proceedings_seq'::regclass) NOT NULL,
    "MarriageDate" timestamp without time zone,
    "DADate" timestamp without time zone,
    "CourtID" integer NOT NULL,
    "CaseNo" character varying(32),
    "OPCSID" character varying(32),
    "FamilyManError" character varying(100),
    "UnionTypeID" integer,
    "UnionID" integer
);


ALTER TABLE dbo."Proceedings" OWNER TO dbadmin;

--
-- TOC entry 244 (class 1259 OID 70121)
-- Name: resultparties_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.resultparties_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.resultparties_seq OWNER TO dbadmin;

--
-- TOC entry 211 (class 1259 OID 69966)
-- Name: ResultParties; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ResultParties" (
    "ResultPartyID" integer DEFAULT nextval('dbo.resultparties_seq'::regclass) NOT NULL,
    "ResultProceedingID" integer,
    "Forename" character varying(100),
    "Surname" character varying(100),
    "OPCSID" character varying(50)
);


ALTER TABLE dbo."ResultParties" OWNER TO dbadmin;

--
-- TOC entry 232 (class 1259 OID 70092)
-- Name: resultproceedings_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.resultproceedings_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.resultproceedings_seq OWNER TO dbadmin;

--
-- TOC entry 212 (class 1259 OID 69971)
-- Name: ResultProceedings; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ResultProceedings" (
    "ResultProceedingID" integer DEFAULT nextval('dbo.resultproceedings_seq'::regclass) NOT NULL,
    "MarriageDate" timestamp without time zone,
    "DADate" timestamp without time zone,
    "CourtID" integer,
    "CaseNo" character varying(31),
    "OPCSID" character varying(31),
    "FamilyManError" character varying(100),
    "UnionTypeID" integer
);


ALTER TABLE dbo."ResultProceedings" OWNER TO dbadmin;

--
-- TOC entry 233 (class 1259 OID 70094)
-- Name: resultsearches_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.resultsearches_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.resultsearches_seq OWNER TO dbadmin;

--
-- TOC entry 213 (class 1259 OID 69976)
-- Name: ResultSearches; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ResultSearches" (
    "ResultSearchID" integer DEFAULT nextval('dbo.resultsearches_seq'::regclass) NOT NULL,
    "DASearchCriteriaID" integer,
    "ResultProceedingID" integer,
    "TraceStatusID" integer,
    "ProceedingID" integer,
    "OriginalPrintDate" timestamp without time zone
);


ALTER TABLE dbo."ResultSearches" OWNER TO dbadmin;

--
-- TOC entry 214 (class 1259 OID 69981)
-- Name: Roles; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Roles" (
    strength integer NOT NULL,
    "Detail" character varying(20) NOT NULL
);


ALTER TABLE dbo."Roles" OWNER TO dbadmin;

--
-- TOC entry 234 (class 1259 OID 70096)
-- Name: salutations_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.salutations_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.salutations_seq OWNER TO dbadmin;

--
-- TOC entry 215 (class 1259 OID 69986)
-- Name: Salutations; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Salutations" (
    "salutationID" integer DEFAULT nextval('dbo.salutations_seq'::regclass) NOT NULL,
    "Detail" character varying(10) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Salutations" OWNER TO dbadmin;

--
-- TOC entry 235 (class 1259 OID 70098)
-- Name: templates_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.templates_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.templates_seq OWNER TO dbadmin;

--
-- TOC entry 216 (class 1259 OID 69991)
-- Name: Templates; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Templates" (
    "templateID" integer DEFAULT nextval('dbo.templates_seq'::regclass) NOT NULL,
    "Discriminator" character varying(128) NOT NULL,
    "templateName" character varying(80) NOT NULL,
    "templateXML" text NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Templates" OWNER TO dbadmin;

--
-- TOC entry 236 (class 1259 OID 70100)
-- Name: tracestatus_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.tracestatus_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.tracestatus_seq OWNER TO dbadmin;

--
-- TOC entry 217 (class 1259 OID 70000)
-- Name: TraceStatus; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."TraceStatus" (
    "TraceStatusID" integer DEFAULT nextval('dbo.tracestatus_seq'::regclass) NOT NULL,
    "Description" character varying(30)
);


ALTER TABLE dbo."TraceStatus" OWNER TO dbadmin;

--
-- TOC entry 237 (class 1259 OID 70102)
-- Name: uniontypes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.uniontypes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.uniontypes_seq OWNER TO dbadmin;

--
-- TOC entry 219 (class 1259 OID 70020)
-- Name: UnionTypes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."UnionTypes" (
    "UnionTypeID" integer DEFAULT nextval('dbo.uniontypes_seq'::regclass) NOT NULL,
    "Description" text
);


ALTER TABLE dbo."UnionTypes" OWNER TO dbadmin;

--
-- TOC entry 238 (class 1259 OID 70104)
-- Name: unions_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.unions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.unions_seq OWNER TO dbadmin;

--
-- TOC entry 218 (class 1259 OID 70012)
-- Name: Unions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Unions" (
    "UnionID" integer DEFAULT nextval('dbo.unions_seq'::regclass) NOT NULL,
    "DataUploadID" integer NOT NULL,
    "DAEvent" text,
    "Error" text,
    "ErrorDate" text,
    "CourtCode" text,
    "NumberofMatter" text,
    "SurnameAtMarriage" text,
    "DateofMarriage" text,
    "DateofDecreeAbsolute" text,
    "ForenamesofPetitioner" text,
    "ForenamesofRespondent" text,
    "ImportError" text,
    "CourtID" integer,
    "UnionType" character varying(50)
);


ALTER TABLE dbo."Unions" OWNER TO dbadmin;

--
-- TOC entry 239 (class 1259 OID 70106)
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
-- TOC entry 220 (class 1259 OID 70028)
-- Name: Users; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Users" (
    "UserID" integer DEFAULT nextval('dbo.users_seq'::regclass) NOT NULL,
    "Name" character varying(150) NOT NULL,
    "DisplayName" character varying(30),
    "LastActive" timestamp without time zone,
    "RoleStrength" integer NOT NULL
);


ALTER TABLE dbo."Users" OWNER TO dbadmin;

--
-- TOC entry 240 (class 1259 OID 70108)
-- Name: works_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.works_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.works_seq OWNER TO dbadmin;

--
-- TOC entry 221 (class 1259 OID 70033)
-- Name: Works; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Works" (
    "workID" integer DEFAULT nextval('dbo.works_seq'::regclass) NOT NULL,
    "daNO" integer NOT NULL,
    "Year" integer NOT NULL,
    "ReceivedBySection" timestamp without time zone NOT NULL,
    "DAInititial" character varying(101) NOT NULL,
    "DASurname" character varying(100) NOT NULL,
    "Applicant" character varying(100) NOT NULL,
    "DATypeID" integer NOT NULL,
    "AssignedOn" timestamp without time zone,
    "AssignedToUserID" integer,
    "ReturnedToSupervisor" timestamp without time zone,
    "Filed" timestamp without time zone,
    "TraceStatusID" integer,
    "OtherInfo" character varying(4000),
    "FurtherAssignedToUserID" integer,
    "ReCheckID" integer
);


ALTER TABLE dbo."Works" OWNER TO dbadmin;

--
-- TOC entry 197 (class 1259 OID 69869)
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
-- TOC entry 3846 (class 2606 OID 69890)
-- Name: Alerts Alerts_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Alerts"
    ADD CONSTRAINT "Alerts_pkey" PRIMARY KEY ("AlertID");


--
-- TOC entry 3848 (class 2606 OID 69898)
-- Name: AuditEventDataRows AuditEventDataRows_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."AuditEventDataRows"
    ADD CONSTRAINT "AuditEventDataRows_pkey" PRIMARY KEY ("idAuditData");


--
-- TOC entry 3850 (class 2606 OID 69903)
-- Name: AuditEventDescriptions AuditEventDescriptions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."AuditEventDescriptions"
    ADD CONSTRAINT "AuditEventDescriptions_pkey" PRIMARY KEY ("idAuditEventDescription");


--
-- TOC entry 3852 (class 2606 OID 69908)
-- Name: AuditEvents AuditEvents_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."AuditEvents"
    ADD CONSTRAINT "AuditEvents_pkey" PRIMARY KEY ("idAuditEvent");


--
-- TOC entry 3854 (class 2606 OID 69913)
-- Name: CourtImportMaps CourtImportMaps_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."CourtImportMaps"
    ADD CONSTRAINT "CourtImportMaps_pkey" PRIMARY KEY ("CourtImportMapID");


--
-- TOC entry 3856 (class 2606 OID 69921)
-- Name: Courts Courts_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Courts"
    ADD CONSTRAINT "Courts_pkey" PRIMARY KEY ("CourtID");


--
-- TOC entry 3858 (class 2606 OID 69929)
-- Name: DASearchCriterias DASearchCriterias_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DASearchCriterias"
    ADD CONSTRAINT "DASearchCriterias_pkey" PRIMARY KEY ("DASearchCriteriaID");


--
-- TOC entry 3862 (class 2606 OID 69942)
-- Name: DATypes DATypes_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DATypes"
    ADD CONSTRAINT "DATypes_pkey" PRIMARY KEY ("DATypeID");


--
-- TOC entry 3860 (class 2606 OID 69937)
-- Name: DataUploads DataUploads_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DataUploads"
    ADD CONSTRAINT "DataUploads_pkey" PRIMARY KEY ("DataUploadID");


--
-- TOC entry 3864 (class 2606 OID 69947)
-- Name: DeletedReasons DeletedReasons_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DeletedReasons"
    ADD CONSTRAINT "DeletedReasons_pkey" PRIMARY KEY ("deletedReasonID");


--
-- TOC entry 3866 (class 2606 OID 69955)
-- Name: FAQs FAQs_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."FAQs"
    ADD CONSTRAINT "FAQs_pkey" PRIMARY KEY ("faqID");


--
-- TOC entry 3844 (class 2606 OID 69876)
-- Name: __MigrationHistory PK_dbo.__MigrationHistory; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."__MigrationHistory"
    ADD CONSTRAINT "PK_dbo.__MigrationHistory" PRIMARY KEY ("MigrationId", "ContextKey");


--
-- TOC entry 3868 (class 2606 OID 69960)
-- Name: Parties Parties_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Parties"
    ADD CONSTRAINT "Parties_pkey" PRIMARY KEY ("PartyID");


--
-- TOC entry 3870 (class 2606 OID 69965)
-- Name: Proceedings Proceedings_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Proceedings"
    ADD CONSTRAINT "Proceedings_pkey" PRIMARY KEY ("ProceedingID");


--
-- TOC entry 3872 (class 2606 OID 69970)
-- Name: ResultParties ResultParties_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."ResultParties"
    ADD CONSTRAINT "ResultParties_pkey" PRIMARY KEY ("ResultPartyID");


--
-- TOC entry 3874 (class 2606 OID 69975)
-- Name: ResultProceedings ResultProceedings_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."ResultProceedings"
    ADD CONSTRAINT "ResultProceedings_pkey" PRIMARY KEY ("ResultProceedingID");


--
-- TOC entry 3876 (class 2606 OID 69980)
-- Name: ResultSearches ResultSearches_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."ResultSearches"
    ADD CONSTRAINT "ResultSearches_pkey" PRIMARY KEY ("ResultSearchID");


--
-- TOC entry 3878 (class 2606 OID 69985)
-- Name: Roles Roles_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Roles"
    ADD CONSTRAINT "Roles_pkey" PRIMARY KEY (strength);


--
-- TOC entry 3880 (class 2606 OID 69990)
-- Name: Salutations Salutations_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Salutations"
    ADD CONSTRAINT "Salutations_pkey" PRIMARY KEY ("salutationID");


--
-- TOC entry 3882 (class 2606 OID 69998)
-- Name: Templates Templates_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Templates"
    ADD CONSTRAINT "Templates_pkey" PRIMARY KEY ("templateID");


--
-- TOC entry 3884 (class 2606 OID 70005)
-- Name: TraceStatus TraceStatus_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."TraceStatus"
    ADD CONSTRAINT "TraceStatus_pkey" PRIMARY KEY ("TraceStatusID");


--
-- TOC entry 3888 (class 2606 OID 70027)
-- Name: UnionTypes UnionTypes_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."UnionTypes"
    ADD CONSTRAINT "UnionTypes_pkey" PRIMARY KEY ("UnionTypeID");


--
-- TOC entry 3886 (class 2606 OID 70019)
-- Name: Unions Unions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Unions"
    ADD CONSTRAINT "Unions_pkey" PRIMARY KEY ("UnionID");


--
-- TOC entry 3890 (class 2606 OID 70032)
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY ("UserID");


--
-- TOC entry 3892 (class 2606 OID 70040)
-- Name: Works Works_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Works"
    ADD CONSTRAINT "Works_pkey" PRIMARY KEY ("workID");


--
-- TOC entry 3893 (class 2620 OID 70164)
-- Name: DataUploads insert_fm; Type: TRIGGER; Schema: dbo; Owner: dbadmin
--

CREATE TRIGGER insert_fm AFTER UPDATE ON dbo."DataUploads" FOR EACH ROW EXECUTE PROCEDURE dbo.insert_fm();


--
-- TOC entry 3894 (class 2620 OID 70166)
-- Name: Works tri_dataseq; Type: TRIGGER; Schema: dbo; Owner: dbadmin
--

CREATE TRIGGER tri_dataseq AFTER INSERT ON dbo."Works" FOR EACH ROW EXECUTE PROCEDURE dbo.tri_dataseq_proc();


--
-- TOC entry 3895 (class 2620 OID 70168)
-- Name: Works tri_insassignddate; Type: TRIGGER; Schema: dbo; Owner: dbadmin
--

CREATE TRIGGER tri_insassignddate AFTER INSERT ON dbo."Works" FOR EACH ROW EXECUTE PROCEDURE dbo.tri_insassignddate_proc();


--
-- TOC entry 3896 (class 2620 OID 70170)
-- Name: Works upd_works; Type: TRIGGER; Schema: dbo; Owner: dbadmin
--

CREATE TRIGGER upd_works AFTER UPDATE ON dbo."Works" FOR EACH ROW EXECUTE PROCEDURE dbo.upd_works_proc();


--
-- TOC entry 4071 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: dbadmin
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2023-10-23 15:25:00 BST

--
-- PostgreSQL database dump complete
--

