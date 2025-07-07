
SET enable_case_sensitive_identifier TO true;

/* RQEV2-5vU9op63Ek */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_assessment_alerts_flags
distkey
(source_document_id)
sortkey
(source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."assessmentStageDetails"."assessmentDate":: date as assessment_date,
    document_item."alertsAndFlags"."assessedAsARiskToChildren":: text as assessed_as_risk_to_children,
    document_item."alertsAndFlags"."likelihoodOfReoffending":: text as likelihood_of_reoffending,
    document_item."alertsAndFlags"."otherLocallyDefinedRisksAssociatedWithTheYoungPerson":: text as other_locally_defined_risk_associated_with_the_young_person,
    document_item."alertsAndFlags"."riskOfSelfHarm":: text as risk_of_self_harm,
    document_item."alertsAndFlags"."riskOfSuicide":: text as risk_of_suicide,
    document_item."alertsAndFlags"."yogrs":: decimal(13, 10) as yogrs
from
    stg.yp_doc_item
where
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'assessment_stage';	
/* RQEV2-N0hdzJFORr */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_assessment_stage_details
distkey
(source_document_id)
sortkey
(source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."assessmentStageDetails"."assessmentDate":: date as assessment_date,
    document_item."assessmentStageDetails"."assessmentStage":: text as assessment_stage,
    document_item."assessmentStageDetails"."assessmentStatus":: text as assessment_status,
    document_item."assessmentStageDetails"."caseType":: text as case_type,
    document_item."assessmentStageDetails"."stageStartDate":: date as stage_start_date,
    document_item."assessmentStageDetails"."stageEndDate":: date as stage_end_date
from
    stg.yp_doc_item
where
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'assessment_stage';	
/* RQEV2-URhjRE428c */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus
distkey
(source_document_id)
sortkey
(source_document_id) as
SELECT
    source_document_id,
    document_item."accommodationAbsconding":: text as accommodation_absconding,
    document_item."accommodationInstability":: text as acommodation_instablity,
    document_item."accommodationOffendingInHome":: text as accommodationoffending_in_home,
    document_item."accommodationOther":: text as accommodation_other,
    document_item."accommodationOverCrowded":: text as accommodation_over_crowded,
    document_item."accommodationShortTermTemporary":: text as accommodation_short_term_temporary,
    document_item."accommodationType":: text as accommodation_type,
    document_item."accommodationUnhealthyUnsafe":: text as accommodation_unhelthy_unsafe,
    document_item."accommodationWithKnownOffenders":: text as accommodation_with_known_offenders,
    document_item."assessmentID":: text as assessment_id,
    document_item."atRiskOfSexualExplotation":: text as at_risk_of_sexual_exploitation,
    document_item."careChildInNeed":: text as care_child_in_need,
    document_item."careChildProtectionPlan":: text as care_child_protection_plan,
    document_item."careEligibleChild":: text as care_eligible_child,
    document_item."careOrder":: text as care_order,
    document_item."careRelevantChild":: text as care_relevant_child,
    document_item."careRemandToLAA":: text as care_remand_to_laa,
    document_item."careRemandToYDA":: text as care_remand_to_yda,
    document_item."careSiblings":: text as care_siblings,
    document_item."careVoluntary":: text as care_voluntary,
    document_item."concernsAccommodation":: text as concerns_accommodation,
    document_item."concernsCareHistory":: text as concerns_care_history,
    document_item."concernsFamilyBehaviour":: text as concerns_family_behaviour,
    --document_item."concernsFamilyBehaviourFurtherExploration"::text as concerns_family_behaviour_further_exploration,
    document_item."concernsLearningAndETE":: text as concerns_learning_and_ete,
    --document_item."concernsLearningAndETEFurtherExploration"::text as concerns_learning_and_ete_further_exploration,
    document_item."concernsLifestyle":: text as concerns_lifestyle,
    document_item."concernsLocalIssues":: text as concerns_local_issues,
    --document_item."concernsLocalIssuesFurtherExploration"::text as concerns_local_issues_further_exploration,
    document_item."concernsMentalHealth":: text as concerns_mental_health,
    document_item."concernsOffenceJustification":: text as concerns_offence_justification,
    document_item."concernsOffencesAttitudes":: text as concerns_offence_attitudes,
    document_item."concernsOtherBehaviour":: text as concerns_other_behaviour,
    document_item."concernsParenting":: text as concerns_parenting,
    --document_item."concernsParentingFurtherExploration"::text as concerns_parenting_further_exploration,
    document_item."concernsPhysicalHealth":: text as concerns_physical_health,
    document_item."concernsRelationsToOthers":: text as concerns_relations_to_others,
    --document_item."concernsRelationsToOthersFurtherExploration"::text as concerns_relations_to_other_further_exploration,
    document_item."concernsRiskToOthers":: text as concerns_risk_to_others,
    document_item."concernsSafetyWellbeing":: text as concerns_safety_and_wellbeing,
    document_item."concernsSignificantRelationships":: text as concerns_significant_relationships,
    --document_item."concernsSignificantRelationshipsFurtherExploration"::text as concerns_significant_relationships_further_exploration,
    document_item."concernsSpeechLanguageCommunication":: text as concerns_speech_language_communication,
    document_item."concernsSubstanceMisuse":: text as concerns_substance_misuse,
    document_item."concernsYPAsParent":: text as concerns_yp_as_parent,
    document_item."countyLinesActivity":: text as county_lines_activity,
    document_item."date":: date as date,
    document_item."gangAssociation":: text as gang_association,
    document_item."indicativeLikelihoodOfReoffending":: text as indicative_likelihood_of_reoffending,
    document_item."indicativeScaledApproachInterventionLevel":: text as indicative_scaled_approach_intervention_level,
    document_item."iomstatus":: text as iom_status,
    document_item."isFirstTimeIdentifiedCriminalExploitation":: text as is_first_time_identified_criminal_exploration,
    document_item."likelihoodOfReoffending":: text as likelihood_of_reoffending,
    document_item."mappacategory":: text as mappa_category,
    document_item."mappalevel":: text as mappa_level,
    document_item."referredNationalReferralMechanismOrOther":: text as referred_national_referral_mechanism_or_other,
    --document_item."resettlement"::text as resettlement,
    document_item."roshjudgement":: text as rosh_judgement,
    document_item."safetyWellbeingJudgement":: text as safety_and_wellbeing_judgement,
    document_item."scaledApproachInterventionLevel":: text as scaled_approach_intervention_level,
    document_item."stage":: text as stage,
    document_item."vulnerableToCriminalExploitation":: text as vulnerable_to_criminal_exploration,
    document_item."yogrs":: float as yogrs,
    document_item."ypcustodyReview":: text as yp_custody_review,
    document_item."ypparentalStatus":: text as yp_parental_status
FROM
    stg.yp_doc_item
WHERE
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	
/* RQEV2-K0YwJXjqRp */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_ete_details
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    d.document_item."ete"."etehours":: int as ete_hours,
    d.document_item."ete"."eteattendance":: text as ete_attendance,
    ete_details."etestatus":: text AS ete_status
FROM
    stg.yp_doc_item d,
    d.document_item."ete"."details" as ete_details
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-Uw2Zwl2puz */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_fad
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    fad."rating":: text,
    fad."category":: text
FROM
    stg.yp_doc_item d,
    d.document_item."factorsAgainstDesistance"."factor" fad
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-0gIcLOlOhb */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_ffd
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    ffd."rating":: text,
    ffd."category":: text
FROM
    stg.yp_doc_item d,
    d.document_item."factorsForDesistance"."factor" ffd
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-LslVGeZm52 */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_risk_of_harm
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    risk."likelihood":: text as likelihood,
    risk."impactOnOthers":: text as impact_on_others,
    risk."behaviourOffence":: text as behaviour_offence
FROM
    stg.yp_doc_item d,
    d.document_item."riskOfHarm"."risk" as risk
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-V9lxyLgCgq */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_saw
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    saw."likelihood":: text,
    saw."outcome":: text AS impact_on_others,
    saw."likelihood":: text as behaviour_offence
FROM
    stg.yp_doc_item d,
    d.document_item."safetyAndWellBeing"."adverseOutcome" saw
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-elqdoF9tkr */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_asset_plus_substance_misuse
distkey
    (source_document_id)
sortkey
    (source_document_id, assessment_id) AS
SELECT
    d.source_document_id,
    d.document_item."assessmentID":: text as assessment_id,
    substance."use":: text,
    substance."type":: text,
    substance."ageAtFirstUse":: int as age_at_first_use
FROM
    stg.yp_doc_item d,
    d.document_item."substanceMisuse"."substance" as substance
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'asset_plus';	
/* RQEV2-n0FG5Duvpz */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_care_status
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."status":: text as status,
    document_item."endDate":: date as end_date,
    document_item."startDate":: date as start_date
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'care_status';	
/* RQEV2-YCwVTayRWS */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_ete_status
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."hours":: int as hours,
    document_item."endDate":: date as end_date,
    document_item."startDate":: date as start_date,
    document_item."description":: text as description
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'ete_status';	
/* RQEV2-YjMR7tk33k */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_hearing_sentence_proposal
distkey
    (source_document_id)
sortkey
    (source_document_id, hearing_id) AS
SELECT
    i.source_document_id,
    i.document_item."hearingID":: text as hearing_id,
    sp."yjbsentenceProposalType":: text as yjb_sentence_proposal_type,
    sp."sortOrder":: int as sort_order,
    sp."cmssentenceProposalDescription":: text as cms_sentence_proposal_description
FROM
    stg.yp_doc_item as i,
    i.document_item."sentenceProposal" as sp
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'hearing';	
/* RQEV2-zLf7hyuAFk */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_intervention_programme
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."endDate":: date as end_date,
    document_item."sortOrder":: int as sort_order,
    document_item."startDate":: date as start_date,
    document_item."disposalType":: text as disposal_type,
    document_item."sentenceGroup":: text as sentence_group,
    document_item."cmsdisposalType":: text as cms_disposal_type,
    document_item."ageOnProgrammeEnd":: int as age_on_programme_end,
    document_item."ageOnProgrammeStart":: int as age_on_programme_start,
    document_item."etehoursOnProgrammeEnd":: int as ete_hours_on_programme_end,
    document_item."interventionProgrammeID":: text as intervention_programme_id,
    document_item."residenceOnProgrammeEnd":: text as residence_on_programme_end,
    document_item."accommodationEndDisposal":: text as accommodation_end_disposal,
    document_item."etehoursOnProgrammeStart":: int as ete_hours_on_programme_start,
    document_item."residenceOnProgrammeStart":: text as residence_on_programme_start,
    document_item."accommodationStartDisposal":: text as occommodation_start_disposal,
    document_item."isStatutorySchoolAgeAtProgrammeEnd":: bool as is_statutory_school_age_at_programme_end,
    document_item."isStatutorySchoolAgeAtProgrammeStart":: bool as is_statutory_school_age_at_programme_start
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'intervention_programme';	
/* RQEV2-u3GRK7Vfp6 */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_hearing_intervention_programme
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    source_document_id,
    document_item."hearingID":: text as hearing_id,
    document_item."interventionProgrammeID":: text as intervention_programme_id
FROM
    stg.yp_doc_item
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'link_hearing_intervention_programme';	
/* RQEV2-DgWj01sAFW */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_intervention_programme_asset
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    source_document_id,
    document_item."assetID":: text as asset_id,
    document_item."interventionProgrammeID":: text as intervention_programme_id
FROM
    stg.yp_doc_item
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'link_intervention_programme_asset';	
/* RQEV2-t63h9oRiEZ */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_intervention_programme_parenting_intervention
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    source_document_id,
    document_item."interventionProgrammeID":: text as intervention_programme_id,
    document_item."parentingInterventionID":: text as parenting_intervention_id
FROM
    stg.yp_doc_item
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'link_intervention_programme_parenting_intervention';	
/* RQEV2-wIMOWs24QG */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_offence_intervention_programme
distkey
    (source_document_id)
sortkey
    (source_document_id) AS
SELECT
    source_document_id,
    document_item."offenceID":: text as offence_id,
    document_item."interventionProgrammeID":: text as intervention_programme_id
FROM
    stg.yp_doc_item
WHERE
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'link_offence_intervention_programme';	
/* RQEV2-BELeuvafCo */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_offence_victim_intervention
distkey
(source_document_id)
sortkey
(source_document_id) AS
SELECT
    source_document_id,
    document_item."offenceID":: text as offence_id,
    document_item."victimInterventionID":: text as victim_intervention_id
FROM
    stg.yp_doc_item
WHERE
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_offence_victim_intervention';	
/* RQEV2-WYS7fLPSgA */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_parenting_intervention
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."engagementLevel":: text as engagement_level,
    document_item."sessionsPlanned":: int as session_planned,
    document_item."sessionsAttended":: int as sessions_attended,
    document_item."interventionStartDate":: date as intervention_start_date,
    document_item."parentingInterventionID":: text as parenting_intervention_id,
    document_item."parentingInterventionType":: text as parenting_intervvention_type
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'parenting_intervention';	
/* RQEV2-Dbu3xNQ1zD */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_residence
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."date":: date as date,
    document_item."description":: text as description
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'residence';	
/* RQEV2-IyrvyaQmrF */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_transfer
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."date":: date as date,
    document_item."description":: text as description
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'transfer';	
/* RQEV2-zuGVHXMjAe */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_victim_intervention
distkey
    (source_document_id)
sortkey
    (source_document_id) as
select
    yp_doc_item.source_document_id,
    document_item."victimType":: text as victim_type,
    document_item."commentedStatus":: text as commented_status,
    document_item."rjofferedStatus":: text as rj_offered_status,
    document_item."satisfactionLevel":: text as satisfaction_level,
    document_item."rjinterventionType":: text as rj_intervention_type,
    document_item."victimInterventionID":: text as victim_intervention_id
from
    stg.yp_doc_item
where
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'victim_intervention';	
