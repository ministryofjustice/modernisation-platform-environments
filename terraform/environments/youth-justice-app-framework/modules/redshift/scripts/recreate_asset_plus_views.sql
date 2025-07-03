SET enable_case_sensitive_identifier TO true;

/* RQEV2-yQdr7cYo56 */
--link the ap_asd view (which includes all time) to the sv view which is restricted 2020-2024
-- DROP MATERIALIZED VIEW IF EXISTS yjb_asset_plus.sv_cross_ap_using_date_only;
CREATE MATERIALIZED VIEW yjb_asset_plus.sv_cross_ap_using_date_only
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    DISTINCT sv.*,
    pd.date_of_birth,
    ap.assessment_id,
    ap."date" AS generic_ap_date,
    ABS(DATEDIFF(day, sv.outcome_date, ap."date")) AS days_from_outcome_to_assessment
FROM
    yjb_case_reporting.mvw_yp_person_details AS pd
    INNER JOIN yjb_case_reporting.mvw_yp_asset_plus AS ap ON pd.source_document_id = ap.source_document_id
    INNER JOIN yjb_ianda_team.sv_2020_2024 AS sv ON sv.ypid = pd.ypid
    AND sv.ypid_dob = pd.date_of_birth
WHERE
    generic_ap_date BETWEEN '2020-04-01'
    AND '2024-04-01'
    AND days_from_outcome_to_assessment <= 60;	
/* RQEV2-gS67XQCzoB */
CREATE MATERIALIZED VIEW yjb_asset_plus.ap_for_sv_cases_generic_date_field
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    DISTINCT sv.*,
    ap.assessment_id,
    ap.stage,
    ap."date" AS generic_ap_date,
    ap.concerns_accommodation,
    ap.concerns_care_history,
    ap.concerns_family_behaviour,
    ap.concerns_learning_and_ete,
    ap.concerns_lifestyle,
    ap.concerns_local_issues,
    ap.concerns_mental_health,
    ap.concerns_offence_justification,
    ap.concerns_offence_attitudes,
    ap.concerns_other_behaviour,
    ap.concerns_parenting,
    ap.concerns_physical_health,
    ap.concerns_relations_to_others,
    ap.concerns_risk_to_others,
    ap.concerns_safety_and_wellbeing,
    ap.concerns_significant_relationships,
    ap.concerns_speech_language_communication,
    ap.concerns_substance_misuse,
    ap.county_lines_activity,
    ap.referred_national_referral_mechanism_or_other,
    ap.at_risk_of_sexual_exploitation,
    ap.rosh_judgement,
    ap.safety_and_wellbeing_judgement,
    ap.vulnerable_to_criminal_exploration,
    af.assessed_as_risk_to_children,
    af.other_locally_defined_risk_associated_with_the_young_person,
    af.risk_of_self_harm,
    af.risk_of_suicide,
    ABS(DATEDIFF(day, sv.outcome_date, ap."date")) AS days_from_outcome_to_assessment
FROM
    yjb_case_reporting.mvw_yp_person_details AS pd
    INNER JOIN yjb_case_reporting.mvw_yp_asset_plus AS ap ON pd.source_document_id = ap.source_document_id
    INNER JOIN yjb_ianda_team.sv_2020_2024 AS sv ON sv.ypid = pd.ypid
    AND sv.ypid_dob = pd.date_of_birth
    LEFT JOIN yjb_case_reporting.mvw_yp_assessment_alerts_flags as af ON af.source_document_id = ap.source_document_id
WHERE
    generic_ap_date BETWEEN '2020-04-01'
    AND '2024-04-01'
    AND days_from_outcome_to_assessment <= 60;	
/* RQEV2-EQdBDAQB31 */
--234971 rows for 2419 children and 7078 offences
CREATE MATERIALIZED VIEW yjb_asset_plus.closest_ap_for_sv_cases_generic_date_field
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    main.*,
    rank.rank,
    ROW_NUMBER() OVER (
        PARTITION BY distinct_offence_id
        ORDER BY
            main.days_from_outcome_to_assessment,
            rank.stage DESC
    ) AS closest_asset_plus
FROM
    yjb_asset_plus.ap_for_sv_cases_generic_date_field AS main
    LEFT JOIN yjb_asset_plus.ap_stage_rank AS rank ON main.stage = rank.stage
QUALIFY closest_asset_plus = 1;	
/* RQEV2-LGJlUJ1LFb */
CREATE MATERIALIZED VIEW yjb_asset_plus.ap
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    DISTINCT ap.source_document_id,
    pd.ypid,
    pd.date_of_birth,
    ap.assessment_id,
    ap."date" AS generic_ap_date,
    ap.stage,
    asd.assessment_date,
    -- af.assessment_date as af_assesment_date,
    asd.assessment_stage,
    asd.assessment_status,
    asd.case_type,
    asd.stage_start_date,
    asd.stage_end_date,
    ap.concerns_accommodation,
    ap.concerns_care_history,
    ap.concerns_family_behaviour,
    ap.concerns_learning_and_ete,
    ap.concerns_lifestyle,
    ap.concerns_local_issues,
    ap.concerns_mental_health,
    ap.concerns_offence_justification,
    ap.concerns_offence_attitudes,
    ap.concerns_other_behaviour,
    ap.concerns_parenting,
    ap.concerns_physical_health,
    ap.concerns_relations_to_others,
    ap.concerns_risk_to_others,
    ap.concerns_safety_and_wellbeing,
    ap.concerns_significant_relationships,
    ap.concerns_speech_language_communication,
    ap.concerns_substance_misuse,
    ap.county_lines_activity,
    ap.referred_national_referral_mechanism_or_other,
    ap.at_risk_of_sexual_exploitation,
    ap.rosh_judgement,
    ap.safety_and_wellbeing_judgement,
    ap.vulnerable_to_criminal_exploration,
    af.assessed_as_risk_to_children,
    af.other_locally_defined_risk_associated_with_the_young_person,
    af.risk_of_self_harm,
    af.risk_of_suicide
FROM
    yjb_case_reporting.mvw_yp_person_details AS pd 
    -- linking on source document id only. Inner join to see how many assessments in mvw_yp_asset_plus has assessment_dates/assessment_stage_details
    INNER JOIN yjb_case_reporting.mvw_yp_asset_plus AS ap ON pd.source_document_id = ap.source_document_id
    INNER JOIN yjb_case_reporting.mvw_yp_assessment_stage_details AS asd ON ap.source_document_id = asd.source_document_id
        AND ap.date = asd.assessment_date
    LEFT JOIN yjb_case_reporting.mvw_yp_assessment_alerts_flags as af ON af.source_document_id = ap.source_document_id;	
/* RQEV2-wTt6Y0yEj9 */
--link the ap view to the sv view
CREATE MATERIALIZED VIEW yjb_asset_plus.ap_for_sv_cases
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    DISTINCT ap.*,
    sv.currentyotid,
    sv.oypid,
    sv.age_serious_violence,
    sv.ethnicity_group,
    sv.gender_name,
    sv.yjs_name,
    sv.area_operations,
    sv.yjb_country,
    sv.label_quarter,
    sv.offence_id,
    sv.distinct_offence_id,
    sv.yjb_offence_category,
    sv.yjb_seriousness_score,
    sv.outcome_date,
    sv.legal_outcome,
    sv.legal_outcome_group_fixed,
    sv.type_of_order,
    ABS(DATEDIFF(day, sv.outcome_date, ap.assessment_date)) AS days_from_outcome_to_assessment
FROM
    yjb_asset_plus.ap
    INNER JOIN yjb_ianda_team.sv_2020_2024 AS sv ON sv.ypid = ap.ypid -- higher match rate when matching on ypid and date of birth than source document id
    AND sv.ypid_dob = ap.date_of_birth
WHERE
    ap.assessment_date BETWEEN '2020-04-01'
    AND '2024-04-01'
    AND days_from_outcome_to_assessment <= 60;	
/* RQEV2-CyBRrX4YPp */
CREATE MATERIALIZED VIEW yjb_asset_plus.ap_care_status_23_24
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    DISTINCT ap.source_document_id,
    pd.ypid,
    pd.date_of_birth,
    ap.assessment_id,
    ap."date" AS generic_ap_date,
    ap.stage,
    -- ap.concerns_accommodation,
    -- ap.concerns_care_history,
    -- ap.concerns_family_behaviour,
    -- ap.concerns_learning_and_ete,
    -- ap.concerns_lifestyle,
    -- ap.concerns_local_issues,
    -- ap.concerns_mental_health,
    -- ap.concerns_offence_justification,
    -- ap.concerns_offence_attitudes,
    -- ap.concerns_other_behaviour,
    -- ap.concerns_parenting,
    -- ap.concerns_physical_health,
    -- ap.concerns_relations_to_others,
    -- ap.concerns_risk_to_others,
    -- ap.concerns_safety_and_wellbeing,
    -- ap.concerns_significant_relationships,
    -- ap.concerns_speech_language_communication,
    -- ap.concerns_substance_misuse,
    -- ap.county_lines_activity,
    -- ap.referred_national_referral_mechanism_or_other,
    -- ap.at_risk_of_sexual_exploitation,
    -- ap.rosh_judgement,
    -- ap.safety_and_wellbeing_judgement,
    -- ap.vulnerable_to_criminal_exploration,
    ap.care_child_in_need,
    ap.care_child_protection_plan,
    ap.care_eligible_child,
    ap.care_order,
    ap.care_relevant_child,
    ap.care_remand_to_laa,
    ap.care_remand_to_yda
FROM
    yjb_case_reporting.mvw_yp_person_details AS pd -- linking on source document id only. Inner join to see how many assessments in mvw_yp_asset_plus has assessment_dates/assessment_stage_details
    INNER JOIN yjb_case_reporting.mvw_yp_asset_plus AS ap ON pd.source_document_id = ap.source_document_id
WHERE ap."date" BETWEEN '2023-04-01' AND '2024-04-01';	
