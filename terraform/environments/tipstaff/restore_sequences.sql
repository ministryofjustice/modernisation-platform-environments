--
-- PostgreSQL database dump
--

-- Dumped from database version 10.21
-- Dumped by pg_dump version 14.4

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
-- Name: addresses_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.addresses_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.addresses_seq OWNER TO dbadmin;

--
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
-- Name: Passports_passportID_seq; Type: SEQUENCE; Schema: dbo; Owner: dbadmin
--

CREATE SEQUENCE dbo.Passports_passportID_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbo.Passports_passportID_seq OWNER TO dbadmin;