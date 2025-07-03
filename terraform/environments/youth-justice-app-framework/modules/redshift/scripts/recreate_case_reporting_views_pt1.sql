
SET enable_case_sensitive_identifier TO true;

/* RQEV2-44tWh6RbCh */
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

alter table yjb_case_reporting.mvw_yp_latest_record owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_latest_record to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_latest_record to group yjb_ianda_team;
grant select on yjb_case_reporting.mvw_yp_latest_record to "IAMR:redshift-serverless-yjb-reporting-moj_ap";


/* ############################# */

/* RQEV2-lDVbWX4glH */
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

alter table yjb_case_reporting.mvw_yp_document_header owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_document_header to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_document_header to group yjb_ianda_team;
grant select on yjb_case_reporting.mvw_yp_document_header to "IAMR:redshift-serverless-yjb-reporting-moj_ap";

/* ############################# */

/* RQEV2-KHbSkUbVNX */
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
  COALESCE(olo."termDays", 0) + (COALESCE(olo."termWeeks", 0) * 7) + (COALESCE(olo."termMonths", 0) * 30.44) + (COALESCE(olo."termYears", 0) * 365.25) + (COALESCE(olo."termHours", 0) / 24) as total_term_days,
  COALESCE(olo."termMonths", 0) + (COALESCE(olo."termDays", 0) / 30.44) + (COALESCE(olo."termWeeks", 0) / 4.348) + (COALESCE(olo."termYears", 0) * 12) + (COALESCE(olo."termHours", 0) / (30.44 * 24)) as total_term_months,
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
  ypid not in (
    select
      yp_id
    from
      yjb_case_reporting_stg.vw_deleted_yps
  )
  and document_item_type = 'offence';

alter table yjb_case_reporting.mvw_yp_offence owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_offence to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_offence to group yjb_ianda_team;
grant select on yjb_case_reporting.mvw_yp_offence to "IAMR:redshift-serverless-yjb-reporting-moj_ap";


  /* ############################ */

  /* RQEV2-ByN30xcGvr */
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

alter table yjb_case_reporting.mvw_yp_person_details owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_person_details to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_person_details to group yjb_ianda_team;
grant select on yjb_case_reporting.mvw_yp_person_details to "IAMR:redshift-serverless-yjb-reporting-moj_ap";


/* ############################################# */

/* RQEV2-TgPxFOMxnP */
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
    and ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    );

alter table yjb_case_reporting.mvw_yp_hearing owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_hearing to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_hearing to group yjb_ianda_team;
--grant select on yjb_case_reporting.mvw_yp_hearing to "IAMR:redshift-serverless-yjb-reporting-moj_ap";

/* ############################ */

/* RQEV2-tMf1lNsyqJ */
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
    ypid not in (
        select
            yp_id
        from
            yjb_case_reporting_stg.vw_deleted_yps
    )
    and document_item_type = 'link_hearing_offence';

alter table yjb_case_reporting.mvw_yp_link_hearing_offence owner to yjb_schedular;

grant select on yjb_case_reporting.mvw_yp_link_hearing_offence to group yjb_data_science;
grant select on yjb_case_reporting.mvw_yp_link_hearing_offence to group yjb_ianda_team;
--grant select on yjb_case_reporting.mvw_yp_link_hearing_offence to "IAMR:redshift-serverless-yjb-reporting-moj_ap";


    /* ############################ */ 