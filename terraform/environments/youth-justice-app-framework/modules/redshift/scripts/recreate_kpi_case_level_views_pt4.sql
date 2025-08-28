SET enable_case_sensitive_identifier TO true;
/* RQEV2-jJnBWZDDhc */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_case_level_v8 distkey (kpi2_source_document_id) sortkey (kpi2_source_document_id) AS WITH kpi2 AS (
  SELECT
    dc.source_document_id as kpi2_source_document_id,
    dc.document_item."startDate" :: date as kpi2_start_date,
    dc.document_item."endDate" :: date as kpi2_end_date,
    dc.document_item."description" :: text as kpi2_description,
    dc.document_item."provisionType" :: text as kpi2_provision_type,
    dc.document_item."suitability" :: text as kpi2_suitability,
    dc.document_item."hoursOffered" :: int as kpi2_hours_offered,
    dc.document_item."hours" :: int as kpi2_hours_attended
  FROM
    stg.yp_doc_item dc
  WHERE
    document_item_type = 'ete_status'
    AND document_item."suitability" is not NULL
),
-- CTE combines kpi2 data from kpi2 CTE with person_detals table and adds markers for where ETE was at start or end of order
kpi2_pd AS (
  SELECT
    DISTINCT kpi2.*,
    person_details.*,
    -- marker stating whether ETE existed at start or not
    yjb_kpi_case_level.f_isAtStart(
      kpi2.kpi2_start_date,
      person_details.legal_outcome_group_fixed,
      person_details.disposal_type_fixed,
      person_details.outcome_date,
      person_details.intervention_start_date
    ) AS ete_start,
    -- marker stating whether ETE existed at end or not
    yjb_kpi_case_level.f_isAtEnd(
      kpi2.kpi2_end_date,
      person_details.intervention_end_date
    ) AS ete_end
  FROM
    kpi2
    INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi2.kpi2_source_document_id = person_details.source_document_id
  WHERE
    -- Filter out ETEs unless they were present at order start, order end or both 
    kpi2.kpi2_start_date <= person_details.intervention_end_date
    AND (
      kpi2.kpi2_end_date = '1900-01-01'
      OR (
        person_details.type_of_order <> 'Custodial sentences'
        AND kpi2.kpi2_end_date >= person_details.intervention_start_date
      )
      OR (
        person_details.disposal_type_fixed = 'DTO_LICENCE'
        AND kpi2.kpi2_end_date >= DATEADD(d, -1, person_details.outcome_date)
      )
      OR (
        person_details.disposal_type_fixed <> 'DTO_LICENCE'
        AND person_details.type_of_order = 'Custodial sentences'
        AND kpi2.kpi2_end_date >= DATEADD(d, -1, person_details.intervention_start_date)
      )
    )
    AND (
      ete_start = TRUE
      OR ete_end = TRUE
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
          WHEN ete_start = TRUE
          AND kpi2_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
          ELSE 0
        END
      ) > 0 THEN FALSE
      ELSE TRUE
    END AS is_suitable_start,
    CASE
      WHEN SUM(
        CASE
          WHEN ete_end = TRUE
          AND kpi2_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
          ELSE 0
        END
      ) > 0 THEN FALSE
      ELSE TRUE
    END AS is_suitable_end
  FROM
    kpi2_pd
  GROUP BY
    ypid,
    label_quarter
),
total_hours AS (
  SELECT
    ypid,
    label_quarter,
    SUM(
      CASE
        WHEN ete_start = TRUE THEN kpi2_hours_offered
        ELSE 0
      END
    ) AS total_hrs_offered_start,
    SUM(
      CASE
        WHEN ete_start = TRUE THEN kpi2_hours_attended
        ELSE 0
      END
    ) AS total_hrs_attended_start,
    SUM(
      CASE
        WHEN ete_end = TRUE THEN kpi2_hours_offered
        ELSE 0
      END
    ) AS total_hrs_offered_end,
    SUM(
      CASE
        WHEN ete_end = TRUE THEN kpi2_hours_attended
        ELSE 0
      END
    ) AS total_hrs_attended_end
  FROM
    kpi2_pd
  GROUP BY
    ypid,
    label_quarter
)
SELECT
  kpi2_pd.*,
  --these ensure that where ETE did not exist at start or end that the input of the true suitability variable (is_suitable_...) is NULL - is 'true' otherwise
  CASE
    WHEN kpi2_pd.ete_start = FALSE THEN NULL
    ELSE true_suitability.is_suitable_start
  END AS is_suitable_start,
  CASE
    WHEN kpi2_pd.ete_end = FALSE THEN NULL
    ELSE true_suitability.is_suitable_end
  END AS is_suitable_end,
  --bring in the total ETE hrs offered and attended at a time
  CASE
    WHEN kpi2_pd.ete_start = FALSE THEN NULL
    ELSE total_hours.total_hrs_offered_start
  END AS total_hrs_offered_start,
  CASE
    WHEN kpi2_pd.ete_start = FALSE THEN NULL
    ELSE total_hours.total_hrs_attended_start
  END AS total_hrs_attended_start,
  CASE
    WHEN kpi2_pd.ete_end = FALSE THEN NULL
    ELSE total_hours.total_hrs_offered_end
  END AS total_hrs_offered_end,
  CASE
    WHEN kpi2_pd.ete_end = FALSE THEN NULL
    ELSE total_hours.total_hrs_attended_end
  END AS total_hrs_attended_end,
  -- headline numerator: in suitable at end 
  CASE
    WHEN is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_end,
  -- suitable start
  CASE
    WHEN is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_start,
  -- unsuitable start and end
  CASE
    WHEN is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_start,
  CASE
    WHEN is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_end,
  --suitable/unsuitable by age at start
  CASE
    WHEN is_suitable_start = TRUE
    AND yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_school_age_start,
  CASE
    WHEN is_suitable_start = TRUE
    AND yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_above_school_age_start,
  CASE
    WHEN is_suitable_start = FALSE
    AND yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_school_age_start,
  CASE
    WHEN is_suitable_end = FALSE
    AND yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_above_school_age_start,
  --suitable/unsuitable by age at end
  CASE
    WHEN is_suitable_end = TRUE
    AND yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_school_age_end,
  CASE
    WHEN is_suitable_end = TRUE
    AND yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_above_school_age_end,
  CASE
    WHEN is_suitable_end = FALSE
    AND yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_school_age_end,
  CASE
    WHEN is_suitable_end = FALSE
    AND yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_above_school_age_end,
  --(this commented section is in the summary code and is pulled from person_details)
  --total school age start and end 
  CASE
    WHEN yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_total_school_age_start,
  CASE
    WHEN yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_total_school_age_end,
  --total above school age start and end  
  CASE
    WHEN yjb_kpi_case_level.f_isSchoolAgeStart(
      kpi2_pd.disposal_type_fixed,
      kpi2_pd.outcome_date,
      kpi2_pd.intervention_start_date,
      kpi2_pd.ypid_dob
    ) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_total_above_school_age_start,
  CASE
    WHEN yjb_kpi_case_level.f_isSchoolAgeEnd(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_total_above_school_age_end,
  --offered part-time and offered full-time start 
  CASE
    WHEN (
      kpi2_total_school_age_start = kpi2_pd.ypid
      AND total_hrs_offered_start < 25
    )
    OR (
      kpi2_total_above_school_age_start = kpi2_pd.ypid
      AND total_hrs_offered_start < 16
    ) THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_offered_part_time_start,
  CASE
    WHEN (
      kpi2_total_school_age_start = kpi2_pd.ypid
      AND total_hrs_offered_start >= 25
    )
    OR (
      kpi2_total_above_school_age_start = kpi2_pd.ypid
      AND total_hrs_offered_start >= 16
    ) THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_offered_full_time_start,
  --offered part-time and offered full-time end
  CASE
    WHEN (
      kpi2_total_school_age_end = kpi2_pd.ypid
      AND total_hrs_offered_end BETWEEN 1 AND 24
    )
    OR (
      kpi2_total_above_school_age_end = kpi2_pd.ypid
      AND total_hrs_offered_end BETWEEN 1 AND 15
    ) THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_offered_part_time_end,
  CASE
    WHEN (
      kpi2_total_school_age_end = kpi2_pd.ypid
      AND total_hrs_offered_end >= 25
    )
    OR (
      kpi2_total_above_school_age_end = kpi2_pd.ypid
      AND total_hrs_offered_end >= 16
    ) THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_offered_full_time_end,
  --in no ETE at all
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'NONE'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_no_ete_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'NONE'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_no_ete_end,
  --suitable by type of order at start of order
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_oocd_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ro_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yc_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ycc_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_cust_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yro_start,
  -- unsuitable by type of order at start of order
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_oocd_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ro_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yc_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ycc_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_cust_start,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yro_start,
  --suitable by type of order at end of order
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_oocd_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yc_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ycc_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ro_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yro_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_cust_end,
  -- unsuitable by type of order at end of order
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_oocd_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yc_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ycc_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ro_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yro_end,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_cust_end,
  -- Provision Type
  -- School 
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'SCHOOL_FULL_TIME',
      'MAINSTREAM_SCHOOL',
      'SCHOOL_PART_TIME'
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'SCHOOL_FULL_TIME',
      'MAINSTREAM_SCHOOL',
      'SCHOOL_PART_TIME'
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_end,
  -- Home educated
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ELECTIVELY_HOME_EDUCATED'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_electively_home_educated_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ELECTIVELY_HOME_EDUCATED'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_electively_home_educated_end,
  -- Pupil referral unit (pru)
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION_PRU_PART_TIME',
      'PUPIL_REFERRAL_UNIT',
      'ALTERNATIVE_PROVISION_PRU_FULL_TIME'
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_pupil_referral_unit_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION_PRU_PART_TIME',
      'PUPIL_REFERRAL_UNIT',
      'ALTERNATIVE_PROVISION_PRU_FULL_TIME'
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_pupil_referral_unit_end,
  -- College
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'COLLEGE'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_college_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'COLLEGE'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_college_end,
  -- Alternative Provision
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION',
      'ALTERNATIVE_PROVISION_ABOVE_SCHOOL_AGE',
      'OTHER',
      'ALTERNATIVE_PROVISION_OTHER_PART_TIME',
      'ALTERNATIVE_PROVISION_OTHER_FULL_TIME'
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION',
      'ALTERNATIVE_PROVISION_ABOVE_SCHOOL_AGE',
      'OTHER',
      'ALTERNATIVE_PROVISION_OTHER_PART_TIME',
      'ALTERNATIVE_PROVISION_OTHER_FULL_TIME'
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_end,
  -- Education reengagement programme
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'EDUCATION_RE_ENGAGEMENT_PROGRAMME'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_education_re_engagement_programme_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'EDUCATION_RE_ENGAGEMENT_PROGRAMME'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_education_re_engagement_programme_end,
  -- Traineeship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINEESHIP'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_traineeship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINEESHIP'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_traineeship_end,
  -- Apprenticeship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINING_COURSE_APPRENTICESHIP'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_apprenticeship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINING_COURSE_APPRENTICESHIP'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_apprenticeship_end,
  -- Internship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SUPPORTED_INTERNSHIP'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_support_internship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SUPPORTED_INTERNSHIP'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_support_internship_end,
  -- Mentoring
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'MENTORING_CIRCLE'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_mentoring_circle_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'MENTORING_CIRCLE'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_mentoring_circle_end,
  -- employment
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'FULL_TIME_EMPLOYMENT',
      'EMPLOYMENT',
      'PART_TIME_EMPLOYMENT'
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_employment_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'FULL_TIME_EMPLOYMENT',
      'EMPLOYMENT',
      'PART_TIME_EMPLOYMENT'
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_employment_end,
  -- Self employment
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SELF_EMPLOYMENT'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_self_employment_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SELF_EMPLOYMENT'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_self_employment_end,
  -- Voluntary work
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'VOLUNTARY_WORK'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_voluntary_work_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'VOLUNTARY_WORK'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_voluntary_work_end,
  -- University
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'UNIVERSITY'
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_university_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'UNIVERSITY'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_university_end,
  -- Hrs offered / attended at start of order
  CASE
    WHEN total_hrs_offered_start BETWEEN 1
    AND 15
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_1_15_start,
  CASE
    WHEN total_hrs_offered_start BETWEEN 16
    AND 24
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_16_24_start,
  CASE
    WHEN total_hrs_offered_start >= 25
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_25_start,
  CASE
    WHEN total_hrs_attended_start BETWEEN 1
    AND 15
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_1_15_start,
  CASE
    WHEN total_hrs_attended_start BETWEEN 16
    AND 24
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_16_24_start,
  CASE
    WHEN total_hrs_attended_start >= 25
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_25_start,
  -- Hrs offered / attended at end of order
  CASE
    WHEN total_hrs_offered_end BETWEEN 1
    AND 15
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_1_15_end,
  CASE
    WHEN total_hrs_offered_end BETWEEN 16
    AND 24
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_16_24_end,
  CASE
    WHEN total_hrs_offered_end >= 25
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_25_end,
  CASE
    WHEN total_hrs_attended_end BETWEEN 1
    AND 15
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_1_15_end,
  CASE
    WHEN total_hrs_attended_end BETWEEN 16
    AND 24
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_16_24_end,
  CASE
    WHEN total_hrs_attended_end >= 25
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_25_end
FROM
  kpi2_pd
  INNER JOIN true_suitability ON kpi2_pd.ypid = true_suitability.ypid
  AND kpi2_pd.label_quarter = true_suitability.label_quarter
  INNER JOIN total_hours ON kpi2_pd.ypid = total_hours.ypid
  AND kpi2_pd.label_quarter = total_hours.label_quarter;	

/* RQEV2-m8B2fMC9R7 */
-- DROP MATERIALIZED VIEW IF EXISTS yjb_kpi_case_level.kpi2_ete_summary_v8 cascade;
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_summary_v8 distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
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
        ) AS total_ypid_ycc,
        COUNT(
            DISTINCT CASE
                WHEN yjb_kpi_case_level.f_isSchoolAgeStart(
                    disposal_type_fixed,
                    outcome_date,
                    intervention_start_date,
                    ypid_dob
                ) = TRUE THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_school_age_start,
        COUNT(
            DISTINCT CASE
                WHEN yjb_kpi_case_level.f_isSchoolAgeEnd(intervention_end_date, ypid_dob) = TRUE THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_school_age_end,
        COUNT(
            DISTINCT CASE
                WHEN yjb_kpi_case_level.f_isSchoolAgeStart(
                    disposal_type_fixed,
                    outcome_date,
                    intervention_start_date,
                    ypid_dob
                ) = FALSE THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_above_school_age_start,
        COUNT(
            DISTINCT CASE
                WHEN yjb_kpi_case_level.f_isSchoolAgeEnd(intervention_end_date, ypid_dob) = FALSE THEN ypid
                ELSE NULL
            END
        ) AS total_ypid_above_school_age_end
    FROM
        "yjb_returns"."yjb_kpi_case_level"."person_details_v8"
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
        --overall measures
        COUNT(DISTINCT kpi2_suitable_end) AS kpi2_suitable_end,
        COUNT(DISTINCT kpi2_unsuitable_end) AS kpi2_unsuitable_end,
        COUNT(DISTINCT kpi2_suitable_start) AS kpi2_suitable_start,
        COUNT(DISTINCT kpi2_unsuitable_start) AS kpi2_unsuitable_start,
        --suitability by age categories at start and end of order
        COUNT(DISTINCT kpi2_suitable_school_age_start) AS kpi2_suitable_school_age_start,
        COUNT(DISTINCT kpi2_unsuitable_school_age_start) AS kpi2_unsuitable_school_age_start,
        COUNT(DISTINCT kpi2_suitable_school_age_end) AS kpi2_suitable_school_age_end,
        COUNT(DISTINCT kpi2_unsuitable_school_age_end) AS kpi2_unsuitable_school_age_end,
        COUNT(DISTINCT kpi2_suitable_above_school_age_start) AS kpi2_suitable_above_school_age_start,
        COUNT(DISTINCT kpi2_unsuitable_above_school_age_start) AS kpi2_unsuitable_above_school_age_start,
        COUNT(DISTINCT kpi2_suitable_above_school_age_end) AS kpi2_suitable_above_school_age_end,
        COUNT(DISTINCT kpi2_unsuitable_above_school_age_end) AS kpi2_unsuitable_above_school_age_end,
        --suitability start/end by type of order
        COUNT(DISTINCT kpi2_suitable_oocd_end) AS kpi2_suitable_oocd_end,
        COUNT(DISTINCT kpi2_suitable_ro_end) AS kpi2_suitable_ro_end,
        COUNT(DISTINCT kpi2_suitable_yc_end) AS kpi2_suitable_yc_end,
        COUNT(DISTINCT kpi2_suitable_ycc_end) AS kpi2_suitable_ycc_end,
        COUNT(DISTINCT kpi2_suitable_cust_end) AS kpi2_suitable_cust_end,
        COUNT(DISTINCT kpi2_suitable_yro_end) AS kpi2_suitable_yro_end,
        COUNT(DISTINCT kpi2_unsuitable_oocd_end) AS kpi2_unsuitable_oocd_end,
        COUNT(DISTINCT kpi2_unsuitable_ro_end) AS kpi2_unsuitable_ro_end,
        COUNT(DISTINCT kpi2_unsuitable_yc_end) AS kpi2_unsuitable_yc_end,
        COUNT(DISTINCT kpi2_unsuitable_ycc_end) AS kpi2_unsuitable_ycc_end,
        COUNT(DISTINCT kpi2_unsuitable_cust_end) AS kpi2_unsuitable_cust_end,
        COUNT(DISTINCT kpi2_unsuitable_yro_end) AS kpi2_unsuitable_yro_end,
        COUNT(DISTINCT kpi2_suitable_oocd_start) AS kpi2_suitable_oocd_start,
        COUNT(DISTINCT kpi2_suitable_ro_start) AS kpi2_suitable_ro_start,
        COUNT(DISTINCT kpi2_suitable_yc_start) AS kpi2_suitable_yc_start,
        COUNT(DISTINCT kpi2_suitable_ycc_start) AS kpi2_suitable_ycc_start,
        COUNT(DISTINCT kpi2_suitable_cust_start) AS kpi2_suitable_cust_start,
        COUNT(DISTINCT kpi2_suitable_yro_start) AS kpi2_suitable_yro_start,
        COUNT(DISTINCT kpi2_unsuitable_oocd_start) AS kpi2_unsuitable_oocd_start,
        COUNT(DISTINCT kpi2_unsuitable_ro_start) AS kpi2_unsuitable_ro_start,
        COUNT(DISTINCT kpi2_unsuitable_yc_start) AS kpi2_unsuitable_yc_start,
        COUNT(DISTINCT kpi2_unsuitable_ycc_start) AS kpi2_unsuitable_ycc_start,
        COUNT(DISTINCT kpi2_unsuitable_cust_start) AS kpi2_unsuitable_cust_start,
        COUNT(DISTINCT kpi2_unsuitable_yro_start) AS kpi2_unsuitable_yro_start,
        -- ETE provision type start/end
        COUNT(DISTINCT kpi2_no_ete_start) AS kpi2_no_ete_start,
        COUNT(DISTINCT kpi2_no_ete_end) AS kpi2_no_ete_end,
        COUNT(DISTINCT kpi2_provision_school_start) AS kpi2_provision_school_start,
        COUNT(DISTINCT kpi2_provision_school_end) AS kpi2_provision_school_end,
        COUNT(
            DISTINCT kpi2_provision_electively_home_educated_start
        ) AS kpi2_provision_electively_home_educated_start,
        COUNT(
            DISTINCT kpi2_provision_electively_home_educated_end
        ) AS kpi2_provision_electively_home_educated_end,
        COUNT(
            DISTINCT kpi2_provision_pupil_referral_unit_start
        ) AS kpi2_provision_pupil_referral_unit_start,
        COUNT(DISTINCT kpi2_provision_pupil_referral_unit_end) AS kpi2_provision_pupil_referral_unit_end,
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
        COUNT(DISTINCT kpi2_provision_employment_start) AS kpi2_provision_employment_start,
        COUNT(DISTINCT kpi2_provision_employment_end) AS kpi2_provision_employment_end,
        COUNT(DISTINCT kpi2_provision_self_employment_start) AS kpi2_provision_self_employment_start,
        COUNT(DISTINCT kpi2_provision_self_employment_end) AS kpi2_provision_self_employment_end,
        COUNT(DISTINCT kpi2_provision_voluntary_work_start) AS kpi2_provision_voluntary_work_start,
        COUNT(DISTINCT kpi2_provision_voluntary_work_end) AS kpi2_provision_voluntary_work_end,
        COUNT(DISTINCT kpi2_provision_university_start) AS kpi2_provision_university_start,
        COUNT(DISTINCT kpi2_provision_university_end) AS kpi2_provision_university_end,
        --offered part-time vs full-time start and end of order
        COUNT(DISTINCT kpi2_offered_part_time_start) AS kpi2_offered_part_time_start,
        COUNT(DISTINCT kpi2_offered_full_time_start) AS kpi2_offered_full_time_start,
        COUNT(DISTINCT kpi2_offered_part_time_end) AS kpi2_offered_part_time_end,
        COUNT(DISTINCT kpi2_offered_full_time_end) AS kpi2_offered_full_time_end,
        --hrs offered versus attended start/end of order
        COUNT(DISTINCT kpi2_hrs_offered_1_15_start) AS kpi2_hrs_offered_1_15_start,
        COUNT(DISTINCT kpi2_hrs_offered_16_24_start) AS kpi2_hrs_offered_16_24_start,
        COUNT(DISTINCT kpi2_hrs_offered_25_start) AS kpi2_hrs_offered_25_start,
        COUNT(DISTINCT kpi2_hrs_attended_1_15_start) AS kpi2_hrs_attended_1_15_start,
        COUNT(DISTINCT kpi2_hrs_attended_16_24_start) AS kpi2_hrs_attended_16_24_start,
        COUNT(DISTINCT kpi2_hrs_attended_25_start) AS kpi2_hrs_attended_25_start,
        COUNT(DISTINCT kpi2_hrs_offered_1_15_end) AS kpi2_hrs_offered_1_15_end,
        COUNT(DISTINCT kpi2_hrs_offered_16_24_end) AS kpi2_hrs_offered_16_24_end,
        COUNT(DISTINCT kpi2_hrs_offered_25_end) AS kpi2_hrs_offered_25_end,
        COUNT(DISTINCT kpi2_hrs_attended_1_15_end) AS kpi2_hrs_attended_1_15_end,
        COUNT(DISTINCT kpi2_hrs_attended_16_24_end) AS kpi2_hrs_attended_16_24_end,
        COUNT(DISTINCT kpi2_hrs_attended_25_end) AS kpi2_hrs_attended_25_end
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi2_ete_case_level_v8"
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
    'KPI 2' AS kpi_number,
    --total children with order ending (headline denominator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid
        ELSE summary_person.total_ypid
    END AS kpi2_total_ypid,
    --total children in each type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_oocd
        ELSE summary_person.total_ypid_oocd
    END AS kpi2_total_ypid_oocd,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yc
        ELSE summary_person.total_ypid_yc
    END AS kpi2_total_ypid_yc_with_yjs,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ycc
        ELSE summary_person.total_ypid_ycc
    END AS kpi2_total_ypid_ycc,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_ro
        ELSE summary_person.total_ypid_ro
    END AS kpi2_total_ypid_ro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_yro
        ELSE summary_person.total_ypid_yro
    END AS kpi2_total_ypid_yro,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.total_ypid_cust
        ELSE summary_person.total_ypid_cust
    END AS kpi2_total_ypid_cust,
    --total children by age category start and end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_total_school_age_start
        ELSE summary_person.total_ypid_school_age_start
    END AS kpi2_total_ypid_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_total_above_school_age_start
        ELSE summary_person.total_ypid_above_school_age_start
    END AS kpi2_total_ypid_above_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_total_school_age_end
        ELSE summary_person.total_ypid_school_age_end
    END AS kpi2_total_ypid_school_age_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_total_above_school_age_end
        ELSE summary_person.total_ypid_above_school_age_end
    END AS kpi2_total_ypid_above_school_age_end,
    -- overall measures
    -- total suitable end (also headline numerator)
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_end
        ELSE summary_cl.kpi2_suitable_end
    END AS kpi2_total_suitable_end,
    --unsuitable end
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_end
        ELSE summary_cl.kpi2_unsuitable_end
    END AS kpi2_total_unsuitable_end,
    --suitable start
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_start
        ELSE summary_cl.kpi2_suitable_start
    END AS kpi2_total_suitable_start,
    --unsuitable start
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_start
        ELSE summary_cl.kpi2_unsuitable_start
    END AS kpi2_total_unsuitable_start,
    --suitable change start to end
    --unsuitable change start to end
    kpi2_total_suitable_end-kpi2_total_suitable_start AS kpi2_suitable_change,
    kpi2_total_unsuitable_end-kpi2_total_unsuitable_start AS kpi2_unsuitable_change,
    --total in suitable ETE at school age start and end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_school_age_start
        ELSE summary_cl.kpi2_suitable_school_age_start
    END AS kpi2_suitable_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_school_age_end
        ELSE summary_cl.kpi2_suitable_school_age_end
    END AS kpi2_suitable_school_age_end,
    --total in suitable ETE above school age start and end of order 
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_above_school_age_start
        ELSE summary_cl.kpi2_suitable_above_school_age_start
    END AS kpi2_suitable_above_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_above_school_age_end
        ELSE summary_cl.kpi2_suitable_above_school_age_end
    END AS kpi2_suitable_above_school_age_end,
    --total in unsuitable ETE at school age start and end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_school_age_start
        ELSE summary_cl.kpi2_unsuitable_school_age_start
    END AS kpi2_unsuitable_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_school_age_end
        ELSE summary_cl.kpi2_unsuitable_school_age_end
    END AS kpi2_unsuitable_school_age_end,
    --total in unsuitable ETE above school age start and end of order 
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_above_school_age_start
        ELSE summary_cl.kpi2_unsuitable_above_school_age_start
    END AS kpi2_unsuitable_above_school_age_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_above_school_age_end
        ELSE summary_cl.kpi2_unsuitable_above_school_age_end
    END AS kpi2_unsuitable_above_school_age_end,
    --suitable start by type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_oocd_start
        ELSE summary_cl.kpi2_suitable_oocd_start
    END AS kpi2_suitable_oocd_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yc_start
        ELSE summary_cl.kpi2_suitable_yc_start
    END AS kpi2_suitable_yc_with_yjs_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ycc_start
        ELSE summary_cl.kpi2_suitable_ycc_start
    END AS kpi2_suitable_ycc_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ro_start
        ELSE summary_cl.kpi2_suitable_ro_start
    END AS kpi2_suitable_ro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yro_start
        ELSE summary_cl.kpi2_suitable_yro_start
    END AS kpi2_suitable_yro_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_cust_start
        ELSE summary_cl.kpi2_suitable_cust_start
    END AS kpi2_suitable_cust_start,
    --unsuitable start by type of order
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_oocd_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_oocd_start
        ELSE summary_cl.kpi2_unsuitable_oocd_start
    END AS kpi2_unsuitable_oocd_start,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_yc_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yc_start
        ELSE summary_cl.kpi2_unsuitable_yc_start
    END AS kpi2_unsuitable_yc_with_yjs_start,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_ycc_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ycc_start
        ELSE summary_cl.kpi2_unsuitable_ycc_start
    END AS kpi2_unsuitable_ycc_start,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_ro_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ro_start
        ELSE summary_cl.kpi2_unsuitable_ro_start
    END AS kpi2_unsuitable_ro_start,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_yro_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yro_start
        ELSE summary_cl.kpi2_unsuitable_yro_start
    END AS kpi2_unsuitable_yro_start,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_cust_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_cust_start
        ELSE summary_cl.kpi2_unsuitable_cust_start
    END AS kpi2_unsuitable_cust_start,
    -- suitable end by type of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_oocd_end
        ELSE summary_cl.kpi2_suitable_oocd_end
    END AS kpi2_suitable_oocd_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yc_end
        ELSE summary_cl.kpi2_suitable_yc_end
    END AS kpi2_suitable_yc_with_yjs_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ycc_end
        ELSE summary_cl.kpi2_suitable_ycc_end
    END AS kpi2_suitable_ycc_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_ro_end
        ELSE summary_cl.kpi2_suitable_ro_end
    END AS kpi2_suitable_ro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_yro_end
        ELSE summary_cl.kpi2_suitable_yro_end
    END AS kpi2_suitable_yro_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_suitable_cust_end
        ELSE summary_cl.kpi2_suitable_cust_end
    END AS kpi2_suitable_cust_end,
    -- unsuitable end by type of order
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_oocd_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_oocd_end
        ELSE summary_cl.kpi2_unsuitable_oocd_end
    END AS kpi2_unsuitable_oocd_end,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_yc_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yc_end
        ELSE summary_cl.kpi2_unsuitable_yc_end
    END AS kpi2_unsuitable_yc_with_yjs_end,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_ycc_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ycc_end
        ELSE summary_cl.kpi2_unsuitable_ycc_end
    END AS kpi2_unsuitable_ycc_end,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_ro_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_ro_end
        ELSE summary_cl.kpi2_unsuitable_ro_end
    END AS kpi2_unsuitable_ro_end,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_yro_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_yro_end
        ELSE summary_cl.kpi2_unsuitable_yro_end
    END AS kpi2_unsuitable_yro_end,
    CASE
        WHEN source_data_flag = 'Data from template'
        AND summary_t.kpi2_unsuitable_cust_end < 0 THEN NULL
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_unsuitable_cust_end
        ELSE summary_cl.kpi2_unsuitable_cust_end
    END AS kpi2_unsuitable_cust_end,
    --total not in ETE start/end
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_no_ete_start
        ELSE summary_cl.kpi2_no_ete_start
    END AS kpi2_no_ete_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_no_ete_end
        ELSE summary_cl.kpi2_no_ete_end
    END AS kpi2_no_ete_end,
    -- offered part-time and full-time start and end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_offered_part_time_start
        ELSE summary_cl.kpi2_offered_part_time_start
    END AS kpi2_offered_part_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_offered_full_time_start
        ELSE summary_cl.kpi2_offered_full_time_start
    END AS kpi2_offered_full_time_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_offered_part_time_end
        ELSE summary_cl.kpi2_offered_part_time_end
    END AS kpi2_offered_part_time_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_offered_full_time_end
        ELSE summary_cl.kpi2_offered_full_time_end
    END AS kpi2_offered_full_time_end,
    --ETE provision type start/end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_start
        ELSE summary_cl.kpi2_provision_school_start
    END AS kpi2_provision_school_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_school_end
        ELSE summary_cl.kpi2_provision_school_end
    END AS kpi2_provision_school_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_electively_home_educated_start
        ELSE summary_cl.kpi2_provision_electively_home_educated_start
    END AS kpi2_provision_electively_home_educated_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_electively_home_educated_end
        ELSE summary_cl.kpi2_provision_electively_home_educated_end
    END AS kpi2_provision_electively_home_educated_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_pupil_referral_unit_start
        ELSE summary_cl.kpi2_provision_pupil_referral_unit_start
    END AS kpi2_provision_pupil_referral_unit_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_pupil_referral_unit_end
        ELSE summary_cl.kpi2_provision_pupil_referral_unit_end
    END AS kpi2_provision_pupil_referral_unit_end,
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
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_employment_start
        ELSE summary_cl.kpi2_provision_employment_start
    END AS kpi2_provision_employment_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_provision_employment_end
        ELSE summary_cl.kpi2_provision_employment_end
    END AS kpi2_provision_employment_end,
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
    --ETE hrs offered start and end of order
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_1_15_start
        ELSE summary_cl.kpi2_hrs_offered_1_15_start
    END AS kpi2_hrs_offered_1_15_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_16_24_start
        ELSE summary_cl.kpi2_hrs_offered_16_24_start
    END AS kpi2_hrs_offered_16_24_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_25_start
        ELSE summary_cl.kpi2_hrs_offered_25_start
    END AS kpi2_hrs_offered_25_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_1_15_end
        ELSE summary_cl.kpi2_hrs_offered_1_15_end
    END AS kpi2_hrs_offered_1_15_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_16_24_end
        ELSE summary_cl.kpi2_hrs_offered_16_24_end
    END AS kpi2_hrs_offered_16_24_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_offered_25_end
        ELSE summary_cl.kpi2_hrs_offered_25_end
    END AS kpi2_hrs_offered_25_end,
    --ETE hrs attended start and end of order 
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_1_15_start
        ELSE summary_cl.kpi2_hrs_attended_1_15_start
    END AS kpi2_hrs_attended_1_15_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_16_24_start
        ELSE summary_cl.kpi2_hrs_attended_16_24_start
    END AS kpi2_hrs_attended_16_24_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_25_start
        ELSE summary_cl.kpi2_hrs_attended_25_start
    END AS kpi2_hrs_attended_25_start,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_1_15_end
        ELSE summary_cl.kpi2_hrs_attended_1_15_end
    END AS kpi2_hrs_attended_1_15_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_16_24_end
        ELSE summary_cl.kpi2_hrs_attended_16_24_end
    END AS kpi2_hrs_attended_16_24_end,
    CASE
        WHEN source_data_flag = 'Data from template' THEN summary_t.kpi2_hrs_attended_25_end
        ELSE summary_cl.kpi2_hrs_attended_25_end
    END AS kpi2_hrs_attended_25_end
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi2_ete_template_v8 AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
/* RQEV2-02GgZ2FwXd */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_case_level_v8 distkey (kpi3_source_document_id) sortkey (kpi3_source_document_id) AS WITH kpi3 AS (
    --extract kpi3 entities not in JSON arrays
    SELECT
        dc.source_document_id as kpi3_source_document_id,
        dc.document_item."kpi3IdentifiedSENDALN" :: text as kpi3_identified_sendaln,
        dc.document_item."kpi3SENDFormalPlan" :: text as kpi3_send_formal_plan,
        dc.document_item."kpi3SENDStartDate" :: date as kpi3_send_start_date,
        dc.document_item."kpi3SENDEndDate" :: date as kpi3_send_end_date
    FROM
        stg.yp_doc_item dc
    WHERE
        document_item_type = 'sendaln'
        AND kpi3_identified_sendaln IS NOT NULL
)
SELECT
    DISTINCT kpi3.*,
    person_details.*,
    --headline measure: identified SEND/ALN and a formal plan in place
    CASE
        WHEN kpi3.kpi3_send_formal_plan = 'YES'
        AND kpi3.kpi3_identified_sendaln = 'YES' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_plan,
    --Sub-measure: identified SEND/ALN and in suitable/unsuitable ETE at any point during they order
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND kpi2.kpi2_suitable_end = kpi2.ypid THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_suitable_ete,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND kpi2.kpi2_unsuitable_end = kpi2.ypid THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_unsuitable_ete,
    /* Sub-measure: identified SEND/ALN broken down by demographic characteristics */
    --identified SEND/ALN by ethnicity group
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'White' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_white,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Mixed' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_mixed_ethnic,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Black or Black British' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_black,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Other Ethnic Group' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_other_ethnic,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Asian or Asian British' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_asian,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Information not obtainable' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_unknown_ethnic,
    --identified SEND/ALN by age group
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.age_on_intervention_start BETWEEN 10
        AND 14 THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_10_14,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.age_on_intervention_start BETWEEN 15
        AND 17 THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_15_17,
    -- identified SEND/ALN by gender
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Male' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_male,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Female' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_female,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Unknown gender' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_unknown_gender,
    /* Sub-measure: identified SEND/ALN by type of order */
    --out of court disposals (oocd)
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Non-substantive out of court disposals with YJS intervention' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_oocd,
    --youth cautions with YJS involvement (yc with yjs)
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Youth Cautions with YJS intervention' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_yc_with_yjs,
    --youth conditional cautions (ycc)
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Youth Conditional Cautions' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_ycc,
    --referral orders (ro)
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Referral Orders' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_ro,
    --youth rehabilitation orders (yro)
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Youth Rehabilitation Orders' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_yro,
    --custodial sentences (cust)    
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.type_of_order = 'Custodial sentences' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_cust
FROM
    kpi3
    INNER JOIN yjb_kpi_case_level.person_details_v8 AS person_details ON kpi3.kpi3_source_document_id = person_details.source_document_id
    LEFT JOIN yjb_kpi_case_level.kpi2_ete_case_level_v8 as kpi2 ON kpi3.kpi3_source_document_id = kpi2.kpi2_source_document_id
WHERE
    (
        kpi3.kpi3_send_end_date = '1900-01-01'
        OR kpi3.kpi3_send_end_date >= person_details.intervention_end_date
    )
    AND kpi3.kpi3_send_start_date <= person_details.intervention_end_date;	

    /* RQEV2-SrXQ6X4y33 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi2_ete_case_level distkey (kpi2_source_document_id) sortkey (kpi2_source_document_id) AS WITH kpi2 AS (
  SELECT
    dc.source_document_id as kpi2_source_document_id,
    dc.document_item."startDate" :: date as kpi2_start_date,
    dc.document_item."endDate" :: date as kpi2_end_date,
    dc.document_item."description" :: text as kpi2_description,
    dc.document_item."provisionType" :: text as kpi2_provision_type,
    dc.document_item."suitability" :: text as kpi2_suitability,
    dc.document_item."hoursOffered" :: text as kpi2_hours_offered,
    dc.document_item."hours" :: int as kpi2_hours_attended
  FROM
    stg.yp_doc_item dc
  WHERE
    document_item_type = 'ete_status'
    AND document_item."suitability" is not NULL
),
-- CTE combines kpi2 data from kpi2 CTE with person_detals table and adds markers for where ETE was at start or end of order
kpi2_pd AS (
  SELECT
    DISTINCT kpi2.*,
    person_details.*,
    -- marker stating whether ETE existed at start or not
    yjb_kpi_case_level.f_isAtStart(
      kpi2.kpi2_start_date,
      person_details.legal_outcome_group_fixed,
      person_details.disposal_type_fixed,
      person_details.outcome_date,
      person_details.intervention_start_date
    ) AS ete_start,
    -- marker stating whether ETE existed at end or not
    yjb_kpi_case_level.f_isAtEnd(
      kpi2.kpi2_end_date,
      person_details.intervention_end_date
    ) AS ete_end
  FROM
    kpi2
    INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi2.kpi2_source_document_id = person_details.source_document_id
  WHERE
    -- Filter out ETEs unless they were present at order start, order end or both 
    kpi2.kpi2_start_date <= person_details.intervention_end_date
    AND (
      kpi2.kpi2_end_date = '1900-01-01'
      OR (
        person_details.type_of_order <> 'Custodial sentences'
        AND kpi2.kpi2_end_date >= person_details.intervention_start_date
      )
      OR (
        person_details.disposal_type_fixed = 'DTO_LICENCE'
        AND kpi2.kpi2_end_date >= DATEADD(d, -1, person_details.outcome_date)
      )
      OR (
        person_details.disposal_type_fixed <> 'DTO_LICENCE'
        AND person_details.type_of_order = 'Custodial sentences'
        AND kpi2.kpi2_end_date >= DATEADD(d, -1, person_details.intervention_start_date)
      )
    )
    AND (
      ete_start = TRUE
      OR ete_end = TRUE
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
          WHEN ete_start = TRUE
          AND kpi2_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
          ELSE 0
        END
      ) > 0 THEN FALSE
      ELSE TRUE
    END AS is_suitable_start,
    CASE
      WHEN SUM(
        CASE
          WHEN ete_end = TRUE
          AND kpi2_suitability IN ('UNSUITABLE', 'UNKNOWN') THEN 1
          ELSE 0
        END
      ) > 0 THEN FALSE
      ELSE TRUE
    END AS is_suitable_end
  FROM
    kpi2_pd
  GROUP BY
    ypid,
    label_quarter
)
SELECT
  kpi2_pd.*,
  --these ensure that where ETE did not exist at start or end that the input of the true suitability variable (is_suitable_...) is NULL - is 'true' otherwise
  CASE
    WHEN kpi2_pd.ete_start = FALSE THEN NULL
    ELSE true_suitability.is_suitable_start
  END AS is_suitable_start,
  CASE
    WHEN kpi2_pd.ete_end = FALSE THEN NULL
    ELSE true_suitability.is_suitable_end
  END AS is_suitable_end,
  -- headline numerator: in suitable at end 
  CASE
    WHEN is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_end,
  -- suitable start
  CASE
    WHEN is_suitable_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_start,
  -- unsuitable start and end
  CASE
    WHEN is_suitable_start = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_start,
  CASE
    WHEN is_suitable_end = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_end,
  --suitable by age end
  CASE
    WHEN is_suitable_end = TRUE
    AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_school_age,
  CASE
    WHEN is_suitable_end = TRUE
    AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_above_school_age,
  --in no ETE at all
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'NONE'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_no_ete,
  --total in ETE (regardless of suitability)
  CASE
    WHEN kpi2_pd.kpi2_provision_type != 'NONE'
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_total_ete,
  --suitable by type of order end
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_oocd,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ro,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yc_with_yjs,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_ycc,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_cust,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_suitable_yro,
  -- unsuitable by type of order end 
  CASE
    WHEN kpi2_pd.type_of_order = 'Non-substantive out of court disposals with YJS intervention'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_oocd,
  CASE
    WHEN kpi2_pd.type_of_order = 'Referral Orders'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ro,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Cautions with YJS intervention'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yc_with_yjs,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Conditional Cautions'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_ycc,
  CASE
    WHEN kpi2_pd.type_of_order = 'Custodial sentences'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_cust,
  CASE
    WHEN kpi2_pd.type_of_order = 'Youth Rehabilitation Orders'
    AND is_suitable_end = FALSE
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_unsuitable_yro,
  -- Provision Type
  -- School full time
  CASE
    WHEN (
      (kpi2_pd.kpi2_provision_type = 'SCHOOL_FULL_TIME')
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended >= 25
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended >= 16
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_full_time_start,
  CASE
    WHEN (
      (kpi2_pd.kpi2_provision_type = 'SCHOOL_FULL_TIME')
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended >= 25
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended >= 16
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_full_time_end,
  -- School part time
  CASE
    WHEN (
      (kpi2_pd.kpi2_provision_type = 'SCHOOL_PART_TIME')
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_part_time_start,
  CASE
    WHEN (
      (kpi2_pd.kpi2_provision_type = 'SCHOOL_PART_TIME')
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'MAINSTREAM_SCHOOL'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_school_part_time_end,
  -- Home educated
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ELECTIVELY_HOME_EDUCATED'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_electively_home_educated_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ELECTIVELY_HOME_EDUCATED'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_electively_home_educated_end,
  -- Provision other part time
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_OTHER_PART_TIME'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_other_part_time_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_OTHER_PART_TIME'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_other_part_time_end,
  -- Provision other full time
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_OTHER_FULL_TIME'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_other_full_time_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_OTHER_FULL_TIME'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_other_full_time_end,
  -- PRU part TIME
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_PRU_PART_TIME'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 0
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_pru_part_time_start,
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_PRU_PART_TIME'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_pru_part_time_end,
  -- PRU full time
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_PRU_FULL_TIME'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_pru_full_time_start,
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'ALTERNATIVE_PROVISION_PRU_FULL_TIME'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'PUPIL_REFERRAL_UNIT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_pru_full_time_end,
  -- College
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'COLLEGE'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_college_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'COLLEGE'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_college_end,
  -- Alternative Provision
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION',
      'ALTERNATIVE_PROVISION_ABOVE_SCHOOL_AGE'
    )
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type IN (
      'ALTERNATIVE_PROVISION',
      'ALTERNATIVE_PROVISION_ABOVE_SCHOOL_AGE'
    )
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_alternative_provision_end,
  -- Education reengagement programme
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'EDUCATION_RE_ENGAGEMENT_PROGRAMME'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_education_re_engagement_programme_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'EDUCATION_RE_ENGAGEMENT_PROGRAMME'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_education_re_engagement_programme_end,
  -- Traineeship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINEESHIP'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_traineeship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINEESHIP'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_traineeship_end,
  -- Apprenticeship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINING_COURSE_APPRENTICESHIP'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_apprenticeship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'TRAINING_COURSE_APPRENTICESHIP'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_apprenticeship_end,
  -- Internship
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SUPPORTED_INTERNSHIP'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_support_internship_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SUPPORTED_INTERNSHIP'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_support_internship_end,
  -- Mentoring
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'MENTORING_CIRCLE'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_mentoring_circle_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'MENTORING_CIRCLE'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_mentoring_circle_end,
  -- Full-time employment
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'FULL_TIME_EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended >= 25
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended >= 16
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_full_time_employment_start,
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'FULL_TIME_EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended >= 25
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended >= 16
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = FALSE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_full_time_employment_end,
  -- Part time employment
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'PART_TIME_EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
    )
    AND kpi2_pd.ete_start = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_part_time_employment_start,
  CASE
    WHEN (
      (
        kpi2_pd.kpi2_provision_type = 'PART_TIME_EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended > 0
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 24
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
      OR (
        kpi2_pd.kpi2_provision_type = 'EMPLOYMENT'
        AND kpi2_pd.kpi2_hours_attended BETWEEN 1
        AND 15
        AND yjb_kpi_case_level.f_isSchoolAge(kpi2_pd.intervention_end_date, kpi2_pd.ypid_dob) = TRUE
      )
    )
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_part_time_employment_end,
  -- Self employment
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SELF_EMPLOYMENT'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_self_employment_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'SELF_EMPLOYMENT'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_self_employment_end,
  -- Voluntary work
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'VOLUNTARY_WORK'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_voluntary_work_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'VOLUNTARY_WORK'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_voluntary_work_end,
  -- University
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'UNIVERSITY'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_university_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'UNIVERSITY'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_university_end,
  -- Other
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'OTHER'
    AND kpi2_pd.ete_start = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_other_start,
  CASE
    WHEN kpi2_pd.kpi2_provision_type = 'OTHER'
    AND kpi2_pd.ete_end = TRUE
    AND kpi2_pd.kpi2_hours_attended > 0 THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_provision_other_end,
  -- Hours/offered summary
  CASE
    WHEN kpi2_pd.kpi2_hours_offered BETWEEN 1
    AND 15
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_1_15,
  CASE
    WHEN kpi2_pd.kpi2_hours_offered BETWEEN 16
    AND 24
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_16_24,
  CASE
    WHEN kpi2_pd.kpi2_hours_offered >= 25
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_offered_25,
  CASE
    WHEN kpi2_pd.kpi2_hours_attended BETWEEN 1
    AND 15
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_1_15,
  CASE
    WHEN kpi2_pd.kpi2_hours_attended BETWEEN 16
    AND 24
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_16_24,
  CASE
    WHEN kpi2_pd.kpi2_hours_attended >= 25
    AND kpi2_pd.ete_end = TRUE THEN kpi2_pd.ypid
    ELSE NULL
  END AS kpi2_hrs_attended_25
FROM
  kpi2_pd
  INNER JOIN true_suitability ON kpi2_pd.ypid = true_suitability.ypid
  AND kpi2_pd.label_quarter = true_suitability.label_quarter;	

    /* RQEV2-RkoxlI5jzj */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_case_level distkey (kpi3_source_document_id) sortkey (kpi3_source_document_id) AS WITH kpi3 AS (
    --extract kpi3 entities not in JSON arrays
    SELECT
        dc.source_document_id as kpi3_source_document_id,
        dc.document_item."kpi3IdentifiedSENDALN" :: text as kpi3_identified_sendaln,
        dc.document_item."kpi3SENDFormalPlan" :: text as kpi3_send_formal_plan,
        dc.document_item."kpi3SENDStartDate" :: date as kpi3_send_start_date,
        dc.document_item."kpi3SENDEndDate" :: date as kpi3_send_end_date
    FROM
        stg.yp_doc_item dc
    WHERE
        document_item_type = 'sendaln'
        AND kpi3_identified_sendaln IS NOT NULL
)
SELECT
    DISTINCT kpi3.*,
    person_details.*,
    --identified SEND/ALN and a formal plan in place
    CASE
        WHEN kpi3.kpi3_send_formal_plan = 'YES'
        AND kpi3.kpi3_identified_sendaln = 'YES' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_plan,
    --identified SEND/ALN and in suitable ETE by the end of the order
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND kpi2.kpi2_suitable_end = kpi2.ypid THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_suitable_ete,
    --identified SEND/ALN by ethnicity group
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'White' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_white,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Mixed' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_mixed_ethnic,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Black or Black British' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_black,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Other Ethnic Group' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_other_ethnic,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Asian or Asian British' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_asian,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.ethnicity_group = 'Information not obtainable' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_unknown_ethnic,
    --identified SEND/ALN by age group
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.age_on_intervention_start BETWEEN 10
        AND 14 THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_10_14,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.age_on_intervention_start BETWEEN 15
        AND 17 THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_15_17,
    -- identified SEND/ALN by gender
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Male' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_male,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Female' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_female,
    CASE
        WHEN kpi3.kpi3_identified_sendaln = 'YES'
        AND person_details.gender_name = 'Unknown gender' THEN person_details.ypid
        ELSE NULL
    END AS kpi3_sendaln_unknown_gender
FROM
    kpi3
    INNER JOIN yjb_kpi_case_level.person_details AS person_details ON kpi3.kpi3_source_document_id = person_details.source_document_id
    LEFT JOIN yjb_kpi_case_level.kpi2_ete_case_level as kpi2 ON kpi3.kpi3_source_document_id = kpi2.kpi2_source_document_id
WHERE
    (
        kpi3.kpi3_send_end_date = '1900-01-01'
        OR kpi3.kpi3_send_end_date >= person_details.intervention_end_date
    )
    AND kpi3.kpi3_send_start_date <= person_details.intervention_end_date;

/* RQEV2-KGKL3nnHZR */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_template_v8 distkey (return_status_id) sortkey (return_status_id) AS WITH template AS (
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
    ) AS kpi3_sendaln_suitable_ete,
    -- submeasure: children with identified send/aln who are not in suitable ETE 
    -- no field for this in template so do total children with identified send/aln - those in suitable ETE
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN total_ypid
            WHEN description = 'Number of children with an identified SEND/ALN need in suitable ETE' THEN NVL(-1 * total_ypid, 0)
            ELSE NULL
        END
    ) AS kpi3_sendaln_unsuitable_ete,
    -- Sub-measure: Children with SEND/ALN broken down by type of order
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN out_court_no_yjs_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_oocd,
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN yc_with_yjs_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_yc_with_yjs,
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN ycc_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_ycc,
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN ro_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_ro,
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN yro_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_yro,
    SUM(
        CASE
            WHEN description = 'Number with an identified SEND/ALN' THEN cust_total
            ELSE NULL
        END
    ) AS kpi3_sendaln_cust,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN out_court_no_yjs_total
            ELSE NULL
        END
    ) AS total_ypid_oocd,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yc_with_yjs_total
            ELSE NULL
        END
    ) AS total_ypid_yc_with_yjs,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ycc_total
            ELSE NULL
        END
    ) AS total_ypid_ycc,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN ro_total
            ELSE NULL
        END
    ) AS total_ypid_ro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN yro_total
            ELSE NULL
        END
    ) AS total_ypid_yro,
    SUM(
        CASE
            WHEN description = 'Number of  children with an order ending in the period' THEN cust_total
            ELSE NULL
        END
    ) AS total_ypid_cust
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
	
/* RQEV2-yjWl3w29L9 */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_summary_long distkey (quarter_label_date) sortkey (quarter_label_date) AS 
/*CTE for values that appear in numerator and denominator*/
--required as when a column is pivoted usinng unpivot, the column name is not available in the unpivoted table so has to be pulled from here instead
WITH numerators_and_denominators AS (
    SELECT
        yjs_name,
        quarter_label,
        kpi3_identified_sendaln
    FROM
        yjb_kpi_case_level.kpi3_sendaln_summary_v8
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
    'SEND/ALN' AS kpi_name,
    'Children with Special Educational Needs and Disabilities or Additional Learning Needs' AS kpi_short_description,
   /*add metadata for every measure*/
    -- whether the measure is for start, end, before or during order - not relevant to all kpis
    CASE
        WHEN unpvt_table.measure_numerator LIKE '%start%' THEN 'Start'
        WHEN unpvt_table.measure_numerator LIKE 'end%' THEN 'End'
        WHEN unpvt_table.measure_numerator LIKE '%prior%' THEN 'Before'
        WHEN unpvt_table.measure_numerator LIKE '%during%' THEN 'During'
        ELSE NULL
    END AS time_point,
    -- whether the measure_numerator is calculating suitable or unsuitable (will not be relevant for some)
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
        WHEN unpvt_table.measure_numerator LIKE '%plan%' THEN 'Formal plan'
        WHEN unpvt_table.measure_numerator LIKE '%identified%' THEN 'Identified SEND/ALN'
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'Out of court disposals'
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
        WHEN unpvt_table.measure_numerator LIKE '%10_%' THEN '10-14 year olds'
        WHEN unpvt_table.measure_numerator LIKE '%15_%' THEN '15-17 year olds'
        /*ethnicity*/
        WHEN unpvt_table.measure_numerator LIKE '%asian%' THEN 'Asian or Asian British'
        WHEN unpvt_table.measure_numerator LIKE '%black%' THEN 'Black or Black British'
        WHEN unpvt_table.measure_numerator LIKE '%white%' THEN 'White'
        WHEN unpvt_table.measure_numerator LIKE '%mixed%' THEN 'Mixed ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%other_e%' THEN 'Other Ethnicity'
        WHEN unpvt_table.measure_numerator LIKE '%unknown_e%' THEN 'Unknown Ethnicity'
        /*ETE */
        WHEN unpvt_table.measure_numerator LIKE '%unsuitable%' THEN 'Unsuitable ETE'
        WHEN unpvt_table.measure_numerator LIKE '%suitable%' THEN 'Suitable ETE'
    END AS measure_category,
    --short description of measure
    CASE
        WHEN measure_category = 'Formal plan' THEN 'Formal plan in place'
        WHEN measure_category IN (
            'Out of court disposals',
            'Youth cautions with YJS intervention',
            'Youth conditional cautions',
            'Referral orders',
            'Youth rehabilitation orders',
            'Custodial sentences'
        ) THEN 'Type of order'
        WHEN measure_category IN (
            'Asian or Asian British',
            'Black or Black British',
            'White',
            'Mixed ethnicity',
            'Other Ethnicity',
            'Unknown Ethnicity',
            '10-14 year olds',
            '15-17 year olds',
            'Female',
            'Male',
            'Unknown Gender'
        ) THEN 'Demographics'
        WHEN measure_category IN ('Unsuitable ETE', 'Suitable ETE') THEN 'ETE'
        ELSE 'Overall measure'
         
    END AS measure_short_description,
    -- full wording of the measure 
    CASE
        WHEN measure_short_description = 'Formal plan in place' THEN 'Proportion of children with identified SEND/ALN that have a formal plan in place'
        WHEN measure_short_description = 'ETE' THEN 'Children with an identified SEND/ALN that are in suitable and unsuitable ETE'
        WHEN measure_short_description = 'Demographics' THEN 'Children with an identified SEND/ALN broken down by demographic characteristics (case level only)'
        WHEN measure_short_description = 'Type of order' THEN 'Children with an identified SEND/ALN broken down by type of order'
        ELSE 'Children that have an identified SEND/ALN'
    END AS measure_long_description,
    --whether measure is the headline measure
    CASE
        WHEN measure_short_description = 'Formal plan in place' THEN TRUE
        ELSE FALSE
    END AS headline_measure,
    --numbering the submeasures
    CASE
        WHEN measure_short_description = 'Overall measure' THEN '3a'
        WHEN measure_short_description = 'ETE' THEN '3b'
        WHEN measure_short_description = 'Demographics' THEN '3c'
        WHEN measure_short_description = 'Type of order' THEN '3d'
        ELSE 'Headline'
    END AS submeasure_number,
    unpvt_table.measure_numerator,
    unpvt_table.numerator_value,
    -- What is in the denominator (name of it)
    CASE
        /*identified SEND/ALN*/
        WHEN unpvt_table.measure_numerator LIKE '%identified%' THEN 'kpi3_total_ypid'
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN 'kpi3_total_ypid_oocd'
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN 'kpi3_total_ypid_yc_with_yjs'
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN 'kpi3_total_ypid_ycc'
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN 'kpi3_total_ypid_ro'
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN 'kpi3_total_ypid_yro'
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN 'kpi3_total_ypid_cust'
        /*all other measures*/
        ELSE 'kpi3_identified_sendaln'
    END AS measure_denominator,
    -- the value in the denominator of each measure
    CASE
        /*identified SEND/ALN*/
        WHEN unpvt_table.measure_numerator LIKE '%identified%' THEN kpi3_total_ypid
        /*type of order*/
        WHEN unpvt_table.measure_numerator LIKE '%oocd%' THEN unpvt_table.kpi3_total_ypid_oocd
        WHEN unpvt_table.measure_numerator LIKE '%yc_with_yjs%' THEN unpvt_table.kpi3_total_ypid_yc_with_yjs
        WHEN unpvt_table.measure_numerator LIKE '%ycc%' THEN unpvt_table.kpi3_total_ypid_ycc
        WHEN unpvt_table.measure_numerator LIKE '%yro%' THEN unpvt_table.kpi3_total_ypid_ro
        WHEN unpvt_table.measure_numerator LIKE '%_ro%' THEN unpvt_table.kpi3_total_ypid_yro
        WHEN unpvt_table.measure_numerator LIKE '%cust%' THEN unpvt_table.kpi3_total_ypid_cust
        /*all other measures*/
        ELSE numerators_and_denominators.kpi3_identified_sendaln
    END AS denominator_value,
      -- New columns: numerator description and denominator description
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with identified SEND/ALN that have a SEND/ALN plan in place'
        ELSE NULL
    END AS headline_numerator_description,
    CASE
        WHEN submeasure_number = 'Headline' THEN 'Children with identified SEND/ALN'
        ELSE NULL
    END AS headline_denominator_description
FROM
    yjb_kpi_case_level.kpi3_sendaln_summary_v8 UNPIVOT (
        numerator_value FOR measure_numerator IN (
            kpi3_sendaln_15_17,
            kpi3_sendaln_10_14,
            kpi3_sendaln_unknown_gender,
            kpi3_sendaln_female,
            kpi3_sendaln_male,
            kpi3_sendaln_unknown_ethnic,
            kpi3_sendaln_asian,
            kpi3_sendaln_other_ethnic,
            kpi3_sendaln_black,
            kpi3_sendaln_mixed_ethnic,
            kpi3_sendaln_white,
            kpi3_sendaln_cust,
            kpi3_sendaln_yro,
            kpi3_sendaln_ro,
            kpi3_sendaln_ycc,
            kpi3_sendaln_yc_with_yjs,
            kpi3_sendaln_oocd,
            kpi3_sendaln_unsuitable_ete,
            kpi3_sendaln_suitable_ete,
            kpi3_sendaln_plan,
            kpi3_identified_sendaln
        )
    ) AS unpvt_table
    LEFT JOIN numerators_and_denominators ON unpvt_table.yjs_name = numerators_and_denominators.yjs_name
    AND unpvt_table.quarter_label = numerators_and_denominators.quarter_label
    LEFT JOIN yjb_ianda_team.yjs_mapping_reversed AS families ON families.yjs_name = unpvt_table.yjs_name;	

/* RQEV2-67NaocBD4q */
CREATE MATERIALIZED VIEW yjb_kpi_case_level.kpi3_sendaln_summary distkey (yot_code) sortkey (yot_code) AS WITH summary_person AS (
    SELECT
        yot_code,
        yjs_name,
        label_quarter,
        area_operations,
        yjb_country,
        -- total orders ending in the period 
        COUNT(DISTINCT ypid) as total_ypid,
        -- total children by demographics
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
        ) AS total_ypid_unknown_gender
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
        COUNT(DISTINCT kpi3_sendaln_plan) AS kpi3_sendaln_plan,
        COUNT(
            DISTINCT CASE
                WHEN kpi3_identified_sendaln = 'YES' THEN ypid
                ELSE NULL
            END
        ) AS kpi3_identified_sendaln,
        COUNT(DISTINCT kpi3_sendaln_suitable_ete) AS kpi3_sendaln_suitable_ete,
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
        COUNT(DISTINCT kpi3_sendaln_15_17) AS kpi3_sendaln_15_17
    FROM
        "yjb_returns"."yjb_kpi_case_level"."kpi3_sendaln_case_level"
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
            summary_t.kpi3_identified_sendaln > 0
            OR summary_t.kpi3_sendaln_plan > 0
            OR summary_t.total_ypid > 0
        ) THEN 'Data from template' -- yjs submitted by template (including where a yjs submitted template and case level (i.e. old 'data from both sources'))
        ELSE 'Data from case level' -- includes any YJS that only submitted by case level
    END AS source_data_flag,
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
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_plan
            ELSE summary_cl.kpi3_sendaln_plan
        END,
        0
    ) AS kpi3_sendaln_plan,
    --headline denominator
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_identified_sendaln
            ELSE summary_cl.kpi3_identified_sendaln
        END,
        0
    ) AS kpi3_identified_sendaln,
    -- identified send/aln in suitable ETE
    COALESCE(
        CASE
            WHEN source_data_flag = 'Data from template' THEN summary_t.kpi3_sendaln_suitable_ete
            ELSE summary_cl.kpi3_sendaln_suitable_ete
        END,
        0
    ) AS kpi3_sendaln_suitable_ete,
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
    END AS total_ypid_white,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_mixed_ethnic
        ELSE NULL
    END AS total_ypid_mixed_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_black
        ELSE NULL
    END AS total_ypid_black,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_other_ethnic
        ELSE NULL
    END AS total_ypid_other_ethnic,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_asian
        ELSE NULL
    END AS total_ypid_asian,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_unknown_ethnic
        ELSE NULL
    END AS total_ypid_unknown_ethnic,
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
    END AS total_ypid_male,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_female
        ELSE NULL
    END AS total_ypid_female,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_unknown_gender
        ELSE NULL
    END AS total_ypid_unknown_gender,
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
    END AS total_ypid_10_14,
    CASE
        WHEN source_data_flag = 'Data from case level' THEN summary_person.total_ypid_15_17
        ELSE NULL
    END AS total_ypid_15_17
FROM
    summary_person
    LEFT JOIN summary_cl ON summary_cl.yot_code = summary_person.yot_code
    AND summary_cl.label_quarter = summary_person.label_quarter FULL
    JOIN yjb_kpi_case_level.kpi3_sendaln_template AS summary_t ON summary_t.yot_code = summary_person.yot_code
    AND summary_t.label_quarter = summary_person.label_quarter;	
