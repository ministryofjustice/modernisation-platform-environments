SET
    enable_case_sensitive_identifier TO true;
DROP MATERIALIZED VIEW IF EXISTS yjb_ianda_team.fte_redshift;
CREATE MATERIALIZED VIEW "yjb_ianda_team"."fte_redshift"
distkey
    (source_document_id)
sortkey
    (source_document_id) AS WITH person_details AS (
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
            ELSE oypid END AS oypid,
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
                WHEN pd.gender IS NULL
                AND pd.sex IS NOT NULL THEN pd.sex
                ELSE pd.gender END
            ) = '1' THEN 'Male'
            WHEN (
                CASE
                WHEN pd.gender IS NULL
                AND pd.sex IS NOT NULL THEN pd.sex
                ELSE pd.gender END
            ) = '2' THEN 'Female'
            ELSE 'Unknown gender' END AS gender_name,
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
            ELSE ISNULL(of.legal_outcome_group, '') END AS legal_outcome_group_fixed,
            CASE
            WHEN m2.Mapping_Target_Text IS NOT NULL THEN m2.Mapping_Target_Text
            ELSE of.legal_outcome END AS legal_outcome_fixed,
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
                ORDER BY
                    of.outcome_date ASC,
                    rank_legal_outcome_desc DESC
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
            LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(of.outcome_date AS date) = CAST(date_tbl.day_date AS date)
        WHERE
            (
                of.age_at_arrest_or_offence BETWEEN 10
                AND 17
                AND of.age_at_first_hearing <= 17
            )
            AND legal_outcome_group_fixed IN ('Pre-Court', 'First-tier', 'Community', 'Custody')
            AND of.outcome_appeal_status NOT IN (
                'Changed on appeal',
                'Result of appeal successful'
            )
            AND pd.ypid NOT IN (
                SELECT
                    yp_id
                FROM
                    yjb_case_reporting_stg.vw_deleted_yps
            ) -- AND main_or_other = 'MAIN'
    ),
    oypid AS (
        SELECT
            *,
            CASE
            WHEN oypid IS NOT NULL
            OR oypid <> 'N/A' THEN ROW_NUMBER() OVER (
                PARTITION BY oypid,
                date_of_birth
                ORDER BY
                    outcome_date ASC,
                    rank_legal_outcome_desc DESC
            )
            ELSE 1 END AS oypid_rn --LW: duplicate FTEs within the same YJS (same oypid, same yjs, same date of birth) and different YJS (same oypid, same DOB)
        FROM
            main_sql
        WHERE
            ypid_rn = 1
    )
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
    label_quarter,
    getdate() AS date_created -- timestamp for when the table was last built via the schedule function
FROM
    oypid
WHERE
    oypid_rn = 1
    AND residence_on_legal_outcome_date <> 'OTHER' --LW: moved here as it removes any duplicate cases that had an earlier 'other' to their previously counted 'local'
;
GRANT ALL ON yjb_ianda_team.fte_redshift TO GROUP yjb_ianda_team;