SET enable_case_sensitive_identifier TO true;

/* RQEV2-d3ezSntxzV */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_case_level_v8 distkey (kpi4_source_document_id) sortkey (kpi4_source_document_id) AS WITH kpi4 AS (
    SELECT
        dc.source_document_id AS kpi4_source_document_id,
        mh."kpi4MHDateScreened" :: date AS kpi4_date_need_identified,
        mh."kpi4MHDateReferred" :: date AS kpi4_date_referred,
        mh."kpi4MHDateOffered" :: date AS kpi4_date_offered,
        mh."kpi4MHDateAttendedStart" :: date AS kpi4_date_attended_start,
        mh."kpi4MHInterventionType" :: text AS kpi4_intervention_type,
        mh."kpi4MHDateAttendedEnd" :: date AS kpi4_date_attended_end
    FROM
        stg.yp_doc_item AS dc,
        dc.document_item."mentalHealth"."kpi4MentalHealthWellbeing" AS mh
    WHERE
        document_item_type = 'health'
        AND kpi4_date_need_identified IS NOT NULL
)
SELECT
    DISTINCT kpi4.*,
    person_details.*,
    -- sub-measure: already receiving MH/EW intervention at the start of the order
    -- function f_inTreatmentPrior checks whether the treatment was open/ongoing when the order started
    CASE
        WHEN yjb_kpi_case_level.f_inTreatmentPrior(
            kpi4.kpi4_date_attended_start,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date,
            kpi4.kpi4_date_attended_end
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_treatment_start,
    --sub-measure: chidlredn identified with a mental health or emotional wellbeing need during their order
    CASE
        WHEN kpi4.kpi4_date_need_identified <> '1900-01-01'
        OR kpi4_treatment_start IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need,
    /* submeasure: MH/EW need broken down by type of order */
    -- out of court disposals
    CASE
        WHEN person_details.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_oocd,
    -- youth cautions with YJS involvement
    CASE
        WHEN person_details.type_of_order = 'Youth Cautions with YJS intervention'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_yc,
    -- youth conditional cautions
    CASE
        WHEN person_details.type_of_order = 'Youth Conditional Cautions'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_ycc,
    -- referral orders
    CASE
        WHEN person_details.type_of_order = 'Referral Orders'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_ro,
    -- youth rehabilitation orders
    CASE
        WHEN person_details.type_of_order = 'Youth Rehabilitation Orders'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_yro,
    -- custody
    CASE
        WHEN person_details.type_of_order = 'Custodial sentences'
        AND kpi4_mh_ew_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need_cust,
    /* sub-measure: offered mh/ew intervention */
    -- child was offered 'help'
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_HELP'
            AND kpi4.kpi4_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_HELP'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_help,
    -- child was offered 'additional help'
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
            AND kpi4.kpi4_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_additional_help,
    -- child was offered 'risk support'
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
            AND kpi4.kpi4_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_risk_support,
    -- child was offered 'advice'
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
            AND kpi4.kpi4_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_advice,
    -- child with need that were offered 'no intervention' -- not sure if this makes sense as there are instances where they attend an intervention but still have 1900 in offered
    CASE
        WHEN kpi4_mh_ew_need = person_details.ypid
        AND kpi4.kpi4_intervention_type = 'NO_INTERVENTION'
        AND kpi4.kpi4_date_offered = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_no_intervention,
    /* sub-measure: attended mh/ew intervention */
    -- kpi4_attended_help
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_HELP'
            AND kpi4.kpi4_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_HELP'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_help,
    -- kpi4_attended_additional_help
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
            AND kpi4.kpi4_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_additional_help,
    -- kpi4_attended_risk_support
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
            AND kpi4.kpi4_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_risk_support,
    -- kpi4_attended_advice
    CASE
        WHEN (
            kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
            AND kpi4.kpi4_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
            AND kpi4_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_advice,
    -- child was offered intervention but did not attend 
    CASE
        WHEN kpi4.kpi4_date_offered BETWEEN person_details.intervention_start_date
        AND person_details.intervention_end_date
        AND kpi4.kpi4_date_attended_start = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_but_not_attended,
    -- headline measure: children with an identified MH/EW need during their order and was offered an MH/EW intervention or was already receiving one when order began
    CASE
        WHEN kpi4_mh_ew_need = person_details.ypid
        AND (
            kpi4_treatment_start = person_details.ypid
            OR kpi4_offered_help = person_details.ypid
            OR kpi4_offered_additional_help = person_details.ypid
            OR kpi4_offered_risk_support = person_details.ypid
            OR kpi4_offered_advice = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_offered
FROM
    kpi4
    INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi4.kpi4_source_document_id = person_details.source_document_id
WHERE
    --need to incorporate that no kpi4_date_attended_end occured after date_screening but before the start of order
    kpi4.kpi4_date_need_identified <= person_details.intervention_end_date;	
/* RQEV2-DYJQjL1zXh */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        kpi4.return_status_id,
        kpi4.reporting_date,
        kpi4.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label_quarter - putting year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi4.description,
        kpi4.ns_total AS out_court_no_yjs_total,
        kpi4.ns_start AS out_court_no_yjs_start,
        kpi4.ns_end AS out_court_no_yjs_end,
        kpi4.yjs_total AS yc_with_yjs_total,
        kpi4.yjs_start yc_with_yjs_start,
        kpi4.yjs_end AS yc_with_yjs_end,
        kpi4.ycc_total,
        kpi4.ycc_start,
        kpi4.ycc_end,
        kpi4.ro_total,
        kpi4.ro_start,
        kpi4.ro_end,
        kpi4.yro_total,
        kpi4.yro_start,
        kpi4.yro_end,
        kpi4.cust_total,
        kpi4.cust_start,
        kpi4.cust_end
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi4_mhew_v1" AS kpi4
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi4.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi4.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --total orders ending in the period
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0) + NVL(yc_with_yjs_total, 0) + NVL(ycc_total, 0) + NVL(ro_total, 0) + NVL(yro_total, 0) + NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS total_ypid,
    -- sub-measure: children identified as having mental health or emotional wellbeing need
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need,
    -- submeasures: number receiving mental health or emotional wellbeing treatment prior to the start of the order
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            ELSE NULL
        END
    ) AS kpi4_treatment_start,
    -- submeasures: mental health or emotional wellbeing need broken down by type of order
    --out of court disposals
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(out_court_no_yjs_end, 0)
            WHEN description = 'Getting Additional Help: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_oocd,
    -- youth cautions with yjs involvement
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(yc_with_yjs_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(yc_with_yjs_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_yc,
    -- youth conditional cautions
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(ycc_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(ycc_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_ycc,
    -- referral orders
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(ro_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(ro_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_ro,
    -- youth rehabilitation orders
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(yro_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(yro_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_yro,
    -- custodial sentences
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(cust_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_cust,
    -- total children in each type of order 
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_oocd,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(yc_with_yjs_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_yc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(ycc_total, 0)
        END
    ) AS kpi4_total_ycc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(ro_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_ro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(yro_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_yro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_cust,
    --submeasure: number of children that were offered different types of mental health treatment during their order
    -- offered_help
    SUM(
        CASE
            WHEN description = 'Getting Help: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_help,
    -- offered_additional_help
    SUM(
        CASE
            WHEN description = 'Getting Additional Help: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_additional_help,
    -- offered_risk_support
    SUM(
        CASE
            WHEN description = 'Getting Risk Support: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_risk_support,
    -- offered_advice
    SUM(
        CASE
            WHEN description = 'Getting Advice: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_advice,
    -- offered no intervention (no category for this so have to subtract from total)
    NVL(kpi4_mh_ew_need) - NVL(kpi4_offered_help, 0) - NVL(kpi4_offered_additional_help, 0) - NVL(kpi4_offered_risk_support, 0) - NVL(kpi4_offered_advice, 0) AS kpi4_offered_no_intervention,
    --submeasure: number of children that attended different types of mental health treatment during their order
    -- attended_help
    SUM(
        CASE
            WHEN description = 'Getting Help: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_help,
    -- attended_additional_help
    SUM(
        CASE
            WHEN description = 'Getting Additional Help: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_additional_help,
    -- attended_risk_support
    SUM(
        CASE
            WHEN description = 'Getting Risk Support: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_risk_support,
    -- attended_advice
    SUM(
        CASE
            WHEN description = 'Getting Advice: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_advice,
    -- offered intervention but not attended (no separate category for this)
    NVL(kpi4_offered_advice, 0) + NVL(kpi4_offered_help, 0) + NVL(kpi4_offered_additional_help, 0) + NVL(kpi4_offered_risk_support, 0) - NVL(kpi4_attended_advice, 0) - NVL(kpi4_attended_help, 0) - NVL(kpi4_attended_additional_help, 0) - NVL(kpi4_attended_risk_support, 0) AS kpi4_offered_but_not_attended,
    --headline measure: children with an identified mh/ew need that were offered an mh/ew intervention or was already receiving one when order began
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            WHEN description IN (
                'Getting Advice: Number of planned or offered interventions',
                'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing',
                'Getting Help: Number of planned or offered interventions',
                'Getting Risk Support: Number of planned or offered interventions'
            ) THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_offered
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

/* RQEV2-LN65IN0ilj */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- total orders ending in period (headline denominator)
        COUNT(DISTINCT ypid) AS total_ypid,
        -- total by type of order 
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
        -- KPI4 HEADLINE MEASURE
        COUNT(DISTINCT kpi4_mh_ew_offered) AS kpi4_mh_ew_offered,
        -- KPI4 SUB-MEASURES FIELDS
        COUNT(DISTINCT kpi4_mh_ew_need) AS kpi4_mh_ew_need,
        COUNT(DISTINCT kpi4_treatment_start) AS kpi4_treatment_start,
        COUNT(DISTINCT kpi4_mh_ew_need_oocd) AS kpi4_mh_ew_need_oocd,
        COUNT(DISTINCT kpi4_mh_ew_need_yc) AS kpi4_mh_ew_need_yc,
        COUNT(DISTINCT kpi4_mh_ew_need_ycc) AS kpi4_mh_ew_need_ycc,
        COUNT(DISTINCT kpi4_mh_ew_need_ro) AS kpi4_mh_ew_need_ro,
        COUNT(DISTINCT kpi4_mh_ew_need_yro) AS kpi4_mh_ew_need_yro,
        COUNT(DISTINCT kpi4_mh_ew_need_cust) AS kpi4_mh_ew_need_cust,
        COUNT(DISTINCT kpi4_offered_advice) AS kpi4_offered_advice,
        COUNT(DISTINCT kpi4_offered_help) AS kpi4_offered_help,
        COUNT(DISTINCT kpi4_offered_additional_help) AS kpi4_offered_additional_help,
        COUNT(DISTINCT kpi4_offered_risk_support) AS kpi4_offered_risk_support,
        COUNT(DISTINCT kpi4_offered_no_intervention) AS kpi4_offered_no_intervention,
        COUNT(DISTINCT kpi4_attended_advice) AS kpi4_attended_advice,
        COUNT(DISTINCT kpi4_attended_help) AS kpi4_attended_help,
        COUNT(DISTINCT kpi4_attended_additional_help) AS kpi4_attended_additional_help,
        COUNT(DISTINCT kpi4_attended_risk_support) AS kpi4_attended_risk_support,
        COUNT(DISTINCT kpi4_offered_but_not_attended) AS kpi4_offered_but_not_attended
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi4_mh_case_level_v8"
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
        summary_person.area_operations,
        summary_t.area_operations
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
        ) END AS DATE
    ) AS quarter_label_date,
    'KPI 4' AS kpi_number,
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi4_mh_ew_need > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    -- KPI4 HEADLINE MEASURE: children with an identified mental health or emotional wellbeing need during their order and was offered an MH/EW intervention or was already receiving one when order began
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_offered
            ELSE summary_cl.kpi4_mh_ew_offered
        END,
        0
    ) AS kpi4_mh_ew_offered,
    -- KPI4 SUB-MEASURES FIELDS
    -- Sub-measure: number of children with a mental health or emotional wellbeing need (in intervention at start of order + identified as having a need through screening)
    -- numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need
            ELSE summary_cl.kpi4_mh_ew_need
        END,
        0
    ) AS kpi4_mh_ew_need,
    -- denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS kpi4_total_ypid,
    -- sub-measure: number of children who were receiving treatment prior to the order starting (still ongoing when the order started)
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_treatment_start
            ELSE summary_cl.kpi4_treatment_start
        END,
        0
    ) AS kpi4_treatment_start,
    -- sub-measure: number of children with mental health or emotional wellbeing need broken down by type of order
    -- numerators: need in each type of order
    -- out of court disposals
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_oocd
            ELSE summary_cl.kpi4_mh_ew_need_oocd
        END,
        0
    ) AS kpi4_mh_ew_need_oocd,
    -- youth cautions with yjs involvement
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_yc
            ELSE summary_cl.kpi4_mh_ew_need_yc
        END,
        0
    ) AS kpi4_mh_ew_need_yc_with_yjs,
    -- youth conditional cautions
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_ycc
            ELSE summary_cl.kpi4_mh_ew_need_ycc
        END,
        0
    ) AS kpi4_mh_ew_need_ycc,
    -- referral orders
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_ro
            ELSE summary_cl.kpi4_mh_ew_need_ro
        END,
        0
    ) AS kpi4_mh_ew_need_ro,
    -- youth rehabilitation orders
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_yro
            ELSE summary_cl.kpi4_mh_ew_need_yro
        END,
        0
    ) AS kpi4_mh_ew_need_yro,
    -- custody
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need_cust
            ELSE summary_cl.kpi4_mh_ew_need_cust
        END,
        0
    ) AS kpi4_mh_ew_need_cust,
    -- denominator: total by type of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_oocd
            ELSE summary_person.total_ypid_oocd
        END,
        0
    ) AS kpi4_total_ypid_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_yc
            ELSE summary_person.total_ypid_yc
        END,
        0
    ) AS kpi4_total_ypid_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_ycc
            ELSE summary_person.total_ypid_ycc
        END,
        0
    ) AS kpi4_total_ypid_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_ro
            ELSE summary_person.total_ypid_ro
        END,
        0
    ) AS kpi4_total_ypid_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_yro
            ELSE summary_person.total_ypid_yro
        END,
        0
    ) AS kpi4_total_ypid_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_total_cust
            ELSE summary_person.total_ypid_cust
        END,
        0
    ) AS kpi4_total_ypid_cust,
    -- submeasure: number of children offered the 4 types of mental health / emotional wellbeing interventions/treatment
    -- offered help
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_help
            ELSE summary_cl.kpi4_offered_help
        END,
        0
    ) AS kpi4_offered_help,
    -- offered additional help
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_additional_help
            ELSE summary_cl.kpi4_offered_additional_help
        END,
        0
    ) AS kpi4_offered_additional_help,
    -- offered risk support
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_risk_support
            ELSE summary_cl.kpi4_offered_risk_support
        END,
        0
    ) AS kpi4_offered_risk_support,
    -- offered advice
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_advice
            ELSE summary_cl.kpi4_offered_advice
        END,
        0
    ) AS kpi4_offered_advice,
    -- offered no intervention - no figures for template (unless we were to take all orders minus the addition of those in each intervention?)
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_no_intervention
            ELSE summary_cl.kpi4_offered_no_intervention
        END,
        0
    ) AS kpi4_offered_no_intervention,
    --submeasure: number of children who attended the 4 types of mental health / emotional wellbeing interventions/treatments
    -- attended help
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_attended_help
            ELSE summary_cl.kpi4_attended_help
        END,
        0
    ) AS kpi4_attended_help,
    -- attended additional help
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_attended_additional_help
            ELSE summary_cl.kpi4_attended_additional_help
        END,
        0
    ) AS kpi4_attended_additional_help,
    -- attended risk support
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_attended_risk_support
            ELSE summary_cl.kpi4_attended_risk_support
        END,
        0
    ) AS kpi4_attended_risk_support,
    -- attended getting advice
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_attended_advice
            ELSE summary_cl.kpi4_attended_advice
        END,
        0
    ) AS kpi4_attended_advice,
    -- offered intervention but did not attended 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_offered_but_not_attended
            ELSE summary_cl.kpi4_offered_but_not_attended
        END,
        0
    ) AS kpi4_offered_but_not_attended
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi4_mh_template_v8 AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-Ph2f6IMGvY */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        kpi4.return_status_id,
        kpi4.reporting_date,
        kpi4.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label_quarter - putting year first and quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi4.description,
        kpi4.ns_total AS out_court_no_yjs_total,
        kpi4.ns_start AS out_court_no_yjs_start,
        kpi4.ns_end AS out_court_no_yjs_end,
        kpi4.yjs_total AS yc_with_yjs_total,
        kpi4.yjs_start yc_with_yjs_start,
        kpi4.yjs_end AS yc_with_yjs_end,
        kpi4.ycc_total,
        kpi4.ycc_start,
        kpi4.ycc_end,
        kpi4.ro_total,
        kpi4.ro_start,
        kpi4.ro_end,
        kpi4.yro_total,
        kpi4.yro_start,
        kpi4.yro_end,
        kpi4.cust_total,
        kpi4.cust_start,
        kpi4.cust_end
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi4_mhew_v1" AS kpi4
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi4.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi4.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --total orders ending in the period
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0) + NVL(yc_with_yjs_total, 0) + NVL(ycc_total, 0) + NVL(ro_total, 0) + NVL(yro_total, 0) + NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS total_ypid,
    -- Headline measure: mental health or emotional wellbeing need
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need,
    -- submeasures: number receiving mental health or emotional wellbeing treatment prior to the start of the order
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            ELSE NULL
        END
    ) AS kpi4_treatment_prior_order,
    -- submeasures: mental health or emotional wellbeing need broken down by type of order
    --out of court disposals
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN out_court_no_yjs_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN out_court_no_yjs_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_oocd,
    -- youth cautions with yjs involvement
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN yc_with_yjs_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN yc_with_yjs_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_yc,
    -- youth conditional cautions
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN ycc_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN ycc_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_ycc,
    -- referral orders
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN ro_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN ro_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_ro,
    -- youth rehabilitation orders
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN yro_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN yro_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_yro,
    -- custodial sentences
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN cust_start
            WHEN description = 'Number of children with a screened OR identified need for an intervention to improve mental health or emotional wellbeing' THEN cust_end
            ELSE NULL
        END
    ) AS kpi4_mh_ew_need_cust,
    -- total children in each type of order 
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_oocd,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(yc_with_yjs_total, 0) 
            ELSE NULL
        END
    ) AS kpi4_total_yc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(ycc_total, 0) 
        END
    ) AS kpi4_total_ycc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(ro_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_ro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(yro_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_yro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS kpi4_total_cust,
    --submeasure: number of children that were offered different types of mental health treatment during their order
    -- offered_help
    SUM(
        CASE
            WHEN description = 'Getting Help: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_help,
    -- offered_additional_help
    SUM(
        CASE
            WHEN description = 'Getting Additional Help: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_additional_help,
    -- offered_risk_support
    SUM(
        CASE
            WHEN description = 'Getting Risk Support: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_risk_support,
    -- offered_advice
    SUM(
        CASE
            WHEN description = 'Getting Advice: Number of planned or offered interventions' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_offered_advice,
    -- offered no intervention (no category for this so have to subtract from total)
    NVL(kpi4_mh_ew_need) - NVL(kpi4_offered_help) - NVL(kpi4_offered_additional_help) - NVL(kpi4_offered_risk_support) - NVL(kpi4_offered_advice) AS kpi4_offered_no_intervention,
    --submeasure: number of children that attended different types of mental health treatment during their order
    -- attended_help
    SUM(
        CASE
            WHEN description = 'Getting Help: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_help,
    -- attended_additional_help
    SUM(
        CASE
            WHEN description = 'Getting Additional Help: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_additional_help,
    -- attended_risk_support
    SUM(
        CASE
            WHEN description = 'Getting Risk Support: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_risk_support,
    -- attended_advice
    SUM(
        CASE
            WHEN description = 'Getting Advice: Number of children attending intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi4_attended_advice,
    -- attended no intervention (no category for this so have to subtract from total)
    NVL(kpi4_mh_ew_need) - NVL(kpi4_attended_help) - NVL(kpi4_attended_additional_help) - NVL(kpi4_attended_risk_support) - NVL(kpi4_attended_advice) AS kpi4_attended_no_intervention
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
/* RQEV2-RbqCrVb7yU */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_case_level distkey (kpi5_source_document_id) sortkey (kpi5_source_document_id) AS WITH kpi5 AS (
    SELECT
        dc.source_document_id as kpi5_source_document_id,
        sm."kpi5SMDateScreened" :: date as kpi5_date_screened,
        sm."kpi5SMDateReferred" :: date as kpi5_date_referred,
        sm."kpi5SMDateOffered" :: date as kpi5_date_offered,
        sm."kpi5SMDateAttendedStart" :: date as kpi5_date_attended_start,
        sm."kpi5SMDateAttendedEnd" :: date as kpi5_date_attended_end,
        sm."kpi5SMInterventionType" :: text as kpi5_intervention_type
    FROM
        stg.yp_doc_item dc,
        dc.document_item."substanceMisuse"."kpi5SubstanceMisuse" AS sm
    WHERE
        document_item_type = 'health'
        AND sm."kpi5SMDateScreened" is not NULL
)
SELECT
    DISTINCT kpi5.*,
    person_details.*,
    --calculate the last day of previous quarter
    -- possibly add filters to make date offered before this date to be used to calculate attendance (so we report a quarter later on a quarter) -- not used in V5 though
    -- CASE
    --     WHEN person_details.quarter IN ('Q2', 'Q3', 'Q4') THEN CAST(
    --         DATEADD(month, -3, person_details.last_day_of_quarter) AS DATE
    --     )
    --     ELSE CAST(CONCAT(person_details.year, '-03-31') AS DATE)
    -- END AS last_day_of_previous_quarter,
    --submeasure: was receiving treatment prior to the order starting (but was open at the time the order started)
    CASE
        WHEN yjb_kpi_case_level.f_inTreatmentPrior(
            kpi5.kpi5_date_attended_start,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date,
            kpi5.kpi5_date_attended_end
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_treatment_prior_order,
    -- headline measure: identified as having a substance misuses need during their order
    -- must i check there was no attended end date before the start of the order?
    CASE
        WHEN kpi5.kpi5_date_screened <> '1900-01-01'
        OR kpi5_treatment_prior_order IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need,
    /*Submeasures - BREAKDOWN BY ORDER */
    --identified substance misuse need at end of order for out of court disposals
    CASE
        WHEN person_details.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_oocd,
    -- identified substance misuse need at end of order for youth cautions
    CASE
        WHEN person_details.type_of_order = 'Youth Cautions with YJS intervention'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_yc,
    -- identified substance misuse need at end of order for youth conditional cautions
    CASE
        WHEN person_details.type_of_order = 'Youth Conditional Cautions'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_ycc,
    -- identified substance misuse need at end of order for referral orders
    CASE
        WHEN person_details.type_of_order = 'Referral Orders'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_ro,
    -- identified substance misuse need at end of order for youth rehabilitation orders
    CASE
        WHEN person_details.type_of_order = 'Youth Rehabilitation Orders'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_yro,
    -- identified substance misuse need at end of order for custodial sentences
    CASE
        WHEN person_details.type_of_order = 'Custodial sentences'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_cust,
    /* submeasure: treatment offered 
     use only those that were offered before the start of the previous order to allow for enough time for children to start intervention in order they intervention finished */
    -- targeted intervention offered
    CASE
        WHEN kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
        AND kpi5.kpi5_date_offered <= person_details.intervention_end_date
        AND kpi5.kpi5_date_offered >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_targeted_intervention,
    -- specialist_substance_misuse_treatment offered
    CASE
        WHEN kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
        AND kpi5.kpi5_date_offered <= person_details.intervention_end_date
        AND kpi5.kpi5_date_offered >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_specialist_substance_misuse_treatment,
    -- complex_care offered
    CASE
        WHEN kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
        AND kpi5.kpi5_date_offered <= person_details.intervention_end_date
        AND kpi5.kpi5_date_offered >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_complex_care,
    -- child was offered 'no intervention' -- not sure if this makes sense as there are instances where they attend an intervention but still have 1900 in offered
    CASE
        WHEN kpi5.kpi5_intervention_type = 'NO_INTERVENTION'
        AND kpi5.kpi5_date_offered = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_no_intervention,
    /* submeasure: treatment attended
     Only measured for the children that were offered intervention by the end of the previous quarter
     child has the chance to attend the treatment up until the end of the quarter their order finished in. */
    -- kpi5_attended_targeted_intervention
    CASE
        WHEN kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
        AND kpi5.kpi5_date_attended_start <= person_details.intervention_end_date
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_offered
        AND kpi5.kpi5_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_targeted_intervention,
    -- kpi5_attended_specialist_substance_misuse_treatment
    CASE
        WHEN kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
        AND kpi5.kpi5_date_attended_start <= person_details.intervention_end_date
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_offered
        AND kpi5.kpi5_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_specialist_substance_misuse_treatment,
    -- kpi5_attended_complex_care
    CASE
        WHEN kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
        AND kpi5.kpi5_date_attended_start <= person_details.intervention_end_date
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_screened
        AND kpi5.kpi5_date_attended_start >= kpi5.kpi5_date_offered
        AND kpi5.kpi5_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_complex_care,
    -- child was attended 'no intervention'
    CASE
        WHEN kpi5.kpi5_intervention_type = 'NO_INTERVENTION'
        AND kpi5.kpi5_date_attended_start = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_no_intervention,
    -- child didnt need intervention -- not needed for anything but may be interesting to know
    CASE
        WHEN kpi5.kpi5_intervention_type = 'NO_INTERVENTION'
        AND kpi5.kpi5_date_screened = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_no_screening_no_intervention
FROM
    kpi5
    INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi5.kpi5_source_document_id = person_details.source_document_id
WHERE
    kpi5.kpi5_date_screened <= person_details.intervention_end_date;	
/* RQEV2-LuWPzAtWtz */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_case_level_v8 distkey (kpi5_source_document_id) sortkey (kpi5_source_document_id) AS WITH kpi5 AS (
    SELECT
        dc.source_document_id as kpi5_source_document_id,
        sm."kpi5SMDateScreened" :: date as kpi5_date_need_identified,
        sm."kpi5SMDateReferred" :: date as kpi5_date_referred,
        sm."kpi5SMDateOffered" :: date as kpi5_date_offered,
        sm."kpi5SMDateAttendedStart" :: date as kpi5_date_attended_start,
        sm."kpi5SMDateAttendedEnd" :: date as kpi5_date_attended_end,
        sm."kpi5SMInterventionType" :: text as kpi5_intervention_type
    FROM
        stg.yp_doc_item dc,
        dc.document_item."substanceMisuse"."kpi5SubstanceMisuse" AS sm
    WHERE
        document_item_type = 'health'
        AND sm."kpi5SMDateScreened" is not NULL
)
SELECT
    DISTINCT kpi5.*,
    person_details.*,
    --submeasure: was receiving treatment prior to the order starting (but was open at the time the order started)
    CASE
        WHEN yjb_kpi_case_level.f_inTreatmentPrior(
            kpi5.kpi5_date_attended_start,
            person_details.legal_outcome_group_fixed,
            person_details.disposal_type_fixed,
            person_details.outcome_date,
            person_details.intervention_start_date,
            kpi5.kpi5_date_attended_end
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_treatment_start,
    -- sub-measure: identified as having a substance misuses need during their order
    CASE
        WHEN kpi5.kpi5_date_need_identified <> '1900-01-01'
        OR kpi5_treatment_start IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need,
    /*Submeasures: SM need by type of order */
    --identified substance misuse need at end of order for out of court disposals
    CASE
        WHEN person_details.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_oocd,
    -- identified substance misuse need at end of order for youth cautions
    CASE
        WHEN person_details.type_of_order = 'Youth Cautions with YJS intervention'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_yc,
    -- identified substance misuse need at end of order for youth conditional cautions
    CASE
        WHEN person_details.type_of_order = 'Youth Conditional Cautions'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_ycc,
    -- identified substance misuse need at end of order for referral orders
    CASE
        WHEN person_details.type_of_order = 'Referral Orders'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_ro,
    -- identified substance misuse need at end of order for youth rehabilitation orders
    CASE
        WHEN person_details.type_of_order = 'Youth Rehabilitation Orders'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_yro,
    -- identified substance misuse need at end of order for custodial sentences
    CASE
        WHEN person_details.type_of_order = 'Custodial sentences'
        AND kpi5_sm_need IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_need_cust,
    /* submeasure: treatment offered */
    -- targeted intervention offered
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
            AND kpi5.kpi5_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_targeted_intervention,
    -- specialist_substance_misuse_treatment offered
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
            AND kpi5.kpi5_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_specialist_sm_treatment,
    -- complex_care offered
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
            AND kpi5.kpi5_date_offered BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_complex_care,
    -- child was offered 'no intervention' 
    CASE
        WHEN kpi5.kpi5_intervention_type = 'NO_INTERVENTION'
        AND kpi5.kpi5_date_offered = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_no_intervention,
    /* submeasure: treatment attended */
    -- kpi5_attended_targeted_intervention
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
            AND kpi5.kpi5_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'TARGETED_INTERVENTION'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_targeted_intervention,
    -- kpi5_attended_specialist_substance_misuse_treatment
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
            AND kpi5.kpi5_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'SPECIALIST_SUBSTANCE_MISUSE_TREATMENT'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_specialist_sm_treatment,
    -- kpi5_attended_complex_care
    CASE
        WHEN (
            kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
            AND kpi5.kpi5_date_attended_start BETWEEN person_details.intervention_start_date
            AND person_details.intervention_end_date
        )
        OR (
            kpi5.kpi5_intervention_type = 'COMPLEX_CARE'
            AND kpi5_treatment_start = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_attended_complex_care,
    -- child was attended 'no intervention'
    CASE
        WHEN kpi5.kpi5_date_offered BETWEEN person_details.intervention_start_date
        AND person_details.intervention_end_date
        AND kpi5.kpi5_date_attended_start = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi5_offered_but_not_attended,
    -- headline measure: children with an identified substance misuse need during their order and was offered a substance misuse intervention or was already receiving one when order began
    CASE
        WHEN kpi5_sm_need = person_details.ypid
        AND (
            kpi5_treatment_start = person_details.ypid
            OR kpi5_offered_targeted_intervention = person_details.ypid
            OR kpi5_offered_specialist_sm_treatment = person_details.ypid
            OR kpi5_offered_complex_care = person_details.ypid
        ) THEN person_details.ypid
        ELSE NULL
    END AS kpi5_sm_offered
FROM
    kpi5
    INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi5.kpi5_source_document_id = person_details.source_document_id
WHERE
    kpi5.kpi5_date_need_identified <= person_details.intervention_end_date;	

    /* RQEV2-rh7jIcjerz */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
        ns_total AS out_court_no_yjs_total,
        ns_start AS out_court_no_yjs_start,
        ns_end AS out_court_no_yjs_end,
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
        cust_end
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi5_substance_misuse_v1" AS kpi5
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi5.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi5.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --total orders ending in the period
    SUM (
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0) + NVL(yc_with_yjs_total, 0) + NVL(ycc_total, 0) + NVL(ro_total, 0) + NVL(yro_total, 0) + NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS total_ypid,
    --submeasure: number of children with a screened or identified need for intervention/treatment to address substance misuse
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need,
    -- submeasure: were receiving treatment prior to the start of the order
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            ELSE NULL
        END
    ) AS kpi5_treatment_start,
    /*SUBMEASURES: NEED BREAKDOWN BY ORDER*/
    -- kpi5_sm_need_oocd 
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(out_court_no_yjs_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_oocd,
    -- kpi5_sm_need_yc
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(yc_with_yjs_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(yc_with_yjs_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_yc,
    -- kpi5_sm_need_ycc
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(ycc_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(ycc_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_ycc,
    -- kpi5_sm_need_ro
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(ro_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(ro_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_ro,
    -- kpi5_sm_need_yro
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(yro_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(yro_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_yro,
    -- kpi5_sm_need_cust
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN NVL(cust_start, 0)
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_need_cust,
    -- total children in each type of order 
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(out_court_no_yjs_total, 0)
            ELSE NULL
        END
    ) AS kpi5_total_oocd,
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(yc_with_yjs_total, 0)
            ELSE NULL
        END
    ) AS kpi5_total_yc,
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(ycc_total, 0)
        END
    ) AS kpi5_total_ycc,
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(ro_total, 0)
            ELSE NULL
        END
    ) AS kpi5_total_ro,
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(yro_total, 0)
            ELSE NULL
        END
    ) AS kpi5_total_yro,
    SUM(
        CASE
            WHEN description = 'Number of children with an order ending in the period' THEN NVL(cust_total, 0)
            ELSE NULL
        END
    ) AS kpi5_total_cust,
    /*TYPE OF SM INTERVENTION*/
    --submeasure: number of children that were offered different types of substance misuse treatment during their order
    -- offered_targeted_intervention
    SUM(
        CASE
            WHEN description = 'Number offered targeted intervention/treatment.' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_offered_targeted_intervention,
    -- offered_specialist_treatment
    SUM(
        CASE
            WHEN description = 'Number offered specialist substance misuse treatment' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_offered_specialist_sm_treatment,
    -- offered_risk_support
    SUM(
        CASE
            WHEN description = 'Number offered complex care treatment intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_offered_complex_care,
    -- offered no intervention (no category for this so have to subtract from total)
    NVL(kpi5_sm_need, 0),
    - NVL(kpi5_offered_targeted_intervention, 0)
    - NVL(kpi5_offered_specialist_sm_treatment, 0)
    - NVL(kpi5_offered_complex_care, 0) AS kpi5_offered_no_intervention,
    --submeasure: number of children who attended different types of substance misuse treatment during their order
    -- kpi5_attended_targeted_intervention
    SUM(
        CASE
            WHEN description = 'Number attending targeted intervention/treatment.' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_attended_targeted_intervention,
    -- kpi5_attended_specialist_substance_misuse_treatment
    SUM(
        CASE
            WHEN description = 'Number attending specialist substance misuse treatment ' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_attended_specialist_sm_treatment,
    -- kpi5_attended_complex_care
    SUM(
        CASE
            WHEN description = 'Number attending complex care treatment intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_attended_complex_care,
    -- children who were offered an intervention but did not attend (no separate category in template available)
    NVL(kpi5_offered_targeted_intervention, 0) 
    + NVL(kpi5_offered_specialist_sm_treatment, 0) 
    + NVL(kpi5_offered_complex_care, 0) 
    - NVL(kpi5_attended_targeted_intervention, 0) 
    - NVL(kpi5_attended_specialist_sm_treatment, 0) 
    - NVL(kpi5_attended_complex_care, 0) AS kpi5_offered_but_not_attended,
    -- headline measure: children with an identified substance misuse need during their order and was offered a substance misuse intervention or was already receiving one when order began
    SUM(
        CASE
            WHEN description IN (
                'Number receiving treatment for mental health or emotional wellbeing prior to screening by YJS',
                'Number receiving treatment for mental health or emotional wellbeing prior to the start of the order'
            ) THEN NVL(out_court_no_yjs_start, 0) + NVL(yc_with_yjs_start, 0) + NVL(ycc_start, 0) + NVL(ro_start, 0) + NVL(yro_start, 0) + NVL(cust_start, 0)
            WHEN description IN (
                'Number offered targeted intervention/treatment.',
                'Number offered specialist substance misuse treatment',
                'Number offered complex care treatment intervention'
            ) THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_sm_offered
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

    /* RQEV2-pFGW1pj0jA */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi5_substance_m_summary_v8 cascade;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- total orders ending in period (headline denominator)
        COUNT(DISTINCT ypid) AS total_ypid,
        -- total by type of order 
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
        -- kPI5 HEADLINE MEASURE
        COUNT(DISTINCT kpi5_sm_offered) AS kpi5_sm_offered,
        -- KPI5 SUB-MEASURE FIELDS
        COUNT(DISTINCT kpi5_sm_need) AS kpi5_sm_need,
        COUNT(DISTINCT kpi5_treatment_start) AS kpi5_treatment_start,
        COUNT(DISTINCT kpi5_sm_need_oocd) AS kpi5_sm_need_oocd,
        COUNT(DISTINCT kpi5_sm_need_yc) AS kpi5_sm_need_yc,
        COUNT(DISTINCT kpi5_sm_need_ycc) AS kpi5_sm_need_ycc,
        COUNT(DISTINCT kpi5_sm_need_ro) AS kpi5_sm_need_ro,
        COUNT(DISTINCT kpi5_sm_need_yro) AS kpi5_sm_need_yro,
        COUNT(DISTINCT kpi5_sm_need_cust) AS kpi5_sm_need_cust,
        COUNT(DISTINCT kpi5_offered_targeted_intervention) AS kpi5_offered_targeted_intervention,
        COUNT(
            DISTINCT kpi5_offered_specialist_sm_treatment
        ) AS kpi5_offered_specialist_sm_treatment,
        COUNT(DISTINCT kpi5_offered_complex_care) AS kpi5_offered_complex_care,
        COUNT(DISTINCT kpi5_offered_no_intervention) AS kpi5_offered_no_intervention,
        COUNT(DISTINCT kpi5_attended_targeted_intervention) AS kpi5_attended_targeted_intervention,
        COUNT(
            DISTINCT kpi5_attended_specialist_sm_treatment
        ) AS kpi5_attended_specialist_sm_treatment,
        COUNT(DISTINCT kpi5_attended_complex_care) AS kpi5_attended_complex_care,
        COUNT(DISTINCT kpi5_offered_but_not_attended) AS kpi5_offered_but_not_attended
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi5_substance_m_case_level_v8"
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
        ) END AS DATE
    ) AS quarter_label_date,
    'KPI 5' AS kpi_number,
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi5_sm_need > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    -- KPI5 HEADLINE MEASURE: children with an identified substance misuse need during their order and was offered a substance misuse intervention or was already receiving one when order began
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_offered
            ELSE summary_cl.kpi5_sm_offered
        END,
        0
    ) AS kpi5_sm_offered,
    -- KPI5 SUB-MEASURE FIELDS
    -- Sub-measure: children with an identified substance misuse need
    -- numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need
            ELSE summary_cl.kpi5_sm_need
        END,
        0
    ) AS kpi5_sm_need,
    -- denominator: total orders ending in the period
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS Kpi5_total_ypid,
    --sub-measure: children already attending sm intervention at start of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_treatment_start
            ELSE summary_cl.kpi5_treatment_start
        END,
        0
    ) AS kpi5_treatment_start,
    -- sub-measure: children with an sm need broken down by type of order
    -- numerators: need by type of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_oocd
            ELSE summary_cl.kpi5_sm_need_oocd
        END,
        0
    ) AS kpi5_sm_need_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_yc
            ELSE summary_cl.kpi5_sm_need_yc
        END,
        0
    ) AS kpi5_sm_need_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_ycc
            ELSE summary_cl.kpi5_sm_need_ycc
        END,
        0
    ) AS kpi5_sm_need_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_ro
            ELSE summary_cl.kpi5_sm_need_ro
        END,
        0
    ) AS kpi5_sm_need_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_yro
            ELSE summary_cl.kpi5_sm_need_yro
        END,
        0
    ) AS kpi5_sm_need_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_cust
            ELSE summary_cl.kpi5_sm_need_cust
        END,
        0
    ) AS kpi5_sm_need_cust,
    -- denominators: total by type of order 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_oocd
            ELSE summary_person.total_ypid_oocd
        END,
        0
    ) AS kpi5_total_ypid_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_yc
            ELSE summary_person.total_ypid_yc
        END,
        0
    ) AS kpi5_total_ypid_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_ycc
            ELSE summary_person.total_ypid_ycc
        END,
        0
    ) AS kpi5_total_ypid_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_ro
            ELSE summary_person.total_ypid_ro
        END,
        0
    ) AS kpi5_total_ypid_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_yro
            ELSE summary_person.total_ypid_yro
        END,
        0
    ) AS kpi5_total_ypid_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_cust
            ELSE summary_person.total_ypid_cust
        END,
        0
    ) AS kpi5_total_ypid_cust,
    /*sub-measure: children offered and attending different sm interventions*/
    --Offered intervention
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_targeted_intervention
            ELSE summary_cl.kpi5_offered_targeted_intervention
        END,
        0
    ) AS kpi5_offered_targeted_intervention,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_specialist_sm_treatment
            ELSE summary_cl.kpi5_offered_specialist_sm_treatment
        END,
        0
    ) AS kpi5_offered_specialist_sm_treatment,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_complex_care
            ELSE summary_cl.kpi5_offered_complex_care
        END,
        0
    ) AS kpi5_offered_complex_care,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_no_intervention
            ELSE summary_cl.kpi5_offered_no_intervention
        END,
        0
    ) AS kpi5_offered_no_intervention,
    --attended intervention
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_targeted_intervention
            ELSE summary_cl.kpi5_attended_targeted_intervention
        END,
        0
    ) AS kpi5_attended_targeted_intervention,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_specialist_sm_treatment
            ELSE summary_cl.kpi5_attended_specialist_sm_treatment
        END,
        0
    ) AS kpi5_attended_specialist_sm_treatment,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_complex_care
            ELSE summary_cl.kpi5_attended_complex_care
        END,
        0
    ) AS kpi5_attended_complex_care,
    -- offered intervention but did not attended 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_but_not_attended
            ELSE summary_cl.kpi5_offered_but_not_attended
        END,
        0
    ) AS kpi5_offered_but_not_attended
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi5_substance_m_template_v8 AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	

/* RQEV2-gvUkUAKbv8 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- total orders ending in period (headline denominator)
        COUNT(DISTINCT ypid) AS total_ypid,
        -- total by type of order 
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
        COUNT(DISTINCT kpi5_sm_need) AS kpi5_sm_need,
        -- KPI5 SUB-MEASURE FIELDS
        COUNT(DISTINCT kpi5_treatment_prior_order) AS kpi5_treatment_prior_order,
        COUNT(DISTINCT kpi5_sm_need_oocd) AS kpi5_sm_need_oocd,
        COUNT(DISTINCT kpi5_sm_need_yc) AS kpi5_sm_need_yc,
        COUNT(DISTINCT kpi5_sm_need_ycc) AS kpi5_sm_need_ycc,
        COUNT(DISTINCT kpi5_sm_need_ro) AS kpi5_sm_need_ro,
        COUNT(DISTINCT kpi5_sm_need_yro) AS kpi5_sm_need_yro,
        COUNT(DISTINCT kpi5_sm_need_cust) AS kpi5_sm_need_cust,
        COUNT(DISTINCT kpi5_offered_targeted_intervention) AS kpi5_offered_targeted_intervention,
        COUNT(
            DISTINCT kpi5_offered_specialist_substance_misuse_treatment
        ) AS kpi5_offered_specialist_substance_misuse_treatment,
        COUNT(DISTINCT kpi5_offered_complex_care) AS kpi5_offered_complex_care,
        COUNT(DISTINCT kpi5_offered_no_intervention) AS kpi5_offered_no_intervention,
        COUNT(DISTINCT kpi5_attended_targeted_intervention) AS kpi5_attended_targeted_intervention,
        COUNT(
            DISTINCT kpi5_attended_specialist_substance_misuse_treatment
        ) AS kpi5_attended_specialist_substance_misuse_treatment,
        COUNT(DISTINCT kpi5_attended_complex_care) AS kpi5_attended_complex_care,
        COUNT(DISTINCT kpi5_attended_no_intervention) AS kpi5_attended_no_intervention
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi5_substance_m_case_level"
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
            OR summary_t.kpi5_sm_need > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --headline denominator: total orders ending in the period
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS total_ypid,
    --headline numerator: children with an identified substance misuse need
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need
            ELSE summary_cl.kpi5_sm_need
        END,
        0
    ) AS kpi5_sm_need,
    --KPI5 SUB-MEASURE FIELDS
    --kpi5_treatment_prior_order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_treatment_prior_order
            ELSE summary_cl.kpi5_treatment_prior_order
        END,
        0
    ) AS kpi5_treatment_prior_order,
    --BROKEN DOWN BY TYPE OF ORDER
    -- need by type of order
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_oocd
            ELSE summary_cl.kpi5_sm_need_oocd
        END,
        0
    ) AS kpi5_sm_need_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_yc
            ELSE summary_cl.kpi5_sm_need_yc
        END,
        0
    ) AS kpi5_sm_need_yc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_ycc
            ELSE summary_cl.kpi5_sm_need_ycc
        END,
        0
    ) AS kpi5_sm_need_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_ro
            ELSE summary_cl.kpi5_sm_need_ro
        END,
        0
    ) AS kpi5_sm_need_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_yro
            ELSE summary_cl.kpi5_sm_need_yro
        END,
        0
    ) AS kpi5_sm_need_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_sm_need_cust
            ELSE summary_cl.kpi5_sm_need_cust
        END,
        0
    ) AS kpi5_sm_need_cust,
    -- total by type of order 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_oocd
            ELSE summary_person.total_ypid_oocd
        END,
        0
    ) AS kpi5_total_ypid_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_yc
            ELSE summary_person.total_ypid_yc
        END,
        0
    ) AS kpi5_total_ypid_yc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_ycc
            ELSE summary_person.total_ypid_ycc
        END,
        0
    ) AS kpi5_total_ypid_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_ro
            ELSE summary_person.total_ypid_ro
        END,
        0
    ) AS kpi5_total_ypid_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_yro
            ELSE summary_person.total_ypid_yro
        END,
        0
    ) AS kpi5_total_ypid_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_total_cust
            ELSE summary_person.total_ypid_cust
        END,
        0
    ) AS kpi5_total_ypid_cust,
    /*BROKEN DOWN BY TYPE OF SM INTERVENTION*/
    --Offered - only case level
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_targeted_intervention
            ELSE summary_cl.kpi5_offered_targeted_intervention
        END,
        0
    ) AS kpi5_offered_targeted_intervention,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_specialist_substance_misuse_treatment
            ELSE summary_cl.kpi5_offered_specialist_substance_misuse_treatment
        END,
        0
    ) AS kpi5_offered_specialist_substance_misuse_treatment,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_complex_care
            ELSE summary_cl.kpi5_offered_complex_care
        END,
        0
    ) AS kpi5_offered_complex_care,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_offered_no_intervention
            ELSE summary_cl.kpi5_offered_no_intervention
        END,
        0
    ) AS kpi5_offered_no_intervention,
    --attended - for template and case level
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_targeted_intervention
            ELSE summary_cl.kpi5_offered_targeted_intervention
        END,
        0
    ) AS kpi5_attended_targeted_intervention,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_specialist_substance_misuse_treatment
            ELSE summary_cl.kpi5_attended_specialist_substance_misuse_treatment
        END,
        0
    ) AS kpi5_attended_specialist_substance_misuse_treatment,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_complex_care
            ELSE summary_cl.kpi5_attended_complex_care
        END,
        0
    ) AS kpi5_attended_complex_care,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi5_attended_no_intervention
            ELSE summary_cl.kpi5_attended_no_intervention
        END,
        0
    ) AS kpi5_attended_no_intervention
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi5_substance_m_template AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-YOFlPVLrnr */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
/*CTE for values that appear in numerator and denominator*/
--required as when a column is pivoted usinng unpivot, the column name is not available in the unpivoted table so has to be pulled from here instead
WITH numerators_and_denominators AS (
    SELECT
        yjs_name,
        quarter_label,
        kpi5_sm_need,
        kpi5_offered_targeted_intervention,
        kpi5_offered_specialist_sm_treatment,
        kpi5_offered_complex_care,
        kpi5_sm_offered
    FROM
        yjb_kpi_case_level.kpi5_substance_m_summary_v8
)
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
    'Substance Misuse' AS kpi_name,
    'Children with substance misuse needs' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start or end of order 
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%not_attended%' THEN 'During'
        ELSE 'Start or During'
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
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'Out of court disposals'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'Youth rehabilitation orders'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'Referral orders'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'Custodial sentences'
        /* offered & attended */
        WHEN unpvt_table.measure_numerator LIKE '%offered_targeted%' THEN 'Offered targeted intervention'
        WHEN unpvt_table.measure_numerator LIKE '%offered_specialist%' THEN 'Offered specialist SM treatment'
        WHEN unpvt_table.measure_numerator LIKE '%offered_complex%' THEN 'Offered complex care'
        WHEN unpvt_table.measure_numerator LIKE '%offered_no_intervention%' THEN 'Offered nothing'
        WHEN unpvt_table.measure_numerator LIKE '%attended_targeted%' THEN 'Attended targeted intervention'
        WHEN unpvt_table.measure_numerator LIKE '%attended_specialist%' THEN 'Attended specialist SM treatment'
        WHEN unpvt_table.measure_numerator LIKE '%attended_complex%' THEN 'Attended complex care'
        WHEN unpvt_table.measure_numerator LIKE '%not_attended%' THEN 'Did not attend'
        /* total need */
        WHEN unpvt_table.measure_numerator LIKE '%need%' THEN 'Need'
        /* headline measure */
        WHEN unpvt_table.measure_numerator LIKE '%offered%' THEN 'Offered something'
        /* attending intervention at start */
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Already attending'
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
            'Offered targeted intervention',
            'Offered specialist SM treatment',
            'Offered complex care',
            'Offered nothing',
            'Attended targeted intervention',
            'Attended specialist SM treatment',
            'Attended complex care',
            'Did not attend'
        ) THEN 'SM intervention Offer & Attendance'
        WHEN measure_category = 'Offered something' THEN 'Offered SM intervention'
        WHEN measure_category = 'Need' THEN 'Total SM need'
        WHEN measure_category = 'Already attending' THEN 'Attending SM intervention at start'
        ELSE NULL
    END AS measure_short_description,
    -- full wording of the measure 
    CASE
        WHEN measure_short_description = 'Offered SM intervention' THEN 'Proportion of children with an identified substance misuse (SM) need who were referred to or offered an SM intervention'
        WHEN measure_short_description = 'Total SM need' THEN 'Children with an identified need for SM intervention during their order'
        WHEN measure_short_description = 'Attending SM intervention at start' THEN 'Children already attending an SM intervention at the start of the order'
        WHEN measure_short_description = 'SM intervention Offer & Attendance' THEN 'Children offered versus attending an SM intervention broken down by intervention type'
        WHEN measure_short_description = 'Type of order' THEN 'Children with an identified need for SM intervention broken down by type of order'
    END AS measure_long_description,
    --whether measure is the headline measure
    CASE
        WHEN measure_short_description = 'Offered SM intervention' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    --numbering the submeasures
    CASE
        WHEN measure_short_description = 'Total SM need' THEN '5a'
        WHEN measure_short_description = 'Attending SM intervention at start' THEN '5b'
        WHEN measure_short_description = 'SM intervention Offer & Attendance' THEN '5c'
        WHEN measure_short_description = 'Type of order' THEN '5d'
        ELSE 'Headline'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        /* total need */
        WHEN measure_category = 'Need' THEN 'kpi5_total_ypid'
        /* type of order */
        WHEN measure_category = 'Out of court disposals' THEN 'kpi5_total_ypid_oocd'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi5_total_ypid_yc_with_yjs'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi5_total_ypid_ycc'
        WHEN measure_category = 'Referral orders' THEN 'kpi5_total_ypid_ro'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi5_total_ypid_yro'
        WHEN measure_category = 'Custodial sentences' THEN 'kpi5_total_ypid_cust'
        /* attending SM intervention */
        WHEN measure_category = 'Attended targeted intervention' THEN 'kpi5_offered_targeted_intervention'
        WHEN measure_category = 'Attended specialist SM treatment' THEN 'kpi5_attended_specialist_sm_treatment'
        WHEN measure_category = 'Attended complex care' THEN 'kpi5_offered_complex_care'
        WHEN measure_Category = 'Did not attend' THEN 'kpi5_sm_offered'
        /*all other measures*/
        ELSE 'kpi5_sm_need'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        /* total need */
        WHEN measure_category = 'Need' THEN kpi5_total_ypid
        /* type of order */
        WHEN measure_category = 'Out of court disposals' THEN unpvt_table.kpi5_total_ypid_oocd
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN unpvt_table.kpi5_total_ypid_yc_with_yjs
        WHEN measure_category = 'Youth conditional cautions' THEN unpvt_table.kpi5_total_ypid_ycc
        WHEN measure_category = 'Referral orders' THEN unpvt_table.kpi5_total_ypid_ro
        WHEN measure_category = 'Youth rehabilitation orders' THEN unpvt_table.kpi5_total_ypid_yro
        WHEN measure_category = 'Custodial sentences' THEN unpvt_table.kpi5_total_ypid_cust
        /* attending SM intervention */
        WHEN measure_category = 'Attended targeted intervention' THEN numerators_and_denominators.kpi5_offered_targeted_intervention
        WHEN measure_category = 'Attended specialist SM treatment' THEN numerators_and_denominators.kpi5_offered_specialist_sm_treatment
        WHEN measure_category = 'Attended complex care' THEN numerators_and_denominators.kpi5_offered_complex_care
        WHEN measure_Category = 'Did not attend' THEN numerators_and_denominators.kpi5_sm_offered
        /*all other measures*/
        ELSE numerators_and_denominators.kpi5_sm_need
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an identified SM need who were offered a SM intervention'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an identified need for SM intervention'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi5_substance_m_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi5_offered_but_not_attended,
            kpi5_attended_targeted_intervention,
            kpi5_attended_specialist_sm_treatment,
            kpi5_attended_complex_care,
            kpi5_offered_no_intervention,
            kpi5_offered_targeted_intervention,
            kpi5_offered_specialist_sm_treatment,
            kpi5_offered_complex_care,
            kpi5_sm_need_cust,
            kpi5_sm_need_yro,
            kpi5_sm_need_ro,
            kpi5_sm_need_ycc,
            kpi5_sm_need_yc_with_yjs,
            kpi5_sm_need_oocd,
            kpi5_treatment_start,
            kpi5_sm_need,
            kpi5_sm_offered
        )
    ) AS unpvt_table
    LEFT JOIN numerators_and_denominators ON unpvt_table.yjs_name = numerators_and_denominators.yjs_name
    AND unpvt_table.quarter_label = numerators_and_denominators.quarter_label
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
/* RQEV2-kkESjDRoHv */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_case_level distkey (source_document_id) sortkey (source_document_id) AS
SELECT
    --total oocds is distinct ypid in this view
    DISTINCT *,
    --total oocds that were successfully completed
    CASE
        WHEN kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd,
    --total oocds by 6 oocd legal outcomes
    CASE
        WHEN legal_outcome = 'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_total_community_resolution,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_total_o22_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_total_o22_deferred_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_total_o20_21_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CAUTION' THEN ypid
        ELSE NULL
    END AS kpi6_total_yc_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CONDITIONAL_CAUTION' THEN ypid
        ELSE NULL
    END AS kpi6_total_ycc,
    -- successfully completed by 6 oocd legal outcomes
    CASE
        WHEN legal_outcome = 'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_community_resolution,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_o22_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_o22_deferred_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_o20_21_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CAUTION'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_yc_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CONDITIONAL_CAUTION'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_successful_ycc,
    --successfully completed OOCDs by ethnicity group
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'White' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_white,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Mixed' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_mixed_ethnic,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Black or Black British' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_black,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Other Ethnic Group' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_other_ethnic,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Asian or Asian British' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_asian,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Information not obtainable' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_ethnic,
    --successfully completed OOCDs by age group
    CASE
        WHEN kpi6_successfully_completed = true
        AND age_on_intervention_start BETWEEN 10
        AND 14 THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_10_14,
    CASE
        WHEN kpi6_successfully_completed = true
        AND age_on_intervention_start BETWEEN 15
        AND 17 THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_15_17,
    --successfully completed OOCDs by gender
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Male' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_male,
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Female' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_female,
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Unknown gender' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_gender,
    --total OOCDs by ethnicity group
    CASE
        WHEN ethnicity_group = 'White' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_white,
    CASE
        WHEN ethnicity_group = 'Mixed' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_mixed_ethnic,
    CASE
        WHEN ethnicity_group = 'Black or Black British' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_black,
    CASE
        WHEN ethnicity_group = 'Other Ethnic Group' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_other_ethnic,
    CASE
        WHEN ethnicity_group = 'Asian or Asian British' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_asian,
    CASE
        WHEN ethnicity_group = 'Information not obtainable' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_unknown_ethnic,
    --total OOCDs by age group
    CASE
        WHEN age_on_intervention_start BETWEEN 10
        AND 14 THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_10_14,
    CASE
        WHEN age_on_intervention_start BETWEEN 15
        AND 17 THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_15_17,
    --total OOCDs by gender
    CASE
        WHEN gender_name = 'Male' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_male,
    CASE
        WHEN gender_name = 'Female' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_female,
    CASE
        WHEN gender_name = 'Unknown gender' THEN ypid
        ELSE NULL
    END AS kpi6_total_oocd_unknown_gender
FROM
    yjb_kpi_case_level.person_details
WHERE
    legal_outcome_group_fixed IN ('Diversion', 'Pre-Court');	
/* RQEV2-SQ5xdTN9uc */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_case_level_v8 distkey (source_document_id) sortkey (source_document_id) AS WITH pd AS (
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
        --only count these disposal types - cant use the group as there is something wrong with the mapping of disposal types to their group 
        AND intervention_mapping.disposal_type_fixed IN (
            'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT',
            'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT',
            'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT',
            'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT',
            'YOUTH_CONDITIONAL_CAUTION',
            'YOUTH_CAUTION'
        ) -- only count these disposal types 
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
        ) -- AND pd.ypid NOT IN (
        --     SELECT
        --         yp_id
        --     FROM
        --         yjb_case_reporting_stg.vw_deleted_yps
        -- )
        AND yjs_name <> 'Cumbria'
),
--had to add this CTE due to order of operations. legal_outcome OUTCOME_22 that were actually 'NOT_KNOWN' cases were not getting seriousness ranking or type of order (NULLs) when they were in the CTE above.
add_seriousness_kpi_count_rank AS (
    SELECT
        combine.*,
        seriousness.seriousness_ranking,
        count_in_kpi_lo.legal_outcome_group_fixed,
        count_in_kpi_lo.count_in_kpi_legal_outcome,
        count_in_kpi_lo.mapping_to_kpi_template AS type_of_order,
        --row_number ensures we only take one intervention programme id per outcome_date - as there are more than one row for some offences
        ROW_NUMBER() OVER (
            PARTITION BY ypid,
            intervention_programme_id -- by partitioning by ypid and offence_id we count all offences - rather than just one
            ORDER BY
                seriousness_ranking,
                outcome_date DESC --where multiple seriousness_ranking or outcome dates for same offence we take latest
        ) as rank_over_intervention_programme_id
    FROM
        combine
        LEFT JOIN yjb_kpi_case_level.count_in_kpi_legal_outcome as count_in_kpi_lo ON UPPER(TRIM(combine.legal_outcome)) = TRIM(count_in_kpi_lo.legal_outcome)
        LEFT JOIN yjb_ianda_team.legal_outcome_seriousness_ranking AS seriousness ON UPPER(TRIM(combine.legal_outcome)) = TRIM(seriousness.legal_outcome)
    WHERE
        count_in_kpi_legal_outcome = 'YES'
        AND count_in_kpi_lo.legal_outcome_group_fixed IN ('Diversion', 'Pre-Court')
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
        add_seriousness_kpi_count_rank
    WHERE
        rank_over_intervention_programme_id = 1
)
SELECT
    --total oocds is distinct ypid in this view
    DISTINCT *,
    /* HEADLINE NUMERATOR */
    --total children that successfully completed an OOCD
    CASE
        WHEN kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_oocd,
    CASE
        WHEN kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_oocd,
    /* submeasure: total actual number of successfully completed oocds (children can have more than one - although rare) */
    CASE
        WHEN kpi6_successfully_completed = true THEN intervention_programme_id
        ELSE NULL
    END AS kpi6_successful_oocd,
    /* submeasure: children that successfully completed and did not completed oocds */
    --numerators
    -- children that successfully completed 6 oocd interventions
    CASE
        WHEN legal_outcome = 'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_cr,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_o22_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_o22_deferred_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_o20_21_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CAUTION'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_yc_with_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CONDITIONAL_CAUTION'
        AND kpi6_successfully_completed = true THEN ypid
        ELSE NULL
    END AS kpi6_ypid_successful_ycc,
    -- children that did not complete 6 oocd interventions
    CASE
        WHEN legal_outcome = 'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_cr,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_o22_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_o22_deferred_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_o20_21_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CAUTION'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_yc_with_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CONDITIONAL_CAUTION'
        AND kpi6_successfully_completed = FALSE THEN ypid
        ELSE NULL
    END AS kpi6_ypid_not_completed_ycc,
    --denominator:total children in each of the 6 oocd intervention types
    CASE
        WHEN legal_outcome = 'COMMUNITY_RESOLUTION_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_cr,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_o22_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_22_DEFERRED_PROSECUTION_CAUTION_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_o22_deferred_yjs,
    CASE
        WHEN legal_outcome = 'NO_FURTHER_ACTION_OUTCOME_20_21_WITH_YJS_INVOLVEMENT' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_o20_21_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CAUTION' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_yc_with_yjs,
    CASE
        WHEN legal_outcome = 'YOUTH_CONDITIONAL_CAUTION' THEN ypid
        ELSE NULL
    END AS kpi6_ypid_total_ycc,
    /* submeasure: children that successfully completed and did not completed oocds by demographics (case level only)*/
    --numerators
    --successfully completed OOCDs by ethnicity group
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'White' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_white,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Mixed' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_mixed_ethnic,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Black or Black British' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_black,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Other Ethnic Group' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_other_ethnic,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Asian or Asian British' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_asian,
    CASE
        WHEN kpi6_successfully_completed = true
        AND ethnicity_group = 'Information not obtainable' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_ethnic,
    --successfully completed OOCDs by age group
    CASE
        WHEN kpi6_successfully_completed = true
        AND age_on_intervention_start BETWEEN 10
        AND 14 THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_10_14,
    CASE
        WHEN kpi6_successfully_completed = true
        AND age_on_intervention_start BETWEEN 15
        AND 17 THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_15_17,
    --successfully completed OOCDs by gender
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Male' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_male,
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Female' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_female,
    CASE
        WHEN kpi6_successfully_completed = true
        AND gender_name = 'Unknown gender' THEN ypid
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_gender,
    --not completed OOCDs by ethnicity group
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'White' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_white,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'Mixed' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_mixed_ethnic,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'Black or Black British' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_black,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'Other Ethnic Group' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_other_ethnic,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'Asian or Asian British' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_asian,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND ethnicity_group = 'Information not obtainable' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_unknown_ethnic,
    --not completed OOCDs by age group
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND age_on_intervention_start BETWEEN 10
        AND 14 THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_10_14,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND age_on_intervention_start BETWEEN 15
        AND 17 THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_15_17,
    --not completed OOCDs by gender
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND gender_name = 'Male' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_male,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND gender_name = 'Female' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_female,
    CASE
        WHEN kpi6_successfully_completed = FALSE
        AND gender_name = 'Unknown gender' THEN ypid
        ELSE NULL
    END AS kpi6_not_completed_oocd_unknown_gender -- --total OOCDs by ethnicity group (don't actually use - may be useful in future)
    -- CASE
    --     WHEN ethnicity_group = 'White' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_white,
    -- CASE
    --     WHEN ethnicity_group = 'Mixed' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_mixed_ethnic,
    -- CASE
    --     WHEN ethnicity_group = 'Black or Black British' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_black,
    -- CASE
    --     WHEN ethnicity_group = 'Other Ethnic Group' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_other_ethnic,
    -- CASE
    --     WHEN ethnicity_group = 'Asian or Asian British' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_asian,
    -- CASE
    --     WHEN ethnicity_group = 'Information not obtainable' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_unknown_ethnic,
    -- --total OOCDs by age group
    -- CASE
    --     WHEN age_on_intervention_start BETWEEN 10
    --     AND 14 THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_10_14,
    -- CASE
    --     WHEN age_on_intervention_start BETWEEN 15
    --     AND 17 THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_15_17,
    -- --total OOCDs by gender
    -- CASE
    --     WHEN gender_name = 'Male' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_male,
    -- CASE
    --     WHEN gender_name = 'Female' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_female,
    -- CASE
    --     WHEN gender_name = 'Unknown gender' THEN ypid
    --     ELSE NULL
    -- END AS kpi6_ypid_total_oocd_unknown_gender
FROM
    case_level;	
/* RQEV2-z6s3RukOfk */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_cl AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        --total oocds
        COUNT(DISTINCT ypid) AS kpi6_total_oocd,
        --total successful oocds
        COUNT(DISTINCT kpi6_successful_oocd) AS kpi6_successful_oocd,
        --total oocds by the 6 oocd legal outcomes
        COUNT(DISTINCT kpi6_total_community_resolution) AS kpi6_total_community_resolution,
        COUNT(DISTINCT kpi6_total_o22_yjs) AS kpi6_total_o22_yjs,
        COUNT(DISTINCT kpi6_total_o22_deferred_yjs) AS kpi6_total_o22_deferred_yjs,
        COUNT(DISTINCT kpi6_total_o20_21_yjs) AS kpi6_total_o20_21_yjs,
        COUNT(DISTINCT kpi6_total_yc_yjs) AS kpi6_total_yc_yjs,
        COUNT(DISTINCT kpi6_total_ycc) AS kpi6_total_ycc,
        --successful oocds by the 6 oocd legal outcomes
        COUNT(DISTINCT kpi6_successful_community_resolution) AS kpi6_successful_community_resolution,
        COUNT(DISTINCT kpi6_successful_o22_yjs) AS kpi6_successful_o22_yjs,
        COUNT(DISTINCT kpi6_successful_o22_deferred_yjs) AS kpi6_successful_o22_deferred_yjs,
        COUNT(DISTINCT kpi6_successful_o20_21_yjs) AS kpi6_successful_o20_21_yjs,
        COUNT(DISTINCT kpi6_successful_yc_yjs) AS kpi6_successful_yc_yjs,
        COUNT(DISTINCT kpi6_successful_ycc) AS kpi6_successful_ycc,
        --successful oocds by ethnicity group
        COUNT(DISTINCT kpi6_successful_oocd_white) AS kpi6_successful_oocd_white,
        COUNT(DISTINCT kpi6_successful_oocd_mixed_ethnic) AS kpi6_successful_oocd_mixed_ethnic,
        COUNT(DISTINCT kpi6_successful_oocd_black) AS kpi6_successful_oocd_black,
        COUNT(DISTINCT kpi6_successful_oocd_other_ethnic) AS kpi6_successful_oocd_other_ethnic,
        COUNT(DISTINCT kpi6_successful_oocd_asian) AS kpi6_successful_oocd_asian,
        COUNT(DISTINCT kpi6_successful_oocd_unknown_ethnic) AS kpi6_successful_oocd_unknown_ethnic,
        --successful oocds by age group
        COUNT(DISTINCT kpi6_successful_oocd_10_14) AS kpi6_successful_oocd_10_14,
        COUNT(DISTINCT kpi6_successful_oocd_15_17) AS kpi6_successful_oocd_15_17,
        --successful oocds by gender
        COUNT(DISTINCT kpi6_successful_oocd_male) AS kpi6_successful_oocd_male,
        COUNT(DISTINCT kpi6_successful_oocd_female) AS kpi6_successful_oocd_female,
        COUNT(DISTINCT kpi6_successful_oocd_unknown_gender) AS kpi6_successful_oocd_unknown_gender,
        --total oocds by ethnicity group
        COUNT(DISTINCT kpi6_total_oocd_white) AS kpi6_total_oocd_white,
        COUNT(DISTINCT kpi6_total_oocd_mixed_ethnic) AS kpi6_total_oocd_mixed_ethnic,
        COUNT(DISTINCT kpi6_total_oocd_black) AS kpi6_total_oocd_black,
        COUNT(DISTINCT kpi6_total_oocd_other_ethnic) AS kpi6_total_oocd_other_ethnic,
        COUNT(DISTINCT kpi6_total_oocd_asian) AS kpi6_total_oocd_asian,
        COUNT(DISTINCT kpi6_total_oocd_unknown_ethnic) AS kpi6_total_oocd_unknown_ethnic,
        --total oocds by age group
        COUNT(DISTINCT kpi6_total_oocd_10_14) AS kpi6_total_oocd_10_14,
        COUNT(DISTINCT kpi6_total_oocd_15_17) AS kpi6_total_oocd_15_17,
        --total oocds by gender
        COUNT(DISTINCT kpi6_total_oocd_male) AS kpi6_total_oocd_male,
        COUNT(DISTINCT kpi6_total_oocd_female) AS kpi6_total_oocd_female,
        COUNT(DISTINCT kpi6_total_oocd_unknown_gender) AS kpi6_total_oocd_unknown_gender
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi6_oocd_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        area_operations,
        yjb_country,
        label_quarter
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
            summary_t.kpi6_total_oocd > 0
            OR summary_t.kpi6_successful_oocd > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --headline measure
    --headline numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_oocd
            ELSE summary_cl.kpi6_successful_oocd
        END,
        0
    ) AS kpi6_successful_oocd,
    --denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_oocd
            ELSE summary_cl.kpi6_total_oocd
        END,
        0
    ) AS kpi6_total_oocd,
    --broken down by 6 oocd legal outcomes
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_community_resolution
            ELSE summary_cl.kpi6_total_community_resolution
        END,
        0
    ) AS kpi6_total_community_resolution,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_o22_yjs
            ELSE summary_cl.kpi6_total_o22_yjs
        END,
        0
    ) AS kpi6_total_o22_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_o22_deferred_yjs
            ELSE summary_cl.kpi6_total_o22_deferred_yjs
        END,
        0
    ) AS kpi6_total_o22_deferred_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_o20_21_yjs
            ELSE summary_cl.kpi6_total_o20_21_yjs
        END,
        0
    ) AS kpi6_total_o20_21_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_yc_yjs
            ELSE summary_cl.kpi6_total_yc_yjs
        END,
        0
    ) AS kpi6_total_yc_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_total_ycc
            ELSE summary_cl.kpi6_total_ycc
        END,
        0
    ) AS kpi6_total_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_community_resolution
            ELSE summary_cl.kpi6_successful_community_resolution
        END,
        0
    ) AS kpi6_successful_community_resolution,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_o22_yjs
            ELSE summary_cl.kpi6_successful_o22_yjs
        END,
        0
    ) AS kpi6_successful_o22_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_o22_deferred_yjs
            ELSE summary_cl.kpi6_successful_o22_deferred_yjs
        END,
        0
    ) AS kpi6_successful_o22_deferred_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_o20_21_yjs
            ELSE summary_cl.kpi6_successful_o20_21_yjs
        END,
        0
    ) AS kpi6_successful_o20_21_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_yc_yjs
            ELSE summary_cl.kpi6_successful_yc_yjs
        END,
        0
    ) AS kpi6_successful_yc_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_successful_ycc
            ELSE summary_cl.kpi6_successful_ycc
        END,
        0
    ) AS kpi6_successful_ycc,
    --broken down by ethnicity group (case level only)
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_white
        ELSE NULL
    END AS kpi6_successful_oocd_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_mixed_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_black
        ELSE NULL
    END AS kpi6_successful_oocd_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_other_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_asian
        ELSE NULL
    END AS kpi6_successful_oocd_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_unknown_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_white
        ELSE NULL
    END AS kpi6_total_oocd_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_mixed_ethnic
        ELSE NULL
    END AS kpi6_total_oocd_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_black
        ELSE NULL
    END AS kpi6_total_oocd_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_other_ethnic
        ELSE NULL
    END AS kpi6_total_oocd_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_asian
        ELSE NULL
    END AS kpi6_total_oocd_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_unknown_ethnic
        ELSE NULL
    END AS kpi6_total_oocd_unknown_ethnic,
    --broken down by age group (case level only)
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_10_14
        ELSE NULL
    END AS kpi6_successful_oocd_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_15_17
        ELSE NULL
    END AS kpi6_successful_oocd_15_17,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_10_14
        ELSE NULL
    END AS kpi6_total_oocd_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_15_17
        ELSE NULL
    END AS kpi6_total_oocd_15_17,
    --broken down by gender (case level only)
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_male
        ELSE NULL
    END AS kpi6_successful_oocd_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_female
        ELSE NULL
    END AS kpi6_successful_oocd_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_unknown_gender
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_gender,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_male
        ELSE NULL
    END AS kpi6_total_oocd_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_female
        ELSE NULL
    END AS kpi6_total_oocd_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_unknown_gender
        ELSE NULL
    END AS kpi6_total_oocd_unknown_gender
FROM
    summary_cl FULL
    OUTER JOIN yjb_kpi_case_level.kpi6_oocd_template AS summary_t ON summary_t.yot_code = summary_cl.yot_code
    AND summary_t.label_quarter = summary_cl.label_quarter;	
    /* RQEV2-JA8YCugPOk */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
        community_resolution,
        nfa_o22_yjs,
        nfa_o22_deferred_yjs,
        nfa_o20_21_yjs,
        yc_yjs,
        ycc
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi6_ooc_v1" AS kpi6
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi6.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi6.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --total number of children with oocds
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_total_oocd,
    --children who successfully completed oocd
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_oocd,
    --children who did not complete oocd
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_oocd,
    --Chlidren who succesfully completed intervention programmes by 6 oocd legal outcomes
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN community_resolution
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_cr,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o22_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_o22_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o22_deferred_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_o22_deferred_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o20_21_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_o20_21_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN yc_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_yc_with_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_successful_ycc,
    --children who did not complete intervention programmes by 6 oocd legal outcomes
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN community_resolution
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_cr,
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN nfa_o22_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_o22_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN nfa_o22_deferred_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_o22_deferred_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN nfa_o20_21_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_o20_21_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN yc_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_yc_with_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_not_completed_ycc,
    --total oocds by 6 oocd legal outcomes
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN community_resolution
            ELSE NULL
        END
    ) AS kpi6_ypid_total_cr,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o22_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_total_o22_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o22_deferred_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_total_o22_deferred_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o20_21_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_total_o20_21_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yc_yjs
            ELSE NULL
        END
    ) AS kpi6_ypid_total_yc_with_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ycc
            ELSE NULL
        END
    ) AS kpi6_ypid_total_ycc
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

    /* RQEV2-sniOIaGyLE */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_cl AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        /*headline measure*/
        --numerator: total children wit successful oocds
        COUNT(DISTINCT kpi6_ypid_successful_oocd) AS kpi6_ypid_successful_oocd,
        --total children that did not completed a oocds (currently not used)
        COUNT(DISTINCT kpi6_ypid_not_completed_oocd) AS kpi6_ypid_not_completed_oocd,
        --denominator: total children with oocds
        COUNT(DISTINCT ypid) AS kpi6_ypid_total_oocd,
        /*submeasure 6a*/
        --numerator: total actual successful oocds
        COUNT(DISTINCT kpi6_successful_oocd) AS kpi6_successful_oocd,
        --denominatory:total actual oocds
        COUNT(
            DISTINCT intervention_programme_id
        ) as kpi6_total_oocd,
        /*submeasure 6b*/
        --numerator: children withsuccessful oocds by the 6 oocd legal outcomes
        COUNT(
            DISTINCT kpi6_ypid_successful_cr
        ) AS kpi6_ypid_successful_cr,
        COUNT(DISTINCT kpi6_ypid_successful_o22_yjs) AS kpi6_ypid_successful_o22_yjs,
        COUNT(DISTINCT kpi6_ypid_successful_o22_deferred_yjs) AS kpi6_ypid_successful_o22_deferred_yjs,
        COUNT(DISTINCT kpi6_ypid_successful_o20_21_yjs) AS kpi6_ypid_successful_o20_21_yjs,
        COUNT(DISTINCT kpi6_ypid_successful_yc_with_yjs) AS kpi6_ypid_successful_yc_with_yjs,
        COUNT(DISTINCT kpi6_ypid_successful_ycc) AS kpi6_ypid_successful_ycc,
        --numerator: children with not completed oocds by the 6 oocd legal outcomes
        COUNT(DISTINCT kpi6_ypid_not_completed_cr) AS kpi6_ypid_not_completed_cr,
        COUNT(DISTINCT kpi6_ypid_not_completed_o22_yjs) AS kpi6_ypid_not_completed_o22_yjs,
        COUNT(
            DISTINCT kpi6_ypid_not_completed_o22_deferred_yjs
        ) AS kpi6_ypid_not_completed_o22_deferred_yjs,
        COUNT(DISTINCT kpi6_ypid_not_completed_o20_21_yjs) AS kpi6_ypid_not_completed_o20_21_yjs,
        COUNT(DISTINCT kpi6_ypid_not_completed_yc_with_yjs) AS kpi6_ypid_not_completed_yc_with_yjs,
        COUNT(DISTINCT kpi6_ypid_not_completed_ycc) AS kpi6_ypid_not_completed_ycc,
        --denominator: total children with oocds by the 6 oocd legal outcomes
        COUNT(DISTINCT kpi6_ypid_total_cr) AS kpi6_ypid_total_cr,
        COUNT(DISTINCT kpi6_ypid_total_o22_yjs) AS kpi6_ypid_total_o22_yjs,
        COUNT(DISTINCT kpi6_ypid_total_o22_deferred_yjs) AS kpi6_ypid_total_o22_deferred_yjs,
        COUNT(DISTINCT kpi6_ypid_total_o20_21_yjs) AS kpi6_ypid_total_o20_21_yjs,
        COUNT(DISTINCT kpi6_ypid_total_yc_with_yjs) AS kpi6_ypid_total_yc_with_yjs,
        COUNT(DISTINCT kpi6_ypid_total_ycc) AS kpi6_ypid_total_ycc,
        /*submeasure 6c*/
        --children with successful oocds by ethnicity group
        COUNT(DISTINCT kpi6_successful_oocd_white) AS kpi6_successful_oocd_white,
        COUNT(DISTINCT kpi6_successful_oocd_mixed_ethnic) AS kpi6_successful_oocd_mixed_ethnic,
        COUNT(DISTINCT kpi6_successful_oocd_black) AS kpi6_successful_oocd_black,
        COUNT(DISTINCT kpi6_successful_oocd_other_ethnic) AS kpi6_successful_oocd_other_ethnic,
        COUNT(DISTINCT kpi6_successful_oocd_asian) AS kpi6_successful_oocd_asian,
        COUNT(DISTINCT kpi6_successful_oocd_unknown_ethnic) AS kpi6_successful_oocd_unknown_ethnic,
        --children with successful oocds by age group
        COUNT(DISTINCT kpi6_successful_oocd_10_14) AS kpi6_successful_oocd_10_14,
        COUNT(DISTINCT kpi6_successful_oocd_15_17) AS kpi6_successful_oocd_15_17,
        --children with successful oocds by gender
        COUNT(DISTINCT kpi6_successful_oocd_male) AS kpi6_successful_oocd_male,
        COUNT(DISTINCT kpi6_successful_oocd_female) AS kpi6_successful_oocd_female,
        COUNT(DISTINCT kpi6_successful_oocd_unknown_gender) AS kpi6_successful_oocd_unknown_gender,
        --chidlren not completed oocds by ethnicity group
        COUNT(DISTINCT kpi6_not_completed_oocd_white) AS kpi6_not_completed_oocd_white,
        COUNT(DISTINCT kpi6_not_completed_oocd_mixed_ethnic) AS kpi6_not_completed_oocd_mixed_ethnic,
        COUNT(DISTINCT kpi6_not_completed_oocd_black) AS kpi6_not_completed_oocd_black,
        COUNT(DISTINCT kpi6_not_completed_oocd_other_ethnic) AS kpi6_not_completed_oocd_other_ethnic,
        COUNT(DISTINCT kpi6_not_completed_oocd_asian) AS kpi6_not_completed_oocd_asian,
        COUNT(DISTINCT kpi6_not_completed_oocd_unknown_ethnic) AS kpi6_not_completed_oocd_unknown_ethnic,
        --chidlren not completed oocds by age group
        COUNT(DISTINCT kpi6_not_completed_oocd_10_14) AS kpi6_not_completed_oocd_10_14,
        COUNT(DISTINCT kpi6_not_completed_oocd_15_17) AS kpi6_not_completed_oocd_15_17,
        --chidlren not completed oocds by gender
        COUNT(DISTINCT kpi6_not_completed_oocd_male) AS kpi6_not_completed_oocd_male,
        COUNT(DISTINCT kpi6_not_completed_oocd_female) AS kpi6_not_completed_oocd_female,
        COUNT(DISTINCT kpi6_not_completed_oocd_unknown_gender) AS kpi6_not_completed_oocd_unknown_gender
        /* don't actually get used but may be useful in future */
        --total oocds by ethnicity group
        -- COUNT(DISTINCT kpi6_total_oocd_white) AS kpi6_total_oocd_white,
        -- COUNT(DISTINCT kpi6_total_oocd_mixed_ethnic) AS kpi6_total_oocd_mixed_ethnic,
        -- COUNT(DISTINCT kpi6_total_oocd_black) AS kpi6_total_oocd_black,
        -- COUNT(DISTINCT kpi6_total_oocd_other_ethnic) AS kpi6_total_oocd_other_ethnic,
        -- COUNT(DISTINCT kpi6_total_oocd_asian) AS kpi6_total_oocd_asian,
        -- COUNT(DISTINCT kpi6_total_oocd_unknown_ethnic) AS kpi6_total_oocd_unknown_ethnic,
        -- --total oocds by age group
        -- COUNT(DISTINCT kpi6_total_oocd_10_14) AS kpi6_total_oocd_10_14,
        -- COUNT(DISTINCT kpi6_total_oocd_15_17) AS kpi6_total_oocd_15_17,
        -- --total oocds by gender
        -- COUNT(DISTINCT kpi6_total_oocd_male) AS kpi6_total_oocd_male,
        -- COUNT(DISTINCT kpi6_total_oocd_female) AS kpi6_total_oocd_female,
        -- COUNT(DISTINCT kpi6_total_oocd_unknown_gender) AS kpi6_total_oocd_unknown_gender
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi6_oocd_case_level_v8"
    GROUP BY
        yot_code,
        yjs_name,
        area_operations,
        yjb_country,
        label_quarter
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
    --financial year
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
        ) END AS DATE
    ) AS quarter_label_date,
    'KPI 6' AS kpi_number,
    CASE
        WHEN (
            summary_t.kpi6_ypid_total_oocd > 0
            OR summary_t.kpi6_ypid_successful_oocd > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --headline measure
    --headline numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_oocd
            ELSE summary_cl.kpi6_ypid_successful_oocd
        END,
        0
    ) AS kpi6_ypid_successful_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_oocd
            ELSE summary_cl.kpi6_ypid_not_completed_oocd
        END,
        0
    ) AS kpi6_ypid_not_completed_oocd,
    --denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_oocd
            ELSE summary_cl.kpi6_ypid_total_oocd
        END,
        0
    ) AS kpi6_ypid_total_oocd,
    --submeasure 6a - only possible on case level until new template is implemented
    --numerator: total actual successful oocds
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd
    END AS kpi6_successful_oocd,
    --denominator: total actual oocds
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd
        ELSE NULL
    END AS kpi6_total_oocd,
    /*submeasure 6c*/
    --numerator: children with successful oocds by the 6 oocd legal outcomes
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_cr
            ELSE summary_cl.kpi6_ypid_successful_cr
        END,
        0
    ) AS kpi6_ypid_successful_cr,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_o22_yjs
            ELSE summary_cl.kpi6_ypid_successful_o22_yjs
        END,
        0
    ) AS kpi6_ypid_successful_o22_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_o22_deferred_yjs
            ELSE summary_cl.kpi6_ypid_successful_o22_deferred_yjs
        END,
        0
    ) AS kpi6_ypid_successful_o22_deferred_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_o20_21_yjs
            ELSE summary_cl.kpi6_ypid_successful_o20_21_yjs
        END,
        0
    ) AS kpi6_ypid_successful_o20_21_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_yc_with_yjs
            ELSE summary_cl.kpi6_ypid_successful_yc_with_yjs
        END,
        0
    ) AS kpi6_ypid_successful_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_successful_ycc
            ELSE summary_cl.kpi6_ypid_successful_ycc
        END,
        0
    ) AS kpi6_ypid_successful_ycc,
    --numerator: 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_cr
            ELSE summary_cl.kpi6_ypid_not_completed_cr
        END,
        0
    ) AS kpi6_ypid_not_completed_cr,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_o22_yjs
            ELSE summary_cl.kpi6_ypid_not_completed_o22_yjs
        END,
        0
    ) AS kpi6_ypid_not_completed_o22_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_o22_deferred_yjs
            ELSE summary_cl.kpi6_ypid_not_completed_o22_deferred_yjs
        END,
        0
    ) AS kpi6_ypid_not_completed_o22_deferred_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_o20_21_yjs
            ELSE summary_cl.kpi6_ypid_not_completed_o20_21_yjs
        END,
        0
    ) AS kpi6_ypid_not_completed_o20_21_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_yc_with_yjs
            ELSE summary_cl.kpi6_ypid_not_completed_yc_with_yjs
        END,
        0
    ) AS kpi6_ypid_not_completed_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_not_completed_ycc
            ELSE summary_cl.kpi6_ypid_not_completed_ycc
        END,
        0
    ) AS kpi6_ypid_not_completed_ycc,
    --denominator: total by 6 oocd legal outcomes
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_cr
            ELSE summary_cl.kpi6_ypid_total_cr
        END,
        0
    ) AS kpi6_ypid_total_cr,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_o22_yjs
            ELSE summary_cl.kpi6_ypid_total_o22_yjs
        END,
        0
    ) AS kpi6_ypid_total_o22_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_o22_deferred_yjs
            ELSE summary_cl.kpi6_ypid_total_o22_deferred_yjs
        END,
        0
    ) AS kpi6_ypid_total_o22_deferred_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_o20_21_yjs
            ELSE summary_cl.kpi6_ypid_total_o20_21_yjs
        END,
        0
    ) AS kpi6_ypid_total_o20_21_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_yc_with_yjs
            ELSE summary_cl.kpi6_ypid_total_yc_with_yjs
        END,
        0
    ) AS kpi6_ypid_total_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi6_ypid_total_ycc
            ELSE summary_cl.kpi6_ypid_total_ycc
        END,
        0
    ) AS kpi6_ypid_total_ycc,
    /*submeasure 6c children with not completed oocds by the 6 oocd legal outcomes (case level only)*/
    --by ethnicity 
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_white
        ELSE NULL
    END AS kpi6_successful_oocd_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_mixed_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_black
        ELSE NULL
    END AS kpi6_successful_oocd_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_other_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_asian
        ELSE NULL
    END AS kpi6_successful_oocd_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_unknown_ethnic
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_white
        ELSE NULL
    END AS kpi6_not_completed_oocd_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_mixed_ethnic
        ELSE NULL
    END AS kpi6_not_completed_oocd_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_black
        ELSE NULL
    END AS kpi6_not_completed_oocd_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_other_ethnic
        ELSE NULL
    END AS kpi6_not_completed_oocd_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_asian
        ELSE NULL
    END AS kpi6_not_completed_oocd_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_unknown_ethnic
        ELSE NULL
    END AS kpi6_not_completed_oocd_unknown_ethnic,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_white
    --     ELSE NULL
    -- END AS kpi6_total_oocd_white,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_mixed_ethnic
    --     ELSE NULL
    -- END AS kpi6_total_oocd_mixed_ethnic,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_black
    --     ELSE NULL
    -- END AS kpi6_total_oocd_black,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_other_ethnic
    --     ELSE NULL
    -- END AS kpi6_total_oocd_other_ethnic,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_asian
    --     ELSE NULL
    -- END AS kpi6_total_oocd_asian,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_unknown_ethnic
    --     ELSE NULL
    -- END AS kpi6_total_oocd_unknown_ethnic,
    --by age group 
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_10_14
        ELSE NULL
    END AS kpi6_successful_oocd_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_15_17
        ELSE NULL
    END AS kpi6_successful_oocd_15_17,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_10_14
        ELSE NULL
    END AS kpi6_not_completed_oocd_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_15_17
        ELSE NULL
    END AS kpi6_not_completed_oocd_15_17,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_10_14
    --     ELSE NULL
    -- END AS kpi6_total_oocd_10_14,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_15_17
    --     ELSE NULL
    -- END AS kpi6_total_oocd_15_17,
    --by gender
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_male
        ELSE NULL
    END AS kpi6_successful_oocd_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_female
        ELSE NULL
    END AS kpi6_successful_oocd_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_successful_oocd_unknown_gender
        ELSE NULL
    END AS kpi6_successful_oocd_unknown_gender,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_male
        ELSE NULL
    END AS kpi6_not_completed_oocd_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_female
        ELSE NULL
    END AS kpi6_not_completed_oocd_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_not_completed_oocd_unknown_gender
        ELSE NULL
    END AS kpi6_not_completed_oocd_unknown_gender
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_male
    --     ELSE NULL
    -- END AS kpi6_total_oocd_male,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_female
    --     ELSE NULL
    -- END AS kpi6_total_oocd_female,
    -- CASE
    --     WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi6_total_oocd_unknown_gender
    --     ELSE NULL
    -- END AS kpi6_total_oocd_unknown_gender
FROM
    summary_cl FULL
    OUTER JOIN yjb_kpi_case_level.kpi6_oocd_template_v8 AS summary_t ON summary_t.yot_code = summary_cl.yot_code
    AND summary_t.label_quarter = summary_cl.label_quarter;	

/* RQEV2-Zp7HHGV7U8 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
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
    'OOCD' AS kpi_name,
    'Children receiving out-of-court disposals' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE 'end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
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
    -- give a category for every measure measurement
    CASE
        /*sub-measure 6b: type of OOCD*/
        WHEN unpvt_table.measure_numerator LIKE '%o20%' THEN 'No further action - Outcome 20/21 with YJS involvement'
        WHEN unpvt_table.measure_numerator LIKE '%o22_deferred%' THEN 'No further action - Outcome 22 Deferred prosecution/caution with YJS involvement'
        WHEN unpvt_table.measure_numerator LIKE '%o22%' THEN 'No further action - Outcome 22 with YJS involvement'
        WHEN unpvt_table.measure_numerator LIKE '%cr%' THEN 'Community resolution with YJS involvement'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        /*sub-measure 6c: demographics*/
        --gender
        WHEN unpvt_table.measure_numerator LIKE '%female%' THEN 'Female'
        WHEN unpvt_table.measure_numerator LIKE '%male%' THEN 'Male'
        WHEN unpvt_table.measure_numerator LIKE '%unknown_g%' THEN 'Unknown Gender'
        /*age*/
        WHEN unpvt_table.measure_numerator LIKE '%10_%' THEN '10-14 year olds'
        WHEN unpvt_table.measure_numerator LIKE '%15_%' THEN '15-17 year olds'
        /*ethnicity*/
        WHEN unpvt_table.measure_numerator LIKE '%asian%' THEN 'Asian or Asian British'
        WHEN unpvt_table.measure_numerator LIKE '%black%' THEN 'Black or Black British'
        WHEN unpvt_table.measure_numerator LIKE '%white%' THEN 'White'
        WHEN unpvt_table.measure_numerator LIKE '%mixed%' THEN 'Mixed ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%other_e%' THEN 'Other Ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%unknown_e%' THEN 'Unknown Ethnicity'
        /*headline measure - children with successful oocds and not completed oocds*/
        WHEN unpvt_table.measure_numerator LIKE '%ypid_successful_oocd%' THEN 'Children'
        /* submeasure 6a: total successful oocds */
        WHEN unpvt_table.measure_numerator LIKE '%successful_oocd%' THEN 'Out of court disposals'
    END AS measure_category,
    --short description of measure 
    CASE
        WHEN measure_category = 'Children' THEN 'Total count of children'
        WHEN measure_category = 'Out of court disposals' THEN 'Total count of OOCDs'
        WHEN measure_category IN (
            'No further action - Outcome 20/21 with YJS involvement',
            'No further action - Outcome 22 Deferred prosecution/caution with YJS involvement',
            'No further action - Outcome 22 with YJS involvement',
            'Community resolution with YJS involvement',
            'Youth cautions with YJS intervention',
            'Youth conditional cautions'
        ) THEN 'Type of OOCD'
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
        ELSE NULL
    END AS measure_short_description,
    -- full wording of the measure
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%ypid_successful_oocd%' THEN 'Proportion of children with an out-of-court disposal (OOCD) who successfully completed their intervention programme'
        WHEN measure_short_description = 'Total count of OOCDs' THEN 'Successfully completed OOCDs'
        WHEN measure_short_description = 'Type of OOCD' THEN 'Children with a successfully completed versus not completed OOCD broken down by type of intervention'
        WHEN measure_short_description = 'Demographics' THEN 'Children with a successfully completed versus not completed OOCD by demographic characteristics (case-level only)'
        ELSE NULL
    END AS measure_long_description,
    --whether measure is the headline measure
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%ypid_successful_oocd%' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    --numbering the submeasures
    CASE
        WHEN measure_short_description = 'Total count of OOCDs' THEN '6a'
        WHEN measure_short_description = 'Type of OOCD' THEN '6b'
        WHEN measure_short_description = 'Demographics' THEN '6c'
        ELSE 'Headline'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        /*for sub-measure 6b: type of OOCD*/
        WHEN unpvt_table.measure_numerator LIKE '%o20%' THEN 'kpi6_ypid_total_o20_21_yjs'
        WHEN unpvt_table.measure_numerator LIKE '%o22_deferred%' THEN 'kpi6_ypid_total_o22_deferred_yjs'
        WHEN unpvt_table.measure_numerator LIKE '%o22%' THEN 'kpi6_ypid_total_o22_yjs'
        WHEN unpvt_table.measure_numerator LIKE '%cr%' THEN 'kpi6_ypid_total_cr'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'kpi6_ypid_total_yc_with_yjs'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'kpi6_ypid_total_ycc'
        /*for headline (successful children) and sub-measure 6 (demographics)*/
        WHEN measure_short_description IN ('Demographics', 'Total count of children') THEN 'kpi6_ypid_total_oocd'
        /* submeasure 6a (total successful oocds) */
        ELSE 'kpi6_total_oocd'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        /*for sub-measure 6b: type of OOCD*/
        WHEN unpvt_table.measure_numerator LIKE '%o20%' THEN kpi6_ypid_total_o20_21_yjs
        WHEN unpvt_table.measure_numerator LIKE '%o22_deferred%' THEN kpi6_ypid_total_o22_deferred_yjs
        WHEN unpvt_table.measure_numerator LIKE '%o22%' THEN kpi6_ypid_total_o22_yjs
        WHEN unpvt_table.measure_numerator LIKE '%cr%' THEN kpi6_ypid_total_cr
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN kpi6_ypid_total_yc_with_yjs
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN kpi6_ypid_total_ycc
        /*for headline (successful children) and sub-measure 6 (demographics)*/
        WHEN measure_short_description IN ('Demographics', 'Total count of children') THEN kpi6_ypid_total_oocd
        /* submeasure 6a (total successful oocds) */
        ELSE kpi6_total_oocd
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an OOCD who successfully completed their intervention programme'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an OOCD ending'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi6_oocd_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi6_not_completed_oocd_unknown_gender,
            kpi6_not_completed_oocd_female,
            kpi6_not_completed_oocd_male,
            kpi6_successful_oocd_unknown_gender,
            kpi6_successful_oocd_female,
            kpi6_successful_oocd_male,
            kpi6_not_completed_oocd_15_17,
            kpi6_not_completed_oocd_10_14,
            kpi6_successful_oocd_15_17,
            kpi6_successful_oocd_10_14,
            kpi6_not_completed_oocd_unknown_ethnic,
            kpi6_not_completed_oocd_asian,
            kpi6_not_completed_oocd_other_ethnic,
            kpi6_not_completed_oocd_black,
            kpi6_not_completed_oocd_mixed_ethnic,
            kpi6_not_completed_oocd_white,
            kpi6_successful_oocd_unknown_ethnic,
            kpi6_successful_oocd_asian,
            kpi6_successful_oocd_other_ethnic,
            kpi6_successful_oocd_black,
            kpi6_successful_oocd_mixed_ethnic,
            kpi6_successful_oocd_white,
            kpi6_ypid_not_completed_ycc,
            kpi6_ypid_not_completed_yc_with_yjs,
            kpi6_ypid_not_completed_o20_21_yjs,
            kpi6_ypid_not_completed_o22_deferred_yjs,
            kpi6_ypid_not_completed_o22_yjs,
            kpi6_ypid_not_completed_cr,
            kpi6_ypid_successful_ycc,
            kpi6_ypid_successful_yc_with_yjs,
            kpi6_ypid_successful_o20_21_yjs,
            kpi6_ypid_successful_o22_deferred_yjs,
            kpi6_ypid_successful_o22_yjs,
            kpi6_ypid_successful_cr,
            kpi6_successful_oocd,
            kpi6_ypid_successful_oocd
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
