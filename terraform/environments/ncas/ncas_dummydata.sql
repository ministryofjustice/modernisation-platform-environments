--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7
-- Dumped by pg_dump version 15.3

-- Started on 2023-10-24 16:06:45 BST

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
-- TOC entry 5 (class 2615 OID 25034)
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
-- TOC entry 210 (class 1259 OID 25035)
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
-- TOC entry 211 (class 1259 OID 25036)
-- Name: ADGroups; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."ADGroups" (
    "ADGroupID" integer DEFAULT nextval('dbo.adgroups_seq'::regclass) NOT NULL,
    "Name" character varying(80) NOT NULL,
    "RoleStrength" integer NOT NULL
);


ALTER TABLE dbo."ADGroups" OWNER TO dbadmin;

--
-- TOC entry 212 (class 1259 OID 25040)
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
-- TOC entry 213 (class 1259 OID 25041)
-- Name: Actions; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Actions" (
    "ActionID" integer DEFAULT nextval('dbo.actions_seq'::regclass) NOT NULL,
    "Name" character varying(7) NOT NULL
);


ALTER TABLE dbo."Actions" OWNER TO dbadmin;

--
-- TOC entry 214 (class 1259 OID 25045)
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
-- TOC entry 215 (class 1259 OID 25046)
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
-- TOC entry 216 (class 1259 OID 25050)
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
-- TOC entry 217 (class 1259 OID 25051)
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
-- TOC entry 218 (class 1259 OID 25057)
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
-- TOC entry 219 (class 1259 OID 25058)
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
-- TOC entry 220 (class 1259 OID 25064)
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
-- TOC entry 221 (class 1259 OID 25065)
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
-- TOC entry 222 (class 1259 OID 25071)
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
-- TOC entry 223 (class 1259 OID 25072)
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
-- TOC entry 224 (class 1259 OID 25076)
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
-- TOC entry 225 (class 1259 OID 25077)
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
-- TOC entry 226 (class 1259 OID 25081)
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
-- TOC entry 227 (class 1259 OID 25082)
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
-- TOC entry 228 (class 1259 OID 25086)
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
-- TOC entry 229 (class 1259 OID 25087)
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
-- TOC entry 230 (class 1259 OID 25091)
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
-- TOC entry 231 (class 1259 OID 25092)
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
-- TOC entry 232 (class 1259 OID 25097)
-- Name: Roles; Type: TABLE; Schema: dbo; Owner: dbadmin
--

CREATE TABLE dbo."Roles" (
    strength integer NOT NULL,
    "Detail" character varying(20) NOT NULL
);


ALTER TABLE dbo."Roles" OWNER TO dbadmin;

--
-- TOC entry 233 (class 1259 OID 25100)
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
-- TOC entry 234 (class 1259 OID 25101)
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
-- TOC entry 235 (class 1259 OID 25107)
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
-- TOC entry 4372 (class 0 OID 25036)
-- Dependencies: 211
-- Data for Name: ADGroups; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."ADGroups" ("ADGroupID", "Name", "RoleStrength") FROM stdin;
1	gg_ssg_developers	100
\.


--
-- TOC entry 4374 (class 0 OID 25041)
-- Dependencies: 213
-- Data for Name: Actions; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Actions" ("ActionID", "Name") FROM stdin;
1	Added
2	Updated
3	Deleted
\.


--
-- TOC entry 4376 (class 0 OID 25046)
-- Dependencies: 215
-- Data for Name: Audits; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Audits" ("AuditID", "Date", "UserID", "ObjPrimaryKey", "RootPrimaryKey", "ActionID", "Object") FROM stdin;
1	2014-05-06 12:15:37.777	1	1	\N	1	User
2	2023-10-24 14:43:28.82514	0	5	\N	1	NeutralCitation
\.


--
-- TOC entry 4378 (class 0 OID 25051)
-- Dependencies: 217
-- Data for Name: BulkImports; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."BulkImports" ("BulkImportID", "Uploaded", "Filename", "CompanyID", "UploadedByID", "HashValue") FROM stdin;
\.


--
-- TOC entry 4380 (class 0 OID 25058)
-- Dependencies: 219
-- Data for Name: Changes; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Changes" ("ChangeID", "AuditID", "ColumnName", "Was", "Now") FROM stdin;
1	19	ContractedNumber	HC12E03946	null
\.


--
-- TOC entry 4382 (class 0 OID 25065)
-- Dependencies: 221
-- Data for Name: Companies; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Companies" ("CompanyID", "Name", "Add1", "Add2", "Add3", "Add4", "Add5", "Postcode", "DX", "Phone", "Fax", "Email1", "Email2", "Active") FROM stdin;
\.


--
-- TOC entry 4384 (class 0 OID 25072)
-- Dependencies: 223
-- Data for Name: Courts; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Courts" ("CourtID", "Name", "Acronym", "Active") FROM stdin;
1	High Court	EWHC	t
2	Family Court	EWFC	t
3	Court of Protection	EWCOP	t
4	Court of Appeal	EWCA	t
\.


--
-- TOC entry 4386 (class 0 OID 25077)
-- Dependencies: 225
-- Data for Name: DeleteReasons; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."DeleteReasons" (id, "Description", "Deactivated", "deactivatedOn", "deactivatedBy") FROM stdin;
1	Wrong Court	f	\N	\N
2	Wrong Division	f	\N	\N
3	Wrong Judge	f	\N	\N
4	Wrong Date	f	\N	\N
\.


--
-- TOC entry 4388 (class 0 OID 25082)
-- Dependencies: 227
-- Data for Name: Divisions; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Divisions" ("DivisionID", "CourtID", "Acronym", "Name", "Active") FROM stdin;
1	1	Admin	Admin Court	t
2	1	Admlty	Admiralty	t
3	1	Ch	Chancery	t
4	1	Comm	Commercial Court	t
5	1	COP	Court of Protection	t
6	1	Fam	Family Court	t
7	1	Pat	Patents Court	f
9	1	TCC	Technology and Constrction Court	t
10	1	IPEC	Intellectual Property Enterprise Court	t
12	4	Crim	Criminal Division	t
13	4	Civ	Civil Division	t
14	1	SCCO	Senior Courts Costs Office	t
8	1	KB	King's Bench	t
\.


--
-- TOC entry 4390 (class 0 OID 25087)
-- Dependencies: 229
-- Data for Name: Judges; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Judges" ("JudgeID", "Name", "Active", "Archive") FROM stdin;
1	Murdock J	t	f
2	Parker J	t	f
3	Watson, HHJ	t	f
5	hhj Wayne	t	f
6	Lj Stacy, Hank Wilfred	t	f
7	DEPUTY DISTRICT JUDGE DEREK	t	f
9	richards / reed j	t	f
10	Curtis	t	f
\.


--
-- TOC entry 4392 (class 0 OID 25092)
-- Dependencies: 231
-- Data for Name: NeutralCitations; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."NeutralCitations" ("NeutralCitationID", "CitationNumber", "Party1Name", "Party2Name", "JudgmentYear", "CourtID", "DivisionID", "CaseNumber", "ContractedNumber", "JudgeID", "JudgmentDate", "CreatedByID", "CreatedOn", "Deleted", "DeletedReasonID", "DeletedOn", "DeletedByID", "BulkImportID", "Retention") FROM stdin;
5	1	MURPHY	\N	2023	1	1	\N	\N	2	2023-10-02 00:00:00	3	2023-10-24 14:43:28.712342	f	\N	\N	\N	\N	f
\.


--
-- TOC entry 4393 (class 0 OID 25097)
-- Dependencies: 232
-- Data for Name: Roles; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Roles" (strength, "Detail") FROM stdin;
-1	Denied
0	Deactive
50	JudgesClerk
75	CRATU
100	SSG
\.


--
-- TOC entry 4395 (class 0 OID 25101)
-- Dependencies: 234
-- Data for Name: Users; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."Users" ("UserID", "Name", "DisplayName", "LastActive", "RoleStrength") FROM stdin;
0	Migrated Record	Migrated Record	\N	0
1	mark.butler1@justice.gov.uk	Mark Butler	2023-07-25 15:27:25.061769	100
2	jamil.qurashi@justice.gov.uk	Jamil Qurashi	2023-05-30 12:51:39.681253	100
4	mateusz.kolakowski@justice.gov.uk	Mateusz Kolakowski	2023-10-24 14:43:56.082008	100
3	matthew.searle@justice.gov.uk	Matthew Searle	2023-10-24 14:49:21.302146	100
\.


--
-- TOC entry 4396 (class 0 OID 25107)
-- Dependencies: 235
-- Data for Name: __MigrationHistory; Type: TABLE DATA; Schema: dbo; Owner: dbadmin
--

COPY dbo."__MigrationHistory" ("MigrationId", "ContextKey", "Model", "ProductVersion") FROM stdin;
201910031253047_InitialMigration	NCAS.Models.DataContext	\\x1f8b0800000000000400ed5ddd6edcb815be2fd07718cc6591cdc476bcdd06f62e623b69d36eec20ce6eb757813ca338ea6aa4a97ed218459fac177da4be42255194f8730e79284a9ac9b608107828f2f090fc78f8f791e73ffffaf7d9779fb7f1e25398e5519a9c2f8f1e3f592ec2649d6ea2e4fe7c59161fbefa66f9ddb7bffed5d98bcdf6f3e2471eefa48e57a54cf2f3e5c7a2d83d5badf2f5c7701be48fb7d13a4bf3f443f1789d6e57c1265d1d3f79f2bbd5d1d12aac442c2b598bc5d9db3229a26dd8fca87e5ea6c93adc156510bf4e37619cb7e1d597db46eae23ad886f92e5887e7cbebcbe7b78f59b4e5e2791c05950ab761fc61b90892242d82a252f0d90f79785b6469727fbbab0282f8ddc32eace27d08e23c6c157fd647a796e1c9715d86559f908b5a9779916e1d051e9db495b252930faada65576955b5bda8aab778a84bdd54ddf9f2f99a0956b37a7619677534a95e1fb3d88f1675d8a3aed52b70d4ff1e2d2ecbb828b3f03c09cb220be2478b37e55d1cadff143ebc4b7f0e93f3a48c63519d4aa1ea9b145005bdc9d25d98150f6fc30f9292afae968b959c7aa526ef126b2959615e25c5c9f172715d2912dcc561d7f242c16f8b340b7f1f26611614e1e64d5014615635dcab4dd8d49da6839263fd3fcfad825ad55d968bd7c1e7efc3e4bef878befced72f132fa1c6ef8ef36ff1f92a8ea5b5592222b43403f31cfb355df8ae6b6bdfa7d96963b72e3b2e8f3b72ecb7750f3f6490fa47dbf79e2dfc07aa66fd3b8b65b8d485b511549d7c1a7e8be29392073b9781bc6cdc7fc63b463f692e3e03d8bf0324bb7f55f5d6537e1ef6fd3325bd71591021fdf05d97d580c442dcb9606d93aeeec78cdbb8670856b4e6c423b5aafd3c40a9aabb008a2d880d5e311b04a3746e5262ac8a6a88e3cbf21aa731d648678c2b98cd055958ae756fffd2edaba1b956a2e94d99536cbb8b9fbeb9b2cda06d94355477ea2dea66981ca3227a58ef2d6b284ebc2d05fbe1ec7b6a31699cfc5209b5c23ec3d8f20d864215cb7c9e247c8269b94b9fc1824f7610e6ac3bebd0f6af92f3e55901555d23e765973bdf4185c73aa7235740df5c43eabb554872275d47cf21ab55899a8f68dc59eddc0b16c8758b83ee55c268e6853cd422ed3b8dc2696295bb5569a62cef6e7209f3fd3ebf4ef33648af64bd122f8db0db5afe296655097655682d661ebb8b377573e40bb7656dac03edb92e8e87412a85f45f92e0e1e2c999f4c92f7f7415ed4e3ea27601676402bb966585397715da0d6bffa2f5efdeaa28c7f7eb5dda51979badfa798bd8ff5590fe96972eab9fadb0fbb380d36e1c67b05f0328ac3c4d2798943866d1cdeee82e4c17738e705bff096f48720fff86310975dd12fa2a45a784845affe848b4e9e42b352835db347cefb2e5adf47f5af5a6705a2b84ef1af595fba8c182ce1b9be12e9bdd8bb7b85f158daecdf10d57919d0e1c156c7624cb09afb08a69a1662f9ad16789313970b2cfafceb85bedb3a2f18a83d7eb6690871166259956c364733e4713c431e2733e4f174863c4ea7cee34d9a17756cd3aeff08d95cfd3479413e36bbc6befbc19639453d6a4e9bc58b6d10c5a66e483c8421e462ea88a3e422af222ed26ac40992b1f6dc95a1963adc28c9661f7694fc870c3f8088b986219ee775b9bdab37187ca6a96f82eaef23db91f2e9144bdc26ebe371b236e7f4c77273bfadeaf62f619019f27a3aca3aa4a42cd56c1b0f9fa21c029525ef200f654c4c55a1976952817f5d81779efcea0624ec0dd35030cad1d66516d67dd77f9dd80aba49bc55ba0ae3b0e8d7ec344b8f8a791b06b93302dbb45061480981ea34a7336c8f509778e272738ad5a9bad8232c64e9cbff92a8751b1357b88960d595c5725693f7159aaa7d6c83ba3c925de52ea6abda1d26496a0bb171b5bb4856b5fb9803d566fdd745759ec2aa3e8b482d421bdbb918ed18482b4117d9a07c1bc7ae378fe8aa72334a91f46d63e2ca3611ac9ab2589efb44257d17bd89bc873da272d8de39712e7668fb438ee3f5f37596260f5b53bed364ebbeaca4f477840fd20c3c421ce15457fea49fe92adfbdba4b6f68683d86c79fbdd3884b08d77e832e3fa65cd38eb16eb27785a3693811fbe9f7e376407c32d90d88da2c52fea2753de5b35fcf6b66137c8e42ec7d429ad97b60b471ef79d166be1e7715e6eb2cdab16d3b5f76832daba0066b30c2ea74d38b725f650a892f1efc3bec201cb7533f1a809bc8b323b7db6d71852f719b663e5ed03414b88196579592ad3f8eb631ff3ccfd375d4d4a97c7185917364455e249b85e9c205ab4ee1a24655a915d4a25d05ae2aeff3e56fb4b22122bb93f95e24230bc9f28e962a286f1266bb178c5bdcec6dae838d5ea9557d6ce4900ac76156c3a75a2855c358d533a2a4d0411f25eb6817c406ad95346057c16e6ad49a7579a85faec25d98d40837b402257399e9a52bd0e5a35499ad86ce56029c2c281359e32824400ab980327671c3016310ed5c14d8b2d80f0e6580de9486c66e27baa10c6805dfcc674098cee8c55061a0f7f6d0e02c7a3ad80cb70d2c10de3fe050dd490d0f5f5672021dda269e0acc00bc9eda8a2103e0b9f68860dc6f3acc746aecc10f9a9acab38d985acd7f51c365030df3d826df24f21e2aa5db471690ee1f57bace94e685ef320c1822c5baf7cb780644012c5f0c0a26ca6f0f09f17c930e330357581c7c3929f5d01087ab4f01004a6275021fde3cde3acc8043c331398619ca99798f1d8d69460727853a4ee9004f1e3f3ed2b2198437bb46943637dd2c71829ebd25c6506706142a3bd51820b06deb1e04fd390f1d66c86eb764ff4a1d55fbb77eb0e234ab031ecd3a810f6e0ccfdce758982a4792e8fa113b9fb4e2c2b02645ce34072178d8ca122ed55ca0412ae0f0510313b3a823176aaf461c1dbf34eb65d47f2e3c1a1bea0b4465c7c123a34627e44d834e8dce77f0cb596b11665add5a9b8c845391f77c1058ed8997540c012ccc49b0aa73382d589d6e81a1a9b227cc69554fd14322871f12e65a368a231e54faec94d853c8b7e2fc50e2d3cc8c43592d0a067436cd1838949bc2018bfded88c3c0239fec93e1a191a1a741a14aa5262c5026049fa20da9bd511ea51ffe94faf757650fa86354262a16144afb24789309f1421e2debead0a78692fe144c20542d2f6c4a0de5a9c4bc2720c21b1c18622c0f728c780e02bce471f04b15a3fa334d198d2d44d2417ac367064c324a5e7d27b64a1166dc5c07455087859fa1fb355545b58ccfbc6521aa90aa65de8685c4c2c9978b9effa7909d344c2a0218c90c94c0597e161175fb40e9193bc1967f7db60ae6ce8eb42dc9bbc742b5f49cd163115023134ace3aa225718f494884682a6cc5688ee922b820fc74d422437f544913a50da956b54ab868ed9e9f25b9702f4793d04ff36c42c4993528495ab158a435631224a59d0928c9859ead7599f67d3b210af48cb96a662c24db4e5fb1676ab6ca42ab1584b47d531d16e47251ca2c3d030c9419257ccaea42944fb1ccad3530951822798a22b845f42e33f068a85e700b0f513e9e41998882fe9d4533d401ce3db4d6e5807a101e73d4cb8fd0e1247575429ca0666b800da5d5297093019c597d0cde3a410b40a644d11a026d899465aba80125851e00d44b6c231061d35b95422414401a2d0dd560200d89fda41f32bdabc4f498835e35544e8b71490ab05a84c2e963b9a1be083c165a2b0ca839f50ea05e5b26ee85540c847d21a82ecc270cd581f02d24e894e3945ebb7e0c8c0f263a806cd41142805571a314a0f868358ed0735018100eb8cd077c1828bcbacaf410313c6342a824f8bcd55c24edc475b4cad2ce5827189d0cefa7d8eb0b39f3733cf51babbef473bef9ea8b2f87c875069d590d38b51ab9ee94732ad18829cbc2f12bb25ba012ea103c67713b6919ade6d4b395992c7fbb80b65716703ce07040305635c947028254be4330e63c5b7c04da38d5c676aa1df6aafd26dcc0eeb487d1e2d792bb3dd0eedbd98af9d16c03ce5688c3cdb3d7c16e1725f78203ce366471cbbc6f5e7e75ebee9d72cb64acd6d2844cddb1ed722ad22cb80f95aff5246113be8cb2bc7e3a30b80bea4bd9979bad164ddcf14576a7784ef2a6aede627cd38ac7afff6ebba3e62c13d8146f93bdac4a53bf78d8142cd4f64ef4848bdaed69100719eafeaaf77763ba198a4b6237f645292c449770b6524aa16de46bd5a49d89c8b54e6b13be1b37b851daddf401ad82a5449ba5774e29b50be6ee729c86c124c8f7eb4449e69b777b6b6ab6a534b49da1bd304223c3c9b03acdc1fac4ef50e292b8af46510e0f3b981669f7ce0677bde6286940c783d3a1dd8edf4b963a1d7659d9d024cd43b4528334217409fcb85594811dc1e25214178ba230e5938b31907d2dcae640fe46973ade38c45d312a856dc20ea63bf02382a1fda13d1a75ef105842ac367be77d627d62ce008d2d3c52df12fdf2493a09e174698da73d514c13e030b8d64ef3a4b1b50e38189cb1e9fe509441a725048cc1c9a6b574fe931cc9279c64bac50f7479a29f37519c18fe0b9e82892bd7a1f8c38f6508283425c66a59bee82ad6b2f90a2c2eb1f7b726e1bb0ba54bea1dae8992fa50170bdadd28970d287ad1dc5ebe0b4d9c99ac854b14dcab89e284e083c1787f8039781c870f6629033996728e56f7b7b6cc1996341568429c241c6b1234ef001609279a841347094f35094f1d259c6a124e5d24f42ea644297da8c308f89332f0fde4a407f3102529c1821c6c5ced004a326f75003d3df7ee248ae0618e528e01296ee802c67e7cdcdf9305d336e0871a329597e86ed0ac125063a4fb6b922c93cd239449364fc59de1489653f9e6d05504d74c527f11c21da51d23d28e5da5c91e954479f21797e946a9cfa7d05bd1b81cf1968c3c3fc76fcf18b4125c2a498a09e12e6554dd26c98555bfbab587b6fe46ef65d8db55df9a92bf389459bc302c15d77493d82aaf7efc199076a331838d58e11e93e44dd136d0594e7f29109087df18b4ca55cb2a043bcbd2dbc178bb1697377c11b4b76978e9b3ca04794ca41938986e6a3338c2dc9b3b5390a7266de02f6c8663e2edd1f08151430810c193ce34c88d84b9b110330676bf04ccc9cca6c1c013afc50c009f313956c191326842d7f3f1d492eb09792c123eb8c813fc4bc8f2840f74798a930951a2f26990cc8b0754e605781cb62780b60ca9a1c004f95f044422e9a69eface6d755029dc2f84248607ce0c0e8dd8a546e9726f43badf1db1ab2555496cafa6ec3577ab2973de12bc5496158bb25c5415f429dad40cabebdd7dfeb7b80f791d24d187302f98bf93e5d1d1e3d3e5e2791c0539a3dcb584b167eaf55b1283ece8a46690859bed4a4deece43aba5e4f94672c7a2fb8601fd28905cb66047e0769f2d7d4a7649324a8aa7cb85d52f8b8787ac4f4105e67a7340f4123c964372904345ac438c3645a8c43ee93e6bb1f617ef28523e171495d7aeacbf4a36e1e7f3e53f9a94cf16af7e7a2f267eb4b8c9aa1ef96cf164f1cfb11a13787d9fd492183fcade90395815ce1e9419ad0a6fa8635b43d1f1ae5397886887391504acf38453225df4d15d44d5105104db9db3144e107084354be600683d678537e50126952c058ba27861832d3da13e7842df1a69c85578a7f87ab44e01d19788be6611ca12c1d96c9772ca7e01763e4a13b2745e2d2852a74ca6cd7d106ad854e38a6c08563e22c96003bc7990a006b397ec40838cdadc138da353f716910852b8e81377c92257ca3064506ce4414f87509f0a24bc99b6e5eda893534f89bd9ef5e43bfcf7ac270392654340c188c08571044897d2cb0ecb9429d7b98d90d84b0b8169c554b87b28c2c05c970e5ee9215736446ff1085389e22f1e6cd8b98deba9332219296a6489c7a34b3c195de2d3d1259e8e2bb127581956edae426bc6d5a84a32021675b94a11d930b2c614c8f959d4cd0fb24c23ccdd65caf390bb348dc71afd8dcc279a6db4929cec36121031a5ad54d9531e0b69913665d8883c1d26f8d84d30054a32930a97ecbc11d01ded3a4f5f9a745ed306f184da31fb3e29a601a9f002736bccd6d2d95b636341db5c20d4599bceabc964e697efa45ca27db902b04febb793d193c57c8bd3b1c5c8061f95d133c45c3b869cdea77708d432cf95b4442b1b5620533b5354c0d7ac041dc4c474251c5638badf27e2fa06e4e550563780d5dfefda86b6e5c9094406a903844e354d435c3190da16a76fd99b171b58479f91ed71f24080c2d180ade229303b19bc50ba160d623a51cb0ead68332da424d617756798360609f42f8f015a217d798e8c0add6bf84a9e0c1ac85107092d088dca0e1970be3afb29c5807323e79e0b88e05c2defde0f3890479f1c179ef9624f38b3dc8507fa277436a1bd532e3bade76193782245dee1a1b342162ede29f0d79df40ccd77ee67718e823fd72eb6d95a34bd9253897930c33c4088d9b39049f0823e9a4667d5b921067994c82dbb391c1a9b5fb8776fb089e0c21d7e08d9f3a06900436f40ec9d1a17cfc6d89b3d4ed9cd0017c421c0818c43ec817f216fc8e1d217390221cfed1cf0f00330641c1bea1731f0901b6e04275a749b856736afef36f8c85f7cefbe7561219a7d1e360b5a44671182122e8ee206e1067ffdc581fde0841ee38b4a8e99eec12f25ca93f2684bd02b29faeab49f7f4b4fd77da436335fd21eee3d7294cc67c08cc95b89ea6543b139a58e8e892c4eff34bda000e63777346b03df73279f4438a1c7706bda29c339964726072f4320835b93ffb7fb01b53bc1a1cdc1188cfd0f43f3c268c8e0736068823dff1cc80269ff789a73d134084da6578cf68228c437922ba20e7ec27be8c830beabb44f648087c7c2e44372b32b4e40a40f5f185a2cafa4500ecae7420cfe52d87e5003135a06ce560f1f282e3353d37b4b5383c598f51e7002910cfa866dbd8609cdd986fc8fcc63b0c770c89c8bc90165c877de9d60cc37da81cc89f7b50d3ce77cc77133d1fc88fb04f8511e25ea5676aa9b36b50ddb778ea4f376eef80e603fb00788ce979bbbb46a6b46dfc1dcce6bc239e94597cebf80e2b9fb319b7c7696aa0967c19064d881baa6363b00d39566e1a0cab0ff7955323fa3d744f30f906cee01c7269cf57f4d340b8604c31e0e55b162a7d6848b1fa12c4c0eb8b5cae127597aedf02f60f5a0bed1d50cb4514ecb488b01656873c50914ac042baf0d870b05ba645625f7334c4d78ff09928f3b47d5b290563c7a36d267302b21863dbb7646a4e5d3864319204e4c413fa5127710704f8a730ba5f14f343cbd473bddea039c40215117a68ebcceee57258a1b542c9402272b290d06a2974c63d1447329f892f32f96cec6829cce9b295b43549577b3259b2dba06f32f60cf1f020a86908b3c81288e12bd0faab120c884610084a66faeaacd043d809561f6668c301420f68688241e6628a43e00ab5e9bfc8b6ba00f10bc5ce353659f629857af8208ed9b77752827e3401598cece95562f9512b72186c2aac3bafc42f608765539c685acaae9a4f7e00b089f5712903c456bce0b5dfc708d527cf824ced34aefb702fab3204205200747bf840ae073747225c00705e82989d893a50f875b319dc121d409b2253ed4a81d5035b44b2b7b1d80fbb7fafeb6a07c1b723045877758cd133b6c2bd6d3268c39abd35e28efbe9dadd88ab90da87e6a2f919fadde96497d9193fdba0af3e8be177156c94cc2b5b4f9d8c579957c48f94ea8a2118fa2dc0b7c1d16c1262882e759117d08d645f5791de67994dc2f17cd4b6af58b4477e1e655725316bbb2a88a1c6eef6269825cefa59af23f5b693a9fdd34376bf3318a50a9195545086f928b328a379dde2f813b8d88887a93b6bd035ab76551df05bd7fe8245d6bbe0031416df5757bcbefc2ed2eae84e537c96d505fbf74d7ad02eef7e17db07e78d3be2f8f0bb137845ced675751709f05dbbc95d1a7af7e5618de6c3f7ffb5f6d0b3bfc15f90000	6.2.0-61023
202001291007039_AddRetentionFlagToNCs	NCAS.Models.DataContext	\\x1f8b0800000000000400ed5ddd72dc3a72be4f55de616a2e535e8f25599b8d4bda2d4bb2779d1c4b2ecb677372e5a2666899d919723224bd566de5c9729147ca2b842408b20174030dfe0d7d9272954b03028d06f0a1f1f701fd3ffff5df177ff8bedb2ebe8587344ae2cbe5c9f317cb4518af934d143f5e2ef3eccb6f7eb7fcc3effffeef2ede6c76df177f96f1ceca7845ca38bd5c7ecdb2fdabd52a5d7f0d7741fa7c17ad0f499a7cc99eaf93dd2ad824abd3172ffe697572b20a0b11cb42d66271f1318fb36817563f8a9fd749bc0ef7591e6cdf279b709bd6e1c597fb4aeae236d885e93e588797cbdbebd7f7cf45b4e5e2f5360a0a15eec3ed97e52288e3240bb242c1573fa7e17d7648e2c7fb7d11106c3f3dedc322de97609b86b5e2afdae8dc32bc382dcbb06a134a51eb3ccd929da7c093b3ba52567af24e55bb6c2aada8b63745f5664f65a9abaabb5cbe5e0bc17a56afaeb787329a52afcf45ec678b32ec59d3ea0538ca7fcf16d7f936cb0fe1651ce6d921d83e5b7cc81fb6d1fa5fc2a74fc95fc2f832ceb75ba84ea150f14d0928823e1c927d78c89e3e865f1425dfdd2c172b35f54a4fde2436528ac2bc8bb3b3d3e5e2b6502478d8864dcb8382df67c921fc63188787200b371f822c0b0f45c3bddb8455dd193a683996ffcbdc0aa815dd65b9781f7cff298c1fb3af97cb7f5c2ede46dfc38dfc5de7ff731c157dab48921df210d10fe679b16a5bd1deb6377f3c24f99eddb822faf4ad2bf2edd4bc6dd299b4efef5ef46f6033d38fc9b6b45b954857513549b7c1b7e8b12a392273b9f8186eab8fe9d7682feca5c4c16711e1ed21d9957f35955d857fbe4ff2c3baac8804f9f829383c865947d48a6c79902de34e8ed7b469085fb8a6cc2674a3f536899da0b909b320da5ab07a3a0056f9c628df4419db149591a7374465ae9dcc904c389511ba2952c9dccabf3f453b7fa352cc850e6ea5ed32ee1efefdc321da0587a7a28efa89fa98241929cb9e943bca3bcb12ae334b7ff9ed30b69db4c8722e86d9e412619f6504609341b86993e147cc26db94b9fe1ac48f618a6a23be7d0e4af96fbe1590852a191f9baca55e660ca93957b912ba967a129ff55a2a43893aaa3ef51ab54499b8f64dc49edcc0896cbb58b836e554268e6953ed42ae936dbe8b1d53b662ad34c69ced5f8374fa4c6f93bf4e9029d92fa145e86f37f4be4a5b964e5d5658095e872de34ede5de500eddb597903fb644ba293f351a07e13a5fb6df0e4c8fc6c94bc7f0ad2ac1c57bf21b3b019ade4aa614d5fc6358146ff6abff4ea5757f9f62fef76fbe4c09eeeb72926ef636dd65d7a9a9a7aaafef6f37e9b049b70d37b05f036da86b1a3f332870cd738bcdb07f153dfe15c16fcaab7a43f05e9d73f07dbbc29fa5514170b0fa5e8c59f78d1d95368516ab46bb6c8f9dc446bfba8f9d5e8ac4814df29feade84bd79180253ed7d7227d86bdbb55988e65ccfe2d51bd97010d1e5c750c63a2d5dc46b0d53488d56fb5209b9cb95c10d1a75f2fb4ddd67bc1c0edf1934d4398b310c7aa64b33999208fd309f2389b208f9713e4713e761e1f92342b63db76fd07c8e6e697d10bf2b5da35eebb1fec985394a3e6b859bcd905d1d6d60d9987308c5c6c1d71905cd455c455528c38413cd49ebb36d472871b2dd9e4c38e967f97e1071131d53024f3bccd770fe506439f69ea87a0f8fbc475a47c3ec612b7cafa7498aced39fd73be79dc1575fb6f6170b0e4f572907548ce59aab9361ebe4529062a47de411aaa9818ab42af93b800ffba00ef34f9950dc8d81be6a16090a3adeb4358f6ddfeebc45ad05ddc5ba59b701b66ed9a9d67e949311fc320f546609d162b0c2b21529df67496ed11c72e59915d2c862ccfea22d78a70dd3ac632575f353256c4fc7d849ca9751d9356b88ae0d455c4f25653763a9eaa6d6c8bba32925be526a6afda0db8596a83d8b4da4d24a7da6dcc8e6a0b43e0a3ba4ce1545f44e416a18eed5d8c7a30e595a0896c51be8ee3d65b46f455b91aee58fad6316965ab084e4d45ac9e1b4e397f3bbe8a7c84cda6bcdb263c735237b78d26cf81fff5fa90c44f3b5bbee364ebbf3ee5f4778258520d3c200e381e563f9987c3daf75edda53534bc1e23e34fde69e05ac4b7df90eb983117c7432cc0dc5de1641c72c571fafdb01d909e4c3603a2318b54bf185d4ffbdcafe755b309394761f63e9066f21e186dfc7b5eb499aec7dd84e9fa10ede162aa3b4dc29555508235186099bb6945f92f5741e2aba7fe1db6138eeba91f0fc055e4c991db6cdbf8c297b9df331dc1681c2e5d47cbab4b39acbf0eb6c3ff3a4d937554d5a97a0346b07c5445dec49b85ede686a84e70e3a3a8d4026ad1be005791f7e5f21f8cb211229b23fe56a4601da9f24e963a28ef6261bb1782a45c6d92ae838d59a9457d6cd49002c7e1a1844fb1502a86b1a267447166823e8ad7d13ed85ab4d6d2a05d85baf2516ad6e4a17fb909f7615c22dcd20a9ccc55ca98a940938f5665ae1aba580138395006e9e72424502e3a4099b801e281318cbf0e05d674f8d9a10cd19bd3d0d435473f9421add037f3091066528329545878c22d34241d9f0f36cbb50507848f0f38527756c3e3b79ebc4047b6494f0526005ecb91a5908110665b440812391f6626c776f683a6a1f26423a651f33fd4705941c33eb6a957927a0f95ca352607488f8f2b53674ef3e297223a0c91b0eefb653c01a210ba3005051b77b885043cdfe4c3cc423a8683af64b7ce0d71b4fa1c00906c582ff0d1cdd35b870970683926a730c339336fb16350d6f8e0e470d0391de0c5f3e72746369df0e6d688d3e6b62b2a5ed073b7c410ea4c80426da79a0204b56ddd82a03de7e1c38cd8ed56ec5f6ea2eaf8d60f579c6775d0a3592ff0e18dd133f72916a6da9124b97ea4ce279db8b0ac498933cd4e08eeb6b2c44b351568880a983f6a70621677e422edd580a3e38f66bdacfa4f85476b43fd80a86c38786cd49884bc71d069d0f966bf9c751661a2d5adb3c958388504ea5960b5255e723184b03047c1aac9e1746075bc0586a1ca913067543d470f85653e27ccd56c144f3ce8f4d931b1a7916fe1fc50e1d34c8c43552d0e064c36cd1038549bc2038bed358b79e0514ef6d9f030c8d0e3a050a75233162823824fd386d5de248fb21ffeb4faefafca115027a84c5c2c6894f651f0a612e2411e35eb6aee5343457f0e2608aa562f6c2a0dd55389694f40c0631e14621c2f7b0c780e823c0932fba58a55fd89a68cd61662e9a03c063401260525afbc5c5ba4080fd25c0759508685dfb1fb354545d58ccfb46621ea902a65de8799c2c249978b96ffa7919d0c4c6a0204c90c9520597e0e1165fb60e9053bc1957f79b68ae62e8eb41dc99b57478df492d1e3105022134b2e3aa223718b494c043415ae6254c774115e10793aea9061bece6488328654a75a395eb47acfcf911cdccb3124b4d33c971038b34625292b1687b46a4cc2a4d433012d39e8d94697a91fca0351b0f7d07533e320d936fac29e69d82a07ad1608a9fba63e2ca8e5e29459794f18293349f854d5c5289fb0ccb535b0951823794211d222f62e33f2faa85970070f513d9e21998840ffc6a259ea80e61e3aebb2433d805721cdf2137438455d931007d4ac0db0a5b426056e34800bab4fc1db246821c854285a5da0ad90b25c15d5a1a4d84b8266895d04226a7aab5388400194d1d2520d16d210ec27ed90d9bb4a6c8f399855c3e5b45897a408ab0514ce1ccb2df5c5e0b1f05aa143cde97700cddab2712f946210ec0ba03a984f58aa83e05b28d0c98729bd71fd18191f6c7400d5a8138400a7e2562948f1c96a1ca0e79030601c70db0ff82850f4ea2ae343c4f28c09a392f0f3567b918c13d7c12acb38631d6174b2bc9fe2ae2fe2cccff3d46fa8fa32cff9a6ab2fb91c62d7197666d5e1d46ae0bad3cea9a011d39685c35764b34065d4217acee277d23258cde9672b1359fe7a01edae2ce478c0e38060a86a528f048054b94330e43c1bbe266d9d6a533bd51e7bd5fd26dcc8ee740fa325af25377ba0cdb78b9570c859075cac08cf9d17ef83fd3e8a1f8127cf3a64712fdc785effe6dedfcde54ec858ad950999be63dbe4942587e031d4be9693844df8363aa4e51b84c143505ecabedeec8c6870c797d89d9239a99bba668bc94d2b19bffcbbee8e86d74d6453bc4ef6b6284df9746255b0d0d83b31132e4affa9c13638907eb45ac739b69ba1b42471631f4a1121a6848b95560a6323dfa826e34c44ad755e9bc8ddb8ce8d52efa67768152a25d92cad974ba55d28bf99c3340c2541bd5f0725d96fde1dada9c59652d776c6f6c2188d8c27a3ea3445eb93be43494b924e1fa11c19369b16a9f7ce3a77bdea28a943c7c3d391dd4ede4b563a1d7559d9d224d58bb64a8354217c09f2b815caa08e6069299aaf46284cfbe4630c54a78daa3950bff1a50e370e499f8e5a61abb0d974077944d0b53fd447a3fe1d824a48d566eb0510d627e555d0dac203f52de8e04fd10984f3a5552efba0982ac063702dbdef29636b19301b9c89e97e579461a7250c8ce1c9c6b574fd27398a7339c574c30f7c79d0611c1407c37fc55330b872ed8a3ffa588681425b62aa96d58baeb096ed57606989ade33605df4d285f52ebb90d4a6a437d2c6873a35c35a0e4457377f9ae0c7176b2162d11f86983e240f06c30de1e60761ec7f18359ce404ea59ca2d5fb5b5be1554b990a54215e124e0d09869b0187843343c299a784978684979e12ce0d09e73e125a5f55504a1bea3102fea20d7cbf78e9215c4d294a88200f1b577a9252cc5b19c04f2fdd44411132cc53ca2922c50f5dc8d84f8ffb47b260c6067c5743a6f312fd0d9a5302698c4cc74f8a6572b996b2c996a9a4571dc5726adf3cba0af0f1a4f41710ee29ed949076ea2b4d75cd04e5a95f7ca61bb9399f226f45d372e02d19757e4edf9eb168057c33298a81709f32eafe97d4c2ea5ffddac3587f93f732dced6a6e4da95f3cca0c2f0c2bc5b5dd2476ca2b1f7f46a4dd19cc602b56a4eb257553b40ef496d35e0a44e4d137069d72f5b282606f59663b586fd7d2f2865f0401df4ecacab50d9ecd8058b386bacfe7114e146b368fa61bdba40e308f978e19d4694e1df82b9b2dd938803c7c5034130644e8a4130d9803616e28c40c81dd1f01732a4baa33f0e0159b0ee0b326a72a38d20660ecaa3f9d5a7163a18e6be0838f3ce0ab4295073ef0e5690e2ba044ed532799574fa4cc2bf468ed4800add9565d818972c9188824d28d3d8d9edaea9052a48f09458c0c9c181c06494c8fd2e45e8734bf1b92584dd052986355d94b1e5855e6b4268be98c2d1165b9282ae85bb429d95ab7fbc7f43fb66dc8fb208ebe8469267ca72c4f4e9e9f2f17afb751900afa5e4d3e7ba55fe565b1d14ece4a365ab8d9adf4e4fe9cb6524a9a6e14d72ea69f19d42703cbfd0b759ceef6ffd2a614172ea3387bb95c387dbcf4f0b6f52d28c05c6e3440d7c543794947f958cc3aa428588c4a6c931eb3164b27f69e22d53346a8bc71fdfd5dbc09bf5f2eff56a57cb578f7cb6798f8d9e2ee50f4c8578b178bff1caa319197fc592d4971addc0d99a255e1edd65950b4e8863a7535141fef260d8a89769c9fc1c0ba4c3826d2a1e3f02c2a86882cd8edbda548b28127ac45320f409b396b1cac1e60d28957b8288e4737dcd233ea4326ec5b2315518bee14bf1dac53605428a6df5a82fec4705cdba41cb35fa09d8fd384225daf1684342c9b69f31f842a66d6b0222bb2561f916cb0219e415850c399506ea061466dea89c6c9b97f8b28642b5af499bf64c8bbb20c191c1b39ebe910e99f818537db16bf1b756aea31b1d732a8fa0eff2d83ca8264d51070300278359e006952f6b2c32afdca776e0312f7d202b0b6840a0f4f5918d8ebd2c3c33de61687e9799e603d717ccfa30d3bb5713df746a420580d2cf174708967834b7c39b8c4f36125b6642dcbaadd5768c9de1a544941e6e22e5739222b76d7900225d78bbbf9c1966985b9bf4c751ef29024dba1467f2b8b8a671b9d8429b78d44448c692b7526568f8534a460593622cfbb093ef513cc8192cacaa2257b6f043447bbded3972a5daf69033ca1f6ccbe4d4a69c02a3c60810dd95a26136c682c189b0b8c3aabd3f56a329545d67752ae50c87c01d8a6edb793d112cffa16a7619eb10d3e29a3659bf9760c357d9fde01686a3d57d20a45ad5b816cedcc51815eb332748089fb2801a870c3cf09304f54cc5512caeee1ac9190b1e3b82b24dec6a9a42159a476103ad6648f700ec16a5b9a04e66e5e6a781e7c5e77c42908030a271d369cc7c0ec68f022495f3c8899742f37b4a2cdb89052b863dcfd65de480648643d86798d3ad6737cd54863ddf703d8a0c15c87b0d04290b1dc904167bd939f7574387df2eeb98808c9f8eaddfb1197f6e423e8e0e131f1a8b4c81db80c18d1fd85f172ba927d13368a6f54e265203eb764e1e32f837e6fcaccd0fe0ac024ee5ae807e4619bada1e955dc5c4c8319e19302662f4246c10bf98c1b9f9be78718e29924bfeca670b16c7f73dfbfc146828b744102b29741e30086df80d4cb393ebe96a95784bcb29b002e848b82998c43c2e500c81b7301f5438e40c40340331e7e109e8d6743fd2a061e76c30de0d68b6fb3e8cca6f526871307e00bfcb5530d68f665d8246881ee2b80123eaeeb3ae1867e8fc68343e1851eeb1b4f9e991ec15326c9b6ead196a89f54f21dec7e1e377b3a1364b599fdda78777f9683643e01666cfe5374bf1f9acdc94d748c6471dac7f281029427dfc1ac0d7e5b9e7d12e1851ecbdd6baf0ca7581ed95cce74810c6d4dfebfdd67d4ee0c173bb33118c71f86a6855197c1676668c27d11cd6481747c3c4db968ea8426dbbb4a474114e1adc91751b39ff0ce1d19d6979e8e890cf4f0184c3e14c7bf7002a27cf8c1d0e2786b8573503e1562e8b7cb8e831a9cd0d271b63a7fa0f8cc4c6daf368d0d166bd647c0094632681bb6f663069ab30ef93f328fa19ed461732e46079425df697782296f6d3399131f6b1b78caf98ee766a2fd59f911f0a33d6dd4acec74c7717a1bd6af2529e7edd2151fc27e10cf185d2e370f49d1d682be23bdc8996398265c925e4ce9f20b2a5e3a4473c91767a98670118c49c65dba1b6a8b03305369118eaa8cba603724cb337a43b4fc80c9963e795cc245ff37448b604c30ee7351170b3bb5211c7ec4b2b0b904372a479e6499b523bfa0d5437a6bd7333046392323230696a1cb392852b01cadbc3a1c2f14ea245a97dcce300de1ed274c3eedaed5c84259f198d9289fd1ac400c7776f58cc8c8a70ec73220dcaaa29e5315ee20e23095e6162ae31f343cad8f3dd3ea239c4090a809d3475e6f87b00ac50d2b1649815395540603e8b7d35a34682e8177bbfec532d95848d91c94ad2eaaaabbd98acd86cecafa17b0e50f210523c8453d81084789d62bd6501014c2280062d3375fd526821ec2cab0fb5726180a187b03224986590a690ec0ba1fa9fec5b5d007187eb7e9a9729f62d857af4084f1ad77756827e34815d8ceceb556cfb512d72196c2eac3bafacef60076553bc6c5acaaeda477f605c4cf2b19481ea335a7852e7db8c6293e7e12d7d34a1fb702dab3204605100747bf860a9073747625e00705e42909ecc9ca87f9564c63701875426c8977356a33aa867a69e5ae0374ffd6dcdf06cad721b3293abec36a9fd8515bb13d6dc290b33ae39df3e6dbc54aac98eb80e2a7f19ef9c5ea631e971739c5af9b308d1e5b111785cc385c2b9b8f4d9c77f19744ee846a1ac928dabdc0f761166c822c787dc8a22fc13a2b3eafc3348de2c7e5a27a8fad7cd7e821dcbc8beff26c9f674591c3ddc3569920977ba9b6fc2f5686ce1777d5cdda748822146a464511c2bbf82a8fb69b46efb7c89d464244b9495bdf012ddb322bef823e3e35926e0def8494a0bafa9abde54fe16ebf2d84a577f17d505ebff4d7ad00ee4fe163b07efa50bf524f0b7137845aed173751f0780876692da34d5ffc2c30bcd97dfffdff02fcab9f07f0f90000	6.2.0-61023
\.


--
-- TOC entry 4403 (class 0 OID 0)
-- Dependencies: 212
-- Name: actions_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.actions_seq', 3, true);


--
-- TOC entry 4404 (class 0 OID 0)
-- Dependencies: 210
-- Name: adgroups_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.adgroups_seq', 1, true);


--
-- TOC entry 4405 (class 0 OID 0)
-- Dependencies: 214
-- Name: audit_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.audit_seq', 2, true);


--
-- TOC entry 4406 (class 0 OID 0)
-- Dependencies: 216
-- Name: bulkimports_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.bulkimports_seq', 8, true);


--
-- TOC entry 4407 (class 0 OID 0)
-- Dependencies: 218
-- Name: changes_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.changes_seq', 1, true);


--
-- TOC entry 4408 (class 0 OID 0)
-- Dependencies: 220
-- Name: companies_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.companies_seq', 1, true);


--
-- TOC entry 4409 (class 0 OID 0)
-- Dependencies: 222
-- Name: courts_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.courts_seq', 4, true);


--
-- TOC entry 4410 (class 0 OID 0)
-- Dependencies: 224
-- Name: deletereasons_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.deletereasons_seq', 4, true);


--
-- TOC entry 4411 (class 0 OID 0)
-- Dependencies: 226
-- Name: divisions_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.divisions_seq', 14, true);


--
-- TOC entry 4412 (class 0 OID 0)
-- Dependencies: 228
-- Name: judges_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.judges_seq', 1, true);


--
-- TOC entry 4413 (class 0 OID 0)
-- Dependencies: 230
-- Name: neutralcitations_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.neutralcitations_seq', 5, true);


--
-- TOC entry 4414 (class 0 OID 0)
-- Dependencies: 233
-- Name: users_seq; Type: SEQUENCE SET; Schema: dbo; Owner: dbadmin
--

SELECT pg_catalog.setval('dbo.users_seq', 4, true);


--
-- TOC entry 4205 (class 2606 OID 25116)
-- Name: ADGroups ADGroups_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."ADGroups"
    ADD CONSTRAINT "ADGroups_pkey" PRIMARY KEY ("ADGroupID");


--
-- TOC entry 4207 (class 2606 OID 25118)
-- Name: Actions Actions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Actions"
    ADD CONSTRAINT "Actions_pkey" PRIMARY KEY ("ActionID");


--
-- TOC entry 4209 (class 2606 OID 25120)
-- Name: Audits Audits_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Audits"
    ADD CONSTRAINT "Audits_pkey" PRIMARY KEY ("AuditID");


--
-- TOC entry 4211 (class 2606 OID 25122)
-- Name: BulkImports BulkImports_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."BulkImports"
    ADD CONSTRAINT "BulkImports_pkey" PRIMARY KEY ("BulkImportID");


--
-- TOC entry 4213 (class 2606 OID 25124)
-- Name: Changes Changes_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Changes"
    ADD CONSTRAINT "Changes_pkey" PRIMARY KEY ("ChangeID");


--
-- TOC entry 4215 (class 2606 OID 25126)
-- Name: Companies Companies_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Companies"
    ADD CONSTRAINT "Companies_pkey" PRIMARY KEY ("CompanyID");


--
-- TOC entry 4217 (class 2606 OID 25128)
-- Name: Courts Courts_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Courts"
    ADD CONSTRAINT "Courts_pkey" PRIMARY KEY ("CourtID");


--
-- TOC entry 4219 (class 2606 OID 25130)
-- Name: DeleteReasons DeleteReasons_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."DeleteReasons"
    ADD CONSTRAINT "DeleteReasons_pkey" PRIMARY KEY (id);


--
-- TOC entry 4221 (class 2606 OID 25132)
-- Name: Divisions Divisions_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Divisions"
    ADD CONSTRAINT "Divisions_pkey" PRIMARY KEY ("DivisionID");


--
-- TOC entry 4223 (class 2606 OID 25134)
-- Name: Judges Judges_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Judges"
    ADD CONSTRAINT "Judges_pkey" PRIMARY KEY ("JudgeID");


--
-- TOC entry 4225 (class 2606 OID 25136)
-- Name: NeutralCitations NeutralCitations_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."NeutralCitations"
    ADD CONSTRAINT "NeutralCitations_pkey" PRIMARY KEY ("NeutralCitationID");


--
-- TOC entry 4231 (class 2606 OID 25138)
-- Name: __MigrationHistory PK_dbo.__MigrationHistory; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."__MigrationHistory"
    ADD CONSTRAINT "PK_dbo.__MigrationHistory" PRIMARY KEY ("MigrationId", "ContextKey");


--
-- TOC entry 4227 (class 2606 OID 25140)
-- Name: Roles Roles_pkey; Type: CONSTRAINT; Schema: dbo; Owner: dbadmin
--

ALTER TABLE ONLY dbo."Roles"
    ADD CONSTRAINT "Roles_pkey" PRIMARY KEY (strength);


--
-- TOC entry 4229 (class 2606 OID 25142)
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


-- Completed on 2023-10-24 16:06:48 BST

--
-- PostgreSQL database dump complete
--

