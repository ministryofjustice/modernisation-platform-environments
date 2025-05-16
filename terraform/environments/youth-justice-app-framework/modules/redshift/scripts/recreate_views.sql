/* RQEV2-h9EnICvMTa */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'victim_intervention';	

/* RQEV2-l2PJns03rp */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'transfer';	
/* RQEV2-55BsNuYgEJ */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'residence';	

/* RQEV2-tT6Ha2IGi6 */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_person_details
distkey
(source_document_id)
sortkey
(source_document_id) as
select
    yp_doc_header.source_document_id,
    document_item."preferredLanguage":: text as preferred_language,
    document_item."dateOfBirth":: date as date_of_birth,
    document_item."dateOf18ThBirthday":: date as date_of_18th_birthday,
    document_item."gender":: int,
    document_item."sex":: int,
    -- not gender!
    document_item."genderTermUsed":: text as gender_term_used,
    document_item."genderIdentifiedSameSexRegisteredBirth":: text as gender_identified_same_sex_registered_birth,
    document_item."ethnicity":: text,
    document_item."nationality":: text,
    document_item."currentYOTID":: text as currentyotid,
    document_item."ypid":: text,
    document_item."originatingYOTPersonID":: text as originating_yot_person_id,
    document_item."immigrationStatus":: text as immigration_status,
    document_item."pncnumber":: text,
    document_item."religion":: text,
    yp_doc_header.deleted,
    yp_doc_header.yotoucode,
    yp_doc_header.etl_process_id
from
    stg.yp_doc_item
    inner join stg.yp_doc_header on yp_doc_header.source_document_id = yp_doc_item.source_document_id
where
    	document_item.ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'person_details';	

/* RQEV2-v4hc0VtpLj */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'parenting_intervention';	

/* RQEV2-IwVnD1LzBs */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_offence
distkey
(source_document_id)
sortkey
(source_document_id) AS
SELECT
  o.source_document_id,
  o.document_item."offenceID":: text as offence_id,
  o.document_item."offenceDate":: date as offence_date,
  o.document_item."offenceDescription":: text as offence_description,
  o.document_item."offenceLocationPostcode":: text as offence_location_postcode,
  o.document_item."cjscode":: Varchar(10) as cjscode,
  o.document_item."cjscodeUnknown":: varchar(100) as cjscode_unknown,
  o.document_item."arrestDate":: date as arrest_date,
  o.document_item."plea":: text as plea,
  o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence,
  o.document_item."ageOnArrestDate":: int as age_on_arrest_date,
  o.document_item."ageOnOffenceDate":: int as age_on_offence_date,
  o.document_item."ageOnFirstHearing":: int as age_at_first_hearing,
  o.document_item."ageAtCharge":: int as age_at_charge,
  o.document_item."yjbseriousnessScore":: int as yjb_seriousness_score,
  o.document_item."yjboffenceCategory":: varchar(100) as yjb_offence_category,
  o.document_item."programmeBreachID":: varchar(100) as programme_breach_id,
  o.document_item."knifeRelatedOffence":: varchar(100) as knife_related_offence,
  o.document_item."careStatusOnOffenceDate":: varchar(100) as care_status_on_offence_date,
  olo."mainOrOther":: Varchar(100) as main_or_other,
  olo."outcomeDate":: date as outcome_date,
  olo."outcomeEndDate":: date as outcome_end_date,
  olo."outcomeDateOfAppealedOutcome":: date as outcome_date_of_appealed_outcome,
  olo."outcomeAppealStatus":: Varchar(500) as outcome_appeal_status,
  olo."legalOutcome":: Varchar(100) as legal_outcome,
  olo."legalOutcomeGroup":: Varchar(100) as legal_outcome_group,
  olo."cmslegalOutcome":: Varchar(100) as cms_legal_outcome,
  olo."isRelevantCourtDisposal":: bool as is_relevant_court_disposal,
  olo."isSubstantive":: bool as is_substantive,
  olo."isPreCourtDisposal":: bool as is_pre_court_disposal,
  olo."isCourtDisposal":: bool as is_court_disposal,
  olo."isFirstSubstantiveOutcome":: bool as is_first_substanstive_outcome,
  olo."residenceOnLegalOutcomeDate":: Varchar(100) as residence_on_legal_outcome_date,
  olo."careStatusOnOutcomeDate":: Varchar(100) as care_status_on_outcome_date,
  olo."etehoursOnOutcomeDate":: int as ete_hours_on_outcome_date,
  olo."sentencingOccasionID":: Varchar(500) as sentencing_occasion_id,
  olo."termDays":: int as term_days,
  olo."termWeeks":: int as term_weeks,
  olo."termHours":: int as term_hours,
  olo."termMonths":: int as term_months,
  olo."termYears":: int as term_years,
  olo."rank":: int as rank,
  olo."sortOrder":: int as sort_order,
  lo."term":: text as term,
  lo."requirement":: text as requirement,
  lo."isSubstantiveRequirement":: boolean as is_substantive_requirement
FROM
  stg.yp_doc_item AS o
  LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
  LEFT JOIN olo."lorequirements" as lo ON true
WHERE
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and	document_item_type = 'offence';	
/* RQEV2-W1SiM0o7P0 */

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

/* RQEV2-ahXzEA94ge */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_offence_intervention_programme';	

/* RQEV2-le8geoXLtK */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_intervention_programme_parenting_intervention';	

/* RQEV2-qcRvVUv32A */
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
	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_intervention_programme_asset';	

/* RQEV2-Jb5VonxZ3T */
--DROP MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_hearing_offence;

CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_link_hearing_offence
distkey
(source_document_id)
sortkey
(source_document_id) AS
SELECT
    source_document_id,
    document_item."offenceID":: text as offence_id,
    document_item."hearingID":: text as hearing_id
FROM
    stg.yp_doc_item
WHERE
	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_hearing_offence';	

/* RQEV2-u7bzPI1fie */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'link_hearing_intervention_programme';	

/* RQEV2-ffUnoPAsFs */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_latest_record
distkey
(source_document_id)
sortkey
(source_document_id) AS WITH latest_yp AS (
    SELECT
      p.ypid,
      p.source_document_id,
      row_number() over (
        partition BY p.ypid
        ORDER BY
          r.returnstartdate DESC,
          r.returnenddate DESC,
          r.signoff_date DESC,
          r.source_return_id DESC
      ) AS row_number
    FROM
      stg.return_part AS r
      INNER JOIN stg.yp_doc_header as p on r.source_return_id = p.source_return_id
  )
SELECT
  ypid,
  source_document_id
FROM
  latest_yp
WHERE
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and row_number = 1;	

/* RQEV2-fJLAg4gtdb */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'intervention_programme';
	
/* RQEV2-qLjyo9G1LN */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'hearing';	

/* RQEV2-n5vBwIOLsl */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_hearing
distkey
(source_document_id)
sortkey
(source_document_id) AS
SELECT
    source_document_id,
    document_item."hearingID":: text as hearing_id,
    document_item."hearingDate":: date as hearing_date,
    document_item."courtType":: text as court_type,
    document_item."courtName":: text as court_name,
    document_item."cmscourtDescription":: text as cms_court_description,
    document_item."remandDecision":: text as remand_decision,
    document_item."cmsremandDecision":: text as cms_remand_decision,
    document_item."yjbremandProposalType":: text as yjb_remand_proposoal_type,
    document_item."sortOrder":: int as sort_order
FROM
    stg.yp_doc_item
WHERE
    document_item_type = 'hearing'
and		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps);	

/* RQEV2-drRYLuaYPJ */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'ete_status';	

/* RQEV2-0e9sayHezu */
CREATE MATERIALIZED VIEW yjb_case_reporting.mvw_yp_document_header
distkey
(source_document_id)
sortkey
(source_document_id) AS
select
    source_document_id,
    source_return_id,
    currentyotid as current_yot_id,
    ypid,
    yotoucode as yot_ou_code,
    return_start_date,
    return_end_date,
    etl_process_id
from stg.yp_doc_header
where 
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps);	

/* RQEV2-UwHaNPShhv */
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
		ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'care_status';	

/* RQEV2-225pgt2DBB */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-Eatzj6hyXq */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-lCwyiTP6jT */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-HJAaxsz0PP */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-qepfDAvdwX */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-QEpFy04XAc */
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
    	ypid not in (select yp_id from yjb_case_reporting_stg.vw_deleted_yps)
and document_item_type = 'asset_plus';	

/* RQEV2-M1R58ApYPu */
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

/* RQEV2-hU3knhZvq2 */
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

/* RQEV2-fJpHlY7xg5 */
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

