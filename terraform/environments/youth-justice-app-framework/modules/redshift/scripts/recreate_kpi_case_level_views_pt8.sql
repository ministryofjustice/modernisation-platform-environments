SET enable_case_sensitive_identifier TO true;

/* RQEV2-7jH3iSXDS0 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_case_level distkey (kpi4_source_document_id) sortkey (kpi4_source_document_id) AS WITH kpi4 AS (
    SELECT
        dc.source_document_id AS kpi4_source_document_id,
        mh."kpi4MHDateScreened" :: date AS kpi4_date_screened,
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
        AND kpi4_date_screened IS NOT NULL
)
SELECT
    DISTINCT kpi4.*,
    person_details.*,
    -- submeasure: receiving treatment prior to the start of the order
    -- function f_inTreatmentPrior checks whether the treatment was open/ongoing when the order started (so essentially has to straddle the start date for intervention)
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
    END AS kpi4_treatment_prior_order,
    -- headline measure: identified as having a mental health or emotional wellbeing need during their order
    -- must i check there was no attended end date before the start of the order?
    CASE
        WHEN kpi4.kpi4_date_screened <> '1900-01-01'
        OR kpi4_treatment_prior_order IS NOT NULL THEN person_details.ypid
        ELSE NULL
    END AS kpi4_mh_ew_need,
    /* SUBMEASURES: MENTAL HEALTH / EMOTIONAL WELLBEING NEED BROKEN DOWN BY TYPE OF ORDER */
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
    /* SUBMEASURES: OFFERED AND ATTENDED MENTAL HEALTH / EMOTIONAL WELLBEING TREATMENT */
    /* OFFERED */
    -- child was offered 'help'
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_HELP'
        AND kpi4.kpi4_date_offered <= person_details.intervention_end_date
        AND kpi4.kpi4_date_offered >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_help,
    -- child was offered 'additional help'
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
        AND kpi4.kpi4_date_offered <= person_details.intervention_end_date
        AND kpi4.kpi4_date_offered >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_additional_help,
    -- child was offered 'risk support'
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
        AND kpi4.kpi4_date_offered <= person_details.intervention_end_date
        AND kpi4.kpi4_date_offered >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_risk_support,
    -- child was offered 'advice'
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
        AND kpi4.kpi4_date_offered <= person_details.intervention_end_date
        AND kpi4.kpi4_date_offered >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_offered <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_advice,
    -- child was offered 'no intervention' -- not sure if this makes sense as there are instances where they attend an intervention but still have 1900 in offered
    CASE
        WHEN kpi4.kpi4_intervention_type = 'NO_INTERVENTION'
        AND kpi4.kpi4_date_offered = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_offered_no_intervention,
    /* ATTENDED */
    -- kpi4_attended_help
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_HELP'
        AND kpi4.kpi4_date_attended_start <= person_details.intervention_end_date
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_offered
        AND kpi4.kpi4_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_help,
    -- kpi4_attended_additional_help
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_ADDITIONAL_HELP'
        AND kpi4.kpi4_date_attended_start <= person_details.intervention_end_date
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_offered
        AND kpi4.kpi4_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_additional_help,
    -- kpi4_attended_risk_support
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_RISK_SUPPORT'
        AND kpi4.kpi4_date_attended_start <= person_details.intervention_end_date
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_offered
        AND kpi4.kpi4_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_risk_support,
    -- kpi4_attended_advice
    CASE
        WHEN kpi4.kpi4_intervention_type = 'GETTING_ADVICE'
        AND kpi4.kpi4_date_attended_start <= person_details.intervention_end_date
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_screened
        AND kpi4.kpi4_date_attended_start >= kpi4.kpi4_date_offered
        AND kpi4.kpi4_date_attended_start <> '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_advice,
    -- child was attended 'no intervention'
    CASE
        WHEN kpi4.kpi4_intervention_type = 'NO_INTERVENTION'
        AND kpi4.kpi4_date_attended_start = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_attended_no_intervention,
    -- child didnt need intervention -- not needed for anything but may be interesting to know
    CASE
        WHEN kpi4.kpi4_intervention_type = 'NO_INTERVENTION'
        AND kpi4.kpi4_date_screened = '1900-01-01' THEN person_details.ypid
        ELSE NULL
    END AS kpi4_no_screening_no_intervention
FROM
    kpi4
    INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi4.kpi4_source_document_id = person_details.source_document_id
WHERE
    --need to incorporate that no kpi4_date_attended_end occured after date_screening but before the start of order
    kpi4.kpi4_date_screened <= person_details.intervention_end_date;	
/* RQEV2-3NDb4HT8K6 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
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
        COUNT(DISTINCT kpi4_mh_ew_need) AS kpi4_mh_ew_need,
        -- KPI4 SUB-MEASURES FIELDS
        COUNT(DISTINCT kpi4_treatment_prior_order) AS kpi4_treatment_prior_order,
        COUNT(DISTINCT kpi4_mh_ew_need_oocd) AS kpi4_mh_ew_need_oocd,
        COUNT(DISTINCT kpi4_mh_ew_need_yc) AS kpi4_mh_ew_need_yc,
        COUNT(DISTINCT kpi4_mh_ew_need_ycc) AS kpi4_mh_ew_need_ycc,
        COUNT(DISTINCT kpi4_mh_ew_need_ro) AS kpi4_mh_ew_need_ro,
        COUNT(DISTINCT kpi4_mh_ew_need_yro) AS kpi4_mh_ew_need_yro,
        COUNT(DISTINCT kpi4_mh_ew_need_cust) AS kpi4_mh_ew_need_cust,
        COUNT(DISTINCT kpi4_offered_help) AS kpi4_offered_help,
        COUNT(DISTINCT kpi4_offered_additional_help) AS kpi4_offered_additional_help,
        COUNT(DISTINCT kpi4_offered_risk_support) AS kpi4_offered_risk_support,
        COUNT(DISTINCT kpi4_offered_advice) AS kpi4_offered_advice,
        COUNT(DISTINCT kpi4_offered_no_intervention) AS kpi4_offered_no_intervention,
        COUNT(DISTINCT kpi4_attended_help) AS kpi4_attended_help,
        COUNT(DISTINCT kpi4_attended_additional_help) AS kpi4_attended_additional_help,
        COUNT(DISTINCT kpi4_attended_risk_support) AS kpi4_attended_risk_support,
        COUNT(DISTINCT kpi4_attended_advice) AS kpi4_attended_advice,
        COUNT(DISTINCT kpi4_attended_no_intervention) AS kpi4_attended_no_intervention
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi4_mh_case_level"
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
        summary_person.area_operations,
        summary_t.area_operations
    ) AS area_operations,
    COALESCE(
        summary_t.yjb_country,
        summary_person.yjb_country
    ) AS yjb_country,
    CASE
        WHEN (
            summary_t.total_ypid > 0
            OR summary_t.kpi4_mh_ew_need > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
    --headline numerator: number of children with a mental health or emotional wellbeing need (treatment prior + screened need)
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_mh_ew_need
            ELSE summary_cl.kpi4_mh_ew_need
        END,
        0
    ) AS kpi4_mh_ew_need,
    --headline denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS total_ypid,
    -- KPI4 SUB-MEASURES FIELDS
    --number of children who were receiving treatment prior to the order starting (still ongoing when the order started)
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_treatment_prior_order
            ELSE summary_cl.kpi4_treatment_prior_order
        END,
        0
    ) AS kpi4_treatment_prior_order,
    -- submeasure: number of children with mental health or emotional wellbeing need broken down by type of order
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
    ) AS kpi4_mh_ew_need_yc,
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
    -- total by type of order
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
    ) AS kpi4_total_ypid_yc,
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
    -- attended no intervention
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi4_attended_no_intervention
            ELSE summary_cl.kpi4_attended_no_intervention
        END,
        0
    ) AS kpi4_attended_no_intervention
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi4_mh_template AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-x0et0bSNuA */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi4_mh_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS
/*CTE for values that appear in numerator and denominator*/
--required as when a column is pivoted usinng unpivot, the column name is not available in the unpivoted table so has to be pulled from here instead
WITH numerators_and_denominators AS (
    SELECT
        yjs_name,
        quarter_label,
        kpi4_mh_ew_need,
        kpi4_offered_advice,
        kpi4_offered_risk_support,
        kpi4_offered_additional_help,
        kpi4_offered_help,
        kpi4_mh_ew_offered
    FROM
        yjb_kpi_case_level.kpi4_mh_summary_v8
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
    'Mental Health' AS kpi_name,
    'Children with mental health or emotional wellbeing needs' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, during (only relevant to those that were offered by yjs but did not attend) or both of order 
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%not_attended%' THEN 'During'
        ELSE 'Start or During'
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable (does not exist for kpi4 but need column for final unioned table for tableau)
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
        WHEN unpvt_table.measure_numerator LIKE '%offered_additional%' THEN 'Offered additional help'
        WHEN unpvt_table.measure_numerator LIKE '%offered_advice%' THEN 'Offered advice'
        WHEN unpvt_table.measure_numerator LIKE '%offered_risk%' THEN 'Offered risk support'
        WHEN unpvt_table.measure_numerator LIKE '%offered_help%' THEN 'Offered help'
        WHEN unpvt_table.measure_numerator LIKE '%offered_no_intervention%' THEN 'Offered nothing'
        WHEN unpvt_table.measure_numerator LIKE '%attended_additional%' THEN 'Attending Additional help'
        WHEN unpvt_table.measure_numerator LIKE '%attended_advice%' THEN 'Attending advice'
        WHEN unpvt_table.measure_numerator LIKE '%attended_risk%' THEN 'Attending risk support'
        WHEN unpvt_table.measure_numerator LIKE '%attended_help%' THEN 'Attending help'
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
            'Offered additional help',
            'Offered advice',
            'Offered risk support',
            'Offered help',
            'Offered nothing',
            'Attending Additional help',
            'Attending advice',
            'Attending risk support',
            'Attending help',
            'Did not attend'
        ) THEN 'MH/EW intervention Offer & Attendance'
        WHEN measure_category = 'Offered something' THEN 'Offered MH/EW intervention'
        WHEN measure_category = 'Need' THEN 'Total MH/EW need'
        WHEN measure_category = 'Already attending' THEN 'Attending MH/EW intervention at start'
        ELSE NULL
    END AS measure_short_description,
    -- full wording of the measure 
    CASE
        WHEN measure_short_description = 'Offered MH/EW intervention' THEN 'Proportion of children with an identified mental health (MH) or emotional wellbeing (EW) need who were referred to or offered an MH/EW intervention'
        WHEN measure_short_description = 'Total MH/EW need' THEN 'Children with an identified need for MH or EW intervention during their order'
        WHEN measure_short_description = 'Attending MH/EW intervention at start' THEN 'Children already attending an MH or EW intervention at the start of the order'
        WHEN measure_short_description = 'MH/EW intervention Offer & Attendance' THEN 'Children offered versus attending an MH or EW intervention broken down by intervention type'
        WHEN measure_short_description = 'Type of order' THEN 'Children with an identified need for MH or EW intervention broken down by type of order'
    END AS measure_long_description,
    --whether measure is the headline measure
    CASE
        WHEN measure_short_description = 'Offered MH/EW intervention' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    --numbering the submeasures
    CASE
        WHEN measure_short_description = 'Total MH/EW need' THEN '4a'
        WHEN measure_short_description = 'Attending MH/EW intervention at start' THEN '4b'
        WHEN measure_short_description = 'MH/EW intervention Offer & Attendance' THEN '4c'
        WHEN measure_short_description = 'Type of order' THEN '4d'
        ELSE 'Headline'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        /* total need */
        WHEN measure_category = 'Need' THEN 'kpi4_total_ypid'
        /* type of order */
        WHEN measure_category = 'Out of court disposals' THEN 'kpi4_total_ypid_oocd'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi4_total_ypid_yc_with_yjs'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi4_total_ypid_ycc'
        WHEN measure_category = 'Referral orders' THEN 'kpi4_total_ypid_ro'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi4_total_ypid_yro'
        WHEN measure_category = 'Custodial sentences' THEN 'kpi4_total_ypid_cust'
        /* attending MH/EW intervention */
        WHEN measure_category = 'Attending Additional help' THEN 'kpi4_offered_additional_help'
        WHEN measure_category = 'Attending advice' THEN 'kpi4_offered_advice'
        WHEN measure_category = 'Attending risk support' THEN 'kpi4_offered_risk_support'
        WHEN measure_category = 'Attending help' THEN 'kpi4_offered_help '
        WHEN measure_Category = 'Did not attend' THEN 'kpi4_mh_ew_offered'
        /*all other measures*/
        ELSE 'kpi4_mh_ew_need'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        /* total need */
        WHEN measure_category = 'Need' THEN kpi4_total_ypid
        /* type of order */
        WHEN measure_category = 'Out of court disposals' THEN unpvt_table.kpi4_total_ypid_oocd
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN unpvt_table.kpi4_total_ypid_yc_with_yjs
        WHEN measure_category = 'Youth conditional cautions' THEN unpvt_table.kpi4_total_ypid_ycc
        WHEN measure_category = 'Referral orders' THEN unpvt_table.kpi4_total_ypid_ro
        WHEN measure_category = 'Youth rehabilitation orders' THEN unpvt_table.kpi4_total_ypid_yro
        WHEN measure_category = 'Custodial sentences' THEN unpvt_table.kpi4_total_ypid_cust
        /* attending MH/EW intervention */
        WHEN measure_category = 'Attending Additional help' THEN numerators_and_denominators.kpi4_offered_additional_help
        WHEN measure_category = 'Attending advice' THEN numerators_and_denominators.kpi4_offered_advice
        WHEN measure_category = 'Attending risk support' THEN numerators_and_denominators.kpi4_offered_risk_support
        WHEN measure_category = 'Attending help' THEN numerators_and_denominators.kpi4_offered_help
        WHEN measure_Category = 'Did not attend' THEN numerators_and_denominators.kpi4_mh_ew_offered
        /*all other measures*/
        ELSE numerators_and_denominators.kpi4_mh_ew_need
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an identified MH/EW need who were offered a MH/EW intervention'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an identified need for MH/EW intervention'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi4_mh_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi4_offered_but_not_attended,
            kpi4_attended_advice,
            kpi4_attended_risk_support,
            kpi4_attended_additional_help,
            kpi4_attended_help,
            kpi4_offered_no_intervention,
            kpi4_offered_advice,
            kpi4_offered_risk_support,
            kpi4_offered_additional_help,
            kpi4_offered_help,
            kpi4_mh_ew_need_cust,
            kpi4_mh_ew_need_yro,
            kpi4_mh_ew_need_ro,
            kpi4_mh_ew_need_ycc,
            kpi4_mh_ew_need_yc_with_yjs,
            kpi4_mh_ew_need_oocd,
            kpi4_treatment_start,
            kpi4_mh_ew_need,
            kpi4_mh_ew_offered
        )
    ) AS unpvt_table
    LEFT JOIN numerators_and_denominators ON unpvt_table.yjs_name = numerators_and_denominators.yjs_name
    AND unpvt_table.quarter_label = numerators_and_denominators.quarter_label
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	
