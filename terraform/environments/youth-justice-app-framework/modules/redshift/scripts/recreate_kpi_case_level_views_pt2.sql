SET enable_case_sensitive_identifier TO true;

/* RQEV2-wPchWR8u12 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.person_details distkey (source_document_id) sortkey (source_document_id) AS WITH pd AS (
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
        document_item."kpi6SuccessfullyCompleted" AS kpi6_successfully_completed
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
combine AS (
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
        --new label_quarter to get year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
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
        -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting seriousness ranking or type of order (NULLs) when they were in the CTE above.
add_seriousness_count_in_kpi_lo AS (
    SELECT
        combine.*,
        seriousness.seriousness_ranking,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            label_quarter
            ORDER BY
                seriousness_ranking,
                outcome_date DESC
        ) as most_serious_recent
    FROM
        combine
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
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
    offence_id,
    outcome_date,
    residence_on_legal_outcome_date,
    outcome_appeal_status,
    cms_legal_outcome,
    legal_outcome,
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
    add_seriousness_count_in_kpi_lo
WHERE
    most_serious_recent = 1;	
/* RQEV2-xOrMjcNMGZ */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.person_details_v8 distkey (source_document_id) sortkey (source_document_id) AS WITH pd AS (
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
        document_item."kpi6SuccessfullyCompleted" AS kpi6_successfully_completed
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
combine AS (
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
            intervention_mapping.disposal_type_fixed,
            pd.ypid_dob,
            intervention_prog.intervention_start_date,
            offence.outcome_date
        ) AS age_on_intervention_start,
        yjb_kpi_case_level.f_ageAtInterventionEnd(
            pd.ypid_dob,
            intervention_prog.intervention_end_date
        ) AS age_on_intervention_end,
        --new label_quarter to get year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
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
        -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting seriousness ranking or type of order (NULLs) when they were in the CTE above.
add_seriousness_count_in_kpi_lo AS (
    SELECT
        combine.*,
        seriousness.seriousness_ranking,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            label_quarter
            ORDER BY
                seriousness_ranking,
                outcome_date DESC
        ) as most_serious_recent
    FROM
        combine
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
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
    offence_id,
    outcome_date,
    residence_on_legal_outcome_date,
    outcome_appeal_status,
    cms_legal_outcome,
    legal_outcome,
    legal_outcome_group,
    legal_outcome_group_fixed,
    seriousness_ranking,
    intervention_programme_id,
    intervention_start_date,
    intervention_end_date,
    age_on_intervention_start,
    age_on_intervention_end,
    kpi6_successfully_completed,
    cms_disposal_type,
    disposal_type,
    disposal_type_fixed,
    disposal_type_grouped,
    type_of_order
FROM
    add_seriousness_count_in_kpi_lo
WHERE
    most_serious_recent = 1;	

/* RQEV2-dSU4Q8xWlU */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_case_level_v8_access distkey (kpi1_source_document_id_acc) sortkey (kpi1_source_document_id_acc) AS WITH kpi1 AS (
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

/* RQEV2-p6mksfDBLZ */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_case_level_v8 distkey (source_document_id) sortkey (source_document_id) AS WITH kpi10 AS (
    SELECT
        victim.source_document_id as kpi10_source_document_id_victim,
        victim.document_item."victimID" :: text as kpi10_victim_id,
        victim.document_item."engagedRJ" :: text as kpi10_engaged_rj,
        victim.document_item."viewPrior" :: text as kpi10_view_prior,
        --victimType all null in the raw json data - but does exist in quarterly returns with real data. Check with NEC. 
        victim.document_item."victimType" :: text as kpi10_victim_type,
        victim.document_item."engagedRJEnd" :: date as kpi10_engaged_rj_end,
        victim.document_item."engagedRJStart" :: date as kpi10_engaged_rj_start,
        victim.document_item."yjscontactDate" :: date as kpi10_yjs_contact_date,
        victim.document_item."progressProvided" :: text as kpi10_progress_provided,
        victim.document_item."consentYJSContact" :: text as kpi10_consent_yjs_contact,
        victim.document_item."victimInterventionID" :: text as kpi10_victim_intervention_id,
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
        AND GETDATE() -- AND pd.ypid NOT IN (
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
    --sub-measure number of rj processes
    CASE
        WHEN kpi10_engaged_rj = 'Yes' THEN kpi10_victim_intervention_id
        ELSE NULL
    END AS kpi10_rj_process,
    -- sub-measure 10d: victim asked view prior to outcome / victim consented to being contacted
    -- numerator
    CASE
        WHEN kpi10_view_prior = 'Yes'
        AND kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_view_prior,
    -- sub-measure 10e: victim provided info on case/ victim consented to being contacted
    -- numerator
    CASE
        WHEN kpi10_progress_provided = 'Yes'
        AND kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_provided_info,
    -- sub-measure 10f: victims provided additional support / victim consented to being contacted
    -- numerator
    CASE
        WHEN kpi10_additional_support_provided = 'Yes'
        AND kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_given_support,
    --sub-measure 10g: victims contacted by the YJS/ victim consented to being contacted
    --numerator
    CASE
        WHEN kpi10_yjs_contact_date <> '1900-01-01' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_contacted,
    -- denominator for headline, submeasures 10d, 10e, 10f,10g: victims consented contact
    CASE
        WHEN kpi10_consent_yjs_contact = 'Yes' THEN kpi10_victim_id
        ELSE NULL
    END AS kpi10_victim_consent_contact
FROM
    add_victims;	

/* RQEV2-LVTCBAFOFy */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        kpi10.return_status_id,
        kpi10.reporting_date,
        kpi10.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        kpi10.description,
        kpi10.total as total,
        --new label_quarter to get year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter
    FROM
        yjb_returns.yjaf_kpi_returns.kpi10_victims_v1 AS kpi10
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi10.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi10.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    SUM(
        CASE
            WHEN description = 'Number of children with an order closing with an identified victim or victims of youth crime' THEN total
            ELSE 0
        END
    ) AS kpi10_ypids_with_victims,
    --headline numerator: victims who engaged RJ
    SUM(
        CASE
            WHEN description = 'Number of victims engaged with on restorative justice opportunities' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_engaged_rj,
    --sub measure: total victims,
    SUM(
        CASE
            WHEN description = 'Total number of victims ' THEN total
            ELSE 0
        END
    ) AS kpi10_total_victims,
    --sub measure: victims asked view prior
    SUM(
        CASE
            WHEN description = 'Number of victims asked their view prior to OOCD decision-making and planning for statutory court orders' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_view_prior,
    --sub meausre: victims provided info of those who requested info
    -- numerator
    SUM(
        CASE
            WHEN description = 'Of those, the number of victims provided with information about the progress of the child''s case' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_provided_info,
    --sub measure: victims given additional support that asked for it
    -- numerator
    SUM(
        CASE WHEN description = 'Of those victims who asked for additional support, the number provided with information on appropriate support services' THEN total
        ELSE 0
        END
    ) AS kpi10_victim_given_support,
    -- denominator for headline, submeasures 10d, 10e, 10f,10g: victims consented contact
    SUM(
        CASE
            WHEN description = 'Number of victims who consent to be contacted by the YJS' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_consent_contact
FROM
    template
GROUP BY
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter;	
/* RQEV2-3ViOqHoMYU */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi1_acc_template_v8 cascade;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_template_v8 distkey (yot_code) sortkey (yot_code) AS WITH template AS (
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
    --suitable/unsuitable by type of order start
    SUM(out_court_no_yjs_start_yes) AS kpi1_suitable_oocd_start,
    SUM(yc_with_yjs_start_yes) AS kpi1_suitable_yc_with_yjs_start,
    SUM(ycc_start_yes) AS kpi1_suitable_ycc_start,
    SUM(ro_start_yes) AS kpi1_suitable_ro_start,
    SUM(yro_start_yes) AS kpi1_suitable_yro_start,
    SUM(cust_start_yes) AS kpi1_suitable_cust_start,
    SUM(out_court_no_yjs_start_no) AS kpi1_unsuitable_oocd_start,
    SUM(yc_with_yjs_start_no) AS kpi1_unsuitable_yc_with_yjs_start,
    SUM(ycc_start_no) AS kpi1_unsuitable_ycc_start,
    SUM(ro_start_no) AS kpi1_unsuitable_ro_start,
    SUM(yro_start_no) AS kpi1_unsuitable_yro_start,
    SUM(cust_start_no) AS kpi1_unsuitable_cust_start,
    --suitable/unsuitable by type of order end
    SUM(out_court_no_yjs_end_yes) AS kpi1_suitable_oocd_end,
    SUM(yc_with_yjs_end_yes) AS kpi1_suitable_yc_with_yjs_end,
    SUM(ycc_end_yes) AS kpi1_suitable_ycc_end,
    SUM(ro_end_yes) AS kpi1_suitable_ro_end,
    SUM(yro_end_yes) AS kpi1_suitable_yro_end,
    SUM(cust_end_yes) AS kpi1_suitable_cust_end,
    SUM(out_court_no_yjs_end_no) AS kpi1_unsuitable_oocd_end,
    SUM(yc_with_yjs_end_no) AS kpi1_unsuitable_yc_with_yjs_end,
    SUM(ycc_end_no) AS kpi1_unsuitable_ycc_end,
    SUM(ro_end_no) AS kpi1_unsuitable_ro_end,
    SUM(yro_end_no) AS kpi1_unsuitable_yro_end,
    SUM(cust_end_no) AS kpi1_unsuitable_cust_end,
    --total in each type of order
    SUM(out_court_no_yjs_total) AS kpi1_total_oocd,
    SUM(yc_with_yjs_total) AS kpi1_total_yc_with_yjs,
    SUM(ycc_total) AS kpi1_total_ycc,
    SUM(ro_total) AS kpi1_total_ro,
    SUM(yro_total) AS kpi1_total_yro,
    SUM(cust_total) AS kpi1_total_cust,
    --by type of accommodation suitable end
    --- didn't count 'bed and breakfast', 'no fixed abode' and 'unknown' as these are always unsuitable (according to recording guidance)
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_stc_end,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_sch_end,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_yoi_end,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_parents_end,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_other_accom_end,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_independent_living_end,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_residential_unit_end,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_family_not_parents_end,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_temporary_accom_end,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_supported_accom_lodgings_end,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_foster_care_end,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_end
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_friends_end,
    --by type of accommodation suitable start
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_stc_start,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_sch_start,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_yoi_start,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_parents_start,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_other_accom_start,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_independent_living_start,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_residential_unit_start,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_family_not_parents_start,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_temporary_accom_start,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_supported_accom_lodgings_start,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_foster_care_start,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_start
            ELSE NULL
        END
    ) AS kpi1_suitable_living_with_friends_start,
    --by type of accommodation unsuitable end
    SUM(
        CASE
            WHEN description = 'STC' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_stc_end,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_sch_end,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_yoi_end,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_parents_end,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_other_accom_end,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_independent_living_end,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_residential_unit_end,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_family_not_parents_end,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_temporary_accom_end,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_supported_accom_lodgings_end,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_foster_care_end,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_friends_end,
    --by type of accommodation unsuitable start
    SUM(
        CASE
            WHEN description = 'STC' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_stc_start,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_sch_start,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_yoi_start,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_parents_start,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_other_accom_start,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_independent_living_start,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_residential_unit_start,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_family_not_parents_start,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_temporary_accom_start,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_supported_accom_lodgings_start,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_foster_care_start,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_unsuitable_living_with_friends_start,
    -- total by type of accommdation start
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_stc_start,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_sch_start,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_yoi_start,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_living_with_parents_start,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_other_accom_start,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_independent_living_start,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_residential_unit_start,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_living_with_family_not_parents_start,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_temporary_accom_start,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_supported_accom_lodgings_start,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_foster_care_start,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_start + total_unsuitable_start
            ELSE NULL
        END
    ) AS kpi1_total_living_with_friends_start,
    -- total by type of accommdation end
    SUM(
        CASE
            WHEN description = 'STC' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_stc_end,
    SUM(
        CASE
            WHEN description = 'SCH' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_sch_end,
    SUM(
        CASE
            WHEN description = 'YOI' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_yoi_end,
    SUM(
        CASE
            WHEN description = 'Living with parent(s)' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_parents_end,
    SUM(
        CASE
            WHEN description = 'Other' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_other_accom_end,
    SUM(
        CASE
            WHEN description = 'Independent living' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_independent_living_end,
    SUM(
        CASE
            WHEN description = 'Residential unit' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_residential_unit_end,
    SUM(
        CASE
            WHEN description = 'Living with family (not parents)' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_family_not_parents_end,
    SUM(
        CASE
            WHEN description = 'Temporary accomodation' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_temporary_accom_end,
    SUM(
        CASE
            WHEN description = 'Supported accommodation/supported lodgings' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_supported_accom_lodgings_end,
    SUM(
        CASE
            WHEN description = 'Foster Care' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_foster_care_end,
    SUM(
        CASE
            WHEN description = 'Living with friends' THEN total_suitable_end + total_unsuitable_end
            ELSE NULL
        END
    ) AS kpi1_total_living_with_friends_end
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

/* RQEV2-vxAwVyTW3F */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi1_acc_summary_v8;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi1_acc_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
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
        "yjb_returns"."yjb_kpi_case_level"."person_details_v8"
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
        --suitable at start by type of order
        COUNT(DISTINCT kpi1_suitable_ro_start) AS kpi1_suitable_ro_start,
        COUNT(DISTINCT kpi1_suitable_cust_start) AS kpi1_suitable_cust_start,
        COUNT(DISTINCT kpi1_suitable_oocd_start) AS kpi1_suitable_oocd_start,
        COUNT(DISTINCT kpi1_suitable_yc_with_yjs_start) AS kpi1_suitable_yc_with_yjs_start,
        COUNT(DISTINCT kpi1_suitable_yro_start) AS kpi1_suitable_yro_start,
        COUNT(DISTINCT kpi1_suitable_ycc_start) AS kpi1_suitable_ycc_start,
        --unsuitable at start by type of order
        COUNT(DISTINCT kpi1_unsuitable_ro_start) AS kpi1_unsuitable_ro_start,
        COUNT(DISTINCT kpi1_unsuitable_cust_start) AS kpi1_unsuitable_cust_start,
        COUNT(DISTINCT kpi1_unsuitable_oocd_start) AS kpi1_unsuitable_oocd_start,
        COUNT(DISTINCT kpi1_unsuitable_yc_with_yjs_start) AS kpi1_unsuitable_yc_with_yjs_start,
        COUNT(DISTINCT kpi1_unsuitable_yro_start) AS kpi1_unsuitable_yro_start,
        COUNT(DISTINCT kpi1_unsuitable_ycc_start) AS kpi1_unsuitable_ycc_start,
        --suitable at end by type of order
        COUNT(DISTINCT kpi1_suitable_ro_end) AS kpi1_suitable_ro_end,
        COUNT(DISTINCT kpi1_suitable_cust_end) AS kpi1_suitable_cust_end,
        COUNT(DISTINCT kpi1_suitable_oocd_end) AS kpi1_suitable_oocd_end,
        COUNT(DISTINCT kpi1_suitable_yc_with_yjs_end) AS kpi1_suitable_yc_with_yjs_end,
        COUNT(DISTINCT kpi1_suitable_yro_end) AS kpi1_suitable_yro_end,
        COUNT(DISTINCT kpi1_suitable_ycc_end) AS kpi1_suitable_ycc_end,
        --unsuitable at end by type of order
        COUNT(DISTINCT kpi1_unsuitable_ro_end) AS kpi1_unsuitable_ro_end,
        COUNT(DISTINCT kpi1_unsuitable_cust_end) AS kpi1_unsuitable_cust_end,
        COUNT(DISTINCT kpi1_unsuitable_oocd_end) AS kpi1_unsuitable_oocd_end,
        COUNT(DISTINCT kpi1_unsuitable_yc_with_yjs_end) AS kpi1_unsuitable_yc_with_yjs_end,
        COUNT(DISTINCT kpi1_unsuitable_yro_end) AS kpi1_unsuitable_yro_end,
        COUNT(DISTINCT kpi1_unsuitable_ycc_end) AS kpi1_unsuitable_ycc_end,
        --suitable at start of order by type of accommodation
        COUNT(DISTINCT kpi1_suitable_living_with_parents_start) AS kpi1_suitable_living_with_parents_start,
        COUNT(DISTINCT kpi1_suitable_other_accom_start) AS kpi1_suitable_other_accom_start,
        COUNT(DISTINCT kpi1_suitable_independent_living_start) AS kpi1_suitable_independent_living_start,
        COUNT(DISTINCT kpi1_suitable_residential_unit_start) AS kpi1_suitable_residential_unit_start,
        COUNT(DISTINCT kpi1_suitable_living_with_family_not_parents_start) AS kpi1_suitable_living_with_family_not_parents_start,
        COUNT(DISTINCT kpi1_suitable_temporary_accom_start) AS kpi1_suitable_temporary_accom_start,
        COUNT(DISTINCT kpi1_suitable_supported_accom_lodgings_start) AS kpi1_suitable_supported_accom_lodgings_start,
        COUNT(DISTINCT kpi1_suitable_foster_care_start) AS kpi1_suitable_foster_care_start,
        COUNT(DISTINCT kpi1_suitable_living_with_friends_start) AS kpi1_suitable_living_with_friends_start,
        COUNT(DISTINCT kpi1_suitable_stc_start) AS kpi1_suitable_stc_start,
        COUNT(DISTINCT kpi1_suitable_sch_start) AS kpi1_suitable_sch_start,
        COUNT(DISTINCT kpi1_suitable_yoi_start) AS kpi1_suitable_yoi_start,
        --unsuitable at start of order by type of accommodation
        COUNT(DISTINCT kpi1_unsuitable_living_with_parents_start) AS kpi1_unsuitable_living_with_parents_start,
        COUNT(DISTINCT kpi1_unsuitable_other_accom_start) AS kpi1_unsuitable_other_accom_start,
        COUNT(DISTINCT kpi1_unsuitable_independent_living_start) AS kpi1_unsuitable_independent_living_start,
        COUNT(DISTINCT kpi1_unsuitable_residential_unit_start) AS kpi1_unsuitable_residential_unit_start,
        COUNT(DISTINCT kpi1_unsuitable_living_with_family_not_parents_start) AS kpi1_unsuitable_living_with_family_not_parents_start,
        COUNT(DISTINCT kpi1_unsuitable_temporary_accom_start) AS kpi1_unsuitable_temporary_accom_start,
        COUNT(DISTINCT kpi1_unsuitable_supported_accom_lodgings_start) AS kpi1_unsuitable_supported_accom_lodgings_start,
        COUNT(DISTINCT kpi1_unsuitable_foster_care_start) AS kpi1_unsuitable_foster_care_start,
        COUNT(DISTINCT kpi1_unsuitable_living_with_friends_start) AS kpi1_unsuitable_living_with_friends_start,
        COUNT(DISTINCT kpi1_unsuitable_stc_start) AS kpi1_unsuitable_stc_start,
        COUNT(DISTINCT kpi1_unsuitable_sch_start) AS kpi1_unsuitable_sch_start,
        COUNT(DISTINCT kpi1_unsuitable_yoi_start) AS kpi1_unsuitable_yoi_start,
        --suitable at end of order by type of accommodation
        COUNT(DISTINCT kpi1_suitable_living_with_parents_end) AS kpi1_suitable_living_with_parents_end,
        COUNT(DISTINCT kpi1_suitable_other_accom_end) AS kpi1_suitable_other_accom_end,
        COUNT(DISTINCT kpi1_suitable_independent_living_end) AS kpi1_suitable_independent_living_end,
        COUNT(DISTINCT kpi1_suitable_residential_unit_end) AS kpi1_suitable_residential_unit_end,
        COUNT(DISTINCT kpi1_suitable_living_with_family_not_parents_end) AS kpi1_suitable_living_with_family_not_parents_end,
        COUNT(DISTINCT kpi1_suitable_temporary_accom_end) AS kpi1_suitable_temporary_accom_end,
        COUNT(DISTINCT kpi1_suitable_supported_accom_lodgings_end) AS kpi1_suitable_supported_accom_lodgings_end,
        COUNT(DISTINCT kpi1_suitable_foster_care_end) AS kpi1_suitable_foster_care_end,
        COUNT(DISTINCT kpi1_suitable_living_with_friends_end) AS kpi1_suitable_living_with_friends_end,
        COUNT(DISTINCT kpi1_suitable_stc_end) AS kpi1_suitable_stc_end,
        COUNT(DISTINCT kpi1_suitable_sch_end) AS kpi1_suitable_sch_end,
        COUNT(DISTINCT kpi1_suitable_yoi_end) AS kpi1_suitable_yoi_end,
        --unsuitable at end of order by type of accommodation
        COUNT(DISTINCT kpi1_unsuitable_living_with_parents_end) AS kpi1_unsuitable_living_with_parents_end,
        COUNT(DISTINCT kpi1_unsuitable_other_accom_end) AS kpi1_unsuitable_other_accom_end,
        COUNT(DISTINCT kpi1_unsuitable_independent_living_end) AS kpi1_unsuitable_independent_living_end,
        COUNT(DISTINCT kpi1_unsuitable_residential_unit_end) AS kpi1_unsuitable_residential_unit_end,
        COUNT(DISTINCT kpi1_unsuitable_living_with_family_not_parents_end) AS kpi1_unsuitable_living_with_family_not_parents_end,
        COUNT(DISTINCT kpi1_unsuitable_temporary_accom_end) AS kpi1_unsuitable_temporary_accom_end,
        COUNT(DISTINCT kpi1_unsuitable_supported_accom_lodgings_end) AS kpi1_unsuitable_supported_accom_lodgings_end,
        COUNT(DISTINCT kpi1_unsuitable_foster_care_end) AS kpi1_unsuitable_foster_care_end,
        COUNT(DISTINCT kpi1_unsuitable_living_with_friends_end) AS kpi1_unsuitable_living_with_friends_end,
        COUNT(DISTINCT kpi1_unsuitable_stc_end) AS kpi1_unsuitable_stc_end,
        COUNT(DISTINCT kpi1_unsuitable_sch_end) AS kpi1_unsuitable_sch_end,
        COUNT(DISTINCT kpi1_unsuitable_yoi_end) AS kpi1_unsuitable_yoi_end,
        --total by type of accommodation start
        COUNT(DISTINCT kpi1_total_living_with_parents_start) AS kpi1_total_living_with_parents_start,
        COUNT(DISTINCT kpi1_total_other_accom_start) AS kpi1_total_other_accom_start,
        COUNT(DISTINCT kpi1_total_independent_living_start) AS kpi1_total_independent_living_start,
        COUNT(DISTINCT kpi1_total_residential_unit_start) AS kpi1_total_residential_unit_start,
        COUNT(DISTINCT kpi1_total_living_with_family_not_parents_start) AS kpi1_total_living_with_family_not_parents_start,
        COUNT(DISTINCT kpi1_total_temporary_accom_start) AS kpi1_total_temporary_accom_start,
        COUNT(DISTINCT kpi1_total_supported_accom_lodgings_start) AS kpi1_total_supported_accom_lodgings_start,
        COUNT(DISTINCT kpi1_total_foster_care_start) AS kpi1_total_foster_care_start,
        COUNT(DISTINCT kpi1_total_living_with_friends_start) AS kpi1_total_living_with_friends_start,
        COUNT(DISTINCT kpi1_total_stc_start) AS kpi1_total_stc_start,
        COUNT(DISTINCT kpi1_total_sch_start) AS kpi1_total_sch_start,
        COUNT(DISTINCT kpi1_total_yoi_start) AS kpi1_total_yoi_start,
        --total by type of accommodation end
        COUNT(DISTINCT kpi1_total_living_with_parents_end) AS kpi1_total_living_with_parents_end,
        COUNT(DISTINCT kpi1_total_other_accom_end) AS kpi1_total_other_accom_end,
        COUNT(DISTINCT kpi1_total_independent_living_end) AS kpi1_total_independent_living_end,
        COUNT(DISTINCT kpi1_total_residential_unit_end) AS kpi1_total_residential_unit_end,
        COUNT(DISTINCT kpi1_total_living_with_family_not_parents_end) AS kpi1_total_living_with_family_not_parents_end,
        COUNT(DISTINCT kpi1_total_temporary_accom_end) AS kpi1_total_temporary_accom_end,
        COUNT(DISTINCT kpi1_total_supported_accom_lodgings_end) AS kpi1_total_supported_accom_lodgings_end,
        COUNT(DISTINCT kpi1_total_foster_care_end) AS kpi1_total_foster_care_end,
        COUNT(DISTINCT kpi1_total_living_with_friends_end) AS kpi1_total_living_with_friends_end,
        COUNT(DISTINCT kpi1_total_stc_end) AS kpi1_total_stc_end,
        COUNT(DISTINCT kpi1_total_sch_end) AS kpi1_total_sch_end,
        COUNT(DISTINCT kpi1_total_yoi_end) AS kpi1_total_yoi_end
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi1_acc_case_level_v8_access"
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
    COALESCE(
        summary_t.label_quarter,
        summary_person.label_quarter
    ) AS quarter_label,
    -- getting the first date of the quarter 
    CAST(
        CASE
        WHEN SUBSTRING(quarter_label, 5, 2) = 'Q1' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-04-01')
        WHEN SUBSTRING(quarter_label, 5, 2) = 'Q2' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-07-01')
        WHEN SUBSTRING(quarter_label, 5, 2) = 'Q3' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-10-01')
        WHEN SUBSTRING(quarter_label, 5, 2) = 'Q4' THEN CONCAT(
            CAST(SUBSTRING(quarter_label, 1, 4) AS INT) + 1,
            '-01-01'
        ) END AS DATE
    ) AS quarter_label_date,
    'KPI 1' AS kpi_number,
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
    END AS kpi1_total_suitable_end,
    -- unsuitable end
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_end
        ELSE summary_cl.kpi1_unsuitable_end
    END AS kpi1_total_unsuitable_end,
    -- suitable start
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_start
        ELSE summary_cl.kpi1_suitable_start
    END AS kpi1_total_suitable_start,
    -- unsuitable start
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_start
        ELSE summary_cl.kpi1_unsuitable_start
    END AS kpi1_total_unsuitable_start,
    -- change for overall measures
    kpi1_total_suitable_end - kpi1_total_suitable_start AS kpi1_suitable_change,
    kpi1_total_unsuitable_end - kpi1_total_unsuitable_start AS kpi1_unsuitable_change,
    -- by type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_oocd_start
        ELSE summary_cl.kpi1_suitable_oocd_start
    END AS kpi1_suitable_oocd_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_oocd_start
        ELSE summary_cl.kpi1_unsuitable_oocd_start
    END AS kpi1_unsuitable_oocd_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_oocd_end
        ELSE summary_cl.kpi1_suitable_oocd_end
    END AS kpi1_suitable_oocd_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_oocd_end
        ELSE summary_cl.kpi1_unsuitable_oocd_end
    END AS kpi1_unsuitable_oocd_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_oocd
        ELSE summary_person.total_ypid_oocd
    END AS kpi1_total_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yc_with_yjs_start
        ELSE summary_cl.kpi1_suitable_yc_with_yjs_start
    END AS kpi1_suitable_yc_with_yjs_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yc_with_yjs_start
        ELSE summary_cl.kpi1_unsuitable_yc_with_yjs_start
    END AS kpi1_unsuitable_yc_with_yjs_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yc_with_yjs_end
        ELSE summary_cl.kpi1_suitable_yc_with_yjs_end
    END AS kpi1_suitable_yc_with_yjs_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yc_with_yjs_end
        ELSE summary_cl.kpi1_unsuitable_yc_with_yjs_end
    END AS kpi1_unsuitable_yc_with_yjs_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yc_with_yjs
        ELSE summary_person.total_ypid_yc
    END AS kpi1_total_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ycc_start
        ELSE summary_cl.kpi1_suitable_ycc_start
    END AS kpi1_suitable_ycc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ycc_start
        ELSE summary_cl.kpi1_unsuitable_ycc_start
    END AS kpi1_unsuitable_ycc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ycc_end
        ELSE summary_cl.kpi1_suitable_ycc_end
    END AS kpi1_suitable_ycc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ycc_end
        ELSE summary_cl.kpi1_unsuitable_ycc_end
    END AS kpi1_unsuitable_ycc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_ycc
        ELSE summary_person.total_ypid_ycc
    END AS kpi1_total_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ro_start
        ELSE summary_cl.kpi1_suitable_ro_start
    END AS kpi1_suitable_ro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ro_start
        ELSE summary_cl.kpi1_unsuitable_ro_start
    END AS kpi1_unsuitable_ro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_ro_end
        ELSE summary_cl.kpi1_suitable_ro_end
    END AS kpi1_suitable_ro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_ro_end
        ELSE summary_cl.kpi1_unsuitable_ro_end
    END AS kpi1_unsuitable_ro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_ro
        ELSE summary_person.total_ypid_ro
    END AS kpi1_total_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yro_start
        ELSE summary_cl.kpi1_suitable_yro_start
    END AS kpi1_suitable_yro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yro_start
        ELSE summary_cl.kpi1_unsuitable_yro_start
    END AS kpi1_unsuitable_yro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yro_end
        ELSE summary_cl.kpi1_suitable_yro_end
    END AS kpi1_suitable_yro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yro_end
        ELSE summary_cl.kpi1_unsuitable_yro_end
    END AS kpi1_unsuitable_yro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yro
        ELSE summary_person.total_ypid_yro
    END AS kpi1_total_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_cust_start
        ELSE summary_cl.kpi1_suitable_cust_start
    END AS kpi1_suitable_cust_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_cust_start
        ELSE summary_cl.kpi1_unsuitable_cust_start
    END AS kpi1_unsuitable_cust_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_cust_end
        ELSE summary_cl.kpi1_suitable_cust_end
    END AS kpi1_suitable_cust_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_cust_end
        ELSE summary_cl.kpi1_unsuitable_cust_end
    END AS kpi1_unsuitable_cust_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_cust
        ELSE summary_person.total_ypid_cust
    END AS kpi1_total_cust,
    --by accommodation type
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_parents_start
        ELSE summary_cl.kpi1_suitable_living_with_parents_start
    END AS kpi1_suitable_living_with_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_parents_start
        ELSE summary_cl.kpi1_unsuitable_living_with_parents_start
    END AS kpi1_unsuitable_living_with_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_parents_end
        ELSE summary_cl.kpi1_suitable_living_with_parents_end
    END AS kpi1_suitable_living_with_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_parents_end
        ELSE summary_cl.kpi1_unsuitable_living_with_parents_end
    END AS kpi1_unsuitable_living_with_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_parents_start
        ELSE summary_cl.kpi1_total_living_with_parents_start
    END AS kpi1_total_living_with_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_parents_end
        ELSE summary_cl.kpi1_total_living_with_parents_end
    END AS kpi1_total_living_with_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_other_accom_start
        ELSE summary_cl.kpi1_suitable_other_accom_start
    END AS kpi1_suitable_other_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_other_accom_start
        ELSE summary_cl.kpi1_unsuitable_other_accom_start
    END AS kpi1_unsuitable_other_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_other_accom_end
        ELSE summary_cl.kpi1_suitable_other_accom_end
    END AS kpi1_suitable_other_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_other_accom_end
        ELSE summary_cl.kpi1_unsuitable_other_accom_end
    END AS kpi1_unsuitable_other_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_other_accom_start
        ELSE summary_cl.kpi1_total_other_accom_start
    END AS kpi1_total_other_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_other_accom_end
        ELSE summary_cl.kpi1_total_other_accom_end
    END AS kpi1_total_other_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_independent_living_start
        ELSE summary_cl.kpi1_suitable_independent_living_start
    END AS kpi1_suitable_independent_living_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_independent_living_start
        ELSE summary_cl.kpi1_unsuitable_independent_living_start
    END AS kpi1_unsuitable_independent_living_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_independent_living_end
        ELSE summary_cl.kpi1_suitable_independent_living_end
    END AS kpi1_suitable_independent_living_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_independent_living_end
        ELSE summary_cl.kpi1_unsuitable_independent_living_end
    END AS kpi1_unsuitable_independent_living_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_independent_living_start
        ELSE summary_cl.kpi1_total_independent_living_start
    END AS kpi1_total_independent_living_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_independent_living_end
        ELSE summary_cl.kpi1_total_independent_living_end
    END AS kpi1_total_independent_living_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_residential_unit_start
        ELSE summary_cl.kpi1_suitable_residential_unit_start
    END AS kpi1_suitable_residential_unit_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_residential_unit_start
        ELSE summary_cl.kpi1_unsuitable_residential_unit_start
    END AS kpi1_unsuitable_residential_unit_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_residential_unit_end
        ELSE summary_cl.kpi1_suitable_residential_unit_end
    END AS kpi1_suitable_residential_unit_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_residential_unit_end
        ELSE summary_cl.kpi1_unsuitable_residential_unit_end
    END AS kpi1_unsuitable_residential_unit_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_residential_unit_start
        ELSE summary_cl.kpi1_total_residential_unit_start
    END AS kpi1_total_residential_unit_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_residential_unit_end
        ELSE summary_cl.kpi1_total_residential_unit_end
    END AS kpi1_total_residential_unit_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_family_not_parents_start
        ELSE summary_cl.kpi1_suitable_living_with_family_not_parents_start
    END AS kpi1_suitable_living_with_family_not_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_family_not_parents_start
        ELSE summary_cl.kpi1_unsuitable_living_with_family_not_parents_start
    END AS kpi1_unsuitable_living_with_family_not_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_family_not_parents_end
        ELSE summary_cl.kpi1_suitable_living_with_family_not_parents_end
    END AS kpi1_suitable_living_with_family_not_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_family_not_parents_end
        ELSE summary_cl.kpi1_unsuitable_living_with_family_not_parents_end
    END AS kpi1_unsuitable_living_with_family_not_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_family_not_parents_start
        ELSE summary_cl.kpi1_total_living_with_family_not_parents_start
    END AS kpi1_total_living_with_family_not_parents_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_family_not_parents_end
        ELSE summary_cl.kpi1_total_living_with_family_not_parents_end
    END AS kpi1_total_living_with_family_not_parents_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_temporary_accom_start
        ELSE summary_cl.kpi1_suitable_temporary_accom_start
    END AS kpi1_suitable_temporary_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_temporary_accom_start
        ELSE summary_cl.kpi1_unsuitable_temporary_accom_start
    END AS kpi1_unsuitable_temporary_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_temporary_accom_end
        ELSE summary_cl.kpi1_suitable_temporary_accom_end
    END AS kpi1_suitable_temporary_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_temporary_accom_end
        ELSE summary_cl.kpi1_unsuitable_temporary_accom_end
    END AS kpi1_unsuitable_temporary_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_temporary_accom_start
        ELSE summary_cl.kpi1_total_temporary_accom_start
    END AS kpi1_total_temporary_accom_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_temporary_accom_end
        ELSE summary_cl.kpi1_total_temporary_accom_end
    END AS kpi1_total_temporary_accom_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_supported_accom_lodgings_start
        ELSE summary_cl.kpi1_suitable_supported_accom_lodgings_start
    END AS kpi1_suitable_supported_accom_lodgings_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_supported_accom_lodgings_start
        ELSE summary_cl.kpi1_unsuitable_supported_accom_lodgings_start
    END AS kpi1_unsuitable_supported_accom_lodgings_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_supported_accom_lodgings_end
        ELSE summary_cl.kpi1_suitable_supported_accom_lodgings_end
    END AS kpi1_suitable_supported_accom_lodgings_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_supported_accom_lodgings_end
        ELSE summary_cl.kpi1_unsuitable_supported_accom_lodgings_end
    END AS kpi1_unsuitable_supported_accom_lodgings_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_supported_accom_lodgings_start
        ELSE summary_cl.kpi1_total_supported_accom_lodgings_start
    END AS kpi1_total_supported_accom_lodgings_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_supported_accom_lodgings_end
        ELSE summary_cl.kpi1_total_supported_accom_lodgings_end
    END AS kpi1_total_supported_accom_lodgings_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_foster_care_start
        ELSE summary_cl.kpi1_suitable_foster_care_start
    END AS kpi1_suitable_foster_care_start,
     CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_foster_care_start
        ELSE summary_cl.kpi1_unsuitable_foster_care_start
    END AS kpi1_unsuitable_foster_care_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_foster_care_end
        ELSE summary_cl.kpi1_suitable_foster_care_end
    END AS kpi1_suitable_foster_care_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_foster_care_end
        ELSE summary_cl.kpi1_unsuitable_foster_care_end
    END AS kpi1_unsuitable_foster_care_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_foster_care_start
        ELSE summary_cl.kpi1_total_foster_care_start
    END AS kpi1_total_foster_care_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_foster_care_end
        ELSE summary_cl.kpi1_total_foster_care_end
    END AS kpi1_total_foster_care_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_friends_start
        ELSE summary_cl.kpi1_suitable_living_with_friends_start
    END AS kpi1_suitable_living_with_friends_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_friends_start
        ELSE summary_cl.kpi1_unsuitable_living_with_friends_start
    END AS kpi1_unsuitable_living_with_friends_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_living_with_friends_end
        ELSE summary_cl.kpi1_suitable_living_with_friends_end
    END AS kpi1_suitable_living_with_friends_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_living_with_friends_end
        ELSE summary_cl.kpi1_unsuitable_living_with_friends_end
    END AS kpi1_unsuitable_living_with_friends_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_friends_start
        ELSE summary_cl.kpi1_total_living_with_friends_start
    END AS kpi1_total_living_with_friends_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_living_with_friends_end
        ELSE summary_cl.kpi1_total_living_with_friends_end
    END AS kpi1_total_living_with_friends_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_stc_start
        ELSE summary_cl.kpi1_suitable_stc_start
    END AS kpi1_suitable_stc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_stc_start
        ELSE summary_cl.kpi1_unsuitable_stc_start
    END AS kpi1_unsuitable_stc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_stc_end
        ELSE summary_cl.kpi1_suitable_stc_end
    END AS kpi1_suitable_stc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_stc_end
        ELSE summary_cl.kpi1_unsuitable_stc_end
    END AS kpi1_unsuitable_stc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_stc_start
        ELSE summary_cl.kpi1_total_stc_start
    END AS kpi1_total_stc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_stc_end
        ELSE summary_cl.kpi1_total_stc_end
    END AS kpi1_total_stc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_sch_start
        ELSE summary_cl.kpi1_suitable_sch_start
    END AS kpi1_suitable_sch_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_sch_start
        ELSE summary_cl.kpi1_unsuitable_sch_start
    END AS kpi1_unsuitable_sch_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_sch_end
        ELSE summary_cl.kpi1_suitable_sch_end
    END AS kpi1_suitable_sch_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_sch_end
        ELSE summary_cl.kpi1_unsuitable_sch_end
    END AS kpi1_unsuitable_sch_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_sch_start
        ELSE summary_cl.kpi1_total_sch_start
    END AS kpi1_total_sch_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_sch_end
        ELSE summary_cl.kpi1_total_sch_end
    END AS kpi1_total_sch_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yoi_start
        ELSE summary_cl.kpi1_suitable_yoi_start
    END AS kpi1_suitable_yoi_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yoi_start
        ELSE summary_cl.kpi1_unsuitable_yoi_start
    END AS kpi1_unsuitable_yoi_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_suitable_yoi_end
        ELSE summary_cl.kpi1_suitable_yoi_end
    END AS kpi1_suitable_yoi_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_unsuitable_yoi_end
        ELSE summary_cl.kpi1_unsuitable_yoi_end
    END AS kpi1_unsuitable_yoi_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yoi_start
        ELSE summary_cl.kpi1_total_yoi_start
    END AS kpi1_total_yoi_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi1_total_yoi_end
        ELSE summary_cl.kpi1_total_yoi_end
    END AS kpi1_total_yoi_end
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    OUTER JOIN yjb_kpi_case_level.kpi1_acc_template_v8 as summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	

/* RQEV2-4p5DNbThsB */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_summary_v8 distkey (quarter_label_date) sortkey (quarter_label_date) as WITH summary_person AS (
    SELECT
        yot_code,
        label_quarter,
        -- total orders ending in period (headline denominator)
        COUNT(DISTINCT ypid) AS total_ypid
    FROM
        "yjb_returns"."yjb_kpi_case_level"."person_details_v8"
    GROUP BY
        yot_code,
        label_quarter
),
summary_cl AS (
    SELECT
        yjs_name,
        yot_code,
        label_quarter,
        area_operations,
        yjb_country,
        COUNT(DISTINCT ypid) AS kpi10_ypids_with_victims,
        COUNT(DISTINCT kpi10_victim_id) AS kpi10_total_victims,
        COUNT(DISTINCT kpi10_victim_engaged_rj) AS kpi10_victim_engaged_rj,
        COUNT(DISTINCT kpi10_rj_process) AS kpi10_rj_process,
        COUNT(DISTINCT kpi10_victim_contacted) AS kpi10_victim_contacted,
        COUNT(DISTINCT kpi10_victim_consent_contact) AS kpi10_victim_consent_contact,
        COUNT(DISTINCT kpi10_victim_view_prior) AS kpi10_victim_view_prior,
        COUNT(DISTINCT kpi10_victim_provided_info) AS kpi10_victim_provided_info,
        COUNT(DISTINCT kpi10_victim_given_support) AS kpi10_victim_given_support
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi10_victim_case_level_v8"
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
        summary_t.area_operations,
        summary_cl.area_operations
    ) AS area_operations,
    COALESCE(summary_t.yjb_country, summary_cl.yjb_country) AS yjb_country,
    COALESCE(
        summary_t.label_quarter,
        summary_cl.label_quarter
    ) AS quarter_label,
    -- getting the first date of the quarter 
    CAST(
        CASE
            WHEN SUBSTRING(quarter_label, 5, 2) = 'Q1' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-04-01')
            WHEN SUBSTRING(quarter_label, 5, 2) = 'Q2' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-07-01')
            WHEN SUBSTRING(quarter_label, 5, 2) = 'Q3' THEN CONCAT(SUBSTRING(quarter_label, 1, 4), '-10-01')
            WHEN SUBSTRING(quarter_label, 5, 2) = 'Q4' THEN CONCAT(
                CAST(SUBSTRING(quarter_label, 1, 4) AS INT) + 1,
                '-01-01'
            )
        END AS DATE
    ) AS quarter_label_date,
    'KPI 10' AS kpi_number,
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
    -- sub-measure 10c: numer of RJ processes - once this field exists in template it needs to be added here
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi10_rj_process
        ELSE NULL
    END AS kpi10_rj_process,
    -- sub-measure 10a: number of victims
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_total_victims
            ELSE summary_cl.kpi10_total_victims
        END,
        0
    ) AS kpi10_total_victims,
    -- sub-measure 10b: total ypids with victims
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_ypids_with_victims
            ELSE summary_cl.kpi10_ypids_with_victims
        END,
        0
    ) AS kpi10_ypids_with_victims,
    -- sub-measure: victim asked view on case prior / victims consented to contact
    -- numerator 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_view_prior
            ELSE summary_cl.kpi10_victim_view_prior
        END,
        0
    ) AS kpi10_victim_view_prior,
    -- sub-measure 10e: victim provided info on case/ victims consented to contact
    -- numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_provided_info
            ELSE summary_cl.kpi10_victim_provided_info
        END,
        0
    ) AS kpi10_victim_provided_info,
    -- sub-measure 10f: victims provided additional support / victims consented to contact
    --numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_given_support
            ELSE summary_cl.kpi10_victim_given_support
        END,
        0
    ) AS kpi10_victim_given_support,
    --sub-measure 10g: victims contacted by the YJS/ victim consented to being contacted
    --numerator - once this field exists in the template it needs to be added here
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi10_victim_contacted
        ELSE NULL
    END AS kpi10_victim_contacted,
    -- denominator for headline, submeasures 10d, 10e, 10f,10g: victims consented contact
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi10_victim_consent_contact
            ELSE summary_cl.kpi10_victim_consent_contact
        END,
        0
    ) AS kpi10_victim_consent_contact,
    -- denominator for submeasures 10a, 10b (need to add template figure when template has been updated)
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid
        ELSE NULL
    END AS kpi10_total_ypid
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    OUTER JOIN yjb_kpi_case_level.kpi10_victim_template_v8 AS summary_t ON summary_t.yot_code = summary_cl.yot_code
    AND summary_t.label_quarter = summary_cl.label_quarter;	
