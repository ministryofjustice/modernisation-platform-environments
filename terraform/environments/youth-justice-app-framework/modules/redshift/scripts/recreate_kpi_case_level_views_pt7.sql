SET enable_case_sensitive_identifier TO true;

/* RQEV2-f255hZCdpT */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_case_level distkey (kpi7_source_document_id) sortkey (kpi7_source_document_id) as WITH kpi7 as (
    SELECT
        dc.source_document_id as kpi7_source_document_id,
        dc.document_item."status" :: text as kpi7_status,
        dc.document_item."startDate" :: date as kpi7_start_date,
        dc.document_item."endDate" :: date as kpi7_end_date,
        kpi7_map.kpi7_status_to_description_template AS kpi7_status_to_description
    FROM
        stg.yp_doc_item AS dc
        LEFT JOIN yjb_kpi_case_level.kpi7_map kpi7_map on dc.document_item."status" = kpi7_map.kpi7_status
    WHERE
        document_item_type = 'care_status'
        AND dc.document_item."status" is not NULL
        AND dc.document_item."status" <> ''
)
SELECT
    kpi7.*,
    --case when statement adds two categories that were on template but not in kpi7_status_to_description (open to early help prior & referred to early help)
    CASE
        WHEN kpi7.kpi7_status = 'Early Help referral'
        AND kpi7.kpi7_start_date < person_details.intervention_start_date THEN 'Number of children who were already open to Early Help services prior to start of order'
        WHEN kpi7.kpi7_status = 'Early Help referral'
        AND kpi7.kpi7_start_date >= person_details.intervention_start_date THEN 'Number of children referred to Early Help services'
        ELSE kpi7.kpi7_status_to_description
    END AS kpi7_status_to_description_template,
    -- kpi7 status at the start of the order
    CASE
        WHEN yjb_kpi_case_level.f_isatstart(
            kpi7.kpi7_start_date,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date
        ) THEN TRUE
        ELSE FALSE
    END AS kpi7_is_at_start,
    -- kpi7 status at the end of the order
    CASE
        WHEN yjb_kpi_case_level.f_isatend(
            kpi7.kpi7_end_date,
            person_details.intervention_end_date
        ) THEN TRUE
        ELSE FALSE
    END AS kpi7_is_at_end,
    person_details.*,
    --headline measure: total supported by wider services at the end
    CASE
        WHEN kpi7_is_at_end = TRUE
        AND kpi7_status_to_description_template IN (
            'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
            'Number of children on a Child Protection Plan',
            'Number of children who are Children in Need/Children in Need of care and support (Wales)',
            'Number of children on an Early Intervention plan'
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi7_supported_by_wider_services,
    --submeasure: care experienced child (Looked After Child) at start and end of order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_care_experienced_start,
    CASE
        WHEN kpi7_is_at_end = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_care_experienced_end,
    --submeasure: Child Protection Plan at the start of the order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children on a Child Protection Plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_protection_plan_start,
    CASE
        WHEN kpi7_is_at_end = TRUE
        AND kpi7_status_to_description_template = 'Number of children on a Child Protection Plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_protection_plan_end,
    --submeasure: Children in Need (England) / Children in Need of care and supprot (Wales) at the start of the order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_in_need_start,
    CASE
        WHEN kpi7_is_at_end = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_in_need_end,
    --submeasure: Children on Early Intervention Plan at the start of the order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children on an Early Intervention plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_early_intervention_plan_start,
    CASE
        WHEN kpi7_is_at_end = TRUE
        AND kpi7_status_to_description_template = 'Number of children on an Early Intervention plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_early_intervention_plan_end,
    --submeasure: Children on Early Help services at the start of the order
    CASE
        WHEN kpi7_status_to_description_template = 'Number of children who were already open to Early Help services prior to start of order' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_open_early_help_prior,
    CASE
        WHEN kpi7_status_to_description_template = 'Number of children referred to Early Help services' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_referred_to_early_help
FROM
    kpi7
    INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi7.kpi7_source_document_id = person_details.source_document_id
WHERE
    --only take kpi7 status that were relevant to the order / started before the end of the order. we dont care about KPI7 status after the intervention has ended.
    kpi7.kpi7_start_date <= person_details.intervention_end_date --kpi7 status end date should be on or after the order started or still be open unless it was a Early Help referral referral
    AND (
        --when there was an early help referral then it can happen before the intervention start date
        (
            kpi7.kpi7_status = 'Early Help referral'
            AND kpi7.kpi7_end_date <= person_details.intervention_end_date
        )
        OR (
            --non-custodial orders the kpi7 status has to have ended on or after the intervention start date to be relevant to one of the measures (i.e. don't want it ending before order begins)
            person_details.legal_outcome_group_fixed <> 'Custody' -- AND kpi7_status <> 'Early Help referral'
            AND kpi7.kpi7_end_date >= person_details.intervention_start_date
        )
        OR (
            --custodial orders the kpi7 stat has to have ended on or after the day before the outcome date which is also the intervention start date for custodial sentences
            person_details.legal_outcome_group_fixed = 'Custody' -- AND kpi7_status <> 'Early Help referral'
            AND kpi7.kpi7_end_date >= DATEADD(d, -1, person_details.outcome_date)
        ) --or KPI7 status can still open
        OR kpi7.kpi7_end_date = '1900-01-01'
    );	
/* RQEV2-TH1sX7QWch */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_case_level_v8 distkey (kpi7_source_document_id) sortkey (kpi7_source_document_id) as WITH kpi7 as (
    SELECT
        dc.source_document_id as kpi7_source_document_id,
        dc.document_item."status" :: text as kpi7_status,
        dc.document_item."startDate" :: date as kpi7_start_date,
        dc.document_item."endDate" :: date as kpi7_end_date,
        kpi7_map.kpi7_status_to_description_template AS kpi7_status_to_description
    FROM
        stg.yp_doc_item AS dc
        LEFT JOIN yjb_kpi_case_level.kpi7_map kpi7_map on dc.document_item."status" = kpi7_map.kpi7_status
    WHERE
        document_item_type = 'care_status'
        AND dc.document_item."status" is not NULL
        AND dc.document_item."status" <> ''
)
SELECT
    kpi7.*,
    --case when statement adds two categories that were on template but not in kpi7_status_to_description (open to early help prior & referred to early help)
    CASE
        WHEN kpi7.kpi7_status = 'Early Help referral'
        AND kpi7.kpi7_start_date < person_details.intervention_start_date THEN 'Number of children who were already open to Early Help services prior to start of order'
        WHEN kpi7.kpi7_status = 'Early Help referral'
        AND kpi7.kpi7_start_date >= person_details.intervention_start_date THEN 'Number of children referred to Early Help services'
        ELSE kpi7.kpi7_status_to_description
    END AS kpi7_status_to_description_template,
    -- kpi7 care status was only at the start of the order
    CASE
        WHEN yjb_kpi_case_level.f_isatstart(
            kpi7.kpi7_start_date,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date
        ) THEN TRUE
        ELSE FALSE
    END AS kpi7_is_at_start,
    -- kpi7 care status was at the start, during or end of the order - it's possible to be have a care status only in the middle of the order and not start and end
    -- includes care statuses only at start, only during and only at end, or a combination of the three
    CASE
        WHEN yjb_kpi_case_level.f_isduring(
            kpi7_start_date,
            intervention_start_date,
            intervention_end_date,
            disposal_type_fixed,
            outcome_date
        ) THEN TRUE
        ELSE FALSE
    END AS kpi7_is_during,
    -- kpi7 care status was only at the end of the order
    CASE
        WHEN yjb_kpi_case_level.f_isatend(
            kpi7.kpi7_end_date,
            person_details.intervention_end_date
        ) THEN TRUE
        ELSE FALSE
    END AS kpi7_is_at_end,
    person_details.*,
    --headline measure: total supported by wider services at any point during the order 
    CASE
        WHEN kpi7_is_during = TRUE
        AND kpi7_status_to_description_template IN (
            'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
            'Number of children on a Child Protection Plan',
            'Number of children who are Children in Need/Children in Need of care and support (Wales)',
            'Number of children on an Early Intervention plan'
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi7_supported_by_wider_services,
    --submeasure: care experienced child (Looked After Child) at start and end of order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_care_experienced_start,
    CASE
        WHEN kpi7_is_during = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_care_experienced_during,
    --submeasure: Child Protection Plan at the start of the order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children on a Child Protection Plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_protection_plan_start,
    CASE
        WHEN kpi7_is_during = TRUE
        AND kpi7_status_to_description_template = 'Number of children on a Child Protection Plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_protection_plan_during,
    --submeasure: Children in Need (England) / Children in Need of care and supprot (Wales) at the start of the order
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_in_need_start,
    CASE
        WHEN kpi7_is_during = TRUE
        AND kpi7_status_to_description_template = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_child_in_need_during,
    -- --submeasure: Children on Early Intervention Plan at the start of the order
    --renaming early intervention plan to early help plan as they are the same thing and this will reduce confusion
    CASE
        WHEN kpi7_is_at_start = TRUE
        AND kpi7_status_to_description_template = 'Number of children on an Early Intervention plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_early_help_plan_start,
    CASE
        WHEN kpi7_is_during = TRUE
        AND kpi7_status_to_description_template = 'Number of children on an Early Intervention plan' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_early_help_plan_during,
    --submeasure: Children on Early Help services at the start of the order
    CASE
        WHEN kpi7_status_to_description_template = 'Number of children who were already open to Early Help services prior to start of order' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_open_early_help_prior,
    CASE
        WHEN kpi7_status_to_description_template = 'Number of children referred to Early Help services' THEN person_details.ypid
        ELSE NULL
    END AS kpi7_referred_to_early_help,
    --submeasure: children supported by wider services during their order broken down by type of order
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Non-substantive out of court disposals with YJS intervention' THEN ypid
    END AS kpi7_supported_oocd,
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Youth Cautions with YJS intervention' THEN ypid
    END AS kpi7_supported_yc_with_yjs,
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Youth Conditional Cautions' THEN ypid
    END AS kpi7_supported_ycc,
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Referral Orders' THEN ypid
    END AS kpi7_supported_ro,
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Youth Rehabilitation Orders' THEN ypid
    END AS kpi7_supported_yro,
    CASE
        WHEN kpi7_supported_by_wider_services = ypid
        AND type_of_order = 'Custodial sentences' THEN ypid
    END AS kpi7_supported_cust
FROM
    kpi7
    INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi7.kpi7_source_document_id = person_details.source_document_id
WHERE
    --only take kpi7 status that were relevant to the order / started before the end of the order. we dont care about KPI7 status after the intervention has ended.
    kpi7.kpi7_start_date <= person_details.intervention_end_date --kpi7 status end date should be on or after the order started or still be open unless it was a Early Help referral referral
    AND (
        --when there was an early help referral then it can happen before the intervention start date
        (
            kpi7.kpi7_status = 'Early Help referral'
            AND kpi7.kpi7_end_date <= person_details.intervention_start_date
        )
        OR (
            --non-custodial orders the kpi7 status has to have ended on or after the intervention start date to be relevant to one of the measures (i.e. don't want it ending before order begins)
            person_details.legal_outcome_group_fixed <> 'Custody'
            AND kpi7.kpi7_end_date >= person_details.intervention_start_date
        )
        OR (
            --custodial orders the kpi7 stat has to have ended on or after the day before the outcome date which is also the intervention start date for custodial sentences (due to disposal type being split up in custody and licence)
            person_details.legal_outcome_group_fixed = 'Custody'
            AND kpi7.kpi7_end_date >= DATEADD(d, -1, person_details.outcome_date)
        ) --or KPI7 status can still open
        OR kpi7.kpi7_end_date = '1900-01-01'
    );	
/* RQEV2-Rc8ywAgGZL */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        --orders ending in the period (denominator for all kpi7 measures)
        COUNT(DISTINCT ypid) AS total_ypid
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
        yot_code,
        yjs_name,
        label_quarter,
        --headline numerator
        COUNT(DISTINCT kpi7_supported_by_wider_services) AS kpi7_supported_by_wider_services,
        --submeasures numerators
        COUNT(DISTINCT kpi7_care_experienced_start) AS kpi7_care_experienced_start,
        COUNT(DISTINCT kpi7_care_experienced_end) AS kpi7_care_experienced_end,
        COUNT(DISTINCT kpi7_child_protection_plan_start) AS kpi7_child_protection_plan_start,
        COUNT(DISTINCT kpi7_child_protection_plan_end) AS kpi7_child_protection_plan_end,
        COUNT(DISTINCT kpi7_child_in_need_start) AS kpi7_child_in_need_start,
        COUNT(DISTINCT kpi7_child_in_need_end) AS kpi7_child_in_need_end,
        COUNT(DISTINCT kpi7_early_intervention_plan_start) AS kpi7_early_intervention_plan_start,
        COUNT(DISTINCT kpi7_early_intervention_plan_end) AS kpi7_early_intervention_plan_end,
        COUNT(DISTINCT kpi7_open_early_help_prior) AS kpi7_open_early_help_prior,
        COUNT(DISTINCT kpi7_referred_to_early_help) AS kpi7_referred_to_early_help
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi7_wider_services_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter
)
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
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi7_supported_by_wider_services > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --denominator for all measures
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS total_ypid,
    --headline numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_by_wider_services
            ELSE summary_cl.kpi7_supported_by_wider_services
        END,
        0
    ) AS kpi7_supported_by_wider_services,
    --submeasure numerators
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_care_experienced_start
            ELSE summary_cl.kpi7_care_experienced_start
        END,
        0
    ) AS kpi7_care_experienced_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_care_experienced_end
            ELSE summary_cl.kpi7_care_experienced_end
        END,
        0
    ) AS kpi7_care_experienced_end,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_protection_plan_start
            ELSE summary_cl.kpi7_child_protection_plan_start
        END,
        0
    ) AS kpi7_child_protection_plan_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_protection_plan_end
            ELSE summary_cl.kpi7_child_protection_plan_end
        END,
        0
    ) AS kpi7_child_protection_plan_end,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_in_need_start
            ELSE summary_cl.kpi7_child_in_need_start
        END,
        0
    ) AS kpi7_child_in_need_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_in_need_end
            ELSE summary_cl.kpi7_child_in_need_end
        END,
        0
    ) AS kpi7_child_in_need_end,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_early_intervention_plan_start
            ELSE summary_cl.kpi7_early_intervention_plan_start
        END,
        0
    ) AS kpi7_early_intervention_plan_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_early_intervention_plan_end
            ELSE summary_cl.kpi7_early_intervention_plan_end
        END,
        0
    ) AS kpi7_early_intervention_plan_end,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_open_early_help_prior
            ELSE summary_cl.kpi7_open_early_help_prior
        END,
        0
    ) AS kpi7_open_early_help_prior,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_referred_to_early_help
            ELSE summary_cl.kpi7_referred_to_early_help
        END,
        0
    ) AS kpi7_referred_to_early_help
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.yjs_name = summary_person.yjs_name
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    OUTER JOIN yjb_kpi_case_level.kpi7_wider_services_template AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.yjs_name = summary_person.yjs_name
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-k4xUWCNElx */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        return_status_id,
        reporting_date,
        yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        --new label quarter for the correct ordering in tableau graphs
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        description,
        ws_total AS out_court_no_yjs_total,
        ws_start AS out_court_no_yjs_start,
        ws_end AS out_court_no_yjs_end,
        yjs_total AS yc_with_yjs_total,
        yjs_start AS yc_with_yjs_start,
        yjs_end AS yc_with_yjs_end,
        ycc_total,
        ycc_start,
        ycc_end,
        ro_total,
        ro_start,
        ro_end,
        yro_total,
        yro_start,
        yro_end,
        cust_total,
        cust_start,
        cust_end,
        month_number,
        month_name,
        year_number,
        quarter_number,
        quarter_name
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi7_ws_v1" AS kpi7
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi7.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi7.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --denominator for headline and submeasure 7a-7c: total orders ending in the period
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN out_court_no_yjs_total + yc_with_yjs_total + ycc_total + ro_total + yro_total + cust_total
            ELSE NULL
        END
    ) AS total_ypid,
    --headline measure numerator: total children supported by wider services at the end of the order
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_supported_by_wider_services,
    --sub-measure 7a
    --care experienced child/Looked After Child start the order
    SUM(
        CASE
            WHEN description = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_care_experienced_start,
    --Child Protection Plan start the order
    SUM(
        CASE
            WHEN description = 'Number of children on a Child Protection Plan' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_child_protection_plan_start,
    --Children in Need (England) / Children in Need of care and supprot (Wales) at the start of the order
    SUM(
        CASE
            WHEN description = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_child_in_need_start,
     --Children on Early Help Plan at the start of the order
    SUM(
        CASE
            WHEN description = 'Number of children on an Early Intervention plan' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_early_help_plan_start,
    --sub-measure 7b
    --care experienced child/Looked After Child during the order
    SUM(
        CASE
            WHEN description = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_care_experienced_during,
    --care experienced child/Looked After Child durring the order
    SUM(
        CASE
            WHEN description = 'Number of children on a Child Protection Plan' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_child_protection_plan_during,
    --Children in Need (England) / Children in Need of care and supprot (Wales) during of the order
    SUM(
        CASE
            WHEN description = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_child_in_need_during,
   --Children on Early Help Plan at the during of the order
    SUM(
        CASE
            WHEN description = 'Number of children on an Early Intervention plan' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_early_help_plan_during,
    --sub-measure 7c: Children referred to Early Help services before the start of the order or during 
    SUM(
        CASE
            WHEN description = 'Number of children who were already open to Early Help services prior to start of order' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_open_early_help_prior,
    SUM(
        CASE
            WHEN description = 'Number of children referred to Early Help services' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_referred_to_early_help,
    --sub-measure 7d: children supported by wider services broken down by type of order
    --numerators
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN out_court_no_yjs_end
            ELSE NULL
        END
    ) AS kpi7_supported_oocd,
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN yc_with_yjs_end
            ELSE NULL
        END
    ) AS kpi7_supported_yc_with_yjs,
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN ycc_end
            ELSE NULL
        END
    ) AS kpi7_supported_ycc,
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN ro_end
            ELSE NULL
        END
    ) AS kpi7_supported_ro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN yro_end
            ELSE NULL
        END
    ) AS kpi7_supported_yro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children who are a currently care experienced child (known in statute as a Looked After Child)',
                'Number of children on a Child Protection Plan',
                'Number of children who are Children in Need/Children in Need of care and support (Wales)',
                'Number of children on an Early Intervention plan'
            ) THEN cust_end
            ELSE NULL
        END
    ) AS kpi7_supported_cust,
    --denominator for sub-measure 7d:
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN out_court_no_yjs_total 
            ELSE NULL
        END
    ) AS kpi7_total_ypid_oocd,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yc_with_yjs_total
            ELSE NULL
        END
    ) AS kpi7_total_ypid_yc_with_yjs,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ycc_total
            ELSE NULL
        END
    ) AS kpi7_total_ypid_ycc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ro_total
            ELSE NULL
        END
    ) AS kpi7_total_ypid_ro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yro_total
            ELSE NULL
        END
    ) AS kpi7_total_ypid_yro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN cust_total
            ELSE NULL
        END
    ) AS kpi7_total_ypid_cust
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

/* RQEV2-UZcAmurdE6 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        --denominator for headline and submeasures 7a-c: orders ending in the period 
        COUNT(DISTINCT ypid) AS total_ypid,
        -- submeasure 7d denominator: total by type of order 
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
        ) AS total_ypid_yc_with_yjs,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Conditional Cautions' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ycc,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Rehabilitation Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_yro,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Referral Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ro,
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
        yot_code,
        yjs_name,
        label_quarter,
        --headline numerator
        COUNT(DISTINCT kpi7_supported_by_wider_services) AS kpi7_supported_by_wider_services,
        --submeasures numerators
        COUNT(DISTINCT kpi7_care_experienced_start) AS kpi7_care_experienced_start,
        COUNT(DISTINCT kpi7_care_experienced_during) AS kpi7_care_experienced_during,
        COUNT(DISTINCT kpi7_child_protection_plan_start) AS kpi7_child_protection_plan_start,
        COUNT(DISTINCT kpi7_child_protection_plan_during) AS kpi7_child_protection_plan_during,
        COUNT(DISTINCT kpi7_child_in_need_start) AS kpi7_child_in_need_start,
        COUNT(DISTINCT kpi7_child_in_need_during) AS kpi7_child_in_need_during,
        COUNT(DISTINCT kpi7_early_help_plan_start) AS kpi7_early_help_plan_start,
        COUNT(DISTINCT kpi7_early_help_plan_during) AS kpi7_early_help_plan_during,
        COUNT(DISTINCT kpi7_open_early_help_prior) AS kpi7_open_early_help_prior,
        COUNT(DISTINCT kpi7_referred_to_early_help) AS kpi7_referred_to_early_help,
        COUNT(DISTINCT kpi7_supported_oocd) AS kpi7_supported_oocd,
        COUNT(DISTINCT kpi7_supported_yc_with_yjs) AS kpi7_supported_yc_with_yjs,
        COUNT(DISTINCT kpi7_supported_ycc) AS kpi7_supported_ycc,
        COUNT(DISTINCT kpi7_supported_ro) AS kpi7_supported_ro,
        COUNT(DISTINCT kpi7_supported_yro) AS kpi7_supported_yro,
        COUNT(DISTINCT kpi7_supported_cust) AS kpi7_supported_cust
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi7_wider_services_case_level_v8"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter
)
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
    -- financial quarter 
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
            )
        END AS DATE
    ) AS quarter_label_date,
    'KPI 7' AS kpi_number,
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi7_supported_by_wider_services > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --denominator for headline and submeasures 7a-c
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS kpi7_total_ypid,
    --headline numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_by_wider_services
            ELSE summary_cl.kpi7_supported_by_wider_services
        END,
        0
    ) AS kpi7_supported_by_wider_services_during,
    --sub-measure 7a-b numerators
    --care experienced child (Looked After Child) 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_care_experienced_start
            ELSE summary_cl.kpi7_care_experienced_start
        END,
        0
    ) AS kpi7_care_experienced_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_care_experienced_during
            ELSE summary_cl.kpi7_care_experienced_during
        END,
        0
    ) AS kpi7_care_experienced_during,
    --children on a child protection plan 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_protection_plan_start
            ELSE summary_cl.kpi7_child_protection_plan_start
        END,
        0
    ) AS kpi7_child_protection_plan_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_protection_plan_during
            ELSE summary_cl.kpi7_child_protection_plan_during
        END,
        0
    ) AS kpi7_child_protection_plan_during,
    --children in need / children in need of care and support
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_in_need_start
            ELSE summary_cl.kpi7_child_in_need_start
        END,
        0
    ) AS kpi7_child_in_need_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_child_in_need_during
            ELSE summary_cl.kpi7_child_in_need_during
        END,
        0
    ) AS kpi7_child_in_need_during,
    --children on an early help plan
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_early_help_plan_start
            ELSE summary_cl.kpi7_early_help_plan_start
        END,
        0
    ) AS kpi7_early_help_plan_start,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_early_help_plan_during
            ELSE summary_cl.kpi7_early_help_plan_during
        END,
        0
    ) AS kpi7_early_help_plan_during,
    --submeasure 7c: children referred to early help before and after the start ofthe order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_open_early_help_prior
            ELSE summary_cl.kpi7_open_early_help_prior
        END,
        0
    ) AS kpi7_open_early_help_prior,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_referred_to_early_help
            ELSE summary_cl.kpi7_referred_to_early_help
        END,
        0
    ) AS kpi7_referred_to_early_help_during,
    --submeasure 7d numerators: broken down by type of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_oocd
            ELSE summary_cl.kpi7_supported_oocd
        END,
        0
    ) AS kpi7_supported_oocd_during,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_yc_with_yjs
            ELSE summary_cl.kpi7_supported_yc_with_yjs
        END,
        0
    ) AS kpi7_supported_yc_with_yjs_during,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_ycc
            ELSE summary_cl.kpi7_supported_ycc
        END,
        0
    ) AS kpi7_supported_ycc_during,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_ro
            ELSE summary_cl.kpi7_supported_ro
        END,
        0
    ) AS kpi7_supported_ro_during,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_yro
            ELSE summary_cl.kpi7_supported_yro
        END,
        0
    ) AS kpi7_supported_yro_during,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_supported_cust
            ELSE summary_cl.kpi7_supported_cust
        END,
        0
    ) AS kpi7_supported_cust_during,
    --submeasure 7d denominator: total by type of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_oocd
            ELSE summary_person.total_ypid_oocd
        END,
        0
    ) AS kpi7_total_ypid_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_yc_with_yjs
            ELSE summary_person.total_ypid_yc_with_yjs
        END,
        0
    ) AS kpi7_total_ypid_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_ycc
            ELSE summary_person.total_ypid_ycc
        END,
        0
    ) AS kpi7_total_ypid_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_ro
            ELSE summary_person.total_ypid_ro
        END,
        0
    ) AS kpi7_total_ypid_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_yro
            ELSE summary_person.total_ypid_yro
        END,
        0
    ) AS kpi7_total_ypid_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi7_total_ypid_cust
            ELSE summary_person.total_ypid_cust
        END,
        0
    ) AS kpi7_total_ypid_cust
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.yjs_name = summary_person.yjs_name
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    OUTER JOIN yjb_kpi_case_level.kpi7_wider_services_template_v8 AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.yjs_name = summary_person.yjs_name
    AND summary_t.label_quarter = summary_person.label_quarter;	

/* RQEV2-znipJeKCls */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
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
    'Wider Services' AS kpi_name,
    'Children receiving support from wider care services' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable - will be blank but need to column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%unsuitable%' THEN 'Unsuitable'
        WHEN unpvt_table.measure_numerator LIKE '%suitable%' THEN 'Suitable'
        ELSE NULL
    END AS suitability,
    -- whether the measure_numerator is calculating successfully or not completed OOCDs - will be blank but need column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%not_completed%' THEN 'Not completed'
        WHEN unpvt_table.measure_numerator LIKE '%successful%' THEN 'Successfully completed'
        ELSE NULL
    END AS completion,
    -- level of seniority - will be blank here but need column for union all long formats later
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
        /*overall measure / headline */
        WHEN unpvt_table.measure_numerator LIKE '%supported_by_wider_services%' THEN 'Supported by wider services'
        /* types of care status */
        WHEN unpvt_table.measure_numerator LIKE '%care_experienced%' THEN 'Care Experienced Child'
        WHEN unpvt_table.measure_numerator LIKE '%child_in_need%' THEN 'Child in Need (England) / Child in Need of Care and Support (Wales)'
        WHEN unpvt_table.measure_numerator LIKE '%child_protection_plan%' THEN 'Child Protection Plan'
        WHEN unpvt_table.measure_numerator LIKE '%early_help_plan%' THEN 'Early Help Plan'
        /* referral to Early Help */
        WHEN unpvt_table.measure_numerator LIKE '%open_early_help%' THEN 'Open to Early Help before start of order'
        WHEN unpvt_table.measure_numerator LIKE '%referred_to_early_help%' THEN 'Referred to Early Help during order'
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'Out of court disposals'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'Youth rehabilitation orders'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'Referral orders'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'Custodial sentences'
    END AS measure_category,
    --short description of measure
    CASE
        WHEN measure_category IN (
            'Care Experienced Child',
            'Child in Need (England) / Child in Need of Care and Support (Wales)',
            'Child Protection Plan',
            'Early Help Plan'
        )
        AND time_point = 'Start' THEN 'Care status at the start of the order'
        WHEN measure_category IN (
            'Care Experienced Child',
            'Child in Need (England) / Child in Need of Care and Support (Wales)',
            'Child Protection Plan',
            'Early Help Plan'
        )
        AND time_point = 'During' THEN 'Care status at during of the order'
        WHEN measure_category IN (
            'Open to Early Help before start of order',
            'Referred to Early Help during order'
        ) THEN 'Referral to Early Help'
        WHEN measure_category IN (
            'Out of court disposals',
            'Youth cautions with YJS intervention',
            'Youth conditional cautions',
            'Referral orders',
            'Youth rehabilitation orders',
            'Custodial sentences'
        ) THEN 'Type of order'
        ELSE 'Supported by wider services'
    END AS measure_short_description,
    -- full wording of measure
    CASE
        WHEN measure_short_description = 'Care status at the start of the order' THEN 'Children already supported by wider care services when their order started broken down by support type'
        WHEN measure_short_description = 'Care status at during of the order' THEN 'Children supported by wider care services during their order broken down by support type'
        WHEN measure_short_description = 'Referral to Early Help' THEN 'Children who were referred to Early Help before and after the start of their order'
        WHEN measure_short_description = 'Type of order' THEN 'Children supported by wider care services during their order broken down by type of order'
        ELSE 'Proportion of children supported by wider care services during their order'
    END AS measure_long_description,
    -- whether the measure is the headline measure
    CASE
        WHEN measure_short_description = 'Supported by wider services' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    -- measure numbering
    CASE
        WHEN measure_short_description = 'Supported by wider services' THEN 'Headline'
        WHEN measure_short_description = 'Care status at the start of the order' THEN '7a'
        WHEN measure_short_description = 'Care status at during of the order' THEN '7b'
        WHEN measure_short_description = 'Referral to Early Help' THEN '7c'
        ELSE '7d'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        WHEN measure_category = 'Out of court disposals' THEN 'kpi7_total_ypid_oocd'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi7_total_ypid_yc_with_yjs'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi7_total_ypid_ycc'
        WHEN measure_category = 'Referral orders' THEN 'kpi7_total_ypid_ro'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi7_total_ypid_yro'
        WHEN measure_category = 'Custodial sentences' THEN 'kpi7_total_ypid_cust'
        ELSE 'kpi7_total_ypid'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        WHEN measure_category = 'Out of court disposals' THEN kpi7_total_ypid_oocd
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN kpi7_total_ypid_yc_with_yjs
        WHEN measure_category = 'Youth conditional cautions' THEN kpi7_total_ypid_ycc
        WHEN measure_category = 'Referral orders' THEN kpi7_total_ypid_ro
        WHEN measure_category = 'Youth rehabilitation orders' THEN kpi7_total_ypid_yro
        WHEN measure_category = 'Custodial sentences' THEN kpi7_total_ypid_cust
        ELSE kpi7_total_ypid
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children supported by wider services'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an order ending'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi7_wider_services_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi7_care_experienced_during,
            kpi7_care_experienced_start,
            kpi7_child_in_need_during,
            kpi7_child_in_need_start,
            kpi7_child_protection_plan_during,
            kpi7_child_protection_plan_start,
            kpi7_early_help_plan_during,
            kpi7_early_help_plan_start,
            kpi7_open_early_help_prior,
            kpi7_referred_to_early_help_during,
            kpi7_supported_by_wider_services_during,
            kpi7_supported_cust_during,
            kpi7_supported_oocd_during,
            kpi7_supported_ro_during,
            kpi7_supported_yc_with_yjs_during,
            kpi7_supported_ycc_during,
            kpi7_supported_yro_during
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
/* RQEV2-26BvMYgFhX */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi8_summary distkey (return_status_id) sortkey (return_status_id) as WITH template AS (
    SELECT
        kpi8.return_status_id,
        kpi8.reporting_date,
        kpi8.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        --new format for label_quarter - YYYYQQ
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi8.description,
        kpi8.senior_a_attended,
        kpi8.senior_a_not,
        kpi8.senior_b_attended,
        kpi8.senior_b_not,
        kpi8.senior_c_attended,
        kpi8.senior_c_not,
        kpi8.senior_d_attended,
        kpi8.senior_d_not,
        kpi8.senior_e_attended,
        kpi8.senior_e_not,
        kpi8.senior_other_attended,
        kpi8.senior_other_not
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi8_mba_v1" AS kpi8
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi8.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi8.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    -- headline measure: total senior partners attending management boards --Agreed not to include 'senior_other_attended'
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_a_attended + senior_b_attended + senior_c_attended + senior_d_attended + senior_e_attended
        END
    ) AS total_senior_attended,
    -- sub-measure: number senior partners by role (should this be attended by role? rather than total number?)
    SUM(-- MAX(
        CASE
            WHEN description = 'Senior partner'
            AND senior_a_attended > 0 THEN 1
            ELSE 0
        END
    ) -- ) = 1 
    AS senior_LA_children_social_care_attended,
    SUM(-- MAX(
        CASE
            WHEN description = 'Senior partner'
            AND senior_b_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS senior_LA_education_attended,
   SUM( -- MAX(
        CASE
            WHEN description = 'Senior partner'
            AND senior_c_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
   ) AS senior_police_attended,
   SUM( -- MAX(
        CASE
            WHEN description = 'Senior partner'
            AND senior_d_attended > 0 THEN 1
            ELSE 0
        END
    ) -- ) = 1 
    AS senior_probation_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'Senior partner'
            AND senior_e_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS senior_health_attended,
    -- sub-measure: total junior partners attending
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_a_attended + senior_b_attended + senior_c_attended + senior_d_attended + senior_e_attended
        END
    ) AS total_junior_attended,
    -- sub-measure: number junior partners attending by role (attended by role? rather than total number?)
    SUM( -- MAX(
        CASE
            WHEN description = 'Delegated or non-senior partner'
            AND senior_a_attended > 0 THEN 1
            ELSE 0
        END
    ) -- ) = 1 
    AS junior_LA_children_social_care_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'Delegated or non-senior partner'
            AND senior_b_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS junior_LA_education_attended,
    SUM(-- MAX(
        CASE
            WHEN description = 'Delegated or non-senior partner'
            AND senior_c_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS junior_police_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'Delegated or non-senior partner'
            AND senior_d_attended > 0 THEN 1
            ELSE 0
        END
    ) -- ) = 1 
    AS junior_probation_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'Delegated or non-senior partner'
            AND senior_e_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS junior_health_attended,
    -- Number of new attendees by role (again why number if this is binary???)
    SUM( -- MAX(
        CASE
            WHEN description = 'If attended - was this a new partner?'
            AND senior_a_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS new_LA_children_social_care_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'If attended - was this a new partner?'
            AND senior_b_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS new_LA_education_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'If attended - was this a new partner?'
            AND senior_c_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS new_police_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'If attended - was this a new partner?'
            AND senior_d_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS new_probation_attended,
    SUM( -- MAX(
        CASE
            WHEN description = 'If attended - was this a new partner?'
            AND senior_e_attended > 0 THEN 1
            ELSE 0
        END
    -- ) = 1 
    ) AS new_health_attended
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
/* RQEV2-QWwkpxovTY */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi8_summary_v8 distkey (return_status_id) sortkey (return_status_id) as WITH template AS (
    SELECT
        kpi8.return_status_id,
        kpi8.reporting_date,
        kpi8.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        --new format for label_quarter - YYYYQQ
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS quarter_label,
        kpi8.description,
        kpi8.senior_a_attended,
        kpi8.senior_a_not,
        kpi8.senior_b_attended,
        kpi8.senior_b_not,
        kpi8.senior_c_attended,
        kpi8.senior_c_not,
        kpi8.senior_d_attended,
        kpi8.senior_d_not,
        kpi8.senior_e_attended,
        kpi8.senior_e_not,
        kpi8.senior_other_attended,
        kpi8.senior_other_not
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi8_mba_v1" AS kpi8
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi8.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi8.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    quarter_label,
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
    'KPI 8' AS kpi_number,
    -- need source_data_flag in order to have all the same columns for the unioned long format data of all kpis
    'Data from template' AS source_data_flag,
    -- headline measure: total number of sectors represented by senior partners at management boards 
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_a_attended + senior_b_attended + senior_c_attended + senior_d_attended + senior_e_attended
        END
    ) AS kpi8_total_senior_attended,
    -- sub-measure 8a: senior partners attendance by sector 
    -- LA Children's social care
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_a_attended
        END
    ) AS kpi8_senior_LA_children_social_care_attended,
    -- LA Education
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_b_attended
        END
    ) AS kpi8_senior_LA_education_attended,
    -- Police
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_c_attended
        END
    ) AS kpi8_senior_police_attended,
    -- Probation
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_d_attended
        END
    ) AS kpi8_senior_probation_attended,
    -- Health 
    SUM(
        CASE
            WHEN description = 'Senior partner' THEN senior_e_attended
        END
    ) AS kpi8_senior_health_attended,
    -- sub-measure: total junior partners attending
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_a_attended + senior_b_attended + senior_c_attended + senior_d_attended + senior_e_attended
        END
    ) AS kpi8_total_junior_attended,
    -- sub-measure: number junior partners attending by sector
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_a_attended
        END
    ) AS kpi8_junior_LA_children_social_care_attended,
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_b_attended
        END
    ) AS kpi8_junior_LA_education_attended,
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_c_attended
        END
    ) AS kpi8_junior_police_attended,
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_d_attended
        END
    ) AS kpi8_junior_probation_attended,
    SUM(
        CASE
            WHEN description = 'Delegated or non-senior partner' THEN senior_e_attended
        END
    ) AS kpi8_junior_health_attended 
FROM
    template
GROUP BY
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    quarter_label,
    source_data_flag;	

/* RQEV2-LG7gZEth1S */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi8_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
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
    'MB attendance' AS kpi_name,
    'Senior partner attending YJS Management Boards' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE 'end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable - will be blank but need column to union all long formats later
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%unsuitable%' THEN 'Unsuitable'
        WHEN unpvt_table.measure_numerator LIKE '%suitable%' THEN 'Suitable'
        ELSE NULL
    END AS suitability,
    -- whether the measure_numerator is calculating successfully or not completed OOCDs - will be blank but need column to union all long formats later
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
        /* overall measures: headline & 8b */
        WHEN unpvt_table.measure_numerator LIKE '%total%' THEN 'Total attendees'
        /* sector */
        WHEN unpvt_table.measure_numerator LIKE '%social_care%' THEN 'LA children social care'
        WHEN unpvt_table.measure_numerator LIKE '%education%' THEN 'LA education'
        WHEN unpvt_table.measure_numerator LIKE '%police%' THEN 'Police'
        WHEN unpvt_table.measure_numerator LIKE '%probation%' THEN 'Probation'
        WHEN unpvt_table.measure_numerator LIKE '%health%' THEN 'Health'
    END AS measure_category,
    --short description of measure
    CASE
        WHEN measure_category = 'Total attendees'
        AND seniority = 'Senior' THEN 'Total senior attendance'
        WHEN measure_category IN (
            'LA children social care',
            'LA education',
            'Police',
            'Probation',
            'Health'
        )
        AND seniority = 'Senior' THEN 'Senior attendance by sector'
        WHEN measure_category = 'Total attendees'
        AND seniority = 'Delegated' THEN 'Total delegated attendance'
        ELSE 'Delegated attendance by sector'
    END AS measure_short_description,
    -- full wording of measure
    CASE
        WHEN measure_short_description = 'Total senior attendance' THEN 'Total number of sectors out of five that were represented by a senior partner attending management boards (MBs)'
        WHEN measure_short_description = 'Senior attendance by sector' THEN 'Senior partners attending by sector'
        WHEN measure_short_description = 'Delegated attendance by sector' THEN 'Delegated partners attending by sector'
        ELSE 'Total number of sectors out of five that were represented by a delegated partner attending MBs'
    END AS measure_long_description,
    -- whether the measure is the headline measure
    CASE
        WHEN measure_short_description = 'Total senior attendance' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    -- measure numbering
    CASE
        WHEN measure_short_description = 'Total senior attendance' THEN 'Headline'
        WHEN measure_short_description = 'Senior attendance by sector' THEN '8a'
        WHEN measure_short_description = 'Total delegated attendance' THEN '8b'
        ELSE '8c'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    --what is in the denominator measure
    CASE
        WHEN measure_short_description IN (
            'Total senior attendance',
            'Total delegated attendance'
        ) THEN 'kpi8_total_attendance_possible'
        ELSE 'no_denominator'
    END AS measure_denominator,
    --deonominator value
    CASE
        WHEN measure_short_description IN (
            'Total senior attendance',
            'Total delegated attendance'
        ) THEN 5
        ELSE NULL
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Number of statutory sectors represented by a senior partners attending MB'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Number of statutory senior partners expected at each MB per period'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi8_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi8_junior_health_attended,
            kpi8_junior_la_children_social_care_attended,
            kpi8_junior_la_education_attended,
            kpi8_junior_police_attended,
            kpi8_junior_probation_attended,
            kpi8_senior_health_attended,
            kpi8_senior_la_children_social_care_attended,
            kpi8_senior_la_education_attended,
            kpi8_senior_police_attended,
            kpi8_senior_probation_attended,
            kpi8_total_junior_attended,
            kpi8_total_senior_attended
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
/* RQEV2-nY1VKrdj3A */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_case_level distkey (source_document_id) sortkey (source_document_id) AS 
WITH pd AS (
    SELECT
        header.source_document_id as source_document_id,
        document_item."dateOfBirth" :: date as ypid_dob,
        document_item."currentYOTID" :: text as currentyotid,
        document_item."ypid" :: text,
        document_item."ethnicity" :: text,
        document_item."sex" :: text,
        document_item."gender" :: text,
        document_item."originatingYOTPersonID" :: text as oypid,
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
        o.document_item."offenceID" :: text as offence_id,
        o.document_item."ageAtArrestOrOffence" :: int as age_at_arrest_or_offence,
        o.document_item."ageOnFirstHearing" :: int as age_at_first_hearing,
        o.document_item."yjboffenceCategory" :: Varchar(100) as yjb_offence_category,
        o.document_item."yjbseriousnessScore" :: int as yjb_seriousness_score,
        olo."outcomeDate" :: date as outcome_date,
        olo."legalOutcome" :: Varchar(100) as legal_outcome,
        olo."legalOutcomeGroup" :: Varchar(100) as legal_outcome_group,
        olo."cmslegalOutcome" :: Varchar(100) as cms_legal_outcome,
        olo."residenceOnLegalOutcomeDate" :: Varchar(100) as residence_on_legal_outcome_date,
        olo."outcomeAppealStatus" :: Varchar(500) as outcome_appeal_status
    FROM
        stg.yp_doc_item AS o
        LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
    WHERE
        document_item_type = 'offence'
),
intervention_prog AS (
    SELECT
        yp_doc_item.source_document_id as source_document_id_ip,
        document_item."interventionProgrammeID" :: text AS intervention_programme_id,
        document_item."startDate" :: date as intervention_start_date,
        document_item."endDate" :: date as intervention_end_date,
        document_item."cmsdisposalType" AS cms_disposal_type,
        document_item."disposalType" :: text AS disposal_type
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
combine AS(
    SELECT
        DISTINCT pd.*,
        eth.ethnicitygroup AS ethnicity_group,
        CASE
            WHEN sex = '1' THEN 'Male'
            WHEN sex = '2' THEN 'Female'
            WHEN gender = '1' THEN 'Male'
            WHEN gender = '2' THEN 'Female'
            ELSE 'Unknown gender'
        END AS gender_name,
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
        m1.legal_outcome_fixed,
        offence.age_at_arrest_or_offence,
        offence.age_at_first_hearing,
        offence.yjb_offence_category,
        offence.yjb_seriousness_score,
        intervention_prog.*,
        -- year_quarter_name AS label_quarter,
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        intervention_mapping.disposal_type_fixed,
        intervention_mapping.disposal_type_grouped,
        intervention_mapping.count_in_kpis AS count_in_kpi_disposal -- pd.yjs_name + offence.offence_id AS distinct_offence_id, --dont think you need it as you group by yjs_name, etc.
    FROM
        offence
        LEFT JOIN link ON link.offence_id = offence.offence_id
        AND link.source_document_id = offence.source_document_id_offence
        LEFT JOIN intervention_prog ON link.intervention_programme_id = intervention_prog.intervention_programme_id
        AND link.source_document_id = intervention_prog.source_document_id_ip
        LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
        LEFT JOIN refdata.ethnicity_group AS eth ON pd.ethnicity = eth.ethnicity
        LEFT JOIN yjb_kpi_case_level.data_mapping_v2_pivoted AS m1 ON UPPER(TRIM(offence.cms_legal_outcome)) = TRIM(m1.cms_legal_outcome)
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_kpi_case_level.intervention_programme_disposal_type AS intervention_mapping ON UPPER(TRIM(intervention_prog.disposal_type)) = TRIM(intervention_mapping.disposal_type)
    WHERE
        pd.deleted = FALSE
        AND intervention_mapping.count_in_kpis = 'YES' --count_in_kpi_disposal
        AND offence.residence_on_legal_outcome_date <> 'OTHER'
        AND offence.outcome_appeal_status NOT IN (
            'Changed on appeal',
            'Result of appeal successful'
        )
        AND (
            offence.outcome_date >= '2023-04-01'
            AND offence.outcome_date <= GETDATE()
        )
        -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting type of order (NULLs) when they were in the CTE above.
add_count_in_kpi_lo AS (
    SELECT
        combine.*,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        seriousness.seriousness_ranking,
        CASE
            WHEN count_in_kpi_lo.legal_outcome_group_fixed IN ('Pre-Court') THEN age_at_arrest_or_offence
            ELSE age_at_first_hearing
        END AS age_serious_violence
    FROM
        combine
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
    WHERE
        count_in_kpi_lo.count_in_kpi_legal_outcome = 'YES'
        AND count_in_kpi_lo.legal_outcome_group_fixed IN (
            'Pre-Court',
            'First-tier',
            'Community',
            'Custody'
        )
),
case_level AS (
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
        yjb_offence_category,
        yjb_seriousness_score,
        outcome_date,
        residence_on_legal_outcome_date,
        outcome_appeal_status,
        intervention_programme_id,
        intervention_start_date,
        intervention_end_date,
        age_at_arrest_or_offence,
        age_at_first_hearing,
        age_serious_violence,
        cms_legal_outcome,
        legal_outcome,
        legal_outcome_fixed,
        legal_outcome_group,
        legal_outcome_group_fixed,
        cms_disposal_type,
        disposal_type,
        disposal_type_fixed,
        disposal_type_grouped,
        type_of_order,
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            offence_id -- by partitioning by ypid and offence_id we count all offences - rather than just one
            ORDER BY
                seriousness_ranking,
                outcome_date DESC --where multiple seriousness_ranking or outcome dates for same offence we take latest
        ) as most_serious_recent
    FROM
        add_count_in_kpi_lo
    WHERE
        age_serious_violence BETWEEN 10
        AND 17
)
SELECT
    case_level.*,
    -- headline numerator: total numbeer of serious violence offences
    yjb_kpi_case_level.f_seriousviolence(
        case_level.yjb_offence_category,
        case_level.yjb_seriousness_score,
        case_level.offence_id
    ) AS kpi9_sv_offences,
    --sub measures: sv offences broken down by type 
    CASE
        WHEN case_level.yjb_offence_category = 'DRUGS'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_drugs,
    CASE
        WHEN case_level.yjb_offence_category = 'ROBBERY'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_robbery,
    CASE
        WHEN case_level.yjb_offence_category = 'VIOLENCE_AGAINST_THE_PERSON'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_violence_against_person,
    --sub measures: sv offences broken down by score 
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 5 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_5,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 6 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_6,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 7 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_7,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 8 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_8,
    --sub measure: children with sv offences broken down by demographics
    --age
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.age_serious_violence BETWEEN 10
        AND 14 THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_age_10_to_14,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.age_serious_violence BETWEEN 15
        AND 17 THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_age_15_to_17,
    --gender
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Unknown gender' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_unknown_gender,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Male' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_male,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Female' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_female,
    --ethnicity
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'White' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_white,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Mixed' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_mixed_ethnic,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Black or Black British' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_black,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Other Ethnic Group' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_other_ethnic,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Asian or Asian British' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_asian,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Information not obtainable' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_unknown_ethnic,
    --sub measure: total sv offences by type of order, does not include oocd as its diversionary
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Cautions with YJS intervention' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_yc,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Conditional Cautions' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_ycc,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Referral Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_ro,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Rehabilitation Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_yro,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Custodial sentences' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_cust,
      --total offences by type of order. no oocds.
    CASE
        WHEN case_level.type_of_order = 'Youth Cautions with YJS intervention' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_yc,
    CASE
        WHEN case_level.type_of_order = 'Youth Conditional Cautions' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_ycc,
    CASE
        WHEN case_level.type_of_order = 'Referral Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_ro,
    CASE
        WHEN case_level.type_of_order = 'Youth Rehabilitation Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_yro,
    CASE
        WHEN case_level.type_of_order = 'Custodial sentences' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_cust
FROM
    case_level
WHERE most_serious_recent = 1;	
/* RQEV2-pHjje1Lj40 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_case_level_v8 distkey (source_document_id) sortkey (source_document_id) AS WITH pd AS (
    SELECT
        header.source_document_id as source_document_id,
        document_item."dateOfBirth" :: date as ypid_dob,
        document_item."currentYOTID" :: text as currentyotid,
        document_item."ypid" :: text,
        document_item."ethnicity" :: text,
        document_item."sex" :: text,
        document_item."gender" :: text,
        document_item."originatingYOTPersonID" :: text as oypid,
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
        o.document_item."offenceID" :: text as offence_id,
        o.document_item."ageAtArrestOrOffence" :: int as age_at_arrest_or_offence,
        o.document_item."ageOnFirstHearing" :: int as age_at_first_hearing,
        o.document_item."offenceDescription" :: Varchar(1000) as offence_description,
        o.document_item."yjboffenceCategory" :: Varchar(100) as yjb_offence_category,
        o.document_item."yjbseriousnessScore" :: int as yjb_seriousness_score,
        olo."outcomeDate" :: date as outcome_date,
        olo."legalOutcome" :: Varchar(100) as legal_outcome,
        olo."legalOutcomeGroup" :: Varchar(100) as legal_outcome_group,
        olo."cmslegalOutcome" :: Varchar(100) as cms_legal_outcome,
        olo."residenceOnLegalOutcomeDate" :: Varchar(100) as residence_on_legal_outcome_date,
        olo."outcomeAppealStatus" :: Varchar(500) as outcome_appeal_status
    FROM
        stg.yp_doc_item AS o
        LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
    WHERE
        document_item_type = 'offence'
),
intervention_prog AS (
    SELECT
        yp_doc_item.source_document_id as source_document_id_ip,
        document_item."interventionProgrammeID" :: text AS intervention_programme_id,
        document_item."startDate" :: date as intervention_start_date,
        document_item."endDate" :: date as intervention_end_date,
        document_item."cmsdisposalType" AS cms_disposal_type,
        document_item."disposalType" :: text AS disposal_type
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
combine AS(
    SELECT
        DISTINCT pd.*,
        eth.ethnicitygroup AS ethnicity_group,
        CASE
            WHEN sex = '1' THEN 'Male'
            WHEN sex = '2' THEN 'Female'
            WHEN gender = '1' THEN 'Male'
            WHEN gender = '2' THEN 'Female'
            ELSE 'Unknown gender'
        END AS gender_name,
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
        offence.age_at_arrest_or_offence,
        offence.age_at_first_hearing,
        offence.offence_description,
        offence.yjb_offence_category,
        offence.yjb_seriousness_score,
        intervention_prog.*,
        -- year_quarter_name AS label_quarter,
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
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(offence.outcome_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_kpi_case_level.intervention_programme_disposal_type AS intervention_mapping ON UPPER(TRIM(intervention_prog.disposal_type)) = TRIM(intervention_mapping.disposal_type)
    WHERE
        pd.deleted = FALSE
        /* count_in_kpi_disposal */
        AND intervention_mapping.count_in_kpis = 'YES'
        AND offence.residence_on_legal_outcome_date <> 'OTHER'
        AND offence.outcome_appeal_status NOT IN (
            'Changed on appeal',
            'Result of appeal successful'
        )
        AND (
            offence.outcome_date >= '2023-04-01'
            AND offence.outcome_date <= GETDATE()
        ) -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting type of order (NULLs) when they were in the CTE above.
add_count_in_kpi_lo AS (
    SELECT
        combine.*,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        seriousness.seriousness_ranking,
        CASE
            WHEN count_in_kpi_lo.legal_outcome_group_fixed IN ('Pre-Court') THEN age_at_arrest_or_offence
            ELSE age_at_first_hearing
        END AS age_serious_violence
    FROM
        combine
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
    WHERE
        count_in_kpi_lo.count_in_kpi_legal_outcome = 'YES'
        AND count_in_kpi_lo.legal_outcome_group_fixed IN (
            'Pre-Court',
            'First-tier',
            'Community',
            'Custody'
        )
),
case_level AS (
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
        offence_description,
        yjb_offence_category,
        yjb_seriousness_score,
        outcome_date,
        residence_on_legal_outcome_date,
        outcome_appeal_status,
        intervention_programme_id,
        intervention_start_date,
        intervention_end_date,
        age_at_arrest_or_offence,
        age_at_first_hearing,
        age_serious_violence,
        cms_legal_outcome,
        legal_outcome,
        legal_outcome_group,
        legal_outcome_group_fixed,
        cms_disposal_type,
        disposal_type,
        disposal_type_fixed,
        disposal_type_grouped,
        type_of_order,
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            offence_id -- by partitioning by ypid and offence_id we count all offences - rather than just one
            ORDER BY
                seriousness_ranking,
                outcome_date DESC --where multiple seriousness_ranking or outcome dates for same offence we take latest
        ) as most_serious_recent
    FROM
        add_count_in_kpi_lo
    WHERE
        age_serious_violence BETWEEN 10
        AND 17
)
SELECT
    case_level.*,
    -- headline and sub-measure 9a numerator: total number of serious violence offences
    yjb_kpi_case_level.f_seriousviolence(
        case_level.yjb_offence_category,
        case_level.yjb_seriousness_score,
        case_level.offence_id
    ) AS kpi9_sv_offences,
    --sub-measure 9b numerator and sub-measure 9f denominator: total children with sv offences
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_total_ypid,
    --sub-measure 9c numerators: sv offences broken down by type 
    CASE
        WHEN case_level.yjb_offence_category = 'DRUGS'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_drugs,
    CASE
        WHEN case_level.yjb_offence_category = 'ROBBERY'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_robbery,
    CASE
        WHEN case_level.yjb_offence_category = 'VIOLENCE_AGAINST_THE_PERSON'
        AND case_level.yjb_seriousness_score IN (5, 6, 7, 8) THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_violence_against_person,
    --sub-measure 9d numerators: sv offences broken down by score 
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 5 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_5,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 6 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_6,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 7 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_7,
    CASE
        WHEN case_level.yjb_offence_category IN (
            'DRUGS',
            'ROBBERY',
            'VIOLENCE_AGAINST_THE_PERSON'
        )
        AND case_level.yjb_seriousness_score = 8 THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_8,
    --sub-measure 9e numerators: total sv offences by type of order, does not include oocd as its diversionary
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Cautions with YJS intervention' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_yc_with_yjs,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Conditional Cautions' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_ycc,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Referral Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_ro,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Youth Rehabilitation Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_yro,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.type_of_order = 'Custodial sentences' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_sv_cust,
    --sub-measure 9e denominator: total offences by type of order. no oocds.
    CASE
        WHEN case_level.type_of_order = 'Youth Cautions with YJS intervention' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_yc_with_yjs,
    CASE
        WHEN case_level.type_of_order = 'Youth Conditional Cautions' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_ycc,
    CASE
        WHEN case_level.type_of_order = 'Referral Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_ro,
    CASE
        WHEN case_level.type_of_order = 'Youth Rehabilitation Orders' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_yro,
    CASE
        WHEN case_level.type_of_order = 'Custodial sentences' THEN case_level.offence_id
        ELSE NULL
    END AS kpi9_total_offences_cust,
    --sub-measure 9f: children with sv offences broken down by demographics
    --age
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.age_serious_violence BETWEEN 10
        AND 14 THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_age_10_to_14,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.age_serious_violence BETWEEN 15
        AND 17 THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_age_15_to_17,
    --gender
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Unknown gender' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_unknown_gender,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Male' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_male,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.gender_name = 'Female' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_female,
    --ethnicity
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'White' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_white,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Mixed' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_mixed_ethnic,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Black or Black British' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_black,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Other Ethnic Group' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_other_ethnic,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Asian or Asian British' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_asian,
    CASE
        WHEN kpi9_sv_offences = case_level.offence_id
        AND case_level.ethnicity_group = 'Information not obtainable' THEN case_level.ypid
        ELSE NULL
    END AS kpi9_sv_unknown_ethnic
FROM
    case_level
WHERE
    most_serious_recent = 1;	
/* RQEV2-y2qAnb1sGW */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_summary distkey (yot_code) sortkey (yot_code) as WITH summary_cl AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- 'cl_headline_numerator' in previous iterations
        COUNT(DISTINCT kpi9_sv_offences) AS kpi9_sv_offences,
        COUNT(DISTINCT offence_id) AS kpi9_total_offences,
        COUNT(DISTINCT kpi9_sv_drugs) AS kpi9_sv_drugs,
        COUNT(DISTINCT kpi9_sv_robbery) AS kpi9_sv_robbery,
        COUNT(DISTINCT kpi9_sv_violence_against_person) AS kpi9_sv_violence_against_person,
        COUNT(DISTINCT kpi9_sv_5) AS kpi9_sv_5,
        COUNT(DISTINCT kpi9_sv_6) AS kpi9_sv_6,
        COUNT(DISTINCT kpi9_sv_7) AS kpi9_sv_7,
        COUNT(DISTINCT kpi9_sv_8) AS kpi9_sv_8,
        COUNT(DISTINCT kpi9_sv_age_10_to_14) AS kpi9_sv_age_10_to_14,
        COUNT(DISTINCT kpi9_sv_age_15_to_17) AS kpi9_sv_age_15_to_17,
        COUNT(DISTINCT kpi9_sv_unknown_gender) AS kpi9_sv_unknown_gender,
        COUNT(DISTINCT kpi9_sv_male) AS kpi9_sv_male,
        COUNT(DISTINCT kpi9_sv_female) AS kpi9_sv_female,
        COUNT(DISTINCT kpi9_sv_white) AS kpi9_sv_white,
        COUNT(DISTINCT kpi9_sv_mixed_ethnic) AS kpi9_sv_mixed_ethnic,
        COUNT(DISTINCT kpi9_sv_black) AS kpi9_sv_black,
        COUNT(DISTINCT kpi9_sv_other_ethnic) AS kpi9_sv_other_ethnic,
        COUNT(DISTINCT kpi9_sv_asian) AS kpi9_sv_asian,
        COUNT(DISTINCT kpi9_sv_unknown_ethnic) AS kpi9_sv_unknown_ethnic,
        COUNT(DISTINCT kpi9_sv_yc) AS kpi9_sv_yc,
        COUNT(DISTINCT kpi9_sv_ycc) AS kpi9_sv_ycc,
        COUNT(DISTINCT kpi9_sv_ro) AS kpi9_sv_ro,
        COUNT(DISTINCT kpi9_sv_yro) AS kpi9_sv_yro,
        COUNT(DISTINCT kpi9_sv_cust) AS kpi9_sv_cust,
        COUNT(DISTINCT kpi9_total_offences_yc) AS kpi9_total_offences_yc,
        COUNT(DISTINCT kpi9_total_offences_ycc) AS kpi9_total_offences_ycc,
        COUNT(DISTINCT kpi9_total_offences_ro) AS kpi9_total_offences_ro,
        COUNT(DISTINCT kpi9_total_offences_yro) AS kpi9_total_offences_yro,
        COUNT(DISTINCT kpi9_total_offences_cust) AS kpi9_total_offences_cust
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi9_sv_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country
),
combined AS (
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
            WHEN (summary_t.kpi9_sv_offences > 0) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
            ELSE 'Data from case level' -- includes any YJS that only submitted by case level
        END AS source_data_flag,
        --headline numerator: number of serious violence offences
        --previously name 'kpi9_headline_numerator'
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_offences
                ELSE summary_cl.kpi9_sv_offences
            END,
            0
        ) AS kpi9_sv_offences,
        --sub measure: total offences (available for case level only)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences
            ELSE NULL
        END AS kpi9_total_offences,
        --sub measure: sv offences in drugs
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_drugs
                ELSE summary_cl.kpi9_sv_drugs
            END,
            0
        ) AS kpi9_sv_drugs,
        --sub measure: sv offences in robbery
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_robbery
                ELSE summary_cl.kpi9_sv_robbery
            END,
            0
        ) AS kpi9_sv_robbery,
        --sub measure sv offences in violence_against_person
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_violence_against_person
                ELSE summary_cl.kpi9_sv_violence_against_person
            END,
            0
        ) AS kpi9_sv_violence_against_person,
        --sub measure: sv broken down by seriousness score (only available for case level)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_5
            ELSE NULL
        END AS kpi9_sv_5,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_6
            ELSE NULL
        END AS kpi9_sv_6,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_7
            ELSE NULL
        END AS kpi9_sv_7,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_8
            ELSE NULL
        END AS kpi9_sv_8,
        --sub measure: sv broken down by age brackets  (case level only as template counts offences not people)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_age_10_to_14
            ELSE NULL
        END AS kpi9_sv_age_10_to_14,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_age_15_to_17
            ELSE NULL
        END AS kpi9_sv_age_15_to_17,
        --sub meausre: sv offences broken down by gender (available for case level only)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_unknown_gender
            ELSE NULL
        END AS kpi_sv_unknown_gender,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_male
            ELSE NULL
        END AS kpi_sv_male,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_female
            ELSE NULL
        END AS kpi_sv_female,
        --sub measure: sv broken down by ethnicity (available for case level only)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_white
            ELSE NULL
        END AS kpi_sv_white,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_mixed_ethnic
            ELSE NULL
        END AS kpi_sv_mixed_ethnic,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_black
            ELSE NULL
        END AS kpi_sv_black,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_other_ethnic
            ELSE NULL
        END AS kpi_sv_other_ethnic,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_asian
            ELSE NULL
        END AS kpi_sv_asian,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_unknown_ethnic
            ELSE NULL
        END AS kpi_sv_unknown_ethnic,
        --sub meausre: sv offences broken down by type of order (available for case level only). does not include oocd as this is diversionary
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_yc
            ELSE NULL
        END AS kpi9_sv_yc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_ycc
            ELSE NULL
        END AS kpi9_sv_ycc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_ro
            ELSE NULL
        END AS kpi9_sv_ro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_yro
            ELSE NULL
        END AS kpi9_sv_yro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_cust
            ELSE NULL
        END AS kpi9_sv_cust,
        -- total offences by type of order. does not include oocd as this is diversionary
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_yc
            ELSE NULL
        END AS kpi9_total_offences_yc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_ycc
            ELSE NULL
        END AS kpi9_total_offences_ycc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_ro
            ELSE NULL
        END AS kpi9_total_offences_ro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_yro
            ELSE NULL
        END AS kpi9_total_offences_yro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_cust
            ELSE NULL
        END AS kpi9_total_offences_cust
    FROM
        summary_cl 
        FULL JOIN yjb_kpi_case_level.kpi9_sv_template AS summary_t ON summary_cl.yot_code = summary_t.yot_code
        AND summary_cl.label_quarter = summary_t.label_quarter
)
SELECT
    combined.*,
    CASE
        WHEN combined.label_quarter IN ('2023Q1', '2023Q2', '2023Q3', '2023Q4') THEN population."2022_pop"
        WHEN combined.label_quarter IN ('2024Q1', '2024Q2', '2024Q3', '2024Q4') THEN population."2023_pop"
        ELSE NULL
    END AS kpi9_headline_denominator
FROM
    combined
    LEFT JOIN yjb_ianda_team.population AS population ON combined.yjs_name = population.yjs_name_pop;	
/* RQEV2-elcLbRbedw */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        kpi9.return_status_id,
        kpi9.reporting_date,
        kpi9.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label_quarter that switches year and quarter around to be ordered correctly
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi9.description,
        kpi9.age10to15,
        kpi9.age16to17
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi9_sv_v1" AS kpi9
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi9.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi9.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    -- headline and submeasure 9a numerator: total sv offences
    SUM(
        CASE
            WHEN description IN (
                'Offences with a gravity score of 5 or more for Drugs offences resulting in a caution or sentence in the quarter',
                'Offences with a gravity score of 5 or more for Robbery offences resulting in a caution or sentence in the quarter',
                'Offences with a gravity score of 5 or more for Violence Against the Person offences resulting in a caution or sentence in the quarter') THEN age10to15 + age16to17
                ELSE 0
            END
        ) AS kpi9_sv_offences,
        -- sub measure: broken down by offence category
        SUM(
            CASE
                WHEN description = 'Offences with a gravity score of 5 or more for Drugs offences resulting in a caution or sentence in the quarter' THEN age10to15 + age16to17
                ELSE 0
            END
        ) AS kpi9_sv_drugs,
        SUM(
            CASE
                WHEN description = 'Offences with a gravity score of 5 or more for Robbery offences resulting in a caution or sentence in the quarter' THEN age10to15 + age16to17
                ELSE 0
            END
        ) AS kpi9_sv_robbery,
        SUM(
            CASE
                WHEN description = 'Offences with a gravity score of 5 or more for Violence Against the Person offences resulting in a caution or sentence in the quarter' THEN age10to15 + age16to17
                ELSE 0
            END
        ) AS kpi9_sv_violence_against_person
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

/* RQEV2-auETd62tlN */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_summary_v8 distkey (yot_code) sortkey (yot_code) as WITH summary_cl AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        COUNT(DISTINCT kpi9_sv_offences) AS kpi9_sv_offences,
        COUNT(DISTINCT offence_id) AS kpi9_total_offences,
        COUNT(DISTINCT kpi9_sv_total_ypid) AS kpi9_sv_total_ypid,
        COUNT(DISTINCT ypid) AS kpi9_total_ypid,
        COUNT(DISTINCT kpi9_sv_drugs) AS kpi9_sv_drugs,
        COUNT(DISTINCT kpi9_sv_robbery) AS kpi9_sv_robbery,
        COUNT(DISTINCT kpi9_sv_violence_against_person) AS kpi9_sv_violence_against_person,
        COUNT(DISTINCT kpi9_sv_5) AS kpi9_sv_5,
        COUNT(DISTINCT kpi9_sv_6) AS kpi9_sv_6,
        COUNT(DISTINCT kpi9_sv_7) AS kpi9_sv_7,
        COUNT(DISTINCT kpi9_sv_8) AS kpi9_sv_8,
        COUNT(DISTINCT kpi9_sv_age_10_to_14) AS kpi9_sv_age_10_to_14,
        COUNT(DISTINCT kpi9_sv_age_15_to_17) AS kpi9_sv_age_15_to_17,
        COUNT(DISTINCT kpi9_sv_unknown_gender) AS kpi9_sv_unknown_gender,
        COUNT(DISTINCT kpi9_sv_male) AS kpi9_sv_male,
        COUNT(DISTINCT kpi9_sv_female) AS kpi9_sv_female,
        COUNT(DISTINCT kpi9_sv_white) AS kpi9_sv_white,
        COUNT(DISTINCT kpi9_sv_mixed_ethnic) AS kpi9_sv_mixed_ethnic,
        COUNT(DISTINCT kpi9_sv_black) AS kpi9_sv_black,
        COUNT(DISTINCT kpi9_sv_other_ethnic) AS kpi9_sv_other_ethnic,
        COUNT(DISTINCT kpi9_sv_asian) AS kpi9_sv_asian,
        COUNT(DISTINCT kpi9_sv_unknown_ethnic) AS kpi9_sv_unknown_ethnic,
        COUNT(DISTINCT kpi9_sv_yc_with_yjs) AS kpi9_sv_yc_with_yjs,
        COUNT(DISTINCT kpi9_sv_ycc) AS kpi9_sv_ycc,
        COUNT(DISTINCT kpi9_sv_ro) AS kpi9_sv_ro,
        COUNT(DISTINCT kpi9_sv_yro) AS kpi9_sv_yro,
        COUNT(DISTINCT kpi9_sv_cust) AS kpi9_sv_cust,
        COUNT(DISTINCT kpi9_total_offences_yc_with_yjs) AS kpi9_total_offences_yc_with_yjs,
        COUNT(DISTINCT kpi9_total_offences_ycc) AS kpi9_total_offences_ycc,
        COUNT(DISTINCT kpi9_total_offences_ro) AS kpi9_total_offences_ro,
        COUNT(DISTINCT kpi9_total_offences_yro) AS kpi9_total_offences_yro,
        COUNT(DISTINCT kpi9_total_offences_cust) AS kpi9_total_offences_cust
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi9_sv_case_level_v8"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country
),
combined AS (
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
        -- financial quarter 
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
        'KPI 9' AS kpi_number,
        CASE
            WHEN (summary_t.kpi9_sv_offences > 0) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
            ELSE 'Data from case level' -- includes any YJS that only submitted by case level
        END AS source_data_flag,
        --headline numerator, sub-measure 9a numerator and denominator for 9c-9d: number of serious violence offences
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_offences
                ELSE summary_cl.kpi9_sv_offences
            END,
            0
        ) AS kpi9_sv_offences,
        --sub-measure 9a denominator: total offences (available for case level only until template 2.0 is avaialable)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences
            ELSE NULL
        END AS kpi9_total_offences,
        --sub-measure 9b numerator and denominator for sub-measure 9f: total children who committed sv (available only for case level until template 2.0 is available)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_total_ypid
            ELSE NULL
        END AS kpi9_sv_total_ypid,
        --sub-measure 9b denominator: total children who committed any offence (available only for case level until template 2.0 is available)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_ypid
            ELSE NULL
        END AS kpi9_total_ypid,
        --sub-measure 9c numerator: sv offences in drugs
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_drugs
                ELSE summary_cl.kpi9_sv_drugs
            END,
            0
        ) AS kpi9_sv_drugs,
        --sub measure 9c numerator: sv offences in robbery
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_robbery
                ELSE summary_cl.kpi9_sv_robbery
            END,
            0
        ) AS kpi9_sv_robbery,
        --sub-measure 9c numerator: sv offences in violence_against_person
        COALESCE(
            CASE
                WHEN source_data_flag = 'Data from template' THEN summary_t.kpi9_sv_violence_against_person
                ELSE summary_cl.kpi9_sv_violence_against_person
            END,
            0
        ) AS kpi9_sv_violence_against_person,
        --sub-measure 9d: sv broken down by seriousness score (only available for case level)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_5
            ELSE NULL
        END AS kpi9_sv_5,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_6
            ELSE NULL
        END AS kpi9_sv_6,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_7
            ELSE NULL
        END AS kpi9_sv_7,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_8
            ELSE NULL
        END AS kpi9_sv_8,
        --sub-measure 9f numerator: sv broken down by age brackets  (case level only as template counts offences not people)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_age_10_to_14
            ELSE NULL
        END AS kpi9_sv_age_10_to_14,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_age_15_to_17
            ELSE NULL
        END AS kpi9_sv_age_15_to_17,
        --sub-meausre 9f numerator: sv offences broken down by gender (available for case level only)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_unknown_gender
            ELSE NULL
        END AS kpi9_sv_unknown_gender,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_male
            ELSE NULL
        END AS kpi9_sv_male,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_female
            ELSE NULL
        END AS kpi9_sv_female,
        --sub- measure 9f numerator: sv broken down by ethnicity (available for case level only)
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_white
            ELSE NULL
        END AS kpi9_sv_white,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_mixed_ethnic
            ELSE NULL
        END AS kpi9_sv_mixed_ethnic,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_black
            ELSE NULL
        END AS kpi9_sv_black,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_other_ethnic
            ELSE NULL
        END AS kpi9_sv_other_ethnic,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_asian
            ELSE NULL
        END AS kpi9_sv_asian,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_unknown_ethnic
            ELSE NULL
        END AS kpi9_sv_unknown_ethnic,
        --sub-meausre 9e numerator: sv offences broken down by type of order (available for case level only until template 2.0 is available) - does not include oocd as this is diversionary
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_yc_with_yjs
            ELSE NULL
        END AS kpi9_sv_yc_with_yjs,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_ycc
            ELSE NULL
        END AS kpi9_sv_ycc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_ro
            ELSE NULL
        END AS kpi9_sv_ro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_yro
            ELSE NULL
        END AS kpi9_sv_yro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_sv_cust
            ELSE NULL
        END AS kpi9_sv_cust,
        -- sub-measure 9e denominator: total offences by type of order (available for case level only until template 2.0 is available) - does not include oocd as this is diversionary
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_yc_with_yjs
            ELSE NULL
        END AS kpi9_total_offences_yc_with_yjs,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_ycc
            ELSE NULL
        END AS kpi9_total_offences_ycc,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_ro
            ELSE NULL
        END AS kpi9_total_offences_ro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_yro
            ELSE NULL
        END AS kpi9_total_offences_yro,
        CASE
            WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi9_total_offences_cust
            ELSE NULL
        END AS kpi9_total_offences_cust
    FROM
        summary_cl FULL
        JOIN yjb_kpi_case_level.kpi9_sv_template_V8 AS summary_t ON summary_cl.yot_code = summary_t.yot_code
        AND summary_cl.label_quarter = summary_t.label_quarter
)
SELECT
    combined.*,
    CASE
        WHEN combined.quarter_label IN ('2023Q1', '2023Q2', '2023Q3', '2023Q4') THEN population."2022_pop"
        WHEN combined.quarter_label IN ('2024Q1', '2024Q2', '2024Q3', '2024Q4') THEN population."2023_pop"
        /*add years as they become available. always the previous year is used as those are the most recent available figures*/
        ELSE NULL
    END AS kpi9_10_17_population
FROM
    combined
    LEFT JOIN yjb_ianda_team.population AS population ON combined.yjs_name = population.yjs_name_pop;	

/* RQEV2-JTWAxKEkrs */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
/*CTE for values that appear in numerator and denominator*/
--required as when a column is pivoted usinng unpivot, the column name is not available in the unpivoted table so has to be pulled from here instead
WITH numerators_and_denominators AS (
    SELECT
        yjs_name,
        quarter_label,
        kpi9_sv_total_ypid,
        kpi9_sv_offences
    FROM
        yjb_kpi_case_level.kpi9_sv_summary_v8
), first_CTE AS (
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
    'Serious Violence' AS kpi_name,
    'Serious violent offences committed by children' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE 'end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable (does not exist for kpi5 but need column for final unioned table for tableau)
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
    -- give a category for every measure measurement
    CASE
        /*overall measures*/
        WHEN unpvt_table.measure_numerator LIKE '%sv_offences%' THEN 'SV offences'
        WHEN unpvt_table.measure_numerator LIKE '%sv_total_ypid%' THEN 'Children with SV offences'
        /*type of sv offence*/
        WHEN unpvt_table.measure_numerator LIKE '%drugs%' THEN 'Drugs'
        WHEN unpvt_table.measure_numerator LIKE '%robbery%' THEN 'Robbery'
        WHEN unpvt_table.measure_numerator LIKE '%violence_against_person%' THEN 'Violence against the person'
        /*seriousness score*/
        WHEN unpvt_table.measure_numerator LIKE '%sv_5%' THEN '5'
        WHEN unpvt_table.measure_numerator LIKE '%sv_6%' THEN '6'
        WHEN unpvt_table.measure_numerator LIKE '%sv_7%' THEN '7'
        WHEN unpvt_table.measure_numerator LIKE '%sv_8%' THEN '8'
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'Youth rehabilitation orders'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'Referral orders'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'Custodial sentences'
        /*demographics*/
        --gender
        WHEN unpvt_table.measure_numerator LIKE '%female%' THEN 'Female'
        WHEN unpvt_table.measure_numerator LIKE '%male%' THEN 'Male'
        WHEN unpvt_table.measure_numerator LIKE '%unknown_g%' THEN 'Unknown Gender'
        /*age*/
        WHEN unpvt_table.measure_numerator LIKE '%10_to_14%' THEN '10-14 year olds'
        WHEN unpvt_table.measure_numerator LIKE '%15_to_17%' THEN '15-17 year olds'
        /*ethnicity*/
        WHEN unpvt_table.measure_numerator LIKE '%asian%' THEN 'Asian or Asian British'
        WHEN unpvt_table.measure_numerator LIKE '%black%' THEN 'Black or Black British'
        WHEN unpvt_table.measure_numerator LIKE '%white%' THEN 'White'
        WHEN unpvt_table.measure_numerator LIKE '%mixed%' THEN 'Mixed ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%other_e%' THEN 'Other Ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%unknown_e%' THEN 'Unknown Ethnicity'
    END AS measure_category,
    --short description of measure 
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%sv_offences_headline%' THEN 'SV offences per 10,000 children'
        WHEN measure_category = 'SV offences' THEN 'SV offences per all offences'
        WHEN measure_category = 'Children with SV offences' THEN 'Children with SV offences per all children'
        WHEN measure_category IN(
            'Drugs',
            'Robbery',
            'Violence against the person'
        ) THEN 'Type of SV'
        WHEN measure_category IN ('5', '6', '7', '8') THEN 'Seriousness score'
        WHEN measure_category IN (
            'Youth cautions with YJS intervention',
            'Youth conditional cautions',
            'Youth rehabilitation orders',
            'Referral orders',
            'Custodial sentences'
        ) THEN 'Type of order'
        WHEN measure_category IN (
            'Female',
            'Male',
            'Unknown Gender',
            '10-14 year olds',
            '15-17 year olds',
            'Asian or Asian British',
            'Black or Black British',
            'White',
            'Mixed ethnicity',
            'Other Ethnicity',
            'Unknown Ethnicity'
        ) THEN 'Demographics'
    END AS measure_short_description,
    --full measure wording 
    CASE
        WHEN measure_short_description = 'SV offences per 10,000 children' THEN 'Rate of proven serious violence offences per 10,000 children aged 10-17'
        WHEN measure_short_description = 'SV offences per all offences' THEN 'Proportion of all offences in the period that were proven serious violence offences'
        WHEN measure_short_description = 'Children with SV offences per all children' THEN 'Proportion of children who committed an offence in the period that committed proven serious violence'
        WHEN measure_short_description = 'Type of SV' THEN 'Proven serious violence offences by type of offence'
        WHEN measure_short_description = 'Seriousness score' THEN 'Proven serious violence offences by seriousness score'
        ELSE 'Children who committed proven serious violence offences by demographic characteristics (case-level only)'
    END AS measure_long_description,
    -- whether the measure is the headline measure
    CASE
        WHEN measure_short_description LIKE 'SV offences per 10,000 children' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    -- measure numbering
    CASE
        WHEN measure_short_description = 'SV offences per 10,000 children' THEN 'Headline'
        WHEN measure_short_description = 'SV offences per all offences' THEN '9a'
        WHEN measure_short_description = 'Children with SV offences per all children' THEN '9b'
        WHEN measure_short_description = 'Type of SV' THEN '9c'
        WHEN measure_short_description = 'Seriousness score' THEN '9d'
        WHEN measure_short_description = 'Type of order' THEN '9e'
        ELSE '9f'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- name of the denominator (what is in the denominator)
    CASE
        WHEN measure_short_description = 'SV offences per 10,000 children' THEN 'kpi9_10_17_population'
        WHEN measure_short_description = 'SV offences per all offences' THEN 'kpi9_total_offences'
        WHEN measure_short_description = 'Children with SV offences per all children' THEN 'kpi9_total_ypid'
        WHEN measure_short_description IN ('Type of SV', 'Seriousness score') THEN 'kpi9_sv_offences'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi9_total_offences_yc_with_yjs'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi9_total_offences_ycc'
        WHEN measure_category = 'Referral orders' THEN 'kpi9_total_offences_ro'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi9_total_offences_yro'
        WHEN measure_category = 'Custodial sentences' THEN 'kpi9_total_offences_cust'
        ELSE 'kpi9_sv_total_ypid'
    END AS measure_denominator,
    --denominator values
    CASE
        WHEN measure_short_description = 'SV offences per 10,000 children' THEN kpi9_10_17_population
        WHEN measure_short_description = 'SV offences per all offences' THEN kpi9_total_offences
        WHEN measure_short_description = 'Children with SV offences per all children' THEN kpi9_total_ypid
        WHEN measure_short_description IN ('Type of SV', 'Seriousness score') THEN numerators_and_denominators.kpi9_sv_offences
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN kpi9_total_offences_yc_with_yjs
        WHEN measure_category = 'Youth conditional cautions' THEN kpi9_total_offences_ycc
        WHEN measure_category = 'Referral orders' THEN kpi9_total_offences_ro
        WHEN measure_category = 'Youth rehabilitation orders' THEN kpi9_total_offences_yro
        WHEN measure_category = 'Custodial sentences' THEN kpi9_total_offences_cust
        ELSE numerators_and_denominators.kpi9_sv_total_ypid
    END AS denominator_value
FROM
    yjb_kpi_case_level.kpi9_sv_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi9_sv_5,
            kpi9_sv_6,
            kpi9_sv_7,
            kpi9_sv_8,
            kpi9_sv_age_10_to_14,
            kpi9_sv_age_15_to_17,
            kpi9_sv_cust,
            kpi9_sv_drugs,
            kpi9_sv_offences,
            kpi9_sv_offences AS kpi9_sv_offences_headline,
            kpi9_sv_ro,
            kpi9_sv_robbery,
            kpi9_sv_total_ypid,
            kpi9_sv_violence_against_person,
            kpi9_sv_yc_with_yjs,
            kpi9_sv_ycc,
            kpi9_sv_yro,
            kpi9_sv_asian,
            kpi9_sv_black,
            kpi9_sv_female,
            kpi9_sv_male,
            kpi9_sv_mixed_ethnic,
            kpi9_sv_other_ethnic,
            kpi9_sv_unknown_ethnic,
            kpi9_sv_unknown_gender,
            kpi9_sv_white
        )
    ) AS unpvt_table
    LEFT JOIN numerators_and_denominators ON unpvt_table.yjs_name = numerators_and_denominators.yjs_name
    AND unpvt_table.quarter_label = numerators_and_denominators.quarter_label
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name)
    
 SELECT 
        *,
        -- New columns: numerator description and denominator description
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Number of serious violence offences'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Number of 10-17-year-olds in the general population in the YJS area'
        ELSE NULL
    END AS headline_denominator_description
    FROM first_CTE
    
    ;	
