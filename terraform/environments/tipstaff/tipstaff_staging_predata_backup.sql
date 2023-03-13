--
-- PostgreSQL database dump
--

-- Dumped from database version 10.21
-- Dumped by pg_dump version 15.1

-- Started on 2023-01-25 10:56:02 GMT

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
-- TOC entry 8 (class 2615 OID 63720)
-- Name: dbo; Type: SCHEMA; Schema: -; Owner: dbadmin
--

CREATE SCHEMA dbo;


ALTER SCHEMA dbo OWNER TO dbadmin;

--
-- TOC entry 239 (class 1259 OID 111604)
-- Name: addresses_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.addresses_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.addresses_seq OWNER TO dbadmin;

SET default_tablespace = '';

--
-- TOC entry 198 (class 1259 OID 65689)
-- Name: Addresses; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Addresses" (
    "addressID" integer DEFAULT nextval('dbo.addresses_seq'::regclass) NOT NULL,
    "addressLine1" character varying(100) NOT NULL,
    "addressLine2" character varying(100),
    "addressLine3" character varying(100),
    town character varying(100),
    county character varying(100),
    postcode character varying(10),
    phone character varying(20),
    "tipstaffRecordID" integer NOT NULL,
    "addresseeName" character varying(100),
    email character varying(100),
    "secondaryPhone" character varying(20)
);


ALTER TABLE dbo."Addresses" OWNER TO dbadmin;

--
-- TOC entry 240 (class 1259 OID 111606)
-- Name: applicants_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.applicants_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.applicants_seq OWNER TO dbadmin;

--
-- TOC entry 199 (class 1259 OID 65697)
-- Name: Applicants; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Applicants" (
    "ApplicantID" integer DEFAULT nextval('dbo.applicants_seq'::regclass) NOT NULL,
    "salutationID" integer NOT NULL,
    "nameLast" character varying(50) NOT NULL,
    "nameFirst" character varying(50) NOT NULL,
    "addressLine1" character varying(100),
    "addressLine2" character varying(100),
    "addressLine3" character varying(100),
    town character varying(100),
    county character varying(100),
    postcode character varying(10) NOT NULL,
    phone character varying(20),
    "tipstaffRecordID" integer NOT NULL,
    email character varying(100),
    "secondaryPhone" character varying(20)
);


ALTER TABLE dbo."Applicants" OWNER TO dbadmin;

--
-- TOC entry 241 (class 1259 OID 111608)
-- Name: attendancenotecodes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.attendancenotecodes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.attendancenotecodes_seq OWNER TO dbadmin;

--
-- TOC entry 200 (class 1259 OID 65705)
-- Name: AttendanceNoteCodes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AttendanceNoteCodes" (
    "AttendanceNoteCodeID" integer DEFAULT nextval('dbo.attendancenotecodes_seq'::regclass) NOT NULL,
    detail character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."AttendanceNoteCodes" OWNER TO dbadmin;

--
-- TOC entry 242 (class 1259 OID 111610)
-- Name: attendancenotes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.attendancenotes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.attendancenotes_seq OWNER TO dbadmin;

--
-- TOC entry 201 (class 1259 OID 65710)
-- Name: AttendanceNotes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AttendanceNotes" (
    "AttendanceNoteID" integer DEFAULT nextval('dbo.attendancenotes_seq'::regclass) NOT NULL,
    "callDated" timestamp without time zone NOT NULL,
    "callStarted" timestamp without time zone,
    "callEnded" timestamp without time zone,
    "callDetails" character varying(1000) NOT NULL,
    "AttendanceNoteCodeID" integer NOT NULL,
    "tipstaffRecordID" integer NOT NULL
);


ALTER TABLE dbo."AttendanceNotes" OWNER TO dbadmin;

--
-- TOC entry 243 (class 1259 OID 111612)
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
-- TOC entry 202 (class 1259 OID 65718)
-- Name: AuditEventDataRows; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEventDataRows" (
    "idAuditData" integer DEFAULT nextval('dbo.auditeventdatarows_seq'::regclass) NOT NULL,
    "idAuditEvent" integer NOT NULL,
    "ColumnName" character varying(200) NOT NULL,
    "Was" character varying(200) NOT NULL,
    "Now" character varying(200) NOT NULL
);


ALTER TABLE dbo."AuditEventDataRows" OWNER TO dbadmin;

--
-- TOC entry 244 (class 1259 OID 111614)
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
-- TOC entry 203 (class 1259 OID 65726)
-- Name: AuditEventDescriptions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEventDescriptions" (
    "idAuditEventDescription" integer DEFAULT nextval('dbo.auditeventdescriptions_seq'::regclass) NOT NULL,
    "AuditDescription" character varying(40) NOT NULL
);


ALTER TABLE dbo."AuditEventDescriptions" OWNER TO dbadmin;

--
-- TOC entry 245 (class 1259 OID 111616)
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
-- TOC entry 204 (class 1259 OID 65731)
-- Name: AuditEvents; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."AuditEvents" (
    "idAuditEvent" integer DEFAULT nextval('dbo.auditevents_seq'::regclass) NOT NULL,
    "EventDate" timestamp without time zone NOT NULL,
    "UserID" character varying(40) NOT NULL,
    "idAuditEventDescription" integer NOT NULL,
    "RecordChanged" character varying(256) NOT NULL,
    "RecordAddedTo" integer,
    "DeletedReasonID" integer
);


ALTER TABLE dbo."AuditEvents" OWNER TO dbadmin;

--
-- TOC entry 246 (class 1259 OID 111618)
-- Name: caordertypes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.caordertypes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.caordertypes_seq OWNER TO dbadmin;

--
-- TOC entry 205 (class 1259 OID 65736)
-- Name: CAOrderTypes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CAOrderTypes" (
    "caOrderTypeID" integer DEFAULT nextval('dbo.caordertypes_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."CAOrderTypes" OWNER TO dbadmin;

--
-- TOC entry 247 (class 1259 OID 111620)
-- Name: casereviewstatus_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.casereviewstatus_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.casereviewstatus_seq OWNER TO dbadmin;

--
-- TOC entry 207 (class 1259 OID 65749)
-- Name: CaseReviewStatus; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CaseReviewStatus" (
    "caseReviewStatusID" integer DEFAULT nextval('dbo.casereviewstatus_seq'::regclass) NOT NULL,
    "Detail" character varying(20) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."CaseReviewStatus" OWNER TO dbadmin;

--
-- TOC entry 248 (class 1259 OID 111622)
-- Name: casereviews_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.casereviews_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.casereviews_seq OWNER TO dbadmin;

--
-- TOC entry 206 (class 1259 OID 65741)
-- Name: CaseReviews; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CaseReviews" (
    "caseReviewID" integer DEFAULT nextval('dbo.casereviews_seq'::regclass) NOT NULL,
    "reviewDate" timestamp without time zone,
    "actionTaken" character varying(800),
    "caseReviewStatusID" integer NOT NULL,
    "nextReviewDate" timestamp without time zone NOT NULL,
    "tipstaffRecordID" integer NOT NULL
);


ALTER TABLE dbo."CaseReviews" OWNER TO dbadmin;

--
-- TOC entry 249 (class 1259 OID 111624)
-- Name: casestatus_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.casestatus_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.casestatus_seq OWNER TO dbadmin;

--
-- TOC entry 208 (class 1259 OID 65754)
-- Name: CaseStatus; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CaseStatus" (
    "caseStatusID" integer DEFAULT nextval('dbo.casestatus_seq'::regclass) NOT NULL,
    "Detail" character varying(30) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50),
    sequence integer
);


ALTER TABLE dbo."CaseStatus" OWNER TO dbadmin;

--
-- TOC entry 250 (class 1259 OID 111626)
-- Name: childrelationship_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.childrelationship_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.childrelationship_seq OWNER TO dbadmin;

--
-- TOC entry 209 (class 1259 OID 65759)
-- Name: ChildRelationships; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ChildRelationships" (
    "childRelationshipID" integer DEFAULT nextval('dbo.childrelationship_seq'::regclass) NOT NULL,
    "Detail" character varying(40) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."ChildRelationships" OWNER TO dbadmin;

--
-- TOC entry 251 (class 1259 OID 111628)
-- Name: children_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.children_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.children_seq OWNER TO dbadmin;

--
-- TOC entry 210 (class 1259 OID 65764)
-- Name: Children; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Children" (
    "childID" integer DEFAULT nextval('dbo.children_seq'::regclass) NOT NULL,
    "nameLast" character varying(50) NOT NULL,
    "nameFirst" character varying(50) NOT NULL,
    "nameMiddle" character varying(50),
    "dateOfBirth" timestamp without time zone,
    "genderID" integer NOT NULL,
    height text,
    build text,
    "hairColour" text,
    "eyeColour" text,
    specialfeatures text,
    "countryID" integer NOT NULL,
    "tipstaffRecordID" integer NOT NULL,
    "nationalityID" integer,
    "skinColourID" integer,
    "PNCID" character varying(30)
);


ALTER TABLE dbo."Children" OWNER TO dbadmin;

--
-- TOC entry 252 (class 1259 OID 111630)
-- Name: contacttypes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.contacttypes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.contacttypes_seq OWNER TO dbadmin;

--
-- TOC entry 212 (class 1259 OID 65780)
-- Name: ContactTypes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ContactTypes" (
    "contactTypeID" integer DEFAULT nextval('dbo.contacttypes_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."ContactTypes" OWNER TO dbadmin;

--
-- TOC entry 253 (class 1259 OID 111632)
-- Name: contacts_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.contacts_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.contacts_seq OWNER TO dbadmin;

--
-- TOC entry 211 (class 1259 OID 65772)
-- Name: Contacts; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Contacts" (
    "contactID" integer DEFAULT nextval('dbo.contacts_seq'::regclass) NOT NULL,
    "lastName" character varying(50) NOT NULL,
    "addressLine1" character varying(100) NOT NULL,
    "addressLine2" character varying(100),
    "addressLine3" character varying(100),
    town character varying(100),
    county character varying(100),
    postcode character varying(10) NOT NULL,
    "DX" character varying(50),
    "phoneHome" character varying(20),
    "phoneMobile" character varying(20),
    email character varying(60),
    notes character varying(2000),
    "contactTypeID" integer NOT NULL,
    "firstName" character varying(50),
    "salutationID" integer NOT NULL,
    "Retention" boolean DEFAULT false
);


ALTER TABLE dbo."Contacts" OWNER TO dbadmin;

--
-- TOC entry 254 (class 1259 OID 111634)
-- Name: countries_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.countries_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.countries_seq OWNER TO dbadmin;

--
-- TOC entry 213 (class 1259 OID 65785)
-- Name: Countries; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Countries" (
    "countryID" integer DEFAULT nextval('dbo.countries_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Countries" OWNER TO dbadmin;

--
-- TOC entry 214 (class 1259 OID 65790)
-- Name: CurrentPhase; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."CurrentPhase" (
    "Release" character varying(10) NOT NULL,
    "ReleaseDate" timestamp without time zone NOT NULL
);


ALTER TABLE dbo."CurrentPhase" OWNER TO dbadmin;

--
-- TOC entry 255 (class 1259 OID 111636)
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
-- TOC entry 215 (class 1259 OID 65793)
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
-- TOC entry 216 (class 1259 OID 65798)
-- Name: DeletedTipstaffRecords; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DeletedTipstaffRecords" (
    "TipstaffRecordID" integer NOT NULL,
    "deletedReasonID" integer NOT NULL,
    discriminator character varying(50) NOT NULL,
    "UniqueRecordID" character varying(10) NOT NULL
);


ALTER TABLE dbo."DeletedTipstaffRecords" OWNER TO dbadmin;

--
-- TOC entry 256 (class 1259 OID 111638)
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
-- TOC entry 217 (class 1259 OID 65803)
-- Name: Divisions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Divisions" (
    "divisionID" integer DEFAULT nextval('dbo.divisions_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    "Prefix" character varying(4000) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Divisions" OWNER TO dbadmin;

--
-- TOC entry 257 (class 1259 OID 111640)
-- Name: documentstatus_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.documentstatus_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.documentstatus_seq OWNER TO dbadmin;

--
-- TOC entry 219 (class 1259 OID 65819)
-- Name: DocumentStatus; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DocumentStatus" (
    "DocumentStatusID" integer DEFAULT nextval('dbo.documentstatus_seq'::regclass) NOT NULL,
    "Detail" character varying(40) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."DocumentStatus" OWNER TO dbadmin;

--
-- TOC entry 258 (class 1259 OID 111642)
-- Name: documenttypes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.documenttypes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.documenttypes_seq OWNER TO dbadmin;

--
-- TOC entry 220 (class 1259 OID 65824)
-- Name: DocumentTypes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."DocumentTypes" (
    "documentTypeID" integer DEFAULT nextval('dbo.documenttypes_seq'::regclass) NOT NULL,
    "Detail" character varying(100),
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."DocumentTypes" OWNER TO dbadmin;

--
-- TOC entry 259 (class 1259 OID 111644)
-- Name: documents_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.documents_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.documents_seq OWNER TO dbadmin;

--
-- TOC entry 218 (class 1259 OID 65811)
-- Name: Documents; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Documents" (
    "documentID" integer DEFAULT nextval('dbo.documents_seq'::regclass) NOT NULL,
    "documentReference" character varying(60) NOT NULL,
    "countryID" integer,
    "documentStatusID" integer NOT NULL,
    "documentTypeID" integer NOT NULL,
    "templateID" integer,
    "createdOn" timestamp without time zone NOT NULL,
    "createdBy" character varying(50),
    "tipstaffRecordID" integer NOT NULL,
    "binaryFile" bytea,
    "fileName" character varying(256),
    "mimeType" character varying(300),
    "nationalityID" integer
);


ALTER TABLE dbo."Documents" OWNER TO dbadmin;

--
-- TOC entry 260 (class 1259 OID 111646)
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
-- TOC entry 221 (class 1259 OID 65838)
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
-- TOC entry 261 (class 1259 OID 111648)
-- Name: faxcodes_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.faxcodes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.faxcodes_seq OWNER TO dbadmin;

--
-- TOC entry 223 (class 1259 OID 65869)
-- Name: FaxCodes; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."FaxCodes" (
    "faxCodeID" integer DEFAULT nextval('dbo.faxcodes_seq'::regclass) NOT NULL,
    detail character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."FaxCodes" OWNER TO dbadmin;

--
-- TOC entry 262 (class 1259 OID 111650)
-- Name: genders_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.genders_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.genders_seq OWNER TO dbadmin;

--
-- TOC entry 222 (class 1259 OID 65855)
-- Name: Genders; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Genders" (
    "genderID" integer DEFAULT nextval('dbo.genders_seq'::regclass) NOT NULL,
    detail character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Genders" OWNER TO dbadmin;

--
-- TOC entry 263 (class 1259 OID 111652)
-- Name: nationalities_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.nationalities_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.nationalities_seq OWNER TO dbadmin;

--
-- TOC entry 224 (class 1259 OID 65888)
-- Name: Nationalities; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Nationalities" (
    "nationalityID" integer DEFAULT nextval('dbo.nationalities_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Nationalities" OWNER TO dbadmin;

--
-- TOC entry 277 (class 1259 OID 121679)
-- Name: Passports; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Passports" (
    "passportID" integer NOT NULL,
    "passportReference" character varying(60) NOT NULL,
    "countryID" integer,
    "nationalityID" integer NOT NULL,
    "documentStatusID" integer NOT NULL,
    "templateID" integer,
    "createdOn" timestamp without time zone NOT NULL,
    "createdBy" character varying(50),
    "tipstaffRecordID" integer NOT NULL,
    "binaryFile" bytea,
    "fileName" character varying(256),
    "mimeType" character varying(300),
    comments character varying(1000)
);


ALTER TABLE dbo."Passports" OWNER TO dbadmin;

--
-- TOC entry 276 (class 1259 OID 121677)
-- Name: Passports_passportID_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo."Passports_passportID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo."Passports_passportID_seq" OWNER TO dbadmin;

--
-- TOC entry 4267 (class 0 OID 0)
-- Dependencies: 276
-- Name: Passports_passportID_seq; Type: SEQUENCE OWNED BY; Schema: dbo; Owner: dbadmin
--

ALTER SEQUENCE dbo."Passports_passportID_seq" OWNED BY dbo."Passports"."passportID";


--
-- TOC entry 264 (class 1259 OID 111654)
-- Name: policeforces_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.policeforces_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.policeforces_seq OWNER TO dbadmin;

--
-- TOC entry 225 (class 1259 OID 65909)
-- Name: PoliceForces; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."PoliceForces" (
    "policeForceID" integer DEFAULT nextval('dbo.policeforces_seq'::regclass) NOT NULL,
    "policeForceName" character varying(255) NOT NULL,
    "policeForceEmail" character varying(255) NOT NULL,
    active boolean,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."PoliceForces" OWNER TO dbadmin;

--
-- TOC entry 265 (class 1259 OID 111656)
-- Name: protectivemarkings_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.protectivemarkings_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.protectivemarkings_seq OWNER TO dbadmin;

--
-- TOC entry 226 (class 1259 OID 65932)
-- Name: ProtectiveMarkings; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ProtectiveMarkings" (
    "protectiveMarkingID" integer DEFAULT nextval('dbo.protectivemarkings_seq'::regclass) NOT NULL,
    "Detail" character varying(15) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."ProtectiveMarkings" OWNER TO dbadmin;

--
-- TOC entry 266 (class 1259 OID 111658)
-- Name: respondents_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.respondents_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.respondents_seq OWNER TO dbadmin;

--
-- TOC entry 227 (class 1259 OID 65952)
-- Name: Respondents; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Respondents" (
    "respondentID" integer DEFAULT nextval('dbo.respondents_seq'::regclass) NOT NULL,
    "nameLast" character varying(50) NOT NULL,
    "nameFirst" character varying(50) NOT NULL,
    "nameMiddle" character varying(50),
    "dateOfBirth" timestamp without time zone,
    "genderID" integer NOT NULL,
    "childRelationshipID" integer NOT NULL,
    "hairColour" character varying(50),
    "eyeColour" character varying(50),
    height character varying(50),
    build character varying(50),
    specialfeatures character varying(250),
    "countryID" integer NOT NULL,
    "riskOfViolence" character varying(100),
    "riskOfDrugs" character varying(100),
    "tipstaffRecordID" integer NOT NULL,
    "nationalityID" integer,
    "skinColourID" integer,
    "PNCID" character varying(30),
    "addressLine1" character varying(100),
    "addressLine2" character varying(100),
    "addressLine3" character varying(100),
    town character varying(100),
    county character varying(100),
    postcode character varying(10),
    phone character varying(20),
    email character varying(100),
    "secondaryPhone" character varying(20)
);


ALTER TABLE dbo."Respondents" OWNER TO dbadmin;

--
-- TOC entry 267 (class 1259 OID 111660)
-- Name: results_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.results_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.results_seq OWNER TO dbadmin;

--
-- TOC entry 228 (class 1259 OID 65962)
-- Name: Results; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Results" (
    "resultID" integer DEFAULT nextval('dbo.results_seq'::regclass) NOT NULL,
    "Detail" character varying(20) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."Results" OWNER TO dbadmin;

--
-- TOC entry 229 (class 1259 OID 65969)
-- Name: Roles; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Roles" (
    strength integer NOT NULL,
    "Detail" character varying(20) NOT NULL
);


ALTER TABLE dbo."Roles" OWNER TO dbadmin;

--
-- TOC entry 268 (class 1259 OID 111662)
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
-- TOC entry 230 (class 1259 OID 65981)
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
-- TOC entry 269 (class 1259 OID 111664)
-- Name: skincolours_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.skincolours_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.skincolours_seq OWNER TO dbadmin;

--
-- TOC entry 231 (class 1259 OID 65991)
-- Name: SkinColours; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."SkinColours" (
    "skinColourID" integer DEFAULT nextval('dbo.skincolours_seq'::regclass) NOT NULL,
    "Detail" character varying(50) NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."SkinColours" OWNER TO dbadmin;

--
-- TOC entry 270 (class 1259 OID 111666)
-- Name: solicitorfirms_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.solicitorfirms_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.solicitorfirms_seq OWNER TO dbadmin;

--
-- TOC entry 232 (class 1259 OID 66002)
-- Name: SolicitorFirms; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."SolicitorFirms" (
    "solicitorFirmID" integer DEFAULT nextval('dbo.solicitorfirms_seq'::regclass) NOT NULL,
    "firmName" character varying(50) NOT NULL,
    "addressLine1" character varying(100) NOT NULL,
    "addressLine2" character varying(100),
    "addressLine3" character varying(100),
    town character varying(100),
    county character varying(100),
    postcode character varying(10),
    "DX" character varying(50),
    "phoneDayTime" character varying(20),
    "phoneOutofHours" character varying(20),
    email character varying(60),
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50)
);


ALTER TABLE dbo."SolicitorFirms" OWNER TO dbadmin;

--
-- TOC entry 271 (class 1259 OID 111668)
-- Name: solicitors_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.solicitors_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.solicitors_seq OWNER TO dbadmin;

--
-- TOC entry 235 (class 1259 OID 66034)
-- Name: Solicitors; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Solicitors" (
    "solicitorID" integer DEFAULT nextval('dbo.solicitors_seq'::regclass) NOT NULL,
    "firstName" character varying(50),
    "lastName" character varying(50) NOT NULL,
    "solicitorFirmID" integer,
    "salutationID" integer NOT NULL,
    "phoneDayTime" character varying(20),
    "phoneOutofHours" character varying(20),
    email character varying(60),
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50),
    "Retention" boolean DEFAULT false
);


ALTER TABLE dbo."Solicitors" OWNER TO dbadmin;

--
-- TOC entry 272 (class 1259 OID 111670)
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
-- TOC entry 234 (class 1259 OID 66020)
-- Name: Templates; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Templates" (
    "templateID" integer DEFAULT nextval('dbo.templates_seq'::regclass) NOT NULL,
    "Discriminator" character varying(128) NOT NULL,
    "templateName" character varying(80) NOT NULL,
    addresseerequired boolean NOT NULL,
    active boolean NOT NULL,
    deactivated timestamp without time zone,
    "deactivatedBy" character varying(50),
    "templateXML" text
);


ALTER TABLE dbo."Templates" OWNER TO dbadmin;

--
-- TOC entry 273 (class 1259 OID 111672)
-- Name: tipstaffpoliceforces_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.tipstaffpoliceforces_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.tipstaffpoliceforces_seq OWNER TO dbadmin;

--
-- TOC entry 233 (class 1259 OID 66011)
-- Name: TipstaffPoliceForces; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."TipstaffPoliceForces" (
    "tipstaffRecordPoliceForceID" integer DEFAULT nextval('dbo.tipstaffpoliceforces_seq'::regclass) NOT NULL,
    "tipstaffRecordID" integer NOT NULL,
    "policeForceID" integer NOT NULL
);


ALTER TABLE dbo."TipstaffPoliceForces" OWNER TO dbadmin;

--
-- TOC entry 237 (class 1259 OID 66070)
-- Name: TipstaffRecordSolicitors; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."TipstaffRecordSolicitors" (
    "tipstaffRecordID" integer NOT NULL,
    "solicitorID" integer NOT NULL
);


ALTER TABLE dbo."TipstaffRecordSolicitors" OWNER TO dbadmin;

--
-- TOC entry 274 (class 1259 OID 111674)
-- Name: tipstaffrecords_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.tipstaffrecords_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.tipstaffrecords_seq OWNER TO dbadmin;

--
-- TOC entry 236 (class 1259 OID 66043)
-- Name: TipstaffRecords; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."TipstaffRecords" (
    "tipstaffRecordID" integer DEFAULT nextval('dbo.tipstaffrecords_seq'::regclass) NOT NULL,
    "createdBy" character varying(50) NOT NULL,
    "createdOn" timestamp without time zone NOT NULL,
    "protectiveMarkingID" integer NOT NULL,
    "resultID" integer,
    "nextReviewDate" timestamp without time zone NOT NULL,
    "resultDate" timestamp without time zone,
    "arrestCount" integer,
    "prisonCount" integer,
    "resultEnteredBy" character varying(50),
    "caseStatusID" integer NOT NULL,
    "sentSCD26" timestamp without time zone,
    "orderDated" timestamp without time zone,
    "orderReceived" timestamp without time zone,
    "officerDealing" character varying(50),
    "caOrderTypeID" integer,
    "caseNumber" character varying(50),
    "expiryDate" timestamp without time zone,
    "divisionID" integer,
    "Discriminator" character varying(128) NOT NULL,
    "EldestChild" character varying(50),
    "RespondentName" character varying(153),
    "DateExecuted" timestamp without time zone,
    "NPO" character varying(30),
    "DateCirculated" timestamp without time zone,
    "Retention" boolean DEFAULT false
);


ALTER TABLE dbo."TipstaffRecords" OWNER TO dbadmin;

--
-- TOC entry 275 (class 1259 OID 111676)
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
-- TOC entry 238 (class 1259 OID 66080)
-- Name: Users; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Users" (
    "UserID" integer DEFAULT nextval('dbo.users_seq'::regclass) NOT NULL,
    "Name" character varying(100) NOT NULL,
    "DisplayName" character varying(30) NOT NULL,
    "LastActive" timestamp without time zone,
    "RoleStrength" integer NOT NULL
);


ALTER TABLE dbo."Users" OWNER TO dbadmin;

--
-- TOC entry 197 (class 1259 OID 64329)
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
-- TOC entry 3965 (class 2604 OID 121682)
-- Name: Passports passportID; Type: DEFAULT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Passports" ALTER COLUMN "passportID" SET DEFAULT nextval('dbo."Passports_passportID_seq"'::regclass);


ALTER SEQUENCE dbo."addresses_seq" OWNED BY dbo."Addresses"."addressID";
ALTER SEQUENCE dbo."applicants_seq" OWNED BY dbo."Applicants"."ApplicantID";
ALTER SEQUENCE dbo."attendancenotecodes_seq" OWNED BY dbo."AttendanceNoteCodes"."AttendanceNoteCodeID";
ALTER SEQUENCE dbo."attendancenotes_seq" OWNED BY dbo."AttendanceNotes"."AttendanceNoteID";
ALTER SEQUENCE dbo."auditeventdatarows_seq" OWNED BY dbo."AuditEventDataRows"."idAuditData";
ALTER SEQUENCE dbo."auditeventdescriptions_seq" OWNED BY dbo."AuditEventDescriptions"."idAuditEventDescription";
ALTER SEQUENCE dbo."auditevents_seq" OWNED BY dbo."AuditEvents"."idAuditEvent";
ALTER SEQUENCE dbo."caordertypes_seq" OWNED BY dbo."CAOrderTypes"."caOrderTypeID";
ALTER SEQUENCE dbo."casereviews_seq" OWNED BY dbo."CaseReviews"."caseReviewID";
ALTER SEQUENCE dbo."casereviewstatus_seq" OWNED BY dbo."CaseReviewStatus"."caseReviewStatusID";
ALTER SEQUENCE dbo."casestatus_seq" OWNED BY dbo."CaseStatus"."caseStatusID";
ALTER SEQUENCE dbo."childrelationship_seq" OWNED BY dbo."ChildRelationships"."childRelationshipID";
ALTER SEQUENCE dbo."children_seq" OWNED BY dbo."Children"."childID";
ALTER SEQUENCE dbo."contacts_seq" OWNED BY dbo."Contacts"."contactID";
ALTER SEQUENCE dbo."contacttypes_seq" OWNED BY dbo."ContactTypes"."contactTypeID";
ALTER SEQUENCE dbo."countries_seq" OWNED BY dbo."Countries"."countryID";
ALTER SEQUENCE dbo."deletedreasons_seq" OWNED BY dbo."DeletedReasons"."deletedReasonID";
ALTER SEQUENCE dbo."divisions_seq" OWNED BY dbo."Divisions"."divisionID";
ALTER SEQUENCE dbo."documents_seq" OWNED BY dbo."Documents"."documentID";
ALTER SEQUENCE dbo."documentstatus_seq" OWNED BY dbo."DocumentStatus"."DocumentStatusID";
ALTER SEQUENCE dbo."documenttypes_seq" OWNED BY dbo."DocumentTypes"."documentTypeID";
ALTER SEQUENCE dbo."faqs_seq" OWNED BY dbo."FAQs"."faqID";
ALTER SEQUENCE dbo."faxcodes_seq" OWNED BY dbo."FaxCodes"."faxCodeID";
ALTER SEQUENCE dbo."genders_seq" OWNED BY dbo."Genders"."genderID";
ALTER SEQUENCE dbo."nationalities_seq" OWNED BY dbo."Nationalities"."nationalityID";
ALTER SEQUENCE dbo."Passports_passportID_seq" OWNED BY dbo."Passports"."passportID";
ALTER SEQUENCE dbo."policeforces_seq" OWNED BY dbo."PoliceForces"."policeForceID";
ALTER SEQUENCE dbo."protectivemarkings_seq" OWNED BY dbo."ProtectiveMarkings"."protectiveMarkingID";
ALTER SEQUENCE dbo."respondents_seq" OWNED BY dbo."Respondents"."respondentID";
ALTER SEQUENCE dbo."results_seq" OWNED BY dbo."Results"."resultID";
ALTER SEQUENCE dbo."salutations_seq" OWNED BY dbo."Salutations"."salutationID";
ALTER SEQUENCE dbo."skincolours_seq" OWNED BY dbo."SkinColours"."skinColourID";
ALTER SEQUENCE dbo."solicitorfirms_seq" OWNED BY dbo."SolicitorFirms"."solicitorFirmID";
ALTER SEQUENCE dbo."solicitors_seq" OWNED BY dbo."Solicitors"."solicitorID";
ALTER SEQUENCE dbo."templates_seq" OWNED BY dbo."Templates"."templateID";
ALTER SEQUENCE dbo."tipstaffpoliceforces_seq" OWNED BY dbo."TipstaffPoliceForces"."tipstaffRecordPoliceForceID";
ALTER SEQUENCE dbo."tipstaffrecords_seq" OWNED BY dbo."TipstaffRecords"."tipstaffRecordID";
ALTER SEQUENCE dbo."users_seq" OWNED BY dbo."Users"."UserID";