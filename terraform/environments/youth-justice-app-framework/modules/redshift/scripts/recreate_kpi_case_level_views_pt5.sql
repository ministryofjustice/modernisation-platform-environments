SET enable_case_sensitive_identifier TO true;
/* RQEV2-JEjVyr5ViC */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        COUNT(DISTINCT ypid) AS total_ypid,
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
                WHEN type_of_order = 'Referral Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ro,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Custodial sentences' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_cust,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Rehabilitation Orders' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_yro,
        COUNT(
            DISTINCT CASE
                WHEN type_of_order = 'Youth Conditional Cautions' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_ycc
    FROM
        "yjb_returns"."yjb_kpi_case_level"."person_details"
    GROUP BY
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country
),
summary_cl as (
    SELECT
        yot_code,
        yjs_name,
        area_operations,
        yjb_country,
        label_quarter,
        COUNT(DISTINCT kpi2_suitable_end) AS kpi2_suitable_end,
        COUNT(DISTINCT kpi2_unsuitable_end) AS kpi2_unsuitable_end,
        COUNT(DISTINCT kpi2_suitable_start) AS kpi2_suitable_start,
        COUNT(DISTINCT kpi2_unsuitable_start) AS kpi2_unsuitable_start,
        COUNT(DISTINCT kpi2_suitable_school_age) AS kpi2_suitable_school_age,
        COUNT(DISTINCT kpi2_suitable_above_school_age) AS kpi2_suitable_above_school_age,
        COUNT(DISTINCT kpi2_total_ete) AS kpi2_total_ete,
        COUNT(DISTINCT kpi2_no_ete) AS kpi2_no_ete,
        COUNT(DISTINCT kpi2_suitable_oocd) AS kpi2_suitable_oocd,
        COUNT(DISTINCT kpi2_suitable_ro) AS kpi2_suitable_ro,
        COUNT(DISTINCT kpi2_suitable_yc_with_yjs) AS kpi2_suitable_yc_with_yjs,
        COUNT(DISTINCT kpi2_suitable_ycc) AS kpi2_suitable_ycc,
        COUNT(DISTINCT kpi2_suitable_cust) AS kpi2_suitable_cust,
        COUNT(DISTINCT kpi2_suitable_yro) AS kpi2_suitable_yro,
        COUNT(DISTINCT kpi2_unsuitable_oocd) AS kpi2_unsuitable_oocd,
        COUNT(DISTINCT kpi2_unsuitable_ro) AS kpi2_unsuitable_ro,
        COUNT(DISTINCT kpi2_unsuitable_yc_with_yjs) AS kpi2_unsuitable_yc_with_yjs,
        COUNT(DISTINCT kpi2_unsuitable_ycc) AS kpi2_unsuitable_ycc,
        COUNT(DISTINCT kpi2_unsuitable_cust) AS kpi2_unsuitable_cust,
        COUNT(DISTINCT kpi2_unsuitable_yro) AS kpi2_unsuitable_yro,
        COUNT(DISTINCT kpi2_provision_school_full_time_start) AS kpi2_provision_school_full_time_start,
        COUNT(DISTINCT kpi2_provision_school_full_time_end) AS kpi2_provision_school_full_time_end,
        COUNT(DISTINCT kpi2_provision_school_part_time_start) AS kpi2_provision_school_part_time_start,
        COUNT(DISTINCT kpi2_provision_school_part_time_end) AS kpi2_provision_school_part_time_end,
        COUNT(
            DISTINCT kpi2_provision_electively_home_educated_start
        ) AS kpi2_provision_electively_home_educated_start,
        COUNT(
            DISTINCT kpi2_provision_electively_home_educated_end
        ) AS kpi2_provision_electively_home_educated_end,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_other_part_time_start
        ) AS kpi2_provision_alternative_provision_other_part_time_start,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_other_part_time_end
        ) AS kpi2_provision_alternative_provision_other_part_time_end,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_other_full_time_start
        ) AS kpi2_provision_alternative_provision_other_full_time_start,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_other_full_time_end
        ) AS kpi2_provision_alternative_provision_other_full_time_end,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_pru_part_time_start
        ) AS kpi2_provision_alternative_provision_pru_part_time_start,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_pru_part_time_end
        ) AS kpi2_provision_alternative_provision_pru_part_time_end,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_pru_full_time_start
        ) AS kpi2_provision_alternative_provision_pru_full_time_start,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_pru_full_time_end
        ) AS kpi2_provision_alternative_provision_pru_full_time_end,
        COUNT(DISTINCT kpi2_provision_college_start) AS kpi2_provision_college_start,
        COUNT(DISTINCT kpi2_provision_college_end) AS kpi2_provision_college_end,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_start
        ) AS kpi2_provision_alternative_provision_start,
        COUNT(
            DISTINCT kpi2_provision_alternative_provision_end
        ) AS kpi2_provision_alternative_provision_end,
        COUNT(
            DISTINCT kpi2_provision_education_re_engagement_programme_start
        ) AS kpi2_provision_education_re_engagement_programme_start,
        COUNT(
            DISTINCT kpi2_provision_education_re_engagement_programme_end
        ) AS kpi2_provision_education_re_engagement_programme_end,
        COUNT(DISTINCT kpi2_provision_traineeship_start) AS kpi2_provision_traineeship_start,
        COUNT(DISTINCT kpi2_provision_traineeship_end) AS kpi2_provision_traineeship_end,
        COUNT(DISTINCT kpi2_provision_apprenticeship_start) AS kpi2_provision_apprenticeship_start,
        COUNT(DISTINCT kpi2_provision_apprenticeship_end) AS kpi2_provision_apprenticeship_end,
        COUNT(DISTINCT kpi2_provision_support_internship_start) AS kpi2_provision_support_internship_start,
        COUNT(DISTINCT kpi2_provision_support_internship_end) AS kpi2_provision_support_internship_end,
        COUNT(DISTINCT kpi2_provision_mentoring_circle_start) AS kpi2_provision_mentoring_circle_start,
        COUNT(DISTINCT kpi2_provision_mentoring_circle_end) AS kpi2_provision_mentoring_circle_end,
        COUNT(
            DISTINCT kpi2_provision_full_time_employment_start
        ) AS kpi2_provision_full_time_employment_start,
        COUNT(DISTINCT kpi2_provision_full_time_employment_end) AS kpi2_provision_full_time_employment_end,
        COUNT(
            DISTINCT kpi2_provision_part_time_employment_start
        ) AS kpi2_provision_part_time_employment_start,
        COUNT(DISTINCT kpi2_provision_part_time_employment_end) AS kpi2_provision_part_time_employment_end,
        COUNT(DISTINCT kpi2_provision_self_employment_start) AS kpi2_provision_self_employment_start,
        COUNT(DISTINCT kpi2_provision_self_employment_end) AS kpi2_provision_self_employment_end,
        COUNT(DISTINCT kpi2_provision_voluntary_work_start) AS kpi2_provision_voluntary_work_start,
        COUNT(DISTINCT kpi2_provision_voluntary_work_end) AS kpi2_provision_voluntary_work_end,
        COUNT(DISTINCT kpi2_provision_university_start) AS kpi2_provision_university_start,
        COUNT(DISTINCT kpi2_provision_university_end) AS kpi2_provision_university_end,
        COUNT(DISTINCT kpi2_provision_other_start) AS kpi2_provision_other_start,
        COUNT(DISTINCT kpi2_provision_other_end) AS kpi2_provision_other_end,
        COUNT(DISTINCT kpi2_hrs_offered_1_15) as kpi2_hrs_offered_1_15,
        COUNT(DISTINCT kpi2_hrs_offered_16_24) as kpi2_hrs_offered_16_24,
        COUNT(DISTINCT kpi2_hrs_offered_25) as kpi2_hrs_offered_25,
        COUNT(DISTINCT kpi2_hrs_attended_1_15) as kpi2_hrs_attended_1_15,
        COUNT(DISTINCT kpi2_hrs_attended_16_24) as kpi2_hrs_attended_16_24,
        COUNT(DISTINCT kpi2_hrs_attended_25) as kpi2_hrs_attended_25
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi2_ete_case_level"
    GROUP BY
        yot_code,
        yjs_name,
        area_operations,
        yjb_country,
        label_quarter
)
SELECT
    --metadata on YJSs
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
            OR summary_t.kpi2_suitable_end > 0
        ) THEN 'Data from template'
        ELSE 'Data from case level'
    END AS source_data_flag,
    --total children with order ending (headline denominator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
        ELSE summary_person.total_ypid
    END AS total_ypid,
    --total children in each type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_oocd
        ELSE summary_person.total_ypid_oocd
    END AS total_ypid_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yc
        ELSE summary_person.total_ypid_yc
    END AS total_ypid_yc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ycc
        ELSE summary_person.total_ypid_ycc
    END AS total_ypid_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ro
        ELSE summary_person.total_ypid_ro
    END AS total_ypid_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yro
        ELSE summary_person.total_ypid_yro
    END AS total_ypid_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_cust
        ELSE summary_person.total_ypid_cust
    END AS total_ypid_cust,
    -- overall measures
    -- total suitable end (headline numerator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_end
        ELSE summary_cl.kpi2_suitable_end
    END AS kpi2_suitable_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_end
        ELSE summary_cl.kpi2_unsuitable_end
    END AS kpi2_unsuitable_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_start
        ELSE summary_cl.kpi2_suitable_start
    END AS kpi2_suitable_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_start
        ELSE summary_cl.kpi2_unsuitable_start
    END AS kpi2_unsuitable_start, 
    --total not in ETE
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_no_ete
        ELSE summary_cl.kpi2_no_ete
    END AS kpi2_no_ete,
    --total in ETE of any kind (suitable or unsuitable)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_total_ete
        ELSE summary_cl.kpi2_total_ete
    END AS kpi2_total_ete,
    --total in suitable ETE at school age
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_school_age
        ELSE summary_cl.kpi2_suitable_school_age
    END AS kpi2_suitable_school_age,
    --total in suitable ETE above school age
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_above_school_age
        ELSE summary_cl.kpi2_suitable_above_school_age
    END AS kpi2_suitable_above_school_age,
    -- suitable breakdown
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_oocd
        ELSE summary_cl.kpi2_suitable_oocd
    END AS kpi2_suitable_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yc_with_yjs
        ELSE summary_cl.kpi2_suitable_yc_with_yjs
    END AS kpi2_suitable_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ycc
        ELSE summary_cl.kpi2_suitable_ycc
    END AS kpi2_suitable_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ro
        ELSE summary_cl.kpi2_suitable_ro
    END AS kpi2_suitable_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yro
        ELSE summary_cl.kpi2_suitable_yro
    END AS kpi2_suitable_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_cust
        ELSE summary_cl.kpi2_suitable_cust
    END AS kpi2_suitable_cust,
    -- unsuitable breakdown
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_oocd < 0 THEN NULL 
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_oocd
        ELSE summary_cl.kpi2_unsuitable_oocd
    END AS kpi2_unsuitable_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_yc_with_yjs < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yc_with_yjs
        ELSE summary_cl.kpi2_unsuitable_yc_with_yjs
    END AS kpi2_unsuitable_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_ycc < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ycc
        ELSE summary_cl.kpi2_unsuitable_ycc
    END AS kpi2_unsuitable_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_ro < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ro
        ELSE summary_cl.kpi2_unsuitable_ro
    END AS kpi2_unsuitable_ro,
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_yro < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yro
        ELSE summary_cl.kpi2_unsuitable_yro
    END AS kpi2_unsuitable_yro,
    CASE
        WHEN source_data_flag = 'Data from template' AND summary_t.kpi2_unsuitable_cust < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_cust
        ELSE summary_cl.kpi2_unsuitable_cust
    END AS kpi2_unsuitable_cust,
    -- --ETE provision type
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_full_time_start
        ELSE summary_cl.kpi2_provision_school_full_time_start
    END AS kpi2_provision_school_full_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_full_time_end
        ELSE summary_cl.kpi2_provision_school_full_time_end
    END AS kpi2_provision_school_full_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_part_time_start
        ELSE summary_cl.kpi2_provision_school_part_time_start
    END AS kpi2_provision_school_part_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_part_time_end
        ELSE summary_cl.kpi2_provision_school_part_time_end
    END AS kpi2_provision_school_part_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_electively_home_educated_start
        ELSE summary_cl.kpi2_provision_electively_home_educated_start
    END AS kpi2_provision_electively_home_educated_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_electively_home_educated_end
        ELSE summary_cl.kpi2_provision_electively_home_educated_end
    END AS kpi2_provision_electively_home_educated_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_other_part_time_start
        ELSE summary_cl.kpi2_provision_alternative_provision_other_part_time_start
    END AS kpi2_provision_alternative_provision_other_part_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_other_part_time_end
        ELSE summary_cl.kpi2_provision_alternative_provision_other_part_time_end
    END AS kpi2_provision_alternative_provision_other_part_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_other_full_time_start
        ELSE summary_cl.kpi2_provision_alternative_provision_other_full_time_start
    END AS kpi2_provision_alternative_provision_other_full_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_other_full_time_end
        ELSE summary_cl.kpi2_provision_alternative_provision_other_full_time_end
    END AS kpi2_provision_alternative_provision_other_full_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_pru_part_time_start
        ELSE summary_cl.kpi2_provision_alternative_provision_pru_part_time_start
    END AS kpi2_provision_alternative_provision_pru_part_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_pru_part_time_end
        ELSE summary_cl.kpi2_provision_alternative_provision_pru_part_time_end
    END AS kpi2_provision_alternative_provision_pru_part_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_pru_full_time_start
        ELSE summary_cl.kpi2_provision_alternative_provision_pru_full_time_start
    END AS kpi2_provision_alternative_provision_pru_full_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_pru_full_time_end
        ELSE summary_cl.kpi2_provision_alternative_provision_pru_full_time_end
    END AS kpi2_provision_alternative_provision_pru_full_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_college_start
        ELSE summary_cl.kpi2_provision_college_start
    END AS kpi2_provision_college_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_college_end
        ELSE summary_cl.kpi2_provision_college_end
    END AS kpi2_provision_college_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_start
        ELSE summary_cl.kpi2_provision_alternative_provision_start
    END AS kpi2_provision_alternative_provision_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_alternative_provision_end
        ELSE summary_cl.kpi2_provision_alternative_provision_end
    END AS kpi2_provision_alternative_provision_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_education_re_engagement_programme_start
        ELSE summary_cl.kpi2_provision_education_re_engagement_programme_start
    END AS kpi2_provision_education_re_engagement_programme_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_education_re_engagement_programme_end
        ELSE summary_cl.kpi2_provision_education_re_engagement_programme_end
    END AS kpi2_provision_education_re_engagement_programme_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_traineeship_start
        ELSE summary_cl.kpi2_provision_traineeship_start
    END AS kpi2_provision_traineeship_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_traineeship_end
        ELSE summary_cl.kpi2_provision_traineeship_end
    END AS kpi2_provision_traineeship_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_apprenticeship_start
        ELSE summary_cl.kpi2_provision_apprenticeship_start
    END AS kpi2_provision_apprenticeship_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_apprenticeship_end
        ELSE summary_cl.kpi2_provision_apprenticeship_end
    END AS kpi2_provision_apprenticeship_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_support_internship_start
        ELSE summary_cl.kpi2_provision_support_internship_start
    END AS kpi2_provision_support_internship_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_support_internship_end
        ELSE summary_cl.kpi2_provision_support_internship_end
    END AS kpi2_provision_support_internship_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_mentoring_circle_start
        ELSE summary_cl.kpi2_provision_mentoring_circle_start
    END AS kpi2_provision_mentoring_circle_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_mentoring_circle_end
        ELSE summary_cl.kpi2_provision_mentoring_circle_end
    END AS kpi2_provision_mentoring_circle_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_full_time_employment_start
        ELSE summary_cl.kpi2_provision_full_time_employment_start
    END AS kpi2_provision_full_time_employment_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_full_time_employment_end
        ELSE summary_cl.kpi2_provision_full_time_employment_end
    END AS kpi2_provision_full_time_employment_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_part_time_employment_start
        ELSE summary_cl.kpi2_provision_part_time_employment_start
    END AS kpi2_provision_part_time_employment_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_part_time_employment_end
        ELSE summary_cl.kpi2_provision_part_time_employment_end
    END AS kpi2_provision_part_time_employment_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_self_employment_start
        ELSE summary_cl.kpi2_provision_self_employment_start
    END AS kpi2_provision_self_employment_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_self_employment_end
        ELSE summary_cl.kpi2_provision_self_employment_end
    END AS kpi2_provision_self_employment_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_voluntary_work_start
        ELSE summary_cl.kpi2_provision_voluntary_work_start
    END AS kpi2_provision_voluntary_work_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_voluntary_work_end
        ELSE summary_cl.kpi2_provision_voluntary_work_end
    END AS kpi2_provision_voluntary_work_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_university_start
        ELSE summary_cl.kpi2_provision_university_start
    END AS kpi2_provision_university_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_university_end
        ELSE summary_cl.kpi2_provision_university_end
    END AS kpi2_provision_university_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_other_start
        ELSE summary_cl.kpi2_provision_other_start
    END AS kpi2_provision_other_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_other_end
        ELSE summary_cl.kpi2_provision_other_end
    END AS kpi2_provision_other_end,
    --ETE hrs offered
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_1_15
        ELSE summary_cl.kpi2_hrs_offered_1_15
    END AS kpi2_hrs_offered_1_15,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_16_24
        ELSE summary_cl.kpi2_hrs_offered_16_24
    END AS kpi2_hrs_offered_16_24,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_25
        ELSE summary_cl.kpi2_hrs_offered_25
    END AS kpi2_hrs_offered_25,
    --ETE hrs attended
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_1_15
        ELSE summary_cl.kpi2_hrs_attended_1_15
    END AS kpi2_hrs_attended_1_15,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_16_24
        ELSE summary_cl.kpi2_hrs_attended_16_24
    END AS kpi2_hrs_attended_16_24,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_25
        ELSE summary_cl.kpi2_hrs_attended_25
    END AS kpi2_hrs_attended_25
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi2_ete_template AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-Q4kRAmXR1F */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS WITH first AS (
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
    'ETE' AS kpi_name,
    'Children Education, Training, and Employment' AS kpi_short_description,
    /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE '%end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- add metadata on whether the measure_numerator is calculating suitable or unsuitable (will not be relevant for some)
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
    -- add metadata for measure category 
    CASE
        /*age categories*/
        WHEN unpvt_table.measure_numerator LIKE '%above%' THEN 'Above school age'
        WHEN unpvt_table.measure_numerator LIKE '%school_age%' THEN 'School age'
        /*type of ETE*/
        WHEN unpvt_table.measure_numerator LIKE '%school%' THEN 'School'
        WHEN unpvt_table.measure_numerator LIKE '%electively_home_educated%' THEN 'Electively home educated'
        WHEN unpvt_table.measure_numerator LIKE '%pupil_referral_unit%' THEN 'Pupil referral unit'
        WHEN unpvt_table.measure_numerator LIKE '%college%' THEN 'College'
        WHEN unpvt_table.measure_numerator LIKE '%alternative_provision%' THEN 'Alternative provision'
        WHEN unpvt_table.measure_numerator LIKE '%education_re_engagement_programme%' THEN 'Education re-engagement programme'
        WHEN unpvt_table.measure_numerator LIKE '%traineeship%' THEN 'Traineeship'
        WHEN unpvt_table.measure_numerator LIKE '%apprenticeship%' THEN 'Apprenticeship'
        WHEN unpvt_table.measure_numerator LIKE '%support_internship%' THEN 'Supported internship'
        WHEN unpvt_table.measure_numerator LIKE '%mentoring_circle%' THEN 'Mentoring circle'
        WHEN unpvt_table.measure_numerator LIKE '%self%' THEN 'Self employment'
        WHEN unpvt_table.measure_numerator LIKE '%employment%' THEN 'Employment'
        WHEN unpvt_table.measure_numerator LIKE '%university%' THEN 'University'
        WHEN unpvt_table.measure_numerator LIKE '%voluntary_work%' THEN 'Voluntary work'
        WHEN unpvt_table.measure_numerator LIKE '%no_ete%' THEN 'No ETE'
        /* type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'Out of court disposals'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'Youth cautions with YJS intervention'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'Youth conditional cautions'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'Youth rehabilitation orders'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'Referral orders'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'Custodial sentences'
        /*hrs offered*/
        WHEN unpvt_table.measure_numerator LIKE '%offered_1_15%' THEN '1-15 hours offered'
        WHEN unpvt_table.measure_numerator LIKE '%offered_16_24%' THEN '16-24 hours offered'
        WHEN unpvt_table.measure_numerator LIKE '%offered_25%' THEN '25+ hours offered'
        /*hrs attended*/
        WHEN unpvt_table.measure_numerator LIKE '%attended_1_15%' THEN '1-15 hours attended'
        WHEN unpvt_table.measure_numerator LIKE '%attended_16_24%' THEN '16-24 hours attended'
        WHEN unpvt_table.measure_numerator LIKE '%attended_25%' THEN '25+ hours attended'
        /* part-time/full-time*/
        WHEN unpvt_table.measure_numerator LIKE '%part_time%' OR
        unpvt_table.measure_numerator LIKE '%full_time%' THEN 'Part-time/full-time'
        /* Overall measures */
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
            'School',
            'Electively home educated',
            'Pupil referral unit',
            'College',
            'Alternative provision',
            'Education re-engagement programme',
            'Traineeship',
            'Apprenticeship',
            'Supported internship',
            'Mentoring circle',
            'Employment',
            'Self employment',
            'University',
            'Voluntary work',
            'No ETE'
        ) THEN 'Type of ETE'
        WHEN measure_category IN (
            '1-15 hours attended',
            '16-24 hours attended',
            '25+ hours attended'
        ) THEN 'Hours of ETE'
        WHEN measure_category IN (
            'Above school age',
            'School age'
        ) THEN 'Age category'
        WHEN measure_category IN (
            'Part-time/full-time'
        ) THEN 'Part-time/full-time'
        ELSE 'Overall measures'
    END AS measure_short_description,
    -- full measure wording 
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi2_total_suitable_end' THEN 'Proportion of children in suitable ETE at the end of their order'
        WHEN measure_short_description = 'Overall measures' THEN 'Children in suitable versus unsuitable ETE at the start and the end of their order'
        WHEN measure_short_description = 'Age category' THEN 'Children in suitable versus unsuitable ETE at school age and above school age at the start and the end of their order'
        WHEN measure_short_description = 'Part-time/full-time' THEN 'Children offered part-time versus full-time ETE at the start and the end of their order'
        WHEN measure_short_description = 'Type of ETE' THEN 'Children broken down by type of ETE provision they were offered at the start and the end of their order'
        WHEN measure_short_description = 'Hours of ETE' THEN 'Children broken down by number of hours offered and hours attended at the start and the end of their order'
        WHEN measure_short_description = 'Type of order' THEN 'Children in suitable versus unsuitable ETE at the start and the end of their order broken down by type of order'
    END AS measure_long_description,
    -- whether the measure is the headline measure
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi2_total_suitable_end' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    -- measure numbering 
    CASE
        WHEN unpvt_table.measure_numerator = 'kpi2_total_suitable_end' THEN 'Headline'
        WHEN measure_short_description = 'Overall measures' THEN '2a'
        WHEN measure_short_description = 'Age category' THEN '2b'
        WHEN measure_short_description = 'Part-time/full-time' THEN '2c'
        WHEN measure_short_description = 'Type of ETE' THEN '2d'
        WHEN measure_short_description = 'Hours of ETE' THEN '2e'
        WHEN measure_short_description = 'Type of order' THEN '2f'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- set the field name for the denominator
    CASE
        WHEN measure_category = 'Custodial sentences' THEN 'kpi2_total_ypid_cust'
        WHEN measure_category = 'Youth rehabilitation orders' THEN 'kpi2_total_ypid_yro'
        WHEN measure_category = 'Referral orders' THEN 'kpi2_total_ypid_ro'
        WHEN measure_category = 'Youth conditional cautions' THEN 'kpi2_total_ypid_ycc'
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN 'kpi2_total_ypid_yc_with_yjs'
        WHEN measure_category = 'Out of court disposals' THEN 'kpi2_total_ypid_oocd'
        WHEN measure_category = 'School age'
        AND time_point = 'Start' THEN 'kpi2_total_ypid_school_age_start'
        WHEN measure_category = 'School age'
        AND time_point = 'End' THEN 'kpi2_total_ypid_school_age_end'
        WHEN measure_category = 'Above school age'
        AND time_point = 'Start' THEN 'kpi2_total_ypid_above_school_age_start'
        WHEN measure_category = 'Above school age'
        AND time_point = 'End' THEN 'kpi2_total_ypid_above_school_age_end'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_1_15_start' THEN 'kpi2_hrs_offered_1_15_start'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_1_15_end' THEN 'kpi2_hrs_offered_1_15_end'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_16_24_start' THEN 'kpi2_hrs_offered_16_24_start'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_16_24_end' THEN 'kpi2_hrs_offered_16_24_end'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_25_start' THEN 'kpi2_hrs_offered_25_start'
        WHEN unpvt_table.measure_numerator = 'kpi2_hrs_attended_25_end' THEN 'kpi2_hrs_offered_25_end'
        ELSE 'kpi2_total_ypid' -- remaining measures have this denominator (overall measures, type of ETE and part-time/full-time)
    END AS measure_denominator,
    -- fill in the actual values for the denominator
    CASE
        WHEN measure_category = 'Custodial sentences' THEN unpvt_table.kpi2_total_ypid_cust
        WHEN measure_category = 'Youth rehabilitation orders' THEN unpvt_table.kpi2_total_ypid_yro
        WHEN measure_category = 'Referral orders' THEN unpvt_table.kpi2_total_ypid_ro
        WHEN measure_category = 'Youth conditional cautions' THEN unpvt_table.kpi2_total_ypid_ycc
        WHEN measure_category = 'Youth cautions with YJS intervention' THEN unpvt_table.kpi2_total_ypid_yc_with_yjs
        WHEN measure_category = 'Out of court disposals' THEN unpvt_table.kpi2_total_ypid_oocd
        WHEN measure_category = 'School age'
        AND time_point = 'Start' THEN unpvt_table.kpi2_total_ypid_school_age_start
        WHEN measure_category = 'School age'
        AND time_point = 'End' THEN unpvt_table.kpi2_total_ypid_school_age_end
        WHEN measure_category = 'Above school age'
        AND time_point = 'Start' THEN unpvt_table.kpi2_total_ypid_above_school_age_start
        WHEN measure_category = 'Above school age'
        AND time_point = 'End' THEN unpvt_table.kpi2_total_ypid_above_school_age_end
        WHEN measure_numerator = 'kpi2_hrs_attended_1_15_start' THEN unpvt_table.kpi2_hrs_offered_1_15_start
        WHEN measure_numerator = 'kpi2_hrs_attended_1_15_end' THEN unpvt_table.kpi2_hrs_offered_1_15_end
        WHEN measure_numerator = 'kpi2_hrs_attended_16_24_start' THEN unpvt_table.kpi2_hrs_offered_16_24_start
        WHEN measure_numerator = 'kpi2_hrs_attended_16_24_end' THEN unpvt_table.kpi2_hrs_offered_16_24_end
        WHEN measure_numerator = 'kpi2_hrs_attended_25_start' THEN unpvt_table.kpi2_hrs_offered_25_start
        WHEN measure_numerator = 'kpi2_hrs_attended_25_end' THEN unpvt_table.kpi2_hrs_offered_25_end
        ELSE unpvt_table.kpi2_total_ypid -- remaining measures have this denominator (overall measures, type of ETE and part-time/full-time)
    END AS denominator_value
FROM
    yjb_kpi_case_level.kpi2_ete_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi2_hrs_attended_25_end,
            kpi2_hrs_attended_16_24_end,
            kpi2_hrs_attended_1_15_end,
            kpi2_hrs_attended_25_start,
            kpi2_hrs_attended_16_24_start,
            kpi2_hrs_attended_1_15_start,
            kpi2_provision_university_end,
            kpi2_provision_university_start,
            kpi2_provision_voluntary_work_end,
            kpi2_provision_voluntary_work_start,
            kpi2_provision_self_employment_end,
            kpi2_provision_self_employment_start,
            kpi2_provision_employment_end,
            kpi2_provision_employment_start,
            kpi2_provision_mentoring_circle_end,
            kpi2_provision_mentoring_circle_start,
            kpi2_provision_support_internship_end,
            kpi2_provision_support_internship_start,
            kpi2_provision_apprenticeship_end,
            kpi2_provision_apprenticeship_start,
            kpi2_provision_traineeship_end,
            kpi2_provision_traineeship_start,
            kpi2_provision_education_re_engagement_programme_end,
            kpi2_provision_education_re_engagement_programme_start,
            kpi2_provision_alternative_provision_end,
            kpi2_provision_alternative_provision_start,
            kpi2_provision_college_end,
            kpi2_provision_college_start,
            kpi2_provision_pupil_referral_unit_end,
            kpi2_provision_pupil_referral_unit_start,
            kpi2_provision_electively_home_educated_end,
            kpi2_provision_electively_home_educated_start,
            kpi2_provision_school_end,
            kpi2_provision_school_start,
            kpi2_offered_full_time_end,
            kpi2_offered_part_time_end,
            kpi2_offered_full_time_start,
            kpi2_offered_part_time_start,
            kpi2_no_ete_end,
            kpi2_no_ete_start,
            kpi2_unsuitable_cust_end,
            kpi2_unsuitable_yro_end,
            kpi2_unsuitable_ro_end,
            kpi2_unsuitable_ycc_end,
            kpi2_unsuitable_yc_with_yjs_end,
            kpi2_unsuitable_oocd_end,
            kpi2_suitable_cust_end,
            kpi2_suitable_yro_end,
            kpi2_suitable_ro_end,
            kpi2_suitable_ycc_end,
            kpi2_suitable_yc_with_yjs_end,
            kpi2_suitable_oocd_end,
            kpi2_unsuitable_cust_start,
            kpi2_unsuitable_yro_start,
            kpi2_unsuitable_ro_start,
            kpi2_unsuitable_ycc_start,
            kpi2_unsuitable_yc_with_yjs_start,
            kpi2_unsuitable_oocd_start,
            kpi2_suitable_cust_start,
            kpi2_suitable_yro_start,
            kpi2_suitable_ro_start,
            kpi2_suitable_ycc_start,
            kpi2_suitable_yc_with_yjs_start,
            kpi2_suitable_oocd_start,
            kpi2_suitable_above_school_age_end,
            kpi2_suitable_above_school_age_start,
            kpi2_suitable_school_age_end,
            kpi2_suitable_school_age_start,
            kpi2_unsuitable_above_school_age_end,
            kpi2_unsuitable_above_school_age_start,
            kpi2_unsuitable_school_age_end,
            kpi2_unsuitable_school_age_start,
            kpi2_total_unsuitable_start,
            kpi2_total_suitable_start,
            kpi2_total_unsuitable_end,
            kpi2_total_suitable_end,
            kpi2_suitable_change,
            kpi2_unsuitable_change
        )
    ) AS unpvt_table
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name)
    
    SELECT 
        *,
        -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children in suitable ETE at the end of their order'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with an order ending'
        ELSE NULL
    END AS headline_denominator_description
    FROM first
    
    ;	
/* RQEV2-puL2ia47BP */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi3_sendaln_summary_v8;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- total orders ending in the period 
        COUNT(DISTINCT ypid) as total_ypid,
        -- total children by demographics (not currently used - but you may want to use in future for different denominator for demographics)
        -- ethnicity 
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'White' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_white,
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'Mixed' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_mixed_ethnic,
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'Black or Black British' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_black,
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'Other Ethnic Group' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_other_ethnic,
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'Asian or Asian British' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_asian,
        COUNT(
            DISTINCT CASE
                WHEN ethnicity_group = 'Information not obtainable' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_unknown_ethnic,
        -- age groups
        COUNT(
            DISTINCT CASE
                WHEN age_on_intervention_start BETWEEN 10
                AND 14 THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_10_14,
        COUNT(
            DISTINCT CASE
                WHEN age_on_intervention_start BETWEEN 15
                AND 17 THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_15_17,
        -- gender
        COUNT(
            DISTINCT CASE
                WHEN gender_name = 'Male' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_male,
        COUNT(
            DISTINCT CASE
                WHEN gender_name = 'Female' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_female,
        COUNT(
            DISTINCT CASE
                WHEN gender_name = 'Unknown gender' THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_unknown_gender,
        --total by type of order
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
        yot_code,
        yjs_name,
        label_quarter,
        COUNT(DISTINCT kpi3_sendaln_plan) AS kpi3_sendaln_plan,
        COUNT(
            DISTINCT CASE
                WHEN kpi3_identified_sendaln = 'YES' THEN ypid
                ELSE NULL
            END
        ) AS kpi3_identified_sendaln,
        COUNT(DISTINCT kpi3_sendaln_suitable_ete) AS kpi3_sendaln_suitable_ete,
        COUNT(DISTINCT kpi3_sendaln_unsuitable_ete) AS kpi3_sendaln_unsuitable_ete,
        COUNT(DISTINCT kpi3_sendaln_white) AS kpi3_sendaln_white,
        COUNT(DISTINCT kpi3_sendaln_mixed_ethnic) AS kpi3_sendaln_mixed_ethnic,
        COUNT(DISTINCT kpi3_sendaln_black) AS kpi3_sendaln_black,
        COUNT(DISTINCT kpi3_sendaln_other_ethnic) AS kpi3_sendaln_other_ethnic,
        COUNT(DISTINCT kpi3_sendaln_asian) AS kpi3_sendaln_asian,
        COUNT(DISTINCT kpi3_sendaln_unknown_ethnic) AS kpi3_sendaln_unknown_ethnic,
        COUNT(DISTINCT kpi3_sendaln_male) AS kpi3_sendaln_male,
        COUNT(DISTINCT kpi3_sendaln_female) AS kpi3_sendaln_female,
        COUNT(DISTINCT kpi3_sendaln_unknown_gender) AS kpi3_sendaln_unknown_gender,
        COUNT(DISTINCT kpi3_sendaln_10_14) AS kpi3_sendaln_10_14,
        COUNT(DISTINCT kpi3_sendaln_15_17) AS kpi3_sendaln_15_17,
        COUNT(DISTINCT kpi3_sendaln_oocd) AS kpi3_sendaln_oocd,
        COUNT(DISTINCT kpi3_sendaln_yc_with_yjs) AS kpi3_sendaln_yc_with_yjs,
        COUNT(DISTINCT kpi3_sendaln_ycc) AS kpi3_sendaln_ycc,
        COUNT(DISTINCT kpi3_sendaln_ro) AS kpi3_sendaln_ro,
        COUNT(DISTINCT kpi3_sendaln_yro) AS kpi3_sendaln_yro,
        COUNT(DISTINCT kpi3_sendaln_cust) AS kpi3_sendaln_cust
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi3_sendaln_case_level_v8"
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
    CASE
        WHEN (
            summary_t.kpi3_identified_sendaln > 0
            OR summary_t.kpi3_sendaln_plan > 0
            OR summary_t.total_ypid > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
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
            )
        END AS DATE
    ) AS quarter_label_date,
    'KPI 3' AS kpi_number,
    -- total orders ending in the period - denominator for submeasure 3a
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
            ELSE summary_person.total_ypid
        END,
        0
    ) AS kpi3_total_ypid,
    --headline numerator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_plan
            ELSE summary_cl.kpi3_sendaln_plan
        END,
        0
    ) AS kpi3_sendaln_plan,
    --headline denominator and numerator of submeasure 3a
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_identified_sendaln
            ELSE summary_cl.kpi3_identified_sendaln
        END,
        0
    ) AS kpi3_identified_sendaln,
    -- submeasure: identified send/aln in suitable ETE
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_suitable_ete
            ELSE summary_cl.kpi3_sendaln_suitable_ete
        END,
        0
    ) AS kpi3_sendaln_suitable_ete,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_unsuitable_ete
            ELSE summary_cl.kpi3_sendaln_unsuitable_ete
        END,
        0
    ) AS kpi3_sendaln_unsuitable_ete,
    /* Sub-measure: Children with SEND/ALN broken down by type of order */
    --identified send/aln oocd
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_oocd
            ELSE summary_cl.kpi3_sendaln_oocd
        END,
        0
    ) AS kpi3_sendaln_oocd,
    --identified send/aln yc_with_yjs
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_yc_with_yjs
            ELSE summary_cl.kpi3_sendaln_yc_with_yjs
        END,
        0
    ) AS kpi3_sendaln_yc_with_yjs,
    --identified send/aln ycc
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_ycc
            ELSE summary_cl.kpi3_sendaln_ycc
        END,
        0
    ) AS kpi3_sendaln_ycc,
    --identified send/aln ro
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_ro
            ELSE summary_cl.kpi3_sendaln_ro
        END,
        0
    ) AS kpi3_sendaln_ro,
    --identified send/aln yro
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_yro
            ELSE summary_cl.kpi3_sendaln_yro
        END,
        0
    ) AS kpi3_sendaln_yro,
    --identified send/aln cust
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_cust
            ELSE summary_cl.kpi3_sendaln_cust
        END,
        0
    ) AS kpi3_sendaln_cust,
    --total children in each type of order 
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_oocd
            ELSE summary_person.total_ypid_oocd
        END,
        0
    ) AS kpi3_total_ypid_oocd,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yc_with_yjs
            ELSE summary_person.total_ypid_yc_with_yjs
        END,
        0
    ) AS kpi3_total_ypid_yc_with_yjs,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ycc
            ELSE summary_person.total_ypid_ycc
        END,
        0
    ) AS kpi3_total_ypid_ycc,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ro
            ELSE summary_person.total_ypid_ro
        END,
        0
    ) AS kpi3_total_ypid_ro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yro
            ELSE summary_person.total_ypid_yro
        END,
        0
    ) AS kpi3_total_ypid_yro,
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_cust
            ELSE summary_person.total_ypid_cust
        END,
        0
    ) AS kpi3_total_ypid_cust,
    /* Sub-measure: Children with SEND/ALN broken down by demographic characteristics */
    -- identified send/aln by ethnicity
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_white
        ELSE NULL
    END AS kpi3_sendaln_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_mixed_ethnic
        ELSE NULL
    END AS kpi3_sendaln_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_black
        ELSE NULL
    END AS kpi3_sendaln_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_other_ethnic
        ELSE NULL
    END AS kpi3_sendaln_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_asian
        ELSE NULL
    END AS kpi3_sendaln_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_unknown_ethnic
        ELSE NULL
    END AS kpi3_sendaln_unknown_ethnic,
    --total by ethnicity group 
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_white
        ELSE NULL
    END AS kpi3_total_ypid_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_mixed_ethnic
        ELSE NULL
    END AS kpi3_total_ypid_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_black
        ELSE NULL
    END AS kpi3_total_ypid_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_other_ethnic
        ELSE NULL
    END AS kpi3_total_ypid_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_asian
        ELSE NULL
    END AS kpi3_total_ypid_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_unknown_ethnic
        ELSE NULL
    END AS kpi3_total_ypid_unknown_ethnic,
    -- identified send/aln by gender
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_male
        ELSE NULL
    END AS kpi3_sendaln_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_female
        ELSE NULL
    END AS kpi3_sendaln_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_unknown_gender
        ELSE NULL
    END AS kpi3_sendaln_unknown_gender,
    -- total by gender
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_male
        ELSE NULL
    END AS kpi3_total_ypid_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_female
        ELSE NULL
    END AS kpi3_total_ypid_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_unknown_gender
        ELSE NULL
    END AS kpi3_total_ypid_unknown_gender,
    -- identified send/aln by age group
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_10_14
        ELSE NULL
    END AS kpi3_sendaln_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_cl.kpi3_sendaln_15_17
        ELSE NULL
    END AS kpi3_sendaln_15_17,
    -- total by age group 
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_10_14
        ELSE NULL
    END AS kpi3_total_ypid_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_15_17
        ELSE NULL
    END AS kpi3_total_ypid_15_17
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi3_sendaln_template_v8 AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
