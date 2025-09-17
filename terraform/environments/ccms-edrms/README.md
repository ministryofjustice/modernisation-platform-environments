# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->

### **Bringing Up a New EDRMS TDS Database**

When bringing up a new database for the first time. The below commands must be manually run before SOA:

PS: This is copied from location <https://github.com/ministryofjustice/laa-ccms-edrms-web-service/blob/main/sql/liquibase/xxsoa_schema.sql>

```bash

--------------------------------------------------------
--  DDL for Custom Tablespace XXEDRMS
--------------------------------------------------------

CREATE TABLESPACE "XXEDRMS" EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO DATAFILE SIZE 100M AUTOEXTEND ON NEXT 30M MAXSIZE UNLIMITED;

--------------------------------------------------------
--  DDL for User creation XXEDRMS and grants  
--------------------------------------------------------

CREATE USER XXEDRMS IDENTIFIED BY INJECT_COMPLEX_PASSWORD_HERE ;
GRANT CREATE SESSION TO XXEDRMS ;
GRANT UNLIMITED TABLESPACE TO XXEDRMS ;

```

Password **INJECT_COMPLEX_PASSWORD_HERE** Should be provided to SOA team so that this can be stored in SOA Env secrets , for weblogic XXSOA Data source to work.

```bash
--------------------------------------------------------
--  Switch if you are not connected as XXEDRMS user 
--------------------------------------------------------
alter session set current_schema = XXEDRMS;


--------------------------------------------------------
--  DDL for Custom Object XXSOA_DOCUMENT_DETAILS_OBJ
--------------------------------------------------------
CREATE OR REPLACE EDITIONABLE TYPE "XXEDRMS"."XXSOA_DOCUMENT_DETAILS_OBJ" AS OBJECT
(
    EDRMS_DOCUMENT_ID   VARCHAR2(150)
    ,SOURCE_DOCUMENT_ID    NUMBER
    ,FILE_DATA           BLOB
    ,FILE_NAME           VARCHAR2(256)
    ,FILE_EXTENSION_TYPE VARCHAR2(256)
)
/


--------------------------------------------------------
--  DDL for Sequence XXSOA_ERDMS_DOCUMENTS_ID_S
--------------------------------------------------------
CREATE SEQUENCE  "XXEDRMS"."XXSOA_ERDMS_DOCUMENTS_ID_S"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 163715 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;


--------------------------------------------------------
--  DDL for Table XXSOA_EDRMS_DOCUMENTS
--------------------------------------------------------
CREATE TABLE "XXEDRMS"."XXSOA_EDRMS_DOCUMENTS"
( "ID" NUMBER,
     "SOA_INSTANCE_ID" VARCHAR2(256 BYTE),
     "SOURCE_DOCUMENT_ID" NUMBER,
     "EDRMS_DOCUMENT_ID" VARCHAR2(150 BYTE),
     "FILE_NAME" VARCHAR2(256 BYTE),
     "FILE_DATA" BLOB,
     "FILE_EXTENSION_TYPE" VARCHAR2(100 BYTE),
     "SOURCE_SYSTEM" VARCHAR2(100 BYTE),
     "CREATION_DATE" DATE,
     "CREATED_BY" VARCHAR2(100 BYTE)
);

--------------------------------------------------------
--  DDL for Indexes ID_PK and XXSOA_SOA_INSTANCE_ID
--------------------------------------------------------
CREATE UNIQUE INDEX "XXEDRMS"."ID_PK" ON "XXEDRMS"."XXSOA_EDRMS_DOCUMENTS" ("ID");

CREATE INDEX "XXEDRMS"."XXSOA_SOA_INSTANCE_ID" ON "XXEDRMS"."XXSOA_EDRMS_DOCUMENTS" ("SOA_INSTANCE_ID");


--------------------------------------------------------
--  DDL for Package XXSOA_TRANSIENT_DOCUMENT_PKG
--------------------------------------------------------
CREATE OR REPLACE EDITIONABLE PACKAGE "XXEDRMS"."XXSOA_TRANSIENT_DOCUMENT_PKG"
AS
    /* =======================================================================================================
    *
    * $Id$
    * $Header$
    *
    * Module Type : PL/SQL Script
    * Module Name : XXSOA_TRANSIENT_DOCUMENT_PKG.pks
    * Description : This is the package body for store, retrieve and delete documents
    *               for transient processing.
    *
    * Run Env.    : SQL*Plus
    *
    * History
    * =======
    *
    * Version  Name                           Date           Description of Change
    * -------  ---------------              ----------     ------------------------------------
    * 0.1      Sander Rensen                11-Apr-13       Initial Version.
    * =======================================================================================================
    */

    PROCEDURE insert_document_file (p_instance_id      IN VARCHAR2
                                   ,p_source_system    IN VARCHAR2
                                   ,p_document_details IN xxsoa_document_details_obj
                                   ,p_username         IN VARCHAR2
                                   ,x_status          OUT VARCHAR2
                                   ,x_error_message   OUT VARCHAR2
    );
    PROCEDURE retrieve_document_file (p_instance_id       IN VARCHAR2
                                     ,p_username          IN VARCHAR2
                                     ,p_source_system    OUT VARCHAR2
                                     ,p_document_details OUT xxsoa_document_details_obj
                                     ,x_status           OUT VARCHAR2
                                     ,x_error_message    OUT VARCHAR2
    );

    PROCEDURE delete_document_file  (p_instance_id       IN VARCHAR2
                                    ,p_username          IN VARCHAR2
                                    ,x_status           OUT VARCHAR2
                                    ,x_error_message    OUT VARCHAR2
    );
    PROCEDURE insert_document_file_auto (p_instance_id      IN VARCHAR2
                                        ,p_source_system    IN VARCHAR2
                                        ,p_document_details IN xxsoa_document_details_obj
                                        ,p_username         IN VARCHAR2
                                        ,x_status          OUT VARCHAR2
                                        ,x_error_message   OUT VARCHAR2
    );
END XXSOA_TRANSIENT_DOCUMENT_PKG;
/

--------------------------------------------------------
--  DDL for Package Body XXSOA_TRANSIENT_DOCUMENT_PKG
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXEDRMS"."XXSOA_TRANSIENT_DOCUMENT_PKG"
AS
    /*******************************************************************************
    * $Id: $
    *
    * Module Type    : PL/SQL
    *
    * Module Name    : XXSOA_TRANSIENT_DOCUMENT_PKG.PKB
    *
    * Original Author: Sander Rensen
    * Description    : This Package insert/retrieves/deletes documents for transient
    *                  processing.
    *
    * History
    * Version        Date             Name                  Description
    *  0.1           11-Apr-13        Sander Rensen         Initial Version
    *******************************************************************************/

    PROCEDURE insert_document_file (p_instance_id      IN VARCHAR2
                                   ,p_source_system    IN VARCHAR2
                                   ,p_document_details IN xxsoa_document_details_obj
                                   ,p_username         IN VARCHAR2
                                   ,x_status          OUT VARCHAR2
                                   ,x_error_message   OUT VARCHAR2
    )
    AS
    BEGIN

        insert_document_file_auto (p_instance_id
            ,p_source_system
            ,p_document_details
            ,p_username
            ,x_status
            ,x_error_message
            );

    END insert_document_file;


    PROCEDURE insert_document_file_auto (p_instance_id      IN VARCHAR2
                                        ,p_source_system    IN VARCHAR2
                                        ,p_document_details IN xxsoa_document_details_obj
                                        ,p_username         IN VARCHAR2
                                        ,x_status          OUT VARCHAR2
                                        ,x_error_message   OUT VARCHAR2
    )
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;

    BEGIN

        INSERT INTO xxsoa_edrms_documents
        ( id
        ,soa_instance_id
        ,source_document_id
        ,edrms_document_id
        ,file_name
        ,file_data
        ,file_extension_type
        ,source_system
        ,creation_date
        ,created_by
        )
        VALUES
        (xxsoa_erdms_documents_id_s.nextval
        ,p_instance_id
        ,p_document_details.source_document_id
        ,p_document_details.edrms_document_id
        ,p_document_details.file_name
        ,p_document_details.file_data
        ,p_document_details.file_extension_type
        ,p_source_system
        ,sysdate
        ,p_username
        );

        x_status := 'Success';
        commit;
    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'Error';
            x_error_message:='ERROR is :- '||SUBSTR (SQLERRM, 1, 150);
            rollback;
    END insert_document_file_auto;


    PROCEDURE retrieve_document_file (p_instance_id       IN VARCHAR2
                                     ,p_username          IN VARCHAR2
                                     ,p_source_system    OUT VARCHAR2
                                     ,p_document_details OUT xxsoa_document_details_obj
                                     ,x_status           OUT VARCHAR2
                                     ,x_error_message    OUT VARCHAR2
    )
    AS
        CURSOR cur_erdms_documents(p_instance_id VARCHAR2)
            IS
            SELECT source_document_id
                 ,      edrms_document_id
                 ,      file_data
                 ,      file_name
                 ,      file_extension_type
            FROM   xxsoa_edrms_documents
            WHERE  soa_instance_id = p_instance_id;

        rec_erdms_documents cur_erdms_documents%ROWTYPE;
        l_found boolean;
        l_not_found EXCEPTION;

    BEGIN
        --
        OPEN cur_erdms_documents(p_instance_id);
        FETCH cur_erdms_documents INTO rec_erdms_documents;
        l_found := cur_erdms_documents%FOUND;
        CLOSE cur_erdms_documents;

        IF l_found
        THEN

            p_document_details := xxsoa_document_details_obj(rec_erdms_documents.edrms_document_id
                ,rec_erdms_documents.source_document_id
                ,rec_erdms_documents.file_data
                ,rec_erdms_documents.file_name
                ,rec_erdms_documents.file_extension_type
                );
        ELSE
            RAISE l_not_found;
        END IF;

        x_status := 'Success';

    EXCEPTION
        WHEN l_not_found THEN
            x_status := 'Error';
            x_error_message:='There are no records found.';
        WHEN OTHERS THEN
            x_status := 'Error';
            x_error_message:='ERROR is :- '||SUBSTR (SQLERRM, 1, 150);
    END retrieve_document_file;

    PROCEDURE delete_document_file  (p_instance_id       IN VARCHAR2
                                    ,p_username          IN VARCHAR2
                                    ,x_status           OUT VARCHAR2
                                    ,x_error_message    OUT VARCHAR2
    )
        IS

    BEGIN
        DELETE FROM xxsoa_edrms_documents
        WHERE  soa_instance_id = p_instance_id;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'Error';
            x_error_message:='ERROR is :- '||SUBSTR (SQLERRM, 1, 150);
    END delete_document_file;

END XXSOA_TRANSIENT_DOCUMENT_PKG;
/


--------------------------------------------------------
--  DDL for Constraint ID_PK
--------------------------------------------------------
ALTER TABLE "XXEDRMS"."XXSOA_EDRMS_DOCUMENTS" ADD CONSTRAINT "ID_PK" PRIMARY KEY ("ID");

```