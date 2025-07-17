SET enable_case_sensitive_identifier TO true;

/* RQEV2-nu8Ad7ecuv */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi10_victim_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    --headline denominator: victims who consented to contact
    SUM(
        CASE
            WHEN description = 'Number of victims who consent to be contacted by the YJS' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_consent_contact,
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
    -- denominator
    SUM(
        CASE
            WHEN description = 'Number of victims who requested information about the progress of the child''s case' THEN total
            ELSE 0
        END
    ) AS kpi10_victim_request_info,
    --sub measure: victims given additional support that asked for it
    -- numerator
    SUM(
        CASE WHEN description = 'Of those victims who asked for additional support, the number provided with information on appropriate support services' THEN total
        ELSE 0
        END
    ) AS kpi10_victim_given_support,
    -- denominator
    SUM(
        CASE WHEN description = 'The number of victims who asked for additional support' THEN total 
        ELSE 0
        END 
    ) AS kpi10_victim_asked_support
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
/* RQEV2-mifsjUnkqY */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_template distkey (return_status_id) sortkey (return_status_id) as WITH template AS (
    SELECT
        kpi2.return_status_id,
        kpi2.reporting_date,
        kpi2.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label quarter which has year first quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi2.description,
        kpi2.description_group,
        kpi2.ns_school_total,
        kpi2.ns_school_start,
        kpi2.ns_school_end,
        kpi2.ns_above_total,
        kpi2.ns_above_start,
        kpi2.ns_above_end,
        kpi2.yjs_school_total AS yc_with_yjs_school_total,
        kpi2.yjs_school_start AS yc_with_yjs_school_start,
        kpi2.yjs_school_end AS yc_with_yjs_school_end,
        kpi2.yjs_above_total AS yc_with_yjs_above_total,
        kpi2.yjs_above_start AS yc_with_yjs_above_start,
        kpi2.yjs_above_end AS yc_with_yjs_above_end,
        kpi2.ycc_school_total,
        kpi2.ycc_school_start,
        kpi2.ycc_school_end,
        kpi2.ycc_above_total,
        kpi2.ycc_above_start,
        kpi2.ycc_above_end,
        kpi2.ro_school_total,
        kpi2.ro_school_start,
        kpi2.ro_school_end,
        kpi2.ro_above_total,
        kpi2.ro_above_start,
        kpi2.ro_above_end,
        kpi2.yro_school_total,
        kpi2.yro_school_start,
        kpi2.yro_school_end,
        kpi2.yro_above_total,
        kpi2.yro_above_start,
        kpi2.yro_above_end,
        kpi2.cust_school_total,
        kpi2.cust_school_start,
        kpi2.cust_school_release,
        kpi2.cust_school_end,
        kpi2.cust_above_total,
        kpi2.cust_above_start,
        kpi2.cust_above_release,
        kpi2.cust_above_end
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi2_ete_v1" AS kpi2
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi2.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi2.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --NEC: Added NVLs around fields as non-aggregate sum including null values will return null total (i.e.. 1 + NULL == NULL)
    -- overall measures
    -- suitable end (headline numerator)
    SUM(
        CASE
            WHEN description IN (
                'Number of children in suitable ETE with an order closing in the period'
            ) THEN NVL(ns_school_end, 0) + NVL(ns_above_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_school_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_school_end, 0) + NVL(ro_above_end, 0) + NVL(yro_school_end, 0) + NVL(yro_above_end, 0) + NVL(cust_school_end, 0) + NVL(cust_above_end, 0) 
            ELSE NULL
        END
    ) AS kpi2_suitable_end,
    -- unsuitable end
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_end, 0) + NVL(-1 * ns_above_end, 0) + NVL(-1 * ro_school_end, 0) + NVL(-1 * ro_above_end, 0) + NVL(-1 * yc_with_yjs_school_end, 0) + NVL(-1 * yc_with_yjs_above_end, 0) + NVL(-1 * ycc_school_end, 0) + NVL(-1 * ycc_above_end, 0) + NVL(-1 * cust_school_end, 0) + NVL(-1 * cust_above_end, 0) + NVL(-1 * yro_school_end, 0) + NVL(-1 * yro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_end,
    -- suitable start
    SUM(
        CASE
            WHEN description IN (
                'Number of children in suitable ETE with an order closing in the period'
            ) THEN NVL(ns_school_start, 0) + NVL(ns_above_start, 0) + NVL(yc_with_yjs_school_start, 0) + NVL(yc_with_yjs_above_start, 0) + NVL(ycc_school_start, 0) + NVL(ycc_above_start, 0) + NVL(ro_school_start, 0) + NVL(ro_above_start, 0) + NVL(yro_school_start, 0) + NVL(yro_above_start, 0) + NVL(cust_school_start, 0) + NVL(cust_above_start, 0) 
            
            ELSE NULL
        END
    ) AS kpi2_suitable_start,
    -- unsuitable start
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_start, 0) + NVL(-1 * ns_above_start, 0) + NVL(-1 * ro_school_start, 0) + NVL(-1 * ro_above_start, 0) + NVL(-1 * yc_with_yjs_school_start, 0) + NVL(-1 * yc_with_yjs_above_start, 0) + NVL(-1 * ycc_school_start, 0) + NVL(-1 * ycc_above_start, 0) + NVL(-1 * cust_school_start, 0) + NVL(-1 * cust_above_start, 0) + NVL(-1 * yro_school_start, 0) + NVL(-1 * yro_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_start,
    -- total ypid (headline denominator)
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid,
    -- suitable above school and school age
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(ycc_school_end, 0) + NVL(ro_school_end, 0) + NVL(yro_school_end, 0) + NVL(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_school_age,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_above_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_above_end, 0) + NVL(yro_above_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_above_school_age,
    -- not in ETE
    SUM(
        CASE
            WHEN description = 'Number of children not in ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(ycc_school_end, 0) + NVL(ro_school_end, 0) + NVL(yro_school_end, 0) + NVL(cust_school_end, 0) + NVL(ns_above_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_above_end, 0) + NVL(yro_above_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_no_ete,
    -- total in ETE 
    SUM(
        CASE
            WHEN description = 'Number of children in ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(ycc_school_end, 0) + NVL(ro_school_end, 0) + NVL(yro_school_end, 0) + NVL(cust_school_end, 0) + NVL(ns_above_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_above_end, 0) + NVL(yro_above_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_total_ete,
    -- ... suitable
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(ns_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_oocd,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ro_school_end, 0) + NVL(ro_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ro,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yc_with_yjs_school_end, 0) + NVL(yc_with_yjs_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yc_with_yjs,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ycc_school_end, 0) + NVL(ycc_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ycc,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(cust_school_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_cust,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yro_school_end, 0) + NVL(yro_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yro,
    -- ... unsuitable by type of order
    -- Unlike CL no unsuitable figure exists in template: calculate as total - suitable (negate suitable here: aggregation in summary provides total)
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_end, 0) + NVL(-1 * ns_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_oocd,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ro_school_end, 0) + NVL(-1 * ro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ro_school_total, 0) + NVL(ro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ro,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yc_with_yjs_school_end, 0) + NVL(-1 * yc_with_yjs_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yc_with_yjs,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ycc_school_end, 0) + NVL(-1 * ycc_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ycc,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * cust_school_end, 0) + NVL(-1 * cust_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(cust_school_total, 0) + NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_cust,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yro_school_end, 0) + NVL(-1 * yro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yro,
    -- total by type of order

    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_oocd,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_yc,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_ycc,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ro_school_total, 0) + NVL(ro_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_ro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(yro_above_total, 0) + NVL(yro_school_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_yro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_cust,
    -- ** Provision Type
    -- School (full-time)
    SUM(
        CASE
            WHEN description = 'School (full-time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_full_time_start,
    SUM(
        CASE
            WHEN description = 'School (full-time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_full_time_end,
    -- School (part time)
    SUM(
        CASE
            WHEN description = 'School (part time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_part_time_start,
    SUM(
        CASE
            WHEN description = 'School (part time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_part_time_end,
    -- Electively home educated
    SUM(
        CASE
            WHEN description = 'Electively home educated' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_electively_home_educated_start,
    SUM(
        CASE
            WHEN description = 'Electively home educated' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_electively_home_educated_end,
    --Alternative Provision Other (part time)
    SUM(
        CASE
            WHEN description = 'Alternative Provision Other (part time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_other_part_time_start,
    SUM(
        CASE
            WHEN description = 'Alternative Provision Other (part time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_other_part_time_end,
    --Alternative Provision Other (full time)
    SUM(
        CASE
            WHEN description = 'Alternative Provision Other (full time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_other_full_time_start,
    SUM(
        CASE
            WHEN description = 'Alternative Provision Other (full time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_other_full_time_end,
    --Alternative Provision PRU (part time)
    SUM(
        CASE
            WHEN description = 'Alternative Provision PRU (part time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_pru_part_time_start,
    SUM(
        CASE
            WHEN description = 'Alternative Provision PRU (part time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_pru_part_time_end,
    --Alternative Provision PRU (full time)
    SUM(
        CASE
            WHEN description = 'Alternative Provision PRU (full time)' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_pru_full_time_start,
    SUM(
        CASE
            WHEN description = 'Alternative Provision PRU (full time)' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_pru_full_time_end,
    --College
    SUM(
        CASE
            WHEN description = 'College' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_college_start,
    SUM(
        CASE
            WHEN description = 'College' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_college_end,
    --Alternative provision
    SUM(
        CASE
            WHEN description = 'Alternative provision' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_start,
    SUM(
        CASE
            WHEN description = 'Alternative provision' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_end,
    --Education re-engagement programme
    SUM(
        CASE
            WHEN description = 'Education re-engagement programme' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_education_re_engagement_programme_start,
    SUM(
        CASE
            WHEN description = 'Education re-engagement programme' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_education_re_engagement_programme_end,
    --Traineeship
    SUM(
        CASE
            WHEN description = 'Traineeship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_traineeship_start,
    SUM(
        CASE
            WHEN description = 'Traineeship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_traineeship_end,
    --Apprenticeship
    SUM(
        CASE
            WHEN description = 'Apprenticeship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_apprenticeship_start,
    SUM(
        CASE
            WHEN description = 'Apprenticeship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_apprenticeship_end,
    --Supported Internship
    SUM(
        CASE
            WHEN description = 'Supported Internship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_support_internship_start,
    SUM(
        CASE
            WHEN description = 'Supported Internship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_support_internship_end,
    --Mentoring circle
    SUM(
        CASE
            WHEN description = 'Mentoring circle' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_mentoring_circle_start,
    SUM(
        CASE
            WHEN description = 'Mentoring circle' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_mentoring_circle_end,
    --Full-time employment
    SUM(
        CASE
            WHEN description = 'Full-time employment' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_full_time_employment_start,
    SUM(
        CASE
            WHEN description = 'Full-time employment' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_full_time_employment_end,
    --Part-time employment
    SUM(
        CASE
            WHEN description = 'Part-time employment' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_part_time_employment_start,
    SUM(
        CASE
            WHEN description = 'Part-time employment' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_part_time_employment_end,
    --Self-employment
    SUM(
        CASE
            WHEN description = 'Self-employment' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_self_employment_start,
    SUM(
        CASE
            WHEN description = 'Self-employment' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_self_employment_end,
    --Voluntary work
    SUM(
        CASE
            WHEN description = 'Voluntary work' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_voluntary_work_start,
    SUM(
        CASE
            WHEN description = 'Voluntary work' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_voluntary_work_end,
    --University
    SUM(
        CASE
            WHEN description = 'University' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_university_start,
    SUM(
        CASE
            WHEN description = 'University' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_university_end,
    --Other
    SUM(
        CASE
            WHEN description = 'Other' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_other_start,
    SUM(
        CASE
            WHEN description = 'Other' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_other_end,
    -- Hours/offered summary
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_1_15,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_16_24,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_25,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_1_15,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_16_24,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_25
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
/* RQEV2-zvSr0MNSRB */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_template_v8 distkey (return_status_id) sortkey (return_status_id) as WITH template AS (
    SELECT
        kpi2.return_status_id,
        kpi2.reporting_date,
        kpi2.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label quarter which has year first quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi2.description,
        kpi2.description_group,
        kpi2.ns_school_total,
        kpi2.ns_school_start,
        kpi2.ns_school_end,
        kpi2.ns_above_total,
        kpi2.ns_above_start,
        kpi2.ns_above_end,
        kpi2.yjs_school_total AS yc_with_yjs_school_total,
        kpi2.yjs_school_start AS yc_with_yjs_school_start,
        kpi2.yjs_school_end AS yc_with_yjs_school_end,
        kpi2.yjs_above_total AS yc_with_yjs_above_total,
        kpi2.yjs_above_start AS yc_with_yjs_above_start,
        kpi2.yjs_above_end AS yc_with_yjs_above_end,
        kpi2.ycc_school_total,
        kpi2.ycc_school_start,
        kpi2.ycc_school_end,
        kpi2.ycc_above_total,
        kpi2.ycc_above_start,
        kpi2.ycc_above_end,
        kpi2.ro_school_total,
        kpi2.ro_school_start,
        kpi2.ro_school_end,
        kpi2.ro_above_total,
        kpi2.ro_above_start,
        kpi2.ro_above_end,
        kpi2.yro_school_total,
        kpi2.yro_school_start,
        kpi2.yro_school_end,
        kpi2.yro_above_total,
        kpi2.yro_above_start,
        kpi2.yro_above_end,
        kpi2.cust_school_total,
        kpi2.cust_school_start,
        kpi2.cust_school_release,
        kpi2.cust_school_end,
        kpi2.cust_above_total,
        kpi2.cust_above_start,
        kpi2.cust_above_release,
        kpi2.cust_above_end
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi2_ete_v1" AS kpi2
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi2.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi2.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    --NEC: Added NVLs around fields as non-aggregate sum including null values will return null total (i.e.. 1 + NULL == NULL)
    -- overall measures
    -- suitable end (headline numerator)
    SUM(
        CASE
            WHEN description IN (
                'Number of children in suitable ETE with an order closing in the period'
            ) THEN NVL(ns_school_end, 0) + NVL(ns_above_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_school_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_school_end, 0) + NVL(ro_above_end, 0) + NVL(yro_school_end, 0) + NVL(yro_above_end, 0) + NVL(cust_school_end, 0) + NVL(cust_above_end, 0) 
            ELSE NULL
        END
    ) AS kpi2_suitable_end,
    -- unsuitable end
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_end, 0) + NVL(-1 * ns_above_end, 0) + NVL(-1 * ro_school_end, 0) + NVL(-1 * ro_above_end, 0) + NVL(-1 * yc_with_yjs_school_end, 0) + NVL(-1 * yc_with_yjs_above_end, 0) + NVL(-1 * ycc_school_end, 0) + NVL(-1 * ycc_above_end, 0) + NVL(-1 * cust_school_end, 0) + NVL(-1 * cust_above_end, 0) + NVL(-1 * yro_school_end, 0) + NVL(-1 * yro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_end,
    -- suitable start
    SUM(
        CASE
            WHEN description IN (
                'Number of children in suitable ETE with an order closing in the period'
            ) THEN NVL(ns_school_start, 0) + NVL(ns_above_start, 0) + NVL(yc_with_yjs_school_start, 0) + NVL(yc_with_yjs_above_start, 0) + NVL(ycc_school_start, 0) + NVL(ycc_above_start, 0) + NVL(ro_school_start, 0) + NVL(ro_above_start, 0) + NVL(yro_school_start, 0) + NVL(yro_above_start, 0) + NVL(cust_school_start, 0) + NVL(cust_above_start, 0) 
            
            ELSE NULL
        END
    ) AS kpi2_suitable_start,
    -- unsuitable start
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_start, 0) + NVL(-1 * ns_above_start, 0) + NVL(-1 * ro_school_start, 0) + NVL(-1 * ro_above_start, 0) + NVL(-1 * yc_with_yjs_school_start, 0) + NVL(-1 * yc_with_yjs_above_start, 0) + NVL(-1 * ycc_school_start, 0) + NVL(-1 * ycc_above_start, 0) + NVL(-1 * cust_school_start, 0) + NVL(-1 * cust_above_start, 0) + NVL(-1 * yro_school_start, 0) + NVL(-1 * yro_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_start,
    -- total ypid (headline denominator)
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0) + NVL(ro_school_total, 0) + NVL(ro_above_total, 0) + NVL(yro_school_total, 0) + NVL(yro_above_total, 0) + NVL(cust_school_total, 0) + NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid,
    -- suitable school age and above school start of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_start, 0) + NVL(yc_with_yjs_school_start, 0) + NVL(ycc_school_start, 0) + NVL(ro_school_start, 0) + NVL(yro_school_start, 0) + NVL(cust_school_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_school_age_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_above_start, 0) + NVL(yc_with_yjs_above_start, 0) + NVL(ycc_above_start, 0) + NVL(ro_above_start, 0) + NVL(yro_above_start, 0) + NVL(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_above_school_age_start,
    -- suitable school age and above school end of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(ycc_school_end, 0) + NVL(ro_school_end, 0) + NVL(yro_school_end, 0) + NVL(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_school_age_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_above_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_above_end, 0) + NVL(yro_above_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_above_school_age_end,
    -- unsuitable school age and above school start of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_start, 0) + NVL(-1 * ro_school_start, 0) + NVL(-1 * yc_with_yjs_school_start, 0) + NVL(-1 * ycc_school_start, 0) + NVL(-1 * cust_school_start, 0) + NVL(-1 * yro_school_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ro_school_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(ycc_school_total, 0) + NVL(cust_school_total, 0) + NVL(yro_school_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_school_age_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_above_start, 0) + NVL(-1 * ro_above_start, 0) + NVL(-1 * yc_with_yjs_above_start, 0) + NVL(-1 * ycc_above_start, 0) + NVL(-1 * cust_above_start, 0) + NVL(-1 * yro_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN + NVL(ns_above_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_above_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_above_school_age_start,
    -- unsuitable school age and above school end of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_end, 0) + NVL(-1 * ro_school_end, 0) + NVL(-1 * yc_with_yjs_school_end, 0) + NVL(-1 * ycc_school_end, 0) + NVL(-1 * cust_school_end, 0) + NVL(-1 * yro_school_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ro_school_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(ycc_school_total, 0) + NVL(cust_school_total, 0) + NVL(yro_school_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_school_age_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_above_end, 0) + NVL(-1 * ro_above_end, 0) + NVL(-1 * yc_with_yjs_above_end, 0) + NVL(-1 * ycc_above_end, 0) + NVL(-1 * cust_above_end, 0) + NVL(-1 * yro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN + NVL(ns_above_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_above_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_above_school_age_end,
    --total school age and above school age at start of order
    SUM(
        CASE
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_start, 0) + NVL(ro_school_start, 0) + NVL(yc_with_yjs_school_start, 0) + NVL(ycc_school_start, 0) + NVL(cust_school_start, 0) + NVL(yro_school_start, 0)
            ELSE NULL
        END
    ) AS kpi2_total_school_age_start,
    SUM(
        CASE
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_above_start, 0) + NVL(yc_with_yjs_above_start, 0) + NVL(ycc_above_start, 0) + NVL(ro_above_start, 0) + NVL(yro_above_start, 0) + NVL(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_total_above_school_age_start,
    -- total school age and above school age at end of order 
    SUM(
        CASE
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ro_school_total, 0) + NVL(yc_with_yjs_school_total, 0) + NVL(ycc_school_total, 0) + NVL(cust_school_total, 0) + NVL(yro_school_total, 0)
            ELSE NULL
        END
    ) AS kpi2_total_school_age_end,
    SUM(
        CASE
            WHEN description = 'Number of children with an order closing in the period' THEN + NVL(ns_above_total, 0) + NVL(ro_above_total, 0) + NVL(yc_with_yjs_above_total, 0) + NVL(ycc_above_total, 0) + NVL(cust_above_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_total_above_school_age_end,
    -- not in ETE
    SUM(
        CASE
            WHEN description = 'Number of children not in ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(yc_with_yjs_school_end, 0) + NVL(ycc_school_end, 0) + NVL(ro_school_end, 0) + NVL(yro_school_end, 0) + NVL(cust_school_end, 0) + NVL(ns_above_end, 0) + NVL(yc_with_yjs_above_end, 0) + NVL(ycc_above_end, 0) + NVL(ro_above_end, 0) + NVL(yro_above_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_no_ete_end,
    SUM(
        CASE
            WHEN description = 'Number of children not in ETE with an order closing in the period' THEN NVL(ns_school_start, 0) + NVL(yc_with_yjs_school_start, 0) + NVL(ycc_school_start, 0) + NVL(ro_school_start, 0) + NVL(yro_school_start, 0) + NVL(cust_school_start, 0) + NVL(ns_above_start, 0) + NVL(yc_with_yjs_above_start, 0) + NVL(ycc_above_start, 0) + NVL(ro_above_start, 0) + NVL(yro_above_start, 0) + NVL(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_no_ete_start,
    -- suitable by type of order at start of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_start, 0) + NVL(ns_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_oocd_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ro_school_start, 0) + NVL(ro_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ro_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yc_with_yjs_school_start, 0) + NVL(yc_with_yjs_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yc_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ycc_school_start, 0) + NVL(ycc_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ycc_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(cust_school_start, 0) + NVL(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_cust_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yro_school_start, 0) + NVL(yro_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yro_start,
    -- ... unsuitable by type of order at start of order
    -- Unlike CL no unsuitable figure exists in template: calculate as total - suitable (negate suitable here: aggregation in summary provides total)
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_start, 0) + NVL(-1 * ns_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_oocd_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ro_school_start, 0) + NVL(-1 * ro_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ro_school_total, 0) + NVL(ro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ro_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yc_with_yjs_school_start, 0) + NVL(-1 * yc_with_yjs_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yc_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ycc_school_start, 0) + NVL(-1 * ycc_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ycc_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * cust_school_start, 0) + NVL(-1 * cust_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(cust_school_total, 0) + NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_cust_start,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yro_school_start, 0) + NVL(-1 * yro_above_start, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yro_start,
    -- suitable by type of order end of order
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ns_school_end, 0) + NVL(ns_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_oocd_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ro_school_end, 0) + NVL(ro_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ro_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yc_with_yjs_school_end, 0) + NVL(yc_with_yjs_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yc_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(ycc_school_end, 0) + NVL(ycc_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_ycc_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(cust_school_end, 0) + NVL(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_cust_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(yro_school_end, 0) + NVL(yro_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_suitable_yro_end,
    -- ... unsuitable by type of order
    -- Unlike CL no unsuitable figure exists in template: calculate as total - suitable (negate suitable here: aggregation in summary provides total)
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ns_school_end, 0) + NVL(-1 * ns_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_oocd_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ro_school_end, 0) + NVL(-1 * ro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ro_school_total, 0) + NVL(ro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ro_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yc_with_yjs_school_end, 0) + NVL(-1 * yc_with_yjs_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yc_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * ycc_school_end, 0) + NVL(-1 * ycc_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_ycc_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * cust_school_end, 0) + NVL(-1 * cust_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(cust_school_total, 0) + NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_cust_end,
    SUM(
        CASE
            WHEN description = 'Number of children in suitable ETE with an order closing in the period' THEN NVL(-1 * yro_school_end, 0) + NVL(-1 * yro_above_end, 0)
            WHEN description = 'Number of children with an order closing in the period' THEN NVL(yro_school_total, 0) + NVL(yro_above_total, 0)
            ELSE NULL
        END
    ) AS kpi2_unsuitable_yro_end,
    -- total by type of order

    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ns_school_total, 0) + NVL(ns_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_oocd,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(yc_with_yjs_school_total, 0) + NVL(yc_with_yjs_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_yc,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ycc_school_total, 0) + NVL(ycc_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_ycc,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(ro_school_total, 0) + NVL(ro_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_ro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(yro_above_total, 0) + NVL(yro_school_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_yro,
    SUM(
        CASE
            WHEN description IN (
                'Number of children with an order closing in the period'
            ) THEN NVL(cust_above_total, 0)
            ELSE NULL
        END
    ) AS total_ypid_cust,
    -- offered part-time and full-time start and end of the order
    SUM(
        CASE
            WHEN description IN ('Number of children in part time ETE with an order closing in the period') THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_offered_part_time_start,
    SUM(
        CASE
            WHEN description IN ('Number of children in full time ETE with an order closing in the period ') THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_offered_full_time_start,
    SUM(
        CASE
            WHEN description IN ('Number of children in part time ETE with an order closing in the period') THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_offered_part_time_end,
    SUM(
        CASE
            WHEN description IN ('Number of children in full time ETE with an order closing in the period ') THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_offered_full_time_end,
    -- ** Provision Type
    -- School 
    SUM(
        CASE
            WHEN description IN ('School (full-time)', 'School (part time)') THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_start,
    SUM(
        CASE
            WHEN description IN ('School (full-time)','School (part time)') THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_school_end,
    -- Electively home educated
    SUM(
        CASE
            WHEN description = 'Electively home educated' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_electively_home_educated_start,
    SUM(
        CASE
            WHEN description = 'Electively home educated' THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_electively_home_educated_end,
    --Alternative Provision Pupil Referral Unit (PRU)
    SUM(
        CASE
            WHEN description IN ('Alternative Provision PRU (part time)', 'Alternative Provision PRU (full time)') THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_pupil_referral_unit_start,
    SUM(
        CASE
            WHEN description IN ('Alternative Provision PRU (part time)', 'Alternative Provision PRU (full time)') THEN COALESCE(ns_school_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(cust_school_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_pupil_referral_unit_end,
    --College
    SUM(
        CASE
            WHEN description = 'College' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_college_start,
    SUM(
        CASE
            WHEN description = 'College' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_college_end,
    --Alternative provision
    SUM(
        CASE
            WHEN description IN ('Other', 'Alternative Provision Other (part time)', 'Alternative Provision Other (full time)', 'Alternative provision') THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_start,
    SUM(
        CASE
            WHEN description IN ('Other', 'Alternative Provision Other (part time)', 'Alternative Provision Other (full time)', 'Alternative provision') THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_alternative_provision_end,
    --Education re-engagement programme
    SUM(
        CASE
            WHEN description = 'Education re-engagement programme' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_education_re_engagement_programme_start,
    SUM(
        CASE
            WHEN description = 'Education re-engagement programme' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_education_re_engagement_programme_end,
    --Traineeship
    SUM(
        CASE
            WHEN description = 'Traineeship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_traineeship_start,
    SUM(
        CASE
            WHEN description = 'Traineeship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_traineeship_end,
    --Apprenticeship
    SUM(
        CASE
            WHEN description = 'Apprenticeship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_apprenticeship_start,
    SUM(
        CASE
            WHEN description = 'Apprenticeship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_apprenticeship_end,
    --Supported Internship
    SUM(
        CASE
            WHEN description = 'Supported Internship' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_support_internship_start,
    SUM(
        CASE
            WHEN description = 'Supported Internship' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_support_internship_end,
    --Mentoring circle
    SUM(
        CASE
            WHEN description = 'Mentoring circle' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_mentoring_circle_start,
    SUM(
        CASE
            WHEN description = 'Mentoring circle' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_mentoring_circle_end,
    --employment
    SUM(
        CASE
            WHEN description IN ('Full-time employment','Part-time employment') THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_employment_start,
    SUM(
        CASE
            WHEN description IN ('Full-time employment','Part-time employment') THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_employment_end,
    --Self-employment
    SUM(
        CASE
            WHEN description = 'Self-employment' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_self_employment_start,
    SUM(
        CASE
            WHEN description = 'Self-employment' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_self_employment_end,
    --Voluntary work
    SUM(
        CASE
            WHEN description = 'Voluntary work' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_voluntary_work_start,
    SUM(
        CASE
            WHEN description = 'Voluntary work' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_voluntary_work_end,
    --University
    SUM(
        CASE
            WHEN description = 'University' THEN COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_university_start,
    SUM(
        CASE
            WHEN description = 'University' THEN COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_provision_university_end,
    -- hrs offered and attended at start of order
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_1_15_start,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_16_24_start,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_25_start,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_1_15_start,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_16_24_start,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_start, 0) + COALESCE(ns_above_start, 0) + COALESCE(yc_with_yjs_school_start, 0) + COALESCE(yc_with_yjs_above_start, 0) + COALESCE(ycc_school_start, 0) + COALESCE(ycc_above_start, 0) + COALESCE(ro_school_start, 0) + COALESCE(ro_above_start, 0) + COALESCE(yro_school_start, 0) + COALESCE(yro_above_start, 0) + COALESCE(cust_school_start, 0) + COALESCE(cust_above_start, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_25_start,
    -- hrs offered and attended at end of order
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_1_15_end,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_16_24_end,
    SUM(
        CASE
            WHEN description_group = 'Hours offered per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_offered_25_end,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '1 - 15 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_1_15_end,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '16 - 24 hours' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_16_24_end,
    SUM(
        CASE
            WHEN description_group = 'Hours attended per week'
            AND description = '25 hours plus' THEN COALESCE(ns_school_end, 0) + COALESCE(ns_above_end, 0) + COALESCE(yc_with_yjs_school_end, 0) + COALESCE(yc_with_yjs_above_end, 0) + COALESCE(ycc_school_end, 0) + COALESCE(ycc_above_end, 0) + COALESCE(ro_school_end, 0) + COALESCE(ro_above_end, 0) + COALESCE(yro_school_end, 0) + COALESCE(yro_above_end, 0) + COALESCE(cust_school_end, 0) + COALESCE(cust_above_end, 0)
            ELSE NULL
        END
    ) AS kpi2_hrs_attended_25_end
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
/* RQEV2-qMjHmk24t2 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
    SELECT
        kpi3.return_status_id,
        kpi3.reporting_date,
        kpi3.yot_code,
        yot.yjs_name_names_standardised AS yjs_name,
        yot.area_operations_standardised AS area_operations,
        yot.yjb_country_names_standardised AS yjb_country,
        -- new label quarter which has year first quarter second
        CONCAT(
            RIGHT(date_tbl.year_quarter_name, 4),
            LEFT(date_tbl.year_quarter_name, 2)
        ) AS label_quarter,
        kpi3.description,
        kpi3.ns AS out_court_no_yjs_total,
        kpi3.yjs AS yc_with_yjs_total,
        kpi3.ycc AS ycc_total,
        kpi3.ro AS ro_total,
        kpi3.yro AS yro_total,
        kpi3.cust AS cust_total,
        out_court_no_yjs_total + yc_with_yjs_total + ycc_total + ro_total + yro_total + cust_total as total_ypid
    FROM
        "yjb_returns"."yjaf_kpi_returns"."kpi3_send_aln_v1" AS kpi3
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(kpi3.reporting_date AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot ON yot.ou_code_names_standardised = kpi3.yot_code
)
SELECT
    return_status_id,
    reporting_date,
    yot_code,
    yjs_name,
    area_operations,
    yjb_country,
    label_quarter,
    -- total orders ending in the period - denominator for some submeasures
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN total_ypid
            ELSE NULL
        END
    ) AS total_ypid,
    -- headline denominator and a submeasure: number of children with an identified Special Educational NeeDs (England) / Additional Learning Needs (Wales)
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN total_ypid
            ELSE NULL
        END
    ) AS kpi3_identified_sendaln,
    -- headline numerator: of those that have SEND / ALN, who has a formal plan in place
    SUM(
        CASE
            WHEN description = 'Number of children who have a formal plan in place for the current academic year' THEN total_ypid
            ELSE NULL
        END
    ) AS kpi3_sendaln_plan,
    -- submeasure: children with identified send/aln who are in suitable ETE
    SUM(
        CASE
            WHEN description = 'Number of children with an identified SEND/ALN need in suitable ETE' THEN total_ypid
            ELSE NULL
        END
    ) AS kpi3_sendaln_suitable_ete
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
/* RQEV2-zk0lcRpIEm */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi5_substance_m_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    --headline measure: sm need during order
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
    ) AS kpi5_treatment_prior_order,
    /*SUBMEASURES: NEED BREAKDOWN BY ORDER*/
    -- kpi5_sm_need_oocd 
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN out_court_no_yjs_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN out_court_no_yjs_end
            ELSE NULL
        END
    ) AS kpi5_sm_need_oocd,
    -- kpi5_sm_need_yc
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN yc_with_yjs_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN yc_with_yjs_end
            ELSE NULL
        END
    ) AS kpi5_sm_need_yc,
    -- kpi5_sm_need_ycc
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN ycc_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN ycc_end
            ELSE NULL
        END
    ) AS kpi5_sm_need_ycc,
    -- kpi5_sm_need_ro
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN ro_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN ro_end
            ELSE NULL
        END
    ) AS kpi5_sm_need_ro,
    -- kpi5_sm_need_yro
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN yro_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN yro_end
            ELSE NULL
        END
    ) AS kpi5_sm_need_yro,
    -- kpi5_sm_need_cust
    SUM(
        CASE
            WHEN description IN (
                'Number of children in existing treatment or support prior to screening by YJS',
                'Number of children in existing treatment or support prior to the start of the order'
            ) THEN cust_start
            WHEN description = 'Number of children with a screened OR identified need for intervention/treatment to address substance misuse ' THEN cust_end
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
    ) AS kpi5_offered_specialist_substance_misuse_treatment,
    -- offered_risk_support
    SUM(
        CASE
            WHEN description = 'Number offered complex care treatment intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_offered_complex_care,
    -- offered no intervention (no category for this so have to subtract from total)
    NVL(kpi5_sm_need) - NVL(kpi5_offered_targeted_intervention) - NVL(
        kpi5_offered_specialist_substance_misuse_treatment
    ) - NVL(kpi5_offered_complex_care) AS kpi5_offered_no_intervention,
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
    ) AS kpi5_attended_specialist_substance_misuse_treatment,
    -- kpi5_attended_complex_care
    SUM(
        CASE
            WHEN description = 'Number attending complex care treatment intervention' THEN NVL(out_court_no_yjs_end, 0) + NVL(yc_with_yjs_end, 0) + NVL(ycc_end, 0) + NVL(ro_end, 0) + NVL(yro_end, 0) + NVL(cust_end, 0)
            ELSE NULL
        END
    ) AS kpi5_attended_complex_care,
    -- attended no intervention (no category for this so have to subtract from total)
    NVL(kpi5_sm_need) - NVL(kpi5_attended_targeted_intervention) - NVL(
        kpi5_attended_specialist_substance_misuse_treatment
    ) - NVL(kpi5_attended_complex_care) AS kpi5_attended_no_intervention
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
/* RQEV2-M23UWvKXZV */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi6_oocd_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    --total oocds
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_total_oocd,
    --successful oocds
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_successful_oocd,
    --unsuccessful oocds
    SUM (
        CASE
            WHEN description = 'Number of children who did not complete intervention programmes in the quarter' THEN community_resolution + nfa_o22_yjs + nfa_o22_deferred_yjs + nfa_o20_21_yjs + yc_yjs + ycc
            ELSE NULL
        END
    ) AS kpi6_unsuccessful_oocd,
    --total oocds by 6 oocd legal outcomes
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN community_resolution
            ELSE NULL
        END
    ) AS kpi6_total_community_resolution,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o22_yjs
            ELSE NULL
        END
    ) AS kpi6_total_o22_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o22_deferred_yjs
            ELSE NULL
        END
    ) AS kpi6_total_o22_deferred_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN nfa_o20_21_yjs
            ELSE NULL
        END
    ) AS kpi6_total_o20_21_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yc_yjs
            ELSE NULL
        END
    ) AS kpi6_total_yc_yjs,
    SUM (
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ycc
            ELSE NULL
        END
    ) AS kpi6_total_ycc,
    --successful oocds by 6 oocd legal outcomes
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN community_resolution
            ELSE NULL
        END
    ) AS kpi6_successful_community_resolution,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o22_yjs
            ELSE NULL
        END
    ) AS kpi6_successful_o22_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o22_deferred_yjs
            ELSE NULL
        END
    ) AS kpi6_successful_o22_deferred_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN nfa_o20_21_yjs
            ELSE NULL
        END
    ) AS kpi6_successful_o20_21_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN yc_yjs
            ELSE NULL
        END
    ) AS kpi6_successful_yc_yjs,
    SUM (
        CASE
            WHEN description = 'Number of children who completed intervention programmes in the quarter' THEN ycc
            ELSE NULL
        END
    ) AS kpi6_successful_ycc
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
/* RQEV2-97dowCk3Vo */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi7_wider_services_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    --denominator: total orders ending in the period
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
    --submeasure: care experienced child/Looked After Child start and end of the order
    SUM(
        CASE
            WHEN description = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_care_experienced_start,
    SUM(
        CASE
            WHEN description = 'Number of children who are a currently care experienced child (known in statute as a Looked After Child)' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_care_experienced_end,
    --submeasure: Child Protection Plan start and end of the order
    SUM(
        CASE
            WHEN description = 'Number of children on a Child Protection Plan' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_child_protection_plan_start,
    SUM(
        CASE
            WHEN description = 'Number of children on a Child Protection Plan' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_child_protection_plan_end,
    --submeasure: Children in Need (England) / Children in Need of care and supprot (Wales) at the start of the order
    SUM(
        CASE
            WHEN description = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_child_in_need_start,
    SUM(
        CASE
            WHEN description = 'Number of children who are Children in Need/Children in Need of care and support (Wales)' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_child_in_need_end,
    --submeasure: Children on Early Intervention Plan at the start of the order
    SUM(
        CASE
            WHEN description = 'Number of children on an Early Intervention plan' THEN out_court_no_yjs_start + yc_with_yjs_start + ycc_start + ro_start + yro_start + cust_start
            ELSE NULL
        END
    ) AS kpi7_early_intervention_plan_start,
    SUM(
        CASE
            WHEN description = 'Number of children on an Early Intervention plan' THEN out_court_no_yjs_end + yc_with_yjs_end + ycc_end + ro_end + yro_end + cust_end
            ELSE NULL
        END
    ) AS kpi7_early_intervention_plan_end,
    --submeasure: Children on Early Help services at the start of the order
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
    ) AS kpi7_referred_to_early_help
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
/* RQEV2-cSt9Th2FBP */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi9_sv_template distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    -- headline numerator: total sv offences
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
        ) AS kpi9_sv_violence_against_person,
        -- sub measure: broken down by demographics - age only
        SUM(
            CASE
                WHEN description = 'Offences with a gravity score of 5 or more for any offence resulting in a caution or sentence in the quarter' THEN age10to15
                ELSE 0
            END
        ) AS kpi9_sv_age_10_to_15,
        SUM(
            CASE
                WHEN description = 'Offences with a gravity score of 5 or more for any offence resulting in a caution or sentence in the quarter' THEN age16to17
                ELSE 0
            END
        ) AS kpi9_sv_age_16_to_17
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
