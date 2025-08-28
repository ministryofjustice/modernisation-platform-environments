SET enable_case_sensitive_identifier TO true;

/* RQEV2-Q7BDSX0UlC */
CREATE MATERIALIZED VIEW yjb_ianda_team.custodies_since_2014
distkey
    (source_document_id)
sortkey
    (source_document_id) AS 
    WITH pd AS (
        SELECT
            header.source_document_id,
            document_item."dateOfBirth":: date AS ypid_dob,
            document_item."currentYOTID":: text AS currentyotid,
            document_item."ypid":: text,
            document_item."ethnicity":: text,
            document_item."sex":: text,
            document_item."gender":: text,
            document_item."originatingYOTPersonID":: text as oypid,
            header.deleted,
            yot.ou_code_names_standardised AS yot_code,
            yot.yjs_name_names_standardised AS yjs_name,
            yot.area_operations_standardised AS area_operations,
            yot.yjb_country_names_standardised AS yjb_country
        FROM
            stg.yp_doc_item AS dc
            INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record ON dc.source_document_id = latest_record.source_document_id
            INNER JOIN stg.yp_doc_header AS header ON header.source_document_id = dc.source_document_id
            LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = header.yotoucode
        WHERE
            document_item_type = 'person_details'
    ),
    offence AS (
        SELECT
            o.source_document_id AS source_document_id_offence,
            o.document_item."offenceID":: text AS offence_id,
            olo."outcomeDate":: date AS outcome_date,
            olo."legalOutcome":: Varchar(100) AS legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) AS legal_outcome_group,
            olo."termYears":: int AS term_years,
            olo."termMonths":: int AS term_months,
            olo."cmslegalOutcome":: Varchar(100) AS cms_legal_outcome,
            olo."residenceOnLegalOutcomeDate":: Varchar(100) AS residence_on_legal_outcome_date,
            olo."outcomeAppealStatus":: Varchar(500) AS outcome_appeal_status,
            o.document_item."ageOnFirstHearing":: int as age_at_first_hearing
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON TRUE
        WHERE
            document_item_type = 'offence'
    )
SELECT
    DISTINCT pd.*,
    eth.ethnicitygroup AS ethnicity_group,
    CASE
    WHEN pd.sex = '1' THEN 'Male'
    WHEN pd.sex = '2' THEN 'Female'
    WHEN pd.gender = '1' THEN 'Male'
    WHEN pd.gender = '2' THEN 'Female'
    ELSE 'Unknown gender' END AS gender_name,
    offence.offence_id,
    offence.age_at_first_hearing,
    offence.residence_on_legal_outcome_date,
    offence.outcome_appeal_status,
    offence.outcome_date,
    offence.cms_legal_outcome,
    offence.legal_outcome,
    m1.legal_outcome_fixed,
    CASE
    WHEN offence.legal_outcome_group = 'Pre-Court' THEN 'Pre-court'
    ELSE offence.legal_outcome_group END AS legal_outcome_group,
    m1.legal_outcome_group_fixed,
    offence.term_years,
    offence.term_months,
    --new label_quarter to get year first and quarter second
    CONCAT(
        RIGHT(date_tbl.year_quarter_name, 4),
        LEFT(date_tbl.year_quarter_name, 2)
    ) AS label_quarter
FROM
    offence
    LEFT JOIN refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
    LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
    LEFT JOIN refdata.ethnicity_group AS eth ON pd.ethnicity = eth.ethnicity
    LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted as m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
WHERE
    pd.deleted = FALSE
    AND legal_outcome_group_fixed = 'Custody'
    AND offence.outcome_appeal_status NOT IN (
        'Changed on appeal',
        'Result of appeal successful'
    )
    AND offence.residence_on_legal_outcome_date <> 'OTHER'
    AND offence.age_at_first_hearing BETWEEN 10
    AND 17
    AND offence.outcome_date BETWEEN '2014-04-01'
    AND GETDATE()
    AND pd.ypid NOT IN (
        SELECT
            yp_id
        FROM
            yjb_case_reporting_stg.vw_deleted_yps
    );	
/* RQEV2-ajEV8uPsOS */
-- CREATE
-- OR REPLACE VIEW "yjb_ianda_team"."fte_redshift" 
CREATE MATERIALIZED VIEW "yjb_ianda_team"."fte_redshift"
distkey
    (source_document_id)
sortkey
    (source_document_id) AS 
WITH person_details AS (
    SELECT
        header.source_document_id,
        document_item."preferredLanguage":: text as preferred_language,
        document_item."dateOfBirth":: date as date_of_birth,
        -- document_item."dateOf18ThBirthday":: date as date_of_18th_birthday, 
        document_item."gender":: int,
        document_item."sex":: int,
        -- document_item."genderTermUsed":: text as gender_term_used, 
        -- document_item."genderIdentifiedSameSexRegisteredBirth":: text as gender_identified_same_sex_registered_birth, 
        document_item."ethnicity",
        document_item.ethnicitygroup AS ethnicity_group,
        -- document_item."nationality":: text, 
        document_item."currentYOTID":: text as currentyotid,
        document_item."ypid":: text,
        document_item."originatingYOTPersonID":: text as oypid,
        -- document_item."immigrationStatus":: text as immigration_status, 
        document_item."pncnumber":: text,
        document_item."religion":: text,
        header.deleted,
        -- header.yotoucode as header_yotoucode, LW: don't need it twice - can just join on it 
        header.etl_process_id,
        yot.ou_code_names_standardised as ou_code_names_standardised,
        yot.yjs_name_names_standardised as yjs_name,
        yot.yot_region_names_standardised as yjb_region,
        yot.area_operations_standardised as area_operations,
        yot.yjb_country_names_standardised as yjb_country
    FROM
        stg.yp_doc_item as dc
        INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record ON dc.source_document_id = latest_record.source_document_id
        INNER JOIN stg.yp_doc_header as header ON header.source_document_id = dc.source_document_id
        RIGHT JOIN yjb_ianda_team.yjs_standardised as yot ON yot.ou_code_names_standardised = header.yotoucode
    WHERE
        dc.document_item_type = 'person_details'
),
offence AS (
    SELECT
        o.source_document_id as source_document_id_offence,
        o.document_item."offenceID":: text as offence_id,
        o.document_item."offenceDate":: date as offence_date,
        o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence,
        o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
        o.document_item."offenceDescription":: text as offence_description,
        o.document_item."cjscode":: Varchar(10) as cjscode,
        o.document_item."cjscodeUnknown":: varchar(100) as cjscode_unknown,
        o.document_item."yjboffenceCategory":: Varchar(100) as yjb_offence_category,
        o.document_item."knifeRelatedOffence":: Varchar(100) as knife_related_offence,
        o.document_item."yjbseriousnessScore":: int as yjb_seriousness_score,
        olo."outcomeDate":: date as outcome_date,
        olo."outcomeEndDate":: date as outcome_end_date,
        olo."legalOutcome":: Varchar(100) as legal_outcome,
        olo."legalOutcomeGroup":: Varchar(100) as legal_outcome_group,
        olo."cmslegalOutcome":: Varchar(100) as cms_legal_outcome,
        olo."residenceOnLegalOutcomeDate":: Varchar(100) as residence_on_legal_outcome_date,
        olo."outcomeAppealStatus":: Varchar(500) as outcome_appeal_status,
        olo."mainOrOther":: Varchar(10) as main_or_other
    FROM
        stg.yp_doc_item AS o
        LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
    WHERE
        o.document_item_type = 'offence'
),
main_sql AS (
    SELECT
        pd.source_document_id,
        pd.currentyotid,
        pd.ypid,
        CASE 
        WHEN oypid LIKE '% %' THEN NULL
        WHEN oypid LIKE '' THEN NULL
        WHEN oypid IN ('N/A', 'n/a') THEN 'N/A'
        ELSE oypid
        END AS oypid, 
        pd.pncnumber,
        pd.ou_code_names_standardised,
        pd.yjs_name,
        pd.yjb_region,
        pd.area_operations,
        pd.yjb_country,
        pd.date_of_birth,
        CASE
            WHEN (
                CASE
                    WHEN pd.gender IS NULL AND pd.sex IS NOT NULL THEN pd.sex
                    ELSE pd.gender 
                END
            ) = '1' THEN 'Male'
            WHEN (
                CASE
                    WHEN pd.gender IS NULL AND pd.sex IS NOT NULL THEN pd.sex
                    ELSE pd.gender 
                END
            ) = '2' THEN 'Female'
            ELSE 'Unknown gender' 
        END AS gender_name,
        pd.ethnicity,
        pd.ethnicity_group,
        of.*,
        datediff(year, pd.date_of_birth, of.outcome_date) AS age_on_outcome_date,
        pd.deleted,
        CASE
            WHEN m1.Mapping_Target_Text = 'Diversion' THEN 'Diversion'
            WHEN of.legal_outcome IN (
                'OTHER_INFORMAL_ACTION_YOT_INVOLVEMENT',
                'OTHER_INFORMAL_ACTION_NO_YOT_INVOLVEMENT',
                'COMMUNITY_RESOLUTION_OTHER_AGENCY_FACILITATED',
                'COMMUNITY_RESOLUTION_WITH_YOT_INTERVENTION',
                'COMMUNITY_RESOLUTION_POLICE_FACILITATED',
                'COMMUNITY_RESOLUTION'
            ) THEN 'Diversion (Other)'
            WHEN of.legal_outcome IN ('SECTION_250', 'SECTION_254', 'SECTION_259') THEN 'Custody'
            WHEN m1.Mapping_Target_Text IS NOT NULL THEN m1.Mapping_Target_Text
            ELSE ISNULL(of.legal_outcome_group, '') 
        END AS legal_outcome_group_fixed,
        CASE
            WHEN m2.Mapping_Target_Text IS NOT NULL THEN m2.Mapping_Target_Text
            ELSE of.legal_outcome 
        END AS legal_outcome_fixed,
        -- Additional fields from the original offence_labelled
        date_tbl.day_of_month_number,
        -- ... (add any additional fields you need)
        date_tbl.month_number,
        date_tbl.month_name,
        date_tbl.year_number,
        date_tbl.quarter_number,
        date_tbl.quarter_name,
        date_tbl.year_quarter_name AS label_quarter,
        ROW_NUMBER() OVER (
            PARTITION BY pd.ypid
            ORDER BY of.outcome_date ASC, rank_legal_outcome_desc DESC
        ) AS ypid_rn,
        rank_legal_outcome_desc
    FROM
        offence AS of
        INNER JOIN person_details AS pd ON pd.source_document_id = of.source_document_id_offence
        LEFT JOIN refdata.data_mapping AS m1 ON upper(LTRIM(RTRIM(of.cms_legal_outcome))) = LTRIM(RTRIM(m1.Mapping_Source))
            AND m1.Mapping_Type = 'legal_outcome_group_fixed'
        LEFT JOIN refdata.data_mapping AS m2 ON upper(LTRIM(RTRIM(of.cms_legal_outcome))) = LTRIM(RTRIM(m2.Mapping_Source))
            AND m2.Mapping_Type = 'legal_outcome_fixed'
        LEFT JOIN yjb_ianda_team.fte_legal_outcome_mapping fte_mapping ON of.legal_outcome = fte_mapping.legal_outcome
        LEFT JOIN yjb_returns.refdata.ethnicity_group AS eth ON CAST(pd.ethnicity AS NVARCHAR) = CAST(eth.ethnicity AS NVARCHAR)
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(of.outcome_end_date AS date) = CAST(date_tbl.day_date AS date)
    WHERE
        (
            of.age_at_arrest_or_offence BETWEEN 10 AND 17
            AND of.age_at_first_hearing <= 17
        )
        AND legal_outcome_group_fixed IN ('Pre-Court', 'First-tier', 'Community', 'Custody')
        AND of.outcome_appeal_status NOT IN (
            'Changed on appeal', 
            'Result of appeal successful'
            )
        -- AND main_or_other = 'MAIN'
),
oypid AS (SELECT
    *,
    CASE 
    WHEN oypid IS NOT NULL OR oypid <> 'N/A'
    THEN ROW_NUMBER() OVER (
            PARTITION BY oypid, date_of_birth
            ORDER BY outcome_date ASC, rank_legal_outcome_desc DESC
        ) 
    ELSE 1 
    END AS oypid_rn --LW: duplicate FTEs within the same YJS (same oypid, same yjs, same date of birth) and different YJS (same oypid, same DOB)
FROM
    main_sql
WHERE
    ypid_rn = 1)
SELECT  
    source_document_id,
    currentyotid,
    ypid,
    oypid, 
    pncnumber,
    ou_code_names_standardised,
    yjs_name,
    yjb_region,
    area_operations,
    yjb_country,
    date_of_birth,
    gender_name,
    ethnicity,
    ethnicity_group,
    offence_id,
    offence_date,
    age_at_arrest_or_offence,
    age_at_first_hearing,
    age_on_outcome_date,
    offence_description,
    cjscode,
    cjscode_unknown,
    yjb_offence_category,
    knife_related_offence,
    yjb_seriousness_score,
    outcome_date,
    outcome_end_date,
    legal_outcome,
    legal_outcome_group,
    legal_outcome_group_fixed,
    cms_legal_outcome,
    residence_on_legal_outcome_date,
    outcome_appeal_status,
    main_or_other,
    deleted,
    legal_outcome_fixed,
    day_of_month_number,
    month_number,
    month_name,
    year_number,
    quarter_number,
    quarter_name,
    label_quarter
FROM oypid
WHERE oypid_rn = 1
AND residence_on_legal_outcome_date <> 'OTHER' --LW: moved here as it removes any duplicate cases that had an earlier 'other' to their previously counted 'local' 
;	
/* RQEV2-fhABv3ypFq */
CREATE MATERIALIZED VIEW yjb_ianda_team.sexual_offences_since_2016
distkey
    (source_document_id)
sortkey
    (source_document_id) AS WITH pd AS (
        SELECT
            header.source_document_id,
            document_item."dateOfBirth":: date AS ypid_dob,
            document_item."ypid":: text,
            header.deleted
        FROM
            stg.yp_doc_item AS dc
            INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record ON dc.source_document_id = latest_record.source_document_id
            INNER JOIN stg.yp_doc_header AS header ON header.source_document_id = dc.source_document_id
        WHERE
            dc.document_item_type = 'person_details'
            AND header.deleted = FALSE
    ),
    offence AS (
        SELECT
            o.source_document_id AS source_document_id_offence,
            o.document_item."offenceID":: text AS offence_id,
            o.document_item."yjboffenceCategory":: Varchar(100) as yjb_offence_category,
            olo."outcomeDate":: date AS outcome_date,
            olo."legalOutcome":: Varchar(100) AS legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) AS legal_outcome_group,
            olo."cmslegalOutcome":: Varchar(100) AS cms_legal_outcome,
            olo."residenceOnLegalOutcomeDate":: Varchar(100) AS residence_on_legal_outcome_date,
            olo."outcomeAppealStatus":: Varchar(500) AS outcome_appeal_status,
            o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
            o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON TRUE
        WHERE
            o.document_item_type = 'offence'
            AND yjb_offence_category = 'SEXUAL_OFFENCES'
            AND outcome_appeal_status NOT IN (
                'Changed on appeal',
                'Result of appeal successful'
            )
            AND residence_on_legal_outcome_date <> 'OTHER'
            AND outcome_date BETWEEN '2016-04-01'
            AND '2024-03-31'
    ),
    combine AS (
        SELECT
            DISTINCT pd.*,
            offence.age_at_first_hearing,
            CASE
            WHEN m1.legal_outcome_group_fixed IN ('Pre-court') THEN offence.age_at_arrest_or_offence
            ELSE offence.age_at_first_hearing END AS age,
            offence.offence_id,
            offence.residence_on_legal_outcome_date,
            offence.outcome_appeal_status,
            offence.outcome_date,
            offence.cms_legal_outcome,
            offence.legal_outcome,
            m1.legal_outcome_fixed,
            CASE
            WHEN offence.legal_outcome_group = 'Pre-Court' THEN 'Pre-court'
            ELSE offence.legal_outcome_group END AS legal_outcome_group,
            m1.legal_outcome_group_fixed,
            CASE
            WHEN offence.outcome_date BETWEEN '2016-04-01'
            AND '2017-03-31' THEN '2016/2017'
            WHEN offence.outcome_date BETWEEN '2017-04-01'
            AND '2018-03-31' THEN '2017/2018'
            WHEN offence.outcome_date BETWEEN '2018-04-01'
            AND '2019-03-31' THEN '2018/2019'
            WHEN offence.outcome_date BETWEEN '2019-04-01'
            AND '2020-03-31' THEN '2019/2020'
            WHEN offence.outcome_date BETWEEN '2020-04-01'
            AND '2021-03-31' THEN '2020/2021'
            WHEN offence.outcome_date BETWEEN '2021-04-01'
            AND '2022-03-31' THEN '2021/2022'
            WHEN offence.outcome_date BETWEEN '2022-04-01'
            AND '2023-03-31' THEN '2022/2023'
            WHEN offence.outcome_date BETWEEN '2023-04-01'
            AND '2024-03-31' THEN '2023/2024' END AS financial_year
        FROM
            offence
            LEFT JOIN refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
            LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
            LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted as m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
        WHERE
            pd.ypid NOT IN (
                SELECT
                    yp_id
                FROM
                    yjb_case_reporting_stg.vw_deleted_yps
            )
            AND m1.legal_outcome_group_fixed IN ('First-tier', 'Community', 'Pre-court', 'Custody')
    )
SELECT
    *
FROM
    combine
WHERE
    age BETWEEN 10
    AND 17;	
/* RQEV2-vTSOdCWmaq */
CREATE MATERIALIZED VIEW yjb_ianda_team.sexual_offences_since_2016_all_offences
distkey
    (source_document_id)
sortkey
    (source_document_id) AS WITH pd AS (
        SELECT
            header.source_document_id,
            document_item."dateOfBirth":: date AS ypid_dob,
            document_item."ypid":: text,
            header.deleted
        FROM
            stg.yp_doc_item AS dc
            INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record ON dc.source_document_id = latest_record.source_document_id
            INNER JOIN stg.yp_doc_header AS header ON header.source_document_id = dc.source_document_id
        WHERE
            dc.document_item_type = 'person_details'
            AND header.deleted = FALSE
    ),
    offence AS (
        SELECT
            o.source_document_id AS source_document_id_offence,
            o.document_item."offenceID":: text AS offence_id,
            o.document_item."yjboffenceCategory":: Varchar(100) as yjb_offence_category,
            olo."outcomeDate":: date AS outcome_date,
            olo."legalOutcome":: Varchar(100) AS legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) AS legal_outcome_group,
            olo."cmslegalOutcome":: Varchar(100) AS cms_legal_outcome,
            olo."residenceOnLegalOutcomeDate":: Varchar(100) AS residence_on_legal_outcome_date,
            olo."outcomeAppealStatus":: Varchar(500) AS outcome_appeal_status,
            o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
            o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON TRUE
        WHERE
            o.document_item_type = 'offence'
            AND yjb_offence_category = 'SEXUAL_OFFENCES'
            --AND outcome_appeal_status NOT IN (
                --'Changed on appeal',
                --'Result of appeal successful'
           -- )
            AND residence_on_legal_outcome_date <> 'OTHER'
            AND outcome_date BETWEEN '2016-04-01'
            AND '2024-03-31'
    ),
    combine AS (
        SELECT
            DISTINCT pd.*,
            offence.age_at_first_hearing,
            CASE
            WHEN m1.legal_outcome_group_fixed IN ('Pre-court') THEN offence.age_at_arrest_or_offence
            ELSE offence.age_at_first_hearing END AS age,
            offence.offence_id,
            offence.residence_on_legal_outcome_date,
            offence.outcome_appeal_status,
            offence.outcome_date,
            offence.cms_legal_outcome,
            offence.legal_outcome,
            m1.legal_outcome_fixed,
            CASE
            WHEN offence.legal_outcome_group = 'Pre-Court' THEN 'Pre-court'
            ELSE offence.legal_outcome_group END AS legal_outcome_group,
            m1.legal_outcome_group_fixed,
            CASE
            WHEN offence.outcome_date BETWEEN '2016-04-01'
            AND '2017-03-31' THEN '2016/2017'
            WHEN offence.outcome_date BETWEEN '2017-04-01'
            AND '2018-03-31' THEN '2017/2018'
            WHEN offence.outcome_date BETWEEN '2018-04-01'
            AND '2019-03-31' THEN '2018/2019'
            WHEN offence.outcome_date BETWEEN '2019-04-01'
            AND '2020-03-31' THEN '2019/2020'
            WHEN offence.outcome_date BETWEEN '2020-04-01'
            AND '2021-03-31' THEN '2020/2021'
            WHEN offence.outcome_date BETWEEN '2021-04-01'
            AND '2022-03-31' THEN '2021/2022'
            WHEN offence.outcome_date BETWEEN '2022-04-01'
            AND '2023-03-31' THEN '2022/2023'
            WHEN offence.outcome_date BETWEEN '2023-04-01'
            AND '2024-03-31' THEN '2023/2024' END AS financial_year
        FROM
            offence
            LEFT JOIN refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
            LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
            LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted as m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
        WHERE
            pd.ypid NOT IN (
                SELECT
                    yp_id
                FROM
                    yjb_case_reporting_stg.vw_deleted_yps
            )
            --AND m1.legal_outcome_group_fixed IN ('First-tier', 'Community', 'Pre-court', 'Custody')
    )
SELECT
    *
FROM
    combine
WHERE
    age BETWEEN 10
    AND 17;	
/* RQEV2-G1hp8HXkpR */
CREATE MATERIALIZED VIEW yjb_ianda_team.sv_2020_2024
distkey
    (source_document_id)
sortkey
    (source_document_id) AS WITH pd AS (
        SELECT
            header.source_document_id as source_document_id,
            document_item."dateOfBirth":: date as ypid_dob,
            document_item."currentYOTID":: text as currentyotid,
            document_item."ypid":: text,
            document_item."ethnicity":: text,
            document_item."sex":: text,
            document_item."gender":: text,
            document_item."originatingYOTPersonID":: text as oypid,
            header.deleted,
            yot.ou_code_names_standardised as yot_code,
            yot.yjs_name_names_standardised as yjs_name,
            yot.area_operations_standardised as area_operations,
            yot.yjb_country_names_standardised as yjb_country
        FROM
            stg.yp_doc_item as dc
            INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record ON dc.source_document_id = latest_record.source_document_id
            INNER JOIN stg.yp_doc_header as header ON header.source_document_id = dc.source_document_id
            LEFT JOIN yjb_ianda_team.yjs_standardised as yot ON yot.ou_code_names_standardised = header.yotoucode
        WHERE
            document_item_type = 'person_details'
    ),
    offence AS (
        SELECT
            o.source_document_id as source_document_id_offence,
            o.document_item."offenceID":: text as offence_id,
            o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence,
            o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
            o.document_item."yjboffenceCategory":: Varchar(100) as yjb_offence_category,
            o.document_item."yjbseriousnessScore":: int as yjb_seriousness_score,
            olo."outcomeDate":: date as outcome_date,
            olo."legalOutcome":: Varchar(100) as legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) as legal_outcome_group,
            olo."cmslegalOutcome":: Varchar(100) as cms_legal_outcome,
            olo."residenceOnLegalOutcomeDate":: Varchar(100) as residence_on_legal_outcome_date,
            olo."outcomeAppealStatus":: Varchar(500) as outcome_appeal_status
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
        WHERE
            document_item_type = 'offence'
    ),
    combine AS(
        SELECT
            DISTINCT pd.*,
            eth.ethnicitygroup AS ethnicity_group,
            CASE
            WHEN sex = '1' THEN 'Male'
            WHEN sex = '2' THEN 'Female'
            WHEN gender = '1' THEN 'Male'
            WHEN gender = '2' THEN 'Female'
            ELSE 'Unknown gender' END AS gender_name,
            offence.offence_id,
            offence.outcome_date,
            offence.cms_legal_outcome,
            offence.residence_on_legal_outcome_date,
            offence.outcome_appeal_status,
            CASE
            WHEN offence.legal_outcome IN ('NOT_KNOWN', 'OTHER') THEN m1.legal_outcome_fixed
            ELSE offence.legal_outcome END AS legal_outcome,
            offence.legal_outcome_group,
            offence.age_at_arrest_or_offence,
            offence.age_at_first_hearing,
            offence.yjb_offence_category,
            offence.yjb_seriousness_score,
            CONCAT(
                RIGHT(date_tbl.year_quarter_name, 4),
                LEFT(date_tbl.year_quarter_name, 2)
            ) AS label_quarter
        FROM
            offence 
            LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
            LEFT JOIN refdata.ethnicity_group AS eth ON pd.ethnicity = eth.ethnicity
            LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted AS m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
            LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
        WHERE
            pd.deleted = FALSE
            AND offence.residence_on_legal_outcome_date <> 'OTHER'
            AND offence.outcome_appeal_status NOT IN (
                'Changed on appeal',
                'Result of appeal successful'
            )
            AND (
                offence.outcome_date >= '2020-04-01'
                AND offence.outcome_date <= '2024-04-01'
            )
            AND pd.ypid NOT IN (
                SELECT
                    yp_id
                FROM
                    yjb_case_reporting_stg.vw_deleted_yps
            )
            AND pd.yjs_name <> 'Cumbria'
    ),
    --had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting type of order (NULLs) when they were in the CTE above.
    add_count_in_kpi AS (
        SELECT
            combine.*,
            count_in_kpi_lo.legal_outcome_group_fixed,
            count_in_kpi_lo.count_in_kpi_legal_outcome,
            count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
            seriousness.seriousness_ranking,
            CASE
            WHEN count_in_kpi_lo.legal_outcome_group_fixed IN ('Pre-Court') THEN combine.age_at_arrest_or_offence
            ELSE combine.age_at_first_hearing END AS age_serious_violence
        FROM
            combine
            LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
            LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
        WHERE
            count_in_kpi_lo.count_in_kpi_legal_outcome = 'YES'
            AND count_in_kpi_lo.legal_outcome_group_fixed IN ('Pre-Court', 'First-tier', 'Community', 'Custody')
    ),
    limit_age_range AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY ypid,
                offence_id -- by partitioning by ypid and offence_id we count all offences - rather than just one
                ORDER BY
                    seriousness_ranking,
                    outcome_date DESC --where multiple seriousness_ranking or outcome dates for same offence we take latest
            ) as most_serious_recent
        FROM
            add_count_in_kpi
        WHERE
            age_serious_violence BETWEEN 10
            AND 17
    ),
    take_latest_offence AS (
        SELECT
            *,
            -- identify serious violence offences
            yjb_kpi_case_level.f_seriousviolence(
                yjb_offence_category,
                yjb_seriousness_score,
                offence_id
            ) AS kpi9_sv_offences
        FROM
            limit_age_range
        WHERE
            most_serious_recent = 1
    )
SELECT
    source_document_id,
    ypid,
    currentyotid,
    oypid,
    ypid_dob,
    age_serious_violence,
    ethnicity_group,
    gender_name,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    offence_id,
    ypid + offence_id as distinct_offence_id,
    yjb_offence_category,
    yjb_seriousness_score,
    outcome_date,
    legal_outcome,
    legal_outcome_group_fixed,
    type_of_order
FROM
    take_latest_offence
WHERE
    kpi9_sv_offences = offence_id;	
/* RQEV2-TAW3YQ7n5L */


CREATE MATERIALIZED VIEW yjb_ianda_team.yro_moj_JB

distkey
    (source_document_id)
sortkey
    (source_document_id) AS
    
WITH yro AS (
    SELECT
        di.source_document_id AS source_document_id,
        activity_type,
        yro."requirementsYROOnly"::text as requirements_yro_only,
        yro."yrorequirementStartDate":: date as yro_start_date,
        yro."yrorequirementEndDate":: date as yro_end_date
    FROM
        stg.yp_doc_item di,
        di.document_item."offencesASBDetails"."offenceAndASB"."disposals" as disp,
        disp."activityType" as activity_type,
        disp."yrorequirementsGroup" as yro
    WHERE
        document_item_type = 'assessment_stage'
)
 
SELECT DISTINCT
    l.source_document_id,
    yro.source_document_id as yro_source_document_id,
    
    y.yot_name,
    p.currentyotid,
    p.date_of_birth,
    p.PNCnumber,
    p.originating_yot_person_id,
    p.ethnicity,
    p.sex,
 
    CAST(o.outcome_date AS NVARCHAR) AS outcome_date,
    o.legal_outcome,
    o.requirement,
    o.yjb_offence_category,
    o.offence_date,
    o.term_days,
    o.term_months,
    o.term_weeks,
    o.term_years,
    o.outcome_appeal_status,
    h.yjb_sentence_proposal_type,
        
    yro.activity_type,
    yro.yro_start_date,
    yro.yro_end_date
 
FROM yjb_case_reporting.mvw_yp_latest_record as l
    INNER JOIN yjb_case_reporting.mvw_yp_document_header as dh on dh.source_document_id = l.source_document_id
    INNER JOIN yjb_case_reporting.mvw_yp_person_details as p on p.source_document_id = l.source_document_id
    INNER JOIN yjb_case_reporting.mvw_yp_offence as o on o.source_document_id = l.source_document_id
    INNER JOIN yjb_case_reporting.mvw_yp_hearing_sentence_proposal as h on h.source_document_id = l.source_document_id
    LEFT JOIN refdata.yotoucodes as y on y.yotoucode = dh.yot_ou_code
    LEFT JOIN refdata.date_table as DT on  o.outcome_date =  DT.day_date
    LEFT JOIN yro ON l.source_document_id = yro.source_document_id
 
WHERE
    (age_at_first_hearing  >= 10 and age_at_first_hearing  <= 17
    AND age_at_arrest_or_offence >= 10 AND age_at_arrest_or_offence <= 17
    AND UPPER(o.legal_outcome) = 'YOUTH_REHABILITATION_ORDER'
    OR UPPER(o.legal_outcome) = 'REFERRAL_ORDER'
   OR UPPER(o.legal_outcome) = 'DETENTION_AND_TRAINING_ORDER'
    --OR UPPER(o.legal_outcome) = 'SECTION_250'
    --OR UPPER(o.legal_outcome) = 'SECTION_259'
    --OR UPPER(o.legal_outcome) = 'SECTION_254'
    --OR UPPER(o.legal_outcome) = 'SECTION_90_92_DETENTION'
    --OR UPPER(o.legal_outcome) = 'SECTION_226_B'
   -- OR UPPER(o.legal_outcome) = 'SECTION_90_91_DETENTION'
    --OR UPPER(o.legal_outcome) = 'SECTION_226_LIFE'
    AND p.Deleted = 'f')
    and o.outcome_appeal_status <> 'Changed on appeal'
    AND (UPPER(Residence_On_Legal_Outcome_Date) = 'LOCAL'
    OR Residence_On_Legal_Outcome_Date IS NULL)
 
    and o.outcome_date  >= '2017-04-01'
    and o.outcome_date <= '2025-03-31';	
