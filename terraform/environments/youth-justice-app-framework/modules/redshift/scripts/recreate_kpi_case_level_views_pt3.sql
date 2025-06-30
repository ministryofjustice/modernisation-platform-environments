SET enable_case_sensitive_identifier TO true;

/* RQEV2-CCdZbpnsKm */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.children_remand_4_plus_weeks
distkey
    (source_document_id)
sortkey
    (source_document_id) AS WITH pd AS (
        SELECT
            header.source_document_id,
            document_item."ypid":: text,
            document_item."dateOfBirth":: date AS ypid_dob,
            document_item."currentYOTID":: text AS currentyotid,
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
            o.source_document_id as source_document_id_offence,
            o.document_item."offenceID":: text as offence_id,
            o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
            olo."outcomeDate":: date as outcome_date,
            olo."cmslegalOutcome":: Varchar(100) as cms_legal_outcome,
            olo."legalOutcome":: Varchar(100) as legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) as legal_outcome_group,
            olo."residenceOnLegalOutcomeDate":: Varchar(100) as residence_on_legal_outcome_date,
            olo."outcomeAppealStatus":: Varchar(500) as outcome_appeal_status
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
        WHERE
            document_item_type = 'offence'
    ),
    hearing as (
        SELECT
            -- *,
            dc.source_document_id as source_document_id_h,
            dc.document_item."hearingID":: numeric as hearing_id,
            dc.document_item."hearingDate":: date AS hearing_date,
            dc.document_item."cmsremandDecision":: text AS cms_remand_decision,
            dc.document_item."remandDecision":: text AS remand_decision,
            dc.document_item."yjbremandProposalType":: text AS remand_proposal_type
        FROM
            stg.yp_doc_item as dc
        WHERE
            document_item_type = 'hearing'
            AND remand_decision IN (
                'REMAND_TO_LOCAL_AUTHORITY_ACCOMMODATION_AND_GPS_TAG',
                'REMAND_TO_LOCAL_AUTHORITY_ACCOMMODATION',
                'REMAND_TO_LOCAL_AUTHORITY_ACCOMMODATION_AND_TAG',
                'REMAND_IN_CUSTODY',
                'REMAND_TO_LOCAL_AUTHORITY_ACCOMMODATION_AND_RADIO_TAG',
                'REMAND_TO_LOCAL_AUTHORITY_ACCOMMODATION_AND_CURFEW',
                'COURT_ORDERED_SECURE_REMAND'
            )
    ),
    intervention_prog AS (
        SELECT
            yp_doc_item.source_document_id AS source_document_id_ip,
            document_item."interventionProgrammeID":: text AS intervention_programme_id,
            document_item."startDate":: date AS intervention_start_date,
            document_item."endDate":: date AS intervention_end_date,
            document_item."cmsdisposalType" AS cms_disposal_type,
            document_item."disposalType":: text AS disposal_type,
            document_item."kpi6SuccessfullyCompleted" AS kpi6_successfully_completed
        FROM
            stg.yp_doc_item
        WHERE
            document_item_type = 'intervention_programme'
    ),
    link AS(
        SELECT
            link.source_document_id,
            document_item."offenceID":: text AS offence_id,
            document_item."interventionProgrammeID":: text AS intervention_programme_id
        FROM
            stg.yp_doc_item AS link
        WHERE
            document_item_type = 'link_offence_intervention_programme'
    ),
    combine AS (
        SELECT
            DISTINCT pd.*,
            eth.ethnicitygroup AS ethnicity_group,
            CASE
            WHEN pd.sex = '1' THEN 'Male'
            WHEN pd.sex = '2' THEN 'Female'
            WHEN pd.gender = '1' THEN 'Male'
            WHEN pd.gender = '2' THEN 'Female'
            ELSE 'Unknown gender' END AS gender_name,
            hearing.*,
            offence.source_document_id_offence,
            offence.offence_id,
            offence.outcome_date,
            offence.cms_legal_outcome,
            offence.residence_on_legal_outcome_date,
            offence.outcome_appeal_status,
            CASE
            WHEN offence.cms_legal_outcome IN (
                'Outcome 22',
                '~Outcome 22',
                'Outcome 22 - Temp code'
            )
            AND intervention_mapping.disposal_type_fixed = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT' THEN 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT'
            WHEN offence.cms_legal_outcome IN (
                'Deferred Prosecution Outcome 22',
                'Deferred Prosecution Outcome 22 - Other Outcome'
            )
            AND intervention_mapping.disposal_type_fixed = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT' THEN 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT'
            WHEN offence.legal_outcome IN ('NOT_KNOWN', 'OTHER') THEN m1.legal_outcome_fixed
            ELSE offence.legal_outcome END AS legal_outcome,
            CASE
            WHEN offence.legal_outcome_group = 'Pre-Court' THEN 'Pre-court'
            ELSE offence.legal_outcome_group END AS legal_outcome_group,
            m1.legal_outcome_fixed,
            ROW_NUMBER() OVER (
                PARTITION BY pd.ypid,
                offence.offence_id
                ORDER BY
                    hearing.hearing_date
            ) AS earliest_hearing,
            DATEDIFF(days, hearing.hearing_date, offence.outcome_date) AS days_between_hearing_outcome,
            intervention_prog.*,
            DATEDIFF(
                year,
                pd.ypid_dob,
                intervention_prog.intervention_start_date
            ) - (
                CASE
                WHEN DATE_PART('MONTH', pd.ypid_dob) < DATE_PART(
                    'MONTH',
                    intervention_prog.intervention_start_date
                ) THEN 0
                WHEN DATE_PART('MONTH', pd.ypid_dob) > DATE_PART(
                    'MONTH',
                    intervention_prog.intervention_start_date
                ) THEN 1
                WHEN DATE_PART('DAY', pd.ypid_dob) <= DATE_PART('DAY', intervention_prog.intervention_start_date) THEN 0
                ELSE 1 END
            ) AS age_on_intervention_start,
            --new label_quarter to get year first and quarter second
            CONCAT(
                RIGHT(date_tbl.year_quarter_name, 4),
                LEFT(date_tbl.year_quarter_name, 2)
            ) AS label_quarter,
            intervention_mapping.disposal_type_fixed,
            intervention_mapping.disposal_type_grouped,
            intervention_mapping.count_in_kpis AS count_in_kpi_disposal
        FROM
            hearing
            LEFT JOIN offence ON offence.source_document_id_offence = hearing.source_document_id_h
            LEFT JOIN link ON link.offence_id = offence.offence_id
            AND link.source_document_id = offence.source_document_id_offence
            LEFT JOIN intervention_prog ON link.intervention_programme_id = intervention_prog.intervention_programme_id
            AND link.source_document_id = intervention_prog.source_document_id_ip
            LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
            LEFT JOIN refdata.ethnicity_group AS eth ON pd.ethnicity = eth.ethnicity
            LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted AS m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
            LEFT JOIN refdata.date_table AS date_tbl ON CAST(intervention_prog.intervention_end_date AS date) = CAST(date_tbl.day_date AS date)
            LEFT JOIN yjb_kpi_case_level.intervention_programme_disposal_type AS intervention_mapping ON UPPER(TRIM(intervention_prog.disposal_type)) = TRIM(intervention_mapping.disposal_type)
        WHERE
            pd.deleted = FALSE
            AND intervention_mapping.count_in_kpis = 'YES' --count_in_kpi_disposal
            AND offence.outcome_appeal_status NOT IN (
                'Changed on appeal',
                'Result of appeal successful'
            )
            AND offence.residence_on_legal_outcome_date <> 'OTHER'
            AND age_on_intervention_start BETWEEN 10
            AND 17
            AND (
                intervention_prog.intervention_end_date >= '2023-04-01'
                AND intervention_prog.intervention_end_date <= GETDATE()
            )
            AND pd.ypid NOT IN (
                SELECT
                    yp_id
                FROM
                    yjb_case_reporting_stg.vw_deleted_yps
            )
    ),
    add_seriousness_count_in_kpi_lo AS (
        SELECT
            combine.*,
            seriousness.seriousness_ranking,
            count_in_kpi_lo.legal_outcome_group_fixed,
            count_in_kpi_lo.count_in_kpi_legal_outcome,
            count_in_kpi_lo.mapping_to_kpi_template AS type_of_order
        FROM
            combine
            LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
            LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
        WHERE
            type_of_order <> 'Custodial sentences'
            AND combine.earliest_hearing = 1 
            AND combine.days_between_hearing_outcome > 27
    ),
    add_rank AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY ypid,
                label_quarter
                ORDER BY
                    outcome_date DESC
            ) as most_recent_offence
        FROM
            add_seriousness_count_in_kpi_lo
        WHERE
            count_in_kpi_legal_outcome = 'YES'
    )
SELECT
    source_document_id,
    ypid,
    currentyotid,
    oypid,
    ypid_dob,
    ethnicity,
    ethnicity_group,
    gender_name,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    hearing_id,
    hearing_date,
    cms_remand_decision,
    remand_decision,
    remand_proposal_type,
    offence_id,
    outcome_date,
    residence_on_legal_outcome_date,
    outcome_appeal_status,
    cms_legal_outcome,
    legal_outcome,
    legal_outcome_fixed,
    legal_outcome_group,
    legal_outcome_group_fixed,
    seriousness_ranking,
    intervention_programme_id,
    intervention_start_date,
    intervention_end_date,
    age_on_intervention_start,
    kpi6_successfully_completed,
    cms_disposal_type,
    disposal_type,
    disposal_type_fixed,
    disposal_type_grouped,
    type_of_order
FROM
    add_rank
WHERE most_recent_offence = 1;	
/* RQEV2-YQ62D4xqDW */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_case_level distkey (source_document_id) sortkey (source_document_id) AS WITH kpi10 AS (
    SELECT
        victim.source_document_id as kpi10_source_document_id_victim,
        victim.document_item."victimID" :: text as kpi10_victim_id,
        victim.document_item."engagedRJ" :: text as kpi10_engaged_rj,
        victim.document_item."viewPrior" :: text as kpi10_view_prior,
        victim.document_item."victimType" :: text as kpi10_victim_type,
        victim.document_item."engagedRJEnd" :: date as kpi10_engaged_rj_end,
        victim.document_item."engagedRJStart" :: date as kpi10_engaged_rj_start,
        victim.document_item."yjscontactDate" :: date as kpi10_yjs_contact_date,
        victim.document_item."progressRequest" :: text as kpi10_progress_request,
        victim.document_item."progressProvided" :: text as kpi10_progress_provided,
        victim.document_item."consentYJSContact" :: text as kpi10_consent_yjs_contact,
        victim.document_item."progressRequestDate" :: date as kpi10_progress_request_date,
        victim.document_item."progressProvidedDate" :: date as kpi10_progress_provided_date,
        victim.document_item."victimInterventionID" :: text as kpi10_victim_intervention_id,
        victim.document_item."additionalSupportRequest" :: text as kpi10_additional_support_request,
        victim.document_item."additionalSupportProvided" :: text as kpi10_additional_support_provided
    FROM
        stg.yp_doc_item victim
    WHERE
        document_item_type = 'victim_intervention'
        AND victim.document_item."victimID" is not NULL
),
link_victim AS(
    SELECT
        link.source_document_id,
        document_item."offenceID" :: text AS offence_id,
        document_item."victimInterventionID" :: text as victim_intervention_id
    FROM
        stg.yp_doc_item AS link
    WHERE
        document_item_type = 'link_offence_victim_intervention'
),
pd AS (
    SELECT
        header.source_document_id,
        document_item."dateOfBirth" :: date AS ypid_dob,
        document_item."currentYOTID" :: text AS currentyotid,
        document_item."ypid" :: text,
        document_item."ethnicity" :: text,
        document_item."sex" :: text,
        document_item."gender" :: text,
        document_item."originatingYOTPersonID" :: text as oypid,
        header.deleted,
        header.yotoucode AS header_yotoucode,
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
        o.document_item."offenceID" :: text AS offence_id,
        olo."outcomeDate" :: date AS outcome_date,
        olo."legalOutcome" :: Varchar(100) AS legal_outcome,
        olo."legalOutcomeGroup" :: Varchar(100) AS legal_outcome_group,
        olo."cmslegalOutcome" :: Varchar(100) AS cms_legal_outcome,
        olo."residenceOnLegalOutcomeDate" :: Varchar(100) AS residence_on_legal_outcome_date,
        olo."outcomeAppealStatus" :: Varchar(500) AS outcome_appeal_status
    FROM
        stg.yp_doc_item AS o
        LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON TRUE
    WHERE
        document_item_type = 'offence'
),
intervention_prog AS (
    SELECT
        yp_doc_item.source_document_id AS source_document_id_ip,
        document_item."interventionProgrammeID" :: text AS intervention_programme_id,
        document_item."startDate" :: date AS intervention_start_date,
        document_item."endDate" :: date AS intervention_end_date,
        document_item."cmsdisposalType" :: text AS cms_disposal_type,
        document_item."disposalType" :: text AS disposal_type,
        document_item."kpi6SuccessfullyCompleted" AS kpi6_succesfully_completed
    FROM
        stg.yp_doc_item
    WHERE
        document_item_type = 'intervention_programme'
),
link AS(
    SELECT
        link.source_document_id,
        document_item."offenceID" :: text AS offence_id,
        document_item."interventionProgrammeID" :: text AS intervention_programme_id
    FROM
        stg.yp_doc_item AS link
    WHERE
        document_item_type = 'link_offence_intervention_programme'
),
combine_person_details AS(
    SELECT
        DISTINCT pd.*,
        eth.ethnicitygroup AS ethnicity_group,
        CASE
            WHEN pd.sex = '1' THEN 'Male'
            WHEN pd.sex = '2' THEN 'Female'
            WHEN pd.gender = '1' THEN 'Male'
            WHEN pd.gender = '2' THEN 'Female'
            ELSE 'Unknown gender'
        END AS gender_name,
        --new label_quarter to get year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        offence.source_document_id_offence,
        offence.offence_id,
        offence.outcome_date,
        offence.cms_legal_outcome,
        offence.residence_on_legal_outcome_date,
        offence.outcome_appeal_status,
        yjb_kpi_case_level.f_legalOutcome(
            offence.cms_legal_outcome,
            intervention_mapping.disposal_type_fixed,
            offence.legal_outcome,
            m1.legal_outcome_fixed
        ) AS legal_outcome,
        offence.legal_outcome_group,
        intervention_prog.*,
         yjb_kpi_case_level.f_ageAtInterventionStart(
            pd.ypid_dob,
            intervention_prog.intervention_start_date
        ) AS age_on_intervention_start,
        intervention_mapping.disposal_type_fixed,
        intervention_mapping.disposal_type_grouped,
        intervention_mapping.count_in_kpis AS count_in_kpi_disposal
    FROM
        offence
        LEFT JOIN link ON link.offence_id = offence.offence_id
        AND link.source_document_id = offence.source_document_id_offence
        LEFT JOIN intervention_prog ON link.intervention_programme_id = intervention_prog.intervention_programme_id
        AND link.source_document_id = intervention_prog.source_document_id_ip
        LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
        LEFT JOIN refdata.ethnicity_group AS eth ON pd.ethnicity = eth.ethnicity
        LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted AS m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(intervention_prog.intervention_end_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_kpi_case_level.intervention_programme_disposal_type AS intervention_mapping ON UPPER(TRIM(intervention_prog.disposal_type)) = TRIM(intervention_mapping.disposal_type)
    WHERE
        pd.deleted = FALSE
        AND intervention_mapping.count_in_kpis = 'YES' --count_in_kpi_disposal
        AND offence.residence_on_legal_outcome_date <> 'OTHER'
        AND offence.outcome_appeal_status NOT IN (
            'Changed on appeal',
            'Result of appeal successful'
        )
        AND age_on_intervention_start BETWEEN 10
        AND 17
        AND intervention_prog.intervention_end_date BETWEEN '2023-04-01'
        AND GETDATE()
        -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting seriousness ranking or type of order (NULLs) when they were in the CTE above.
add_extras_to_person_details AS (
    SELECT
        combine_person_details.*,
        seriousness.seriousness_ranking,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            offence_id -- by partitioning by ypid and offence_id we count all offences - rather than just one
            ORDER BY
                seriousness_ranking,
                outcome_date DESC,
                intervention_end_date DESC --where multiple seriousness_ranking, intervention end dates or outcome dates for same offence we take latest
        ) as most_serious_recent
    FROM
        combine_person_details
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine_person_details.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine_person_details.legal_outcome)) = TRIM(seriousness.legal_outcome)
    WHERE
        count_in_kpi_lo.count_in_kpi_legal_outcome = 'YES'
),
add_victims AS (
    SELECT
        DISTINCT kpi10.*,
        add_extras_to_person_details.source_document_id,
        add_extras_to_person_details.ypid,
        add_extras_to_person_details.currentyotid,
        add_extras_to_person_details.oypid,
        add_extras_to_person_details.ypid_dob,
        add_extras_to_person_details.ethnicity,
        add_extras_to_person_details.ethnicity_group,
        add_extras_to_person_details.gender_name,
        add_extras_to_person_details.yot_code,
        add_extras_to_person_details.yjs_name,
        add_extras_to_person_details.area_operations,
        add_extras_to_person_details.yjb_country,
        add_extras_to_person_details.label_quarter,
        add_extras_to_person_details.offence_id,
        add_extras_to_person_details.outcome_date,
        add_extras_to_person_details.residence_on_legal_outcome_date,
        add_extras_to_person_details.outcome_appeal_status,
        add_extras_to_person_details.intervention_programme_id,
        add_extras_to_person_details.intervention_start_date,
        add_extras_to_person_details.intervention_end_date,
        add_extras_to_person_details.age_on_intervention_start,
        add_extras_to_person_details.kpi6_succesfully_completed,
        add_extras_to_person_details.cms_legal_outcome,
        add_extras_to_person_details.legal_outcome,
        add_extras_to_person_details.legal_outcome_group,
        add_extras_to_person_details.legal_outcome_group_fixed,
        add_extras_to_person_details.seriousness_ranking,
        add_extras_to_person_details.cms_disposal_type,
        add_extras_to_person_details.disposal_type,
        add_extras_to_person_details.disposal_type_fixed,
        add_extras_to_person_details.disposal_type_grouped,
        add_extras_to_person_details.type_of_order
    FROM
        kpi10
        LEFT JOIN link_victim ON link_victim.victim_intervention_id = kpi10.kpi10_victim_intervention_id
        AND link_victim.source_document_id = kpi10.kpi10_source_document_id_victim
        LEFT JOIN add_extras_to_person_details ON link_victim.offence_id = add_extras_to_person_details.offence_id
        AND link_victim.source_document_id = add_extras_to_person_details.source_document_id
    WHERE
        most_serious_recent = 1
)
SELECT
    add_victims.*,
    -- headline measure: number of victims engaged in RJ / victims consented to contact
    -- numerator: victims engaged RJ
    CASE
        WHEN kpi10_engaged_rj = 'Yes'
        AND kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_engaged_rj,
    -- denominator: victims consented contact
    CASE
        WHEN kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_consent_contact,
    -- sub measure: victim asked view prior to outcome / victim consented to being contacted
    -- numerator: victims asked for their view prior
    CASE
        WHEN kpi10_view_prior = 'Yes'
        AND kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_view_prior,
    -- sub measure: victim provided info on case / victim requested info on case
    -- numerator: victims provided with info on case
    CASE
        WHEN kpi10_progress_provided = 'Yes'
        AND kpi10_progress_request = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_provided_info,
    -- denominator: victims requested info on case
    CASE
        WHEN kpi10_progress_request = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_request_info,
    -- sub measure: victims provided additional support / victims asked for additional support
    -- numerator
    CASE
        WHEN kpi10_additional_support_provided = 'Yes'
        AND kpi10_additional_support_request = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_given_support,
    -- denominator
    CASE
        WHEN kpi10_additional_support_request = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_asked_support
FROM
    add_victims;	
/* RQEV2-EwgoK5cUfo */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_summary distkey (yot_code) sortkey (yot_code) as WITH summary_cl AS (
    SELECT
        yjs_name,
        yot_code,
        label_quarter,
        area_operations,
        yjb_country,
        COUNT(DISTINCT ypid) AS kpi10_ypids_with_victims,
        COUNT(DISTINCT kpi10_victim_id) AS kpi10_total_victims,
        COUNT(DISTINCT kpi10_victim_engaged_rj) AS kpi10_victim_engaged_rj,
        COUNT(DISTINCT kpi10_victim_consent_contact) AS kpi10_victim_consent_contact,
        COUNT(DISTINCT kpi10_victim_view_prior) AS kpi10_victim_view_prior,
        COUNT(DISTINCT kpi10_victim_provided_info) AS kpi10_victim_provided_info,
        COUNT(DISTINCT kpi10_victim_request_info) AS kpi10_victim_request_info,
        COUNT(DISTINCT kpi10_victim_given_support) AS kpi10_victim_given_support,
        COUNT(DISTINCT kpi10_victim_asked_support) AS kpi10_victim_asked_support
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi10_victim_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country
)
SELECT
    COALESCE(summary_t.yjs_name, summary_cl.yjs_name) AS yjs_name,
    COALESCE(
        TRIM(summary_t.yot_code),
        TRIM(summary_cl.yot_code)
    ) AS yot_code,
    COALESCE(
        summary_t.label_quarter,
        summary_cl.label_quarter
    ) AS label_quarter,
    COALESCE(
        summary_t.area_operations,
        summary_cl.area_operations
    ) AS area_operations,
    COALESCE(summary_t.yjb_country, summary_cl.yjb_country) AS yjb_country,
    CASE
        WHEN (
            summary_t.kpi10_ypids_with_victims > 0
            OR summary_t.kpi10_victim_engaged_rj > 0
            OR summary_t.kpi10_victim_consent_contact > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --headline measure: victims engaged rj / victim consent to contact
    -- numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_engaged_rj
            ELSE summary_cl.kpi10_victim_engaged_rj
        END,
        0
    ) AS kpi10_victim_engaged_rj,
    -- denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_consent_contact
            ELSE summary_cl.kpi10_victim_consent_contact
        END,
        0
    ) AS kpi10_victim_consent_contact,
    -- sub measure: number of victims
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_total_victims
            ELSE summary_cl.kpi10_total_victims
        END,
        0
    ) AS kpi10_total_victims,
    -- sub measure: total ypids with victims
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_ypids_with_victims
            ELSE summary_cl.kpi10_ypids_with_victims
        END,
        0
    ) AS kpi10_ypids_with_victims,
    -- sub measure: victim asked view on case prior / victims consented to contact
    -- numerator 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_view_prior
            ELSE summary_cl.kpi10_victim_view_prior
        END,
        0
    ) AS kpi10_victim_view_prior,
    -- sub measure: victim provided case progress / victim requested case progress
    -- numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_provided_info
            ELSE summary_cl.kpi10_victim_provided_info
        END,
        0
    ) AS kpi10_victim_provided_info,
    --denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_request_info
            ELSE summary_cl.kpi10_victim_request_info
        END,
        0
    ) AS kpi10_victim_request_info,
    -- sub measure: victim given additional support / victim asked for additional support
    --numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_given_support
            ELSE summary_cl.kpi10_victim_given_support
        END,
        0
    ) AS kpi10_victim_given_support,
    --denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_asked_support
            ELSE summary_cl.kpi10_victim_asked_support
        END,
        0
    ) AS kpi10_victim_asked_support
FROM
    summary_cl FULL
    OUTER JOIN yjb_kpi_case_level.kpi10_victim_template AS summary_t ON summary_t.yot_code = summary_cl.yot_code
    AND summary_t.label_quarter = summary_cl.label_quarter;	
/* RQEV2-UEzI0ta0aK */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_summary_long distkey (yot_code) sortkey (yot_code) AS
SELECT
    unpvt_table.yjs_name,
    unpvt_table.yot_code,
    unpvt_table.area_operations,
    unpvt_table.yjb_country,
    families."reverse_family members" AS yjs_reverse_family,
    unpvt_table.source_data_flag,
    unpvt_table.quarter_label,
    unpvt_table.quarter_label_date,
    unpvt_table.kpi_number,
    'Victims' AS kpi_name,
    'Victims of youth crime' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable - will be blank for kpi6 but need to column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%unsuitable%' THEN 'Unsuitable'
        WHEN unpvt_table.measure_numerator LIKE '%suitable%' THEN 'Suitable'
        ELSE NULL
    END AS suitability,
    -- whether the measure_numerator is calculating successfully or not completed OOCDs
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%not_completed%' THEN 'Not completed'
        WHEN unpvt_table.measure_numerator LIKE '%successful%' THEN 'Successfully completed'
        ELSE NULL
    END AS completion,
    -- level of seniority -- only relevant for kpi 8 but need column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%senior%' THEN 'Senior'
        WHEN unpvt_table.measure_numerator LIKE '%junior%' THEN 'Delegated'
        ELSE NULL
    END AS seniority,
       -- part-time / full-time - only relevant for KPI 2 but need the column to union all long formats later
     CASE
        WHEN unpvt_table.measure_numerator LIKE '%part%' THEN 'Part-time'
        WHEN unpvt_table.measure_numerator LIKE '%full%' THEN 'Full-time'
        ELSE NULL
    END AS ETE_part_time_full_time,
    -- give a category for every measure measurement a category
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%total_victims%' THEN 'Victims'
        WHEN unpvt_table.measure_numerator LIKE '%contacted%' THEN 'Contacted'
        WHEN unpvt_table.measure_numerator LIKE '%given_support%' THEN 'Given information on additional support'
        WHEN unpvt_table.measure_numerator LIKE '%provided_info%' THEN 'Provided information on case'
        WHEN unpvt_table.measure_numerator LIKE '%view_prior%' THEN 'Gave view prior to legal outcome'
        WHEN unpvt_table.measure_numerator LIKE '%engaged_rj%' THEN 'Engaged with RJ'
        WHEN unpvt_table.measure_numerator LIKE '%ypids_with_victims%' THEN 'Children'
        WHEN unpvt_table.measure_numerator LIKE '%rj_process%' THEN 'RJ processes'
    END AS measure_category,
    --short description of measure
    CASE
        WHEN measure_category = 'Engaged with RJ' THEN 'Number of victims engaged with RJ'
        WHEN measure_category = 'Victims' THEN 'Number of victims'
        WHEN measure_category = 'Children' THEN 'Number of children with victims'
        WHEN measure_category = 'RJ processes' THEN 'Number of RJ processes'
        WHEN measure_category = 'Gave view prior to legal outcome' THEN 'Number of victims who gave their view prior to legal outcome'
        WHEN measure_category = 'Provided information on case' THEN 'Number of victims provided information on a child`s case'
        WHEN measure_category = 'Given information on additional support' THEN 'Number of victims given information on additional support'
        ELSE 'Number of victims contacted'
    END AS measure_short_description,
    -- full wording of measure
    CASE
        WHEN measure_category = 'Engaged with RJ' THEN 'Proportion of victims who consented to being contacted that engaged with Restorative Justice (RJ)'
        WHEN measure_category = 'Victims' THEN 'Total number of victims'
        WHEN measure_category = 'Children' THEN 'Total number of children with victims'
        WHEN measure_category = 'RJ processes' THEN 'Individual RJ processes that were engaged with'
        WHEN measure_category = 'Gave view prior to legal outcome' THEN 'Victims who were asked for their views prior to OOCD decision-making and planning for statutory court orders'
        WHEN measure_category = 'Provided information on case' THEN 'Victims provided with information about the progress of the child`s case'
        WHEN measure_category = 'Given information on additional support' THEN 'Victims informed about additional support services'
        ELSE 'Victims who were contacted by the YJS'
    END AS measure_long_description,
    --whether measure is the headline measure
    CASE
        WHEN measure_category = 'Engaged with RJ' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    --numbering the submeasures
    CASE
        WHEN measure_category = 'Victims' THEN '10a'
        WHEN measure_category = 'Children' THEN '10b'
        WHEN measure_category = 'RJ processes' THEN '10c'
        WHEN measure_category = 'Gave view prior to legal outcome' THEN '10d'
        WHEN measure_category = 'Provided information on case' THEN '10e'
        WHEN measure_category = 'Given information on additional support' THEN '10f'
        WHEN measure_category = 'Contacted' THEN '10g'
        ELSE 'Headline'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        WHEN measure_category IN (
            'Engaged with RJ',
            'Gave view prior to legal outcome',
            'Provided information on case',
            'Given information on additional support',
            'Contacted',
            'RJ processes'
        ) THEN 'kpi10_victim_consent_contact'
        ELSE 'kpi10_total_ypid'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        WHEN measure_category IN (
            'Engaged with RJ',
            'Gave view prior to legal outcome',
            'Provided information on case',
            'Given information on additional support',
            'Contacted',
            'RJ processes'
        ) THEN kpi10_victim_consent_contact
        ELSE kpi10_total_ypid
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Victims who engaged with RJ'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Victims who consented to YJS contact'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi10_victim_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi10_victim_contacted,
            kpi10_victim_given_support,
            kpi10_victim_provided_info,
            kpi10_victim_view_prior,
            kpi10_ypids_with_victims,
            kpi10_total_victims,
            kpi10_rj_process,
            kpi10_victim_engaged_rj
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
/* RQEV2-NmhALFsv7s */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_case_level distkey (kpi1_source_document_id_acc) sortkey (kpi1_source_document_id_acc) AS WITH kpi1 AS (
    SELECT
        dc.source_document_id as kpi1_source_document_id_acc,
        dc.document_item."description" :: text as kpi1_description,
        dc.document_item."date" :: date as kpi1_accommodation_start_date,
        dc.document_item."kpi1EndDate" :: date as kpi1_accommodation_end_date,
        dc.document_item."kpi1PrimaryResidence" :: boolean as kpi1_accommodation_primary_residence,
        dc.document_item."kpi1AccommodationType" :: text as kpi1_accommodation_type,
        dc.document_item."kpi1AccommodationSuitability" :: text as kpi1_accommodation_suitability
    FROM
        stg.yp_doc_item AS dc
    WHERE
        document_item_type = 'residence'
        AND document_item."kpi1AccommodationSuitability" is not NULL -- NOTE: For later sub-mesures- Identify 'cust_release_yes' date variable at case level 'DisposalTypeType'/ We might leave Custodial remands for sub-measures only
),
--CTE combines kpi1 data from CTE above with person_details - LW turned to CTE
kpi1_pd AS (
    SELECT
        DISTINCT kpi1.*,
        person_details.*,
        -- marker stating whether accommodation is at start or not
        yjb_kpi_case_level.f_isAtStart(
            kpi1.kpi1_accommodation_start_date,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date
        ) AS accom_start,
        --marker to say the accommodation is at end
        --for custody cases its end of licence period (intervention_end_date) or date of transfer to adult system (intervention_end_date), for all other orders its intervention_end_date
        yjb_kpi_case_level.f_isAtEnd(
            kpi1.kpi1_accommodation_end_date,
            person_details.intervention_end_date
        ) AS accom_end
    FROM
        kpi1
        INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi1.kpi1_source_document_id_acc = person_details.source_document_id
    WHERE
        kpi1.kpi1_accommodation_primary_residence = 'true' -- -- Filter out accommodations unless they were present at order start, order end or both 
        -- accommodation start date filters - same for all types of orders 
        AND kpi1.kpi1_accommodation_start_date <= person_details.intervention_end_date -- accommodation end date filters
        AND (
            -- 1900-01-01 indicates no end date, i.e. child still lives there
            kpi1.kpi1_accommodation_end_date = '1900-01-01' -- all other sentences accommodation end date should be >= intervention start date
            OR (
                person_details.type_of_order <> 'Custodial sentences'
                AND kpi1.kpi1_accommodation_end_date >= person_details.intervention_start_date
            ) -- DTO_LICENCE disposal types
            OR (
                person_details.disposal_type_fixed = 'DTO_LICENCE'
                AND kpi1.kpi1_accommodation_end_date >= (person_details.outcome_date - INTERVAL '1 day') :: date -- = one day before DTO custody starts (outcome_date = DTO_CUSTODY intervention_start_date)
            ) -- Other custodial sentences (NOT DTO_LICENCE)
            OR (
                person_details.disposal_type_fixed <> 'DTO_LICENCE'
                AND person_details.type_of_order = 'Custodial sentences'
                AND kpi1.kpi1_accommodation_end_date >= (
                    person_details.intervention_start_date - INTERVAL '1 day'
                ) :: date -- = one day before custody begins (intervention_start_date)
            )
        )
        AND (
            accom_start = TRUE
            OR accom_end = TRUE
        )
),
--CTE calculates the true suitability of ETE per child at start and end of their order
--If more than one ETE coexists all have to be suitable to be suitable
true_suitability AS (
    SELECT
        ypid,
        label_quarter,
        CASE
            WHEN SUM(
                CASE
                    WHEN accom_start = TRUE
                    AND kpi1_accommodation_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
                    ELSE 0
                END
            ) > 0 THEN FALSE
            ELSE TRUE
        END AS is_suitable_start,
        CASE
            WHEN SUM(
                CASE
                    WHEN accom_end = TRUE
                    AND kpi1_accommodation_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
                    ELSE 0
                END
            ) > 0 THEN FALSE
            ELSE TRUE
        END AS is_suitable_end
    FROM
        kpi1_pd
    GROUP BY
        ypid,
        label_quarter
) -- combines CTEs kpi1_pd, has_any_unsuitable_end and has_any_unsuitable_start and filters to only include accommodations that existed at start and/or end
SELECT
    kpi1_pd.*,
    CASE
    WHEN kpi1_pd.accom_start = FALSE THEN NULL
    ELSE true_suitability.is_suitable_start
  END AS is_suitable_start,
  CASE
    WHEN kpi1_pd.accom_end = FALSE THEN NULL
    ELSE true_suitability.is_suitable_end
  END AS is_suitable_end,
-- headline measure numerator: suitable at end of order
CASE
    WHEN is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_end,
-- suitable at start of order
CASE
    WHEN is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_start,
-- unsuitable at start of order
CASE
    WHEN is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_start,
--unsuitable at end of order
CASE
    WHEN is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_end,
--suitable by type of order end
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ro,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_cust,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_oocd,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yc_with_yjs,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yro,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ycc,
--unsuitable by type of order end
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ro,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_cust,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_oocd,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yc_with_yjs,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yro,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ycc,
--suitable by type of accommodation
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_stc,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_sch,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yoi,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_parents,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_other_accom,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_independent_living,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    )
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_residential_unit,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_family_not_parents,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_temporary_accom,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_supported_accom_lodgings,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_foster_care,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_friends,
--total in each accommodation type
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_stc,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_sch,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_yoi,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME') THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_parents,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE') THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_other_accom,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_independent_living,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    ) THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_residential_unit,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_family_not_parents,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL') THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_temporary_accom,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_supported_accom_lodgings,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE') THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_foster_care,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS' THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_friends
FROM
    kpi1_pd
    LEFT JOIN true_suitability ON kpi1_pd.ypid = true_suitability.ypid
    AND kpi1_pd.label_quarter = true_suitability.label_quarter;	
/* RQEV2-1o1C8rbN6L */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_case_level_v8 distkey (kpi1_source_document_id_acc) sortkey (kpi1_source_document_id_acc) AS WITH kpi1 AS (
    SELECT
        dc.source_document_id as kpi1_source_document_id_acc,
        dc.document_item."description" :: text as kpi1_description,
        dc.document_item."date" :: date as kpi1_accommodation_start_date,
        dc.document_item."kpi1EndDate" :: date as kpi1_accommodation_end_date,
        dc.document_item."kpi1AccommodationType" :: text as kpi1_accommodation_type,
        dc.document_item."kpi1AccommodationSuitability" :: text as kpi1_accommodation_suitability
    FROM
        stg.yp_doc_item AS dc
    WHERE
        document_item_type = 'residence'
        AND document_item."kpi1AccommodationSuitability" is not NULL -- NOTE: For later sub-mesures- Identify 'cust_release_yes' date variable at case level 'DisposalTypeType'/ We might leave Custodial remands for sub-measures only
),
--CTE combines kpi1 data from CTE above with person_details - LW turned to CTE
kpi1_pd AS (
    SELECT
        DISTINCT kpi1.*,
        person_details.*,
        -- marker stating whether accommodation is at start or not
        yjb_kpi_case_level.f_isAtStart(
            kpi1.kpi1_accommodation_start_date,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date
        ) AS accom_start,
        --marker to say the accommodation is at end
        --for custody cases its end of licence period (intervention_end_date) or date of transfer to adult system (intervention_end_date), for all other orders its intervention_end_date
        yjb_kpi_case_level.f_isAtEnd(
            kpi1.kpi1_accommodation_end_date,
            person_details.intervention_end_date
        ) AS accom_end
    FROM
        kpi1
        INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi1.kpi1_source_document_id_acc = person_details.source_document_id
    WHERE
    /* Filter out accommodations unless they were present at order start, order end or both */
        -- accommodation start date filters - same for all types of orders 
        kpi1.kpi1_accommodation_start_date <= person_details.intervention_end_date 
        /*accommodation end date filters*/
        AND (
            -- 1900-01-01 indicates no end date, i.e. child still lives there
            kpi1.kpi1_accommodation_end_date = '1900-01-01' 
            /* all other sentences accommodation end date should be >= intervention start date */
            OR (
                person_details.type_of_order <> 'Custodial sentences'
                AND kpi1.kpi1_accommodation_end_date >= person_details.intervention_start_date
            ) 
            /* DTO_LICENCE disposal types*/
            OR (
                person_details.disposal_type_fixed = 'DTO_LICENCE'
                AND kpi1.kpi1_accommodation_end_date >= (person_details.outcome_date - INTERVAL '1 day') :: date -- = one day before DTO custody starts (outcome_date = DTO_CUSTODY intervention_start_date)
            ) 
            /* Other custodial sentences (NOT DTO_LICENCE) */
            OR (
                person_details.disposal_type_fixed <> 'DTO_LICENCE'
                AND person_details.type_of_order = 'Custodial sentences'
                AND kpi1.kpi1_accommodation_end_date >= (
                    person_details.intervention_start_date - INTERVAL '1 day'
                ) :: date -- = one day before custody begins (intervention_start_date)
            )
        )
        AND (
            accom_start = TRUE
            OR accom_end = TRUE
        )
),
--CTE calculates the true suitability of ETE per child at start and end of their order
--If more than one ETE coexists all have to be suitable to be suitable
true_suitability AS (
    SELECT
        ypid,
        label_quarter,
        CASE
            WHEN SUM(
                CASE
                    WHEN accom_start = TRUE
                    AND kpi1_accommodation_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
                    ELSE 0
                END
            ) > 0 THEN FALSE
            ELSE TRUE
        END AS is_suitable_start,
        CASE
            WHEN SUM(
                CASE
                    WHEN accom_end = TRUE
                    AND kpi1_accommodation_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
                    ELSE 0
                END
            ) > 0 THEN FALSE
            ELSE TRUE
        END AS is_suitable_end
    FROM
        kpi1_pd
    GROUP BY
        ypid,
        label_quarter
) -- combines CTEs kpi1_pd, has_any_unsuitable_end and has_any_unsuitable_start and filters to only include accommodations that existed at start and/or end
SELECT
    kpi1_pd.*,
    CASE
    WHEN kpi1_pd.accom_start = FALSE THEN NULL
    ELSE true_suitability.is_suitable_start
  END AS is_suitable_start,
  CASE
    WHEN kpi1_pd.accom_end = FALSE THEN NULL
    ELSE true_suitability.is_suitable_end
  END AS is_suitable_end,
-- headline measure numerator: suitable at end of order
CASE
    WHEN is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_end,
-- suitable at start of order
CASE
    WHEN is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_start,
-- unsuitable at start of order
CASE
    WHEN is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_start,
--unsuitable at end of order
CASE
    WHEN is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_end,
--suitable by type of order start
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ro_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_cust_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_oocd_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yc_with_yjs_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yro_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ycc_start,
--unsuitable by type of order start
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ro_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_cust_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_oocd_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yc_with_yjs_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yro_start,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ycc_start,
--suitable by type of order end
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ro_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_cust_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_oocd_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yc_with_yjs_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yro_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_ycc_end,
--unsuitable by type of order end
CASE
    WHEN kpi1_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ro_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_cust_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_oocd_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yc_with_yjs_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yro_end,
CASE
    WHEN kpi1_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_ycc_end,
--suitable by type of accommodation start
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_stc_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_sch_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yoi_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME')
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE')
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_other_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_independent_living_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    )
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_residential_unit_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_family_not_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL')
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_temporary_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_supported_accom_lodgings_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE')
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_foster_care_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS'
    AND is_suitable_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_friends_start,
--unsuitable by type of accommodation start
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_stc_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_sch_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yoi_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME')
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE')
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_other_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_independent_living_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    )
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_residential_unit_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_family_not_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL')
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_temporary_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_supported_accom_lodgings_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE')
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_foster_care_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS'
    AND is_suitable_start = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_friends_start,
--suitable by type of accommodation end
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_stc_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_sch_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_yoi_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_other_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_independent_living_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    )
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_residential_unit_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_family_not_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_temporary_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_supported_accom_lodgings_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE')
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_foster_care_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS'
    AND is_suitable_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_suitable_living_with_friends_end,
--unsuitable by type of accommodation end
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_stc_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_sch_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_yoi_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME')
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE')
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_other_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_independent_living_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    )
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_residential_unit_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_family_not_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL')
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_temporary_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_supported_accom_lodgings_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE')
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_foster_care_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS'
    AND is_suitable_end = FALSE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_unsuitable_living_with_friends_end,

--total in each accommodation type start
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_stc_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_sch_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_yoi_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME') AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE') AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_other_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_independent_living_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    ) AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_residential_unit_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_family_not_parents_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL') AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_temporary_accom_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_supported_accom_lodgings_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE') AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_foster_care_start,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS' AND accom_start = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_friends_start,
--total in each accommodation type end
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'STC' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_stc_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SCH' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_sch_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'YOI' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_yoi_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('LIVING_WITH_PARENT_S', 'AT_HOME') AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('OTHER', 'HOSPITAL', 'TRAVELLER_SITE') AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_other_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'INDEPENDENT_LIVING' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_independent_living_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN (
        'RESIDENTIAL_UNIT_SECURE',
        'RESIDENTIAL_UNIT_PRIVATE',
        'RESIDENTIAL_UNIT_LA'
    ) AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_residential_unit_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FAMILY_NOT_PARENTS' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_family_not_parents_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('TEMPORARY_ACCOMMODATION', 'BAIL_HOSTEL') AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_temporary_accom_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'SUPPORTED_ACCOMMODATION_SUPPORTED_LODGINGS' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_supported_accom_lodgings_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type IN ('FOSTER_CARE_LA', 'FOSTER_CARE_PRIVATE') AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_foster_care_end,
CASE
    WHEN kpi1_pd.kpi1_accommodation_type = 'LIVING_WITH_FRIENDS' AND accom_end = TRUE THEN kpi1_pd.ypid
    ELSE NULL
END AS kpi1_total_living_with_friends_end
FROM
    kpi1_pd
    LEFT JOIN true_suitability ON kpi1_pd.ypid = true_suitability.ypid
    AND kpi1_pd.label_quarter = true_suitability.label_quarter;	

/* RQEV2-TdL9eq7Qs4 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_template distkey (yot_code) sortkey (yot_code) AS WITH template AS (
    SELECT
        kpi1.return_status_id,
        kpi1.reporting_date,
        kpi1.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label quarter which has year first quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi1.description,
        kpi1.ns_total AS out_court_no_yjs_total,
        kpi1.ns_start_yes AS out_court_no_yjs_start_yes,
        kpi1.ns_start_no AS out_court_no_yjs_start_no,
        kpi1.ns_end_yes AS out_court_no_yjs_end_yes,
        kpi1.ns_end_no AS out_court_no_yjs_end_no,
        kpi1.yjs_total AS yc_with_yjs_total,
        kpi1.yjs_start_yes AS yc_with_yjs_start_yes,
        kpi1.yjs_start_no AS yc_with_yjs_start_no,
        kpi1.yjs_end_yes AS yc_with_yjs_end_yes,
        kpi1.yjs_end_no AS yc_with_yjs_end_no,
        kpi1.ycc_total,
        kpi1.ycc_start_yes,
        kpi1.ycc_start_no,
        kpi1.ycc_end_yes,
        kpi1.ycc_end_no,
        kpi1.ro_total,
        kpi1.ro_start_yes,
        kpi1.ro_start_no,
        kpi1.ro_end_yes,
        kpi1.ro_end_no,
        kpi1.yro_total,
        kpi1.yro_start_yes,
        kpi1.yro_start_no,
        kpi1.yro_end_yes,
        kpi1.yro_end_no,
        kpi1.cust_total,
        kpi1.cust_start_yes,
        kpi1.cust_start_no,
        kpi1.cust_release_yes,
        kpi1.cust_release_no,
        kpi1.cust_end_yes,
        kpi1.cust_end_no,
        kpi1.noncust_total,
        kpi1.noncust_start_yes,
        kpi1.noncust_start_no,
        kpi1.noncust_release_yes,
        kpi1.noncust_release_no,
        out_court_no_yjs_total + yc_with_yjs_total + ycc_total + ro_total + yro_total + cust_total AS total_ypid,
        out_court_no_yjs_end_yes + yc_with_yjs_end_yes + ycc_end_yes + ro_end_yes + yro_end_yes + cust_end_yes as total_suitable_end,
        out_court_no_yjs_end_no + yc_with_yjs_end_no + ycc_end_no + ro_end_no + yro_end_no + cust_end_no AS total_unsuitable_end,
        out_court_no_yjs_start_yes + yc_with_yjs_start_yes + ycc_start_yes + ro_start_yes + yro_start_yes + cust_start_yes AS total_suitable_start,
        out_court_no_yjs_start_no + yc_with_yjs_start_no + ycc_start_no + ro_start_no + yro_start_no + cust_start_no AS total_unsuitable_start
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi1_accommodation_detail_v1" AS kpi1
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi1.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi1.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yjs_name,
    yot_code,
    label_quarter,
    area_operations,
    yjb_country,
    --overall measures
    SUM(total_ypid) AS total_ypid,
    SUM(total_suitable_end) AS kpi1_suitable_end,
    SUM(total_unsuitable_end) AS kpi1_unsuitable_end,
    SUM(total_suitable_start) AS kpi1_suitable_start,
    SUM(total_unsuitable_start) AS kpi1_unsuitable_start,
    --by type of order
    SUM(out_court_no_yjs_end_yes) AS kpi1_suitable_oocd,
    SUM(yc_with_yjs_end_yes) AS kpi1_suitable_yc_with_yjs,
    SUM(ycc_end_yes) AS kpi1_suitable_ycc,
    SUM(ro_end_yes) AS kpi1_suitable_ro,
    SUM(yro_end_yes) AS kpi1_suitable_yro,
    SUM(cust_end_yes) AS kpi1_suitable_cust,
    SUM(out_court_no_yjs_end_no) AS kpi1_unsuitable_oocd,
    SUM(yc_with_yjs_end_no) AS kpi1_unsuitable_yc_with_yjs,
    SUM(ycc_end_no) AS kpi1_unsuitable_ycc,
    SUM(ro_end_no) AS kpi1_unsuitable_ro,
    SUM(yro_end_no) AS kpi1_unsuitable_yro,
    SUM(cust_end_no) AS kpi1_unsuitable_cust,
    SUM(out_court_no_yjs_total) AS kpi1_total_oocd,
    SUM(yc_with_yjs_total) AS kpi1_total_yc_with_yjs,
    SUM(ycc_total) AS kpi1_total_ycc,
    SUM(ro_total) AS kpi1_total_ro,
    SUM(yro_total) AS kpi1_total_yro,
    SUM(cust_total) AS kpi1_total_cust,
    --by type of accommodation - didn't count 'bed and breakfast', 'no fixed abode' and 'unknown' as these are always unsuitable (according to recording guidance)
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_stc,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_sch,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_yoi,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_parents,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_other_accom,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_independent_living,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_residential_unit,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_family_not_parents,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_temporary_accom,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_supported_accom_lodgings,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_foster_care,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_friends,
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_stc,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_sch,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_yoi,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_parents,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_other_accom,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_independent_living,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_residential_unit,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_family_not_parents,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_temporary_accom,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_supported_accom_lodgings,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_foster_care,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_friends
FROM
    template
GROUP BY
    return_status_id,
    reporting_date,
    yjs_name,
    yot_code,
    label_quarter,
    area_operations,
    yjb_country;	

/* RQEV2-f6pn5LRjzj */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi1_acc_summary;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        --total orders ending in the period (headline denominator)
        COUNT(DISTINCT ypid) as total_ypid,
        -- total types of orders
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Non-substantive out of court disposals with YJS intervention' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_oocd,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Cautions with YJS intervention' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_yc,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Conditional Cautions' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ycc,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Referral Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ro,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Rehabilitation Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_yro,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Custodial sentences' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_cust
    FROM
        "yjb_returns"."yjb_kpi_case_level"."person_details"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country
),
summary_cl AS (
    SELECT
        yjs_name,
        yot_code,
        label_quarter,
        -- suitable at start of order
        COUNT(DISTINCT kpi1_suitable_start) AS kpi1_suitable_start,
        -- suitable at end of order
        --used in headline numerator
        COUNT(DISTINCT kpi1_suitable_end) AS kpi1_suitable_end,
        -- unsuitable at start of order
        COUNT(DISTINCT kpi1_unsuitable_start) AS kpi1_unsuitable_start,
        --unsuitable at end of order
        COUNT(DISTINCT kpi1_unsuitable_end) AS kpi1_unsuitable_end,
        --suitable at end by type of order
        COUNT(DISTINCT kpi1_suitable_ro) AS kpi1_suitable_ro,
        COUNT(DISTINCT kpi1_suitable_cust) AS kpi1_suitable_cust,
        COUNT(DISTINCT kpi1_suitable_oocd) AS kpi1_suitable_oocd,
        COUNT(DISTINCT kpi1_suitable_yc_with_yjs) AS kpi1_suitable_yc_with_yjs,
        COUNT(DISTINCT kpi1_suitable_yro) AS kpi1_suitable_yro,
        COUNT(DISTINCT kpi1_suitable_ycc) AS kpi1_suitable_ycc,
        --unsuitable at end by type of order
        COUNT(DISTINCT kpi1_unsuitable_ro) AS kpi1_unsuitable_ro,
        COUNT(DISTINCT kpi1_unsuitable_cust) AS kpi1_unsuitable_cust,
        COUNT(DISTINCT kpi1_unsuitable_oocd) AS kpi1_unsuitable_oocd,
        COUNT(DISTINCT kpi1_unsuitable_yc_with_yjs) AS kpi1_unsuitable_yc_with_yjs,
        COUNT(DISTINCT kpi1_unsuitable_yro) AS kpi1_unsuitable_yro,
        COUNT(DISTINCT kpi1_unsuitable_ycc) AS kpi1_unsuitable_ycc,
        --suitable at end of order by type of accommodation
        COUNT(DISTINCT kpi1_suitable_living_with_parents) AS kpi1_suitable_living_with_parents,
        COUNT(DISTINCT kpi1_suitable_other_accom) AS kpi1_suitable_other_accom,
        COUNT(DISTINCT kpi1_suitable_independent_living) AS kpi1_suitable_independent_living,
        COUNT(DISTINCT kpi1_suitable_residential_unit) AS kpi1_suitable_residential_unit,
        COUNT(
            DISTINCT kpi1_suitable_living_with_family_not_parents
        ) AS kpi1_suitable_living_with_family_not_parents,
        COUNT(DISTINCT kpi1_suitable_temporary_accom) AS kpi1_suitable_temporary_accom,
        COUNT(DISTINCT kpi1_suitable_supported_accom_lodgings) AS kpi1_suitable_supported_accom_lodgings,
        COUNT(DISTINCT kpi1_suitable_foster_care) AS kpi1_suitable_foster_care,
        COUNT(DISTINCT kpi1_suitable_living_with_friends) AS kpi1_suitable_living_with_friends,
        COUNT(DISTINCT kpi1_suitable_stc) AS kpi1_suitable_stc,
        COUNT(DISTINCT kpi1_suitable_sch) AS kpi1_suitable_sch,
        COUNT(DISTINCT kpi1_suitable_yoi) AS kpi1_suitable_yoi,
        COUNT(DISTINCT kpi1_total_living_with_parents) AS kpi1_total_living_with_parents,
        COUNT(DISTINCT kpi1_total_other_accom) AS kpi1_total_other_accom,
        COUNT(DISTINCT kpi1_total_independent_living) AS kpi1_total_independent_living,
        COUNT(DISTINCT kpi1_total_residential_unit) AS kpi1_total_residential_unit,
        COUNT(
            DISTINCT kpi1_total_living_with_family_not_parents
        ) AS kpi1_total_living_with_family_not_parents,
        COUNT(DISTINCT kpi1_total_temporary_accom) AS kpi1_total_temporary_accom,
        COUNT(DISTINCT kpi1_total_supported_accom_lodgings) AS kpi1_total_supported_accom_lodgings,
        COUNT(DISTINCT kpi1_total_foster_care) AS kpi1_total_foster_care,
        COUNT(DISTINCT kpi1_total_living_with_friends) AS kpi1_total_living_with_friends,
        COUNT(DISTINCT kpi1_total_stc) AS kpi1_total_stc,
        COUNT(DISTINCT kpi1_total_sch) AS kpi1_total_sch,
        COUNT(DISTINCT kpi1_total_yoi) AS kpi1_total_yoi
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi1_acc_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter
) --LW removed summary_t CTE (template) because all template calcs done in template script now
SELECT
    COALESCE(summary_t.yjs_name, summary_person.yjs_name) AS yjs_name,
    COALESCE(
        TRIM(summary_t.yot_code),
        TRIM(summary_person.yot_code)
    ) AS yot_code,
    COALESCE(
        summary_t.label_quarter,
        summary_person.label_quarter
    ) AS label_quarter,
    COALESCE(
        summary_t.area_operations,
        summary_person.area_operations
    ) AS area_operations,
    COALESCE(
        summary_t.yjb_country,
        summary_person.yjb_country
    ) AS yjb_country,
    -- flag to say whether YJS submitted by template as well or only case level
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi1_suitable_end > 0
        ) THEN 'Data from template'
        ELSE 'Data from case level'
    END AS source_data_flag,
    --total orders ending in the period (headline denominator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
        ELSE summary_person.total_ypid
    END AS kpi1_total_ypid,
    -- overall measures
    -- suitable end (headline numerator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_end
        ELSE summary_cl.kpi1_suitable_end
    END AS kpi1_suitable_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_end
        ELSE summary_cl.kpi1_unsuitable_end
    END AS kpi1_unsuitable_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_start
        ELSE summary_cl.kpi1_suitable_start
    END AS kpi1_suitable_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_start
        ELSE summary_cl.kpi1_unsuitable_start
    END AS kpi1_unsuitable_start,
    -- by type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_oocd
        ELSE summary_cl.kpi1_suitable_oocd
    END AS kpi1_suitable_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_oocd
        ELSE summary_cl.kpi1_unsuitable_oocd
    END AS kpi1_unsuitable_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_oocd
        ELSE summary_person.total_ypid_oocd
    END AS kpi1_total_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yc_with_yjs
        ELSE summary_cl.kpi1_suitable_yc_with_yjs
    END AS kpi1_suitable_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yc_with_yjs
        ELSE summary_cl.kpi1_unsuitable_yc_with_yjs
    END AS kpi1_unsuitable_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yc_with_yjs
        ELSE summary_person.total_ypid_yc
    END AS kpi1_total_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ycc
        ELSE summary_cl.kpi1_suitable_ycc
    END AS kpi1_suitable_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ycc
        ELSE summary_cl.kpi1_unsuitable_ycc
    END AS kpi1_unsuitable_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_ycc
        ELSE summary_person.total_ypid_ycc
    END AS kpi1_total_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ro
        ELSE summary_cl.kpi1_suitable_ro
    END AS kpi1_suitable_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ro
        ELSE summary_cl.kpi1_unsuitable_ro
    END AS kpi1_unsuitable_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_ro
        ELSE summary_person.total_ypid_ro
    END AS kpi1_total_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yro
        ELSE summary_cl.kpi1_suitable_yro
    END AS kpi1_suitable_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yro
        ELSE summary_cl.kpi1_unsuitable_yro
    END AS kpi1_unsuitable_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yro
        ELSE summary_person.total_ypid_yro
    END AS kpi1_total_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_cust
        ELSE summary_cl.kpi1_suitable_cust
    END AS kpi1_suitable_cust,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_cust
        ELSE summary_cl.kpi1_unsuitable_cust
    END AS kpi1_unsuitable_cust,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_cust
        ELSE summary_person.total_ypid_cust
    END AS kpi1_total_cust,
    --by accommodation type
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_parents
        ELSE summary_cl.kpi1_suitable_living_with_parents
    END AS kpi1_suitable_living_with_parents,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_parents
        ELSE summary_cl.kpi1_total_living_with_parents
    END AS kpi1_total_living_with_parents,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_other_accom
        ELSE summary_cl.kpi1_suitable_other_accom
    END AS kpi1_suitable_other_accom,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_other_accom
        ELSE summary_cl.kpi1_total_other_accom
    END AS kpi1_total_other_accom,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_independent_living
        ELSE summary_cl.kpi1_suitable_independent_living
    END AS kpi1_suitable_independent_living,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_independent_living
        ELSE summary_cl.kpi1_total_independent_living
    END AS kpi1_total_independent_living,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_residential_unit
        ELSE summary_cl.kpi1_suitable_residential_unit
    END AS kpi1_suitable_residential_unit,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_residential_unit
        ELSE summary_cl.kpi1_total_residential_unit
    END AS kpi1_total_residential_unit,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_family_not_parents
        ELSE summary_cl.kpi1_suitable_living_with_family_not_parents
    END AS kpi1_suitable_living_with_family_not_parents,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_family_not_parents
        ELSE summary_cl.kpi1_total_living_with_family_not_parents
    END AS kpi1_total_living_with_family_not_parents,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_temporary_accom
        ELSE summary_cl.kpi1_suitable_temporary_accom
    END AS kpi1_suitable_temporary_accom,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_temporary_accom
        ELSE summary_cl.kpi1_total_temporary_accom
    END AS kpi1_total_temporary_accom,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_supported_accom_lodgings
        ELSE summary_cl.kpi1_suitable_supported_accom_lodgings
    END AS kpi1_suitable_supported_accom_lodgings,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_supported_accom_lodgings
        ELSE summary_cl.kpi1_total_supported_accom_lodgings
    END AS kpi1_total_supported_accom_lodgings,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_foster_care
        ELSE summary_cl.kpi1_suitable_foster_care
    END AS kpi1_suitable_foster_care,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_foster_care
        ELSE summary_cl.kpi1_total_foster_care
    END AS kpi1_total_foster_care,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_friends
        ELSE summary_cl.kpi1_suitable_living_with_friends
    END AS kpi1_suitable_living_with_friends,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_friends
        ELSE summary_cl.kpi1_total_living_with_friends
    END AS kpi1_total_living_with_friends,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_stc
        ELSE summary_cl.kpi1_suitable_stc
    END AS kpi1_suitable_stc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_stc
        ELSE summary_cl.kpi1_total_stc
    END AS kpi1_total_stc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_sch
        ELSE summary_cl.kpi1_suitable_sch
    END AS kpi1_suitable_sch,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_sch
        ELSE summary_cl.kpi1_total_sch
    END AS kpi1_total_sch,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yoi
        ELSE summary_cl.kpi1_suitable_yoi
    END AS kpi1_suitable_yoi,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yoi
        ELSE summary_cl.kpi1_total_yoi
    END AS kpi1_total_yoi
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    OUTER JOIN yjb_kpi_case_level.kpi1_acc_template as summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-qcpI9yx99d */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
SELECT
    unpvt_table.yjs_name,
    unpvt_table.yot_code,
    unpvt_table.area_operations,
    unpvt_table.yjb_country,
    families."reverse_family members" AS yjs_reverse_family,
    unpvt_table.source_data_flag,
    unpvt_table.quarter_label,
    unpvt_table.quarter_label_date,
    unpvt_table.kpi_number,
    'Accommodation' AS kpi_name,
    'Children in accommodation' AS kpi_short_description,
    /* add metadata for every measure */
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable (will not be relevant for  kpis)
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%unsuitable%' THEN 'Unsuitable'
        WHEN unpvt_table.measure_numerator LIKE '%suitable%' THEN 'Suitable'
        ELSE NULL
    END AS suitability,
    -- whether the measure_numerator is calculating successfully or not completed OOCDs - only for kpi6 but need to union all tables
    CASE
        WHEN unpvt_table.measure_numerator LIKE 'successful%' THEN 'Successfully completed'
        WHEN unpvt_table.measure_numerator LIKE '%not_completed%' THEN 'Not completed'
        ELSE NULL
    END AS completion,
    -- level of seniority - not relevant for this KPI but need the column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%senior%' THEN 'Senior'
        WHEN unpvt_table.measure_numerator LIKE '%junior%' THEN 'Delegated'
        ELSE NULL
    END AS seniority,
    -- part-time / full-time - only relevant for KPI 2 but need the column to union all long formats later
     CASE
        WHEN unpvt_table.measure_numerator LIKE '%part%' THEN 'Part-time'
        WHEN unpvt_table.measure_numerator LIKE '%full%' THEN 'Full-time'
        ELSE NULL
    END AS ETE_part_time_full_time,
    -- add metadata for measure_numerator category - type of accommodation, type of order
    CASE
        /*type of accommodation*/
        WHEN unpvt_table.measure_numerator LIKE '%living_with_parents%' THEN 'Living with parents'
        WHEN unpvt_table.measure_numerator LIKE '%living_with_family_not_parents%' THEN 'Living with family (not parents)'
        WHEN unpvt_table.measure_numerator LIKE '%living_with_friends%' THEN 'Living with friends'
        WHEN unpvt_table.measure_numerator LIKE '%foster_care%' THEN 'Foster care'
        WHEN unpvt_table.measure_numerator LIKE '%supported_accom_lodgings%' THEN 'Supported accommodation and lodgings'
        WHEN unpvt_table.measure_numerator LIKE '%temporary_accom%' THEN 'Temporary accommodation'
        WHEN unpvt_table.measure_numerator LIKE '%residential_unit%' THEN 'Residential unit'
        WHEN unpvt_table.measure_numerator LIKE '%independent_living%' THEN 'Independent living'
        WHEN unpvt_table.measure_numerator LIKE '%other_accom%' THEN 'Other accommodation'
        WHEN unpvt_table.measure_numerator LIKE '%yoi%' THEN 'Youth offending institute'
        WHEN unpvt_table.measure_numerator LIKE '%stc%' THEN 'Secure training centre'
        WHEN unpvt_table.measure_numerator LIKE '%sch%' THEN 'Secure childrens home'
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'Out of court disposals'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'Youth rehabilitation orders'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'Referral orders'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'Custodial sentences'
        /* overall measures */
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%end%' THEN 'End'
        ELSE 'Change'
    END AS measure_category,
    -- short description of the measure
    CASE
        WHEN measure_category IN (
            'Out of court disposals',
            'Youth cautions with YJS intervention',
            'Youth conditional cautions',
            'Referral orders',
            'Youth rehabilitation orders',
            'Custodial sentences'
        ) THEN 'Type of order'
        WHEN measure_category IN (
            'Living with parents',
            'Living with family (not parents)',
            'Living with friends',
            'Foster care',
            'Supported accommodation and lodgings',
            'Temporary accommodation',
            'Residential unit',
            'Independent living',
            'Other accommodation',
            'Youth offending institute',
            'Secure training centre',
            'Secure childrens home'
        ) THEN 'Type of accommodation'
        ELSE 'Overall measures'
    END AS measure_short_description,
    -- full measure wording
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi1_total_suitable_end' THEN 'Proportion of children in suitable accommodation at the end of their order'
        WHEN measure_short_description = 'Overall measures' THEN 'Children in suitable versus unsuitable accommodation at the start and the end of their order'
        WHEN measure_short_description = 'Type of accommodation' THEN 'Children in suitable versus unsuitable accommodation at the start and the end of their order broken down by type of accommodation'
        WHEN measure_short_description = 'Type of order' THEN 'Children in suitable versus unsuitable accommodation at the start and the end of their order broken down by type of order'
    END AS measure_long_description,
    -- whether the measure is the headline measure
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi1_total_suitable_end' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    -- measure numbering
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi1_total_suitable_end' THEN 'Headline'
        WHEN measure_short_description = 'Overall measures' THEN '1a'
        WHEN measure_short_description = 'Type of accommodation' THEN '1b'
        WHEN measure_short_description = 'Type of order' THEN '1c'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- name of the denominator (what is in the denominator)
    CASE
        WHEN measure_short_description = 'Overall measures' THEN 'kpi1_total_ypid'
        WHEN measure_category = 'Living with parents'
        and time_point = 'End' THEN 'kpi1_total_living_with_parents_end'
        WHEN measure_category = 'Living with family (not parents)'
        and time_point = 'End' THEN 'kpi1_total_living_with_family_not_parents_end'
        WHEN measure_category = 'Living with friends'
        and time_point = 'End' THEN 'kpi1_total_living_with_friends_end'
        WHEN measure_category = 'Foster care'
        and time_point = 'End' THEN 'kpi1_total_foster_care_end'
        WHEN measure_category = 'Supported accommodation and lodgings'
        and time_point = 'End' THEN 'kpi1_total_supported_accom_lodgings_end'
        WHEN measure_category = 'Temporary accommodation'
        and time_point = 'End' THEN 'kpi1_total_temporary_accom_end'
        WHEN measure_category = 'Residential unit'
        and time_point = 'End' THEN 'kpi1_total_residential_unit_end'
        WHEN measure_category = 'Independent living'
        and time_point = 'End' THEN 'kpi1_total_independent_living_end'
        WHEN measure_category = 'Other accommodation'
        and time_point = 'End' THEN 'kpi1_total_other_accom_end'
        WHEN measure_category = 'Youth offending institute'
        and time_point = 'End' THEN 'kpi1_total_yoi_end'
        WHEN measure_category = 'Secure training centre'
        and time_point = 'End' THEN 'kpi1_total_stc_end'
        WHEN measure_category = 'Secure childrens home'
        and time_point = 'End' THEN 'kpi1_total_sch_end'
        WHEN measure_category = 'Living with parents'
        and time_point = 'Start' THEN 'kpi1_total_living_with_parents_start'
        WHEN measure_category = 'Living with family (not parents)'
        and time_point = 'Start' THEN 'kpi1_total_living_with_family_not_parents_start'
        WHEN measure_category = 'Living with friends'
        and time_point = 'Start' THEN 'kpi1_total_living_with_friends_start'
        WHEN measure_category = 'Foster care'
        and time_point = 'Start' THEN 'kpi1_total_foster_care_start'
        WHEN measure_category = 'Supported accommodation and lodgings'
        and time_point = 'Start' THEN 'kpi1_total_supported_accom_lodgings_start'
        WHEN measure_category = 'Temporary accommodation'
        and time_point = 'Start' THEN 'kpi1_total_temporary_accom_start'
        WHEN measure_category = 'Residential unit'
        and time_point = 'Start' THEN 'kpi1_total_residential_unit_start'
        WHEN measure_category = 'Independent living'
        and time_point = 'Start' THEN 'kpi1_total_independent_living_start'
        WHEN measure_category = 'Other accommodation'
        and time_point = 'Start' THEN 'kpi1_total_other_accom_start'
        WHEN measure_category = 'Youth offending institute'
        and time_point = 'Start' THEN 'kpi1_total_yoi_start'
        WHEN measure_category = 'Secure training centre'
        and time_point = 'Start' THEN 'kpi1_total_stc_start'
        WHEN measure_category = 'Secure childrens home'
        and time_point = 'Start' THEN 'kpi1_total_sch_start'
        WHEN measure_category = 'Out of court disposals' THEN 'kpi1_total_oocd'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi1_total_yc_with_yjs'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi1_total_ycc'
        WHEN measure_category = 'Referral orders' THEN 'kpi1_total_ro'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi1_total_yro'
        WHEN measure_category = 'Custodial sentences' THEN 'kpi1_total_cust'
        ELSE NULL
    END AS measure_denominator,
    -- fill in the actual values for the denominator
    CASE
        WHEN measure_short_description = 'Overall measures' THEN unpvt_table.kpi1_total_ypid
        WHEN measure_category = 'Out of court disposals' THEN unpvt_table.kpi1_total_oocd
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN unpvt_table.kpi1_total_yc_with_yjs
        WHEN measure_category = 'Youth conditional cautions' THEN unpvt_table.kpi1_total_ycc
        WHEN measure_category = 'Referral orders' THEN unpvt_table.kpi1_total_ro
        WHEN measure_category = 'Youth rehabilitation orders' THEN unpvt_table.kpi1_total_yro
        WHEN measure_category = 'Custodial sentences' THEN unpvt_table.kpi1_total_cust
        WHEN measure_category = 'Living with parents'
        and time_point = 'End' THEN unpvt_table.kpi1_total_living_with_parents_end
        WHEN measure_category = 'Living with family (not parents)'
        and time_point = 'End' THEN unpvt_table.kpi1_total_living_with_family_not_parents_end
        WHEN measure_category = 'Living with friends'
        and time_point = 'End' THEN unpvt_table.kpi1_total_living_with_friends_end
        WHEN measure_category = 'Foster care'
        and time_point = 'End' THEN unpvt_table.kpi1_total_foster_care_end
        WHEN measure_category = 'Supported accommodation and lodgings'
        and time_point = 'End' THEN unpvt_table.kpi1_total_supported_accom_lodgings_end
        WHEN measure_category = 'Temporary accommodation'
        and time_point = 'End' THEN unpvt_table.kpi1_total_temporary_accom_end
        WHEN measure_category = 'Residential unit'
        and time_point = 'End' THEN unpvt_table.kpi1_total_residential_unit_end
        WHEN measure_category = 'Independent living'
        and time_point = 'End' THEN unpvt_table.kpi1_total_independent_living_end
        WHEN measure_category = 'Other accommodation'
        and time_point = 'End' THEN unpvt_table.kpi1_total_other_accom_end
        WHEN measure_category = 'Youth offending institute'
        and time_point = 'End' THEN unpvt_table.kpi1_total_yoi_end
        WHEN measure_category = 'Secure training centre'
        and time_point = 'End' THEN unpvt_table.kpi1_total_stc_end
        WHEN measure_category = 'Secure childrens home'
        and time_point = 'End' THEN unpvt_table.kpi1_total_sch_end
        WHEN measure_category = 'Living with parents'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_living_with_parents_start
        WHEN measure_category = 'Living with family (not parents)'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_living_with_family_not_parents_start
        WHEN measure_category = 'Living with friends'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_living_with_friends_start
        WHEN measure_category = 'Foster care'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_foster_care_start
        WHEN measure_category = 'Supported accommodation and lodgings'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_supported_accom_lodgings_start
        WHEN measure_category = 'Temporary accommodation'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_temporary_accom_start
        WHEN measure_category = 'Residential unit'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_residential_unit_start
        WHEN measure_category = 'Independent living'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_independent_living_start
        WHEN measure_category = 'Other accommodation'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_other_accom_start
        WHEN measure_category = 'Youth offending institute'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_yoi_start
        WHEN measure_category = 'Secure training centre'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_stc_start
        WHEN measure_category = 'Secure childrens home'
        and time_point = 'Start' THEN unpvt_table.kpi1_total_sch_start
        ELSE NULL
    END AS denominator_value,
    -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children in suitable accommodation at the end of their order'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an order ending'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi1_acc_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi1_unsuitable_yoi_end,
            kpi1_suitable_yoi_end,
            kpi1_unsuitable_yoi_start,
            kpi1_suitable_yoi_start,
            kpi1_unsuitable_sch_end,
            kpi1_suitable_sch_end,
            kpi1_unsuitable_sch_start,
            kpi1_suitable_sch_start,
            kpi1_unsuitable_stc_end,
            kpi1_suitable_stc_end,
            kpi1_unsuitable_stc_start,
            kpi1_suitable_stc_start,
            kpi1_unsuitable_living_with_friends_end,
            kpi1_suitable_living_with_friends_end,
            kpi1_unsuitable_living_with_friends_start,
            kpi1_suitable_living_with_friends_start,
            kpi1_unsuitable_foster_care_end,
            kpi1_suitable_foster_care_end,
            kpi1_unsuitable_foster_care_start,
            kpi1_suitable_foster_care_start,
            kpi1_unsuitable_supported_accom_lodgings_end,
            kpi1_suitable_supported_accom_lodgings_end,
            kpi1_unsuitable_supported_accom_lodgings_start,
            kpi1_suitable_supported_accom_lodgings_start,
            kpi1_unsuitable_temporary_accom_end,
            kpi1_suitable_temporary_accom_end,
            kpi1_unsuitable_temporary_accom_start,
            kpi1_suitable_temporary_accom_start,
            kpi1_unsuitable_living_with_family_not_parents_end,
            kpi1_suitable_living_with_family_not_parents_end,
            kpi1_unsuitable_living_with_family_not_parents_start,
            kpi1_suitable_living_with_family_not_parents_start,
            kpi1_unsuitable_residential_unit_end,
            kpi1_suitable_residential_unit_end,
            kpi1_unsuitable_residential_unit_start,
            kpi1_suitable_residential_unit_start,
            kpi1_unsuitable_independent_living_end,
            kpi1_suitable_independent_living_end,
            kpi1_unsuitable_independent_living_start,
            kpi1_suitable_independent_living_start,
            kpi1_unsuitable_other_accom_end,
            kpi1_suitable_other_accom_end,
            kpi1_unsuitable_other_accom_start,
            kpi1_suitable_other_accom_start,
            kpi1_unsuitable_living_with_parents_end,
            kpi1_suitable_living_with_parents_end,
            kpi1_unsuitable_living_with_parents_start,
            kpi1_suitable_living_with_parents_start,
            kpi1_unsuitable_cust_end,
            kpi1_suitable_cust_end,
            kpi1_unsuitable_cust_start,
            kpi1_suitable_cust_start,
            kpi1_unsuitable_yro_end,
            kpi1_suitable_yro_end,
            kpi1_unsuitable_yro_start,
            kpi1_suitable_yro_start,
            kpi1_unsuitable_ro_end,
            kpi1_suitable_ro_end,
            kpi1_unsuitable_ro_start,
            kpi1_suitable_ro_start,
            kpi1_unsuitable_ycc_end,
            kpi1_suitable_ycc_end,
            kpi1_unsuitable_ycc_start,
            kpi1_suitable_ycc_start,
            kpi1_unsuitable_yc_with_yjs_end,
            kpi1_suitable_yc_with_yjs_end,
            kpi1_unsuitable_yc_with_yjs_start,
            kpi1_suitable_yc_with_yjs_start,
            kpi1_unsuitable_oocd_end,
            kpi1_suitable_oocd_end,
            kpi1_unsuitable_oocd_start,
            kpi1_suitable_oocd_start,
            kpi1_total_unsuitable_start,
            kpi1_total_suitable_start,
            kpi1_total_unsuitable_end,
            kpi1_total_suitable_end,
            kpi1_suitable_change,
            kpi1_unsuitable_change
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
