SET enable_case_sensitive_identifier TO true;

/* RQEV2-zJ5RGwB3Km */
CREATE MATERIALIZED VIEW yjb_ianda_team.data_quality_bs_costs
distkey
    (period_ending)
sortkey
    (period_ending) AS
        SELECT
            yot.yjs_name_names_standardised AS yjs_name,
            year_quarter_name as label_quarter,
            cost.*
        FROM "yjb_returns"."yjaf_bands"."vw_b5_yot_budget" AS cost
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl
            ON CAST(cost.period_ending AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot 
            ON yot.ou_code_names_standardised = cost.source_unit_code;	
/* RQEV2-tNRjIdr4hG */
CREATE MATERIALIZED VIEW yjb_ianda_team.data_quality_bs_gender_ethnicity
distkey
    (period_ending)
sortkey
    (period_ending) AS
        SELECT
            yot.yjs_name_names_standardised AS yjs_name,
            year_quarter_name as label_quarter,
            gender_ethnicity.*
        FROM "yjb_returns"."yjaf_bands"."vw_b8_staffing_by_gender_and_ethnicity" AS gender_ethnicity
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl
            ON CAST(gender_ethnicity.period_ending AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot 
            ON yot.ou_code_names_standardised = gender_ethnicity.source_unit_code;	
/* RQEV2-HdqGeb5yvI */
CREATE MATERIALIZED VIEW yjb_ianda_team.data_quality_bs_staff_by_contract
distkey
    (period_ending)
sortkey
    (period_ending) AS
        SELECT
            yot.yjs_name_names_standardised AS yjs_name,
            year_quarter_name as label_quarter,
            contract.*
        FROM "yjb_returns"."yjaf_bands"."vw_b7_staffing_by_contract_type" AS contract
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl
            ON CAST(contract.period_ending AS date) = CAST(date_tbl.day_date AS date)
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot 
            ON yot.ou_code_names_standardised = contract.source_unit_code;	
/* RQEV2-2ndkzGkVs9 */
CREATE MATERIALIZED VIEW yjb_ianda_team.data_quality_general
distkey
    (source_document_id)
sortkey
    (source_document_id) AS 

WITH pd AS ( 
    SELECT
        header.source_document_id,
        return.cmsextractversion,
        return.cmssystem,
        document_item."ypid":: text,
        document_item."originatingYOTPersonID":: text AS oypid, 
        document_item."pncnumber":: text, 
        document_item."currentYOTID":: text AS currentyotid,
        yot.ou_code_names_standardised AS yot_code, 
        yot.yjs_name_names_standardised AS yjs_name,
        header.deleted, -- Y
        document_item."dateOfBirth":: date AS ypid_dob, 
        document_item."nationality":: text, 
        document_item."religion":: text, 
        document_item."preferredLanguage":: text,
        document_item."immigrationStatus":: text,
        document_item."ethnicity":: text,
        document_item."sex":: text, -- Variable that should be used, not gender
        document_item."gender":: text, -- Not in DRR, historical data pre- 2022
        document_item."genderIdentifiedSameSexRegisteredBirth":: text as gender_identified_same_sex_registered_birth, 
        document_item."genderTermUsed":: text as gender_term_used 
    FROM
        stg.yp_doc_item AS dc
        INNER JOIN yjb_case_reporting.mvw_yp_latest_record AS latest_record 
            ON dc.source_document_id = latest_record.source_document_id
        INNER JOIN stg.yp_doc_header AS header 
            ON header.source_document_id = dc.source_document_id
        LEFT JOIN yjb_ianda_team.yjs_standardised AS yot 
            ON yot.ou_code_names_standardised = header.yotoucode
        LEFT JOIN stg.return_part AS return 
            ON yot.ou_code_names_standardised = return.yotoucode
    WHERE
        document_item_type = 'person_details'
)
,transfer AS (
    SELECT
      yp_doc_item.source_document_id AS source_document_id_tr,
      document_item."description":: text AS transfer_description,
      document_item."date":: text AS transfer_date
    FROM
        stg.yp_doc_item 
    WHERE
        document_item_type = 'transfer'
)
,offence AS ( 
    SELECT
        o.source_document_id AS source_document_id_offence,
        o.document_item."offenceID":: text AS offence_id,
        o.document_item."arrestDate":: text AS arrest_date,
        olo."residenceOnLegalOutcomeDate":: Varchar(100) AS residence_on_legal_outcome_date,  
        o.document_item."yjboffenceCategory":: Varchar(100) as yjb_offence_category, 
        o.document_item."offenceDescription":: text as offence_description, 
        o.document_item."offenceDate":: date as offence_date,
        o.document_item."knifeRelatedOffence":: Varchar(100) as knife_related_offence,
        o.document_item."yjbseriousnessScore":: int as yjb_seriousness_score,   
        o.document_item."plea":: text as plea, 
        o.document_item."ageAtArrestOrOffence":: int as age_at_arrest_or_offence, 
        o.document_item."ageOnFirstHearing":: int as age_at_first_hearing, 
        o.document_item."cjscode":: Varchar(10) as cjscode, 
        olo."cmslegalOutcome":: Varchar(100) as cms_legal_outcome,
        olo."legalOutcome":: Varchar(100) AS legal_outcome,
        olo."legalOutcomeGroup":: Varchar(100) AS legal_outcome_group, 
        olo."outcomeDate":: date AS outcome_date,
        olo."mainOrOther":: Varchar(100) as main_or_other,
        lo."requirement":: text as requirement, 
        lo."term":: text as term, 
        lo."unpaidWorkMandatedHours":: FLOAT4 as unpaid_work_mandated_hours,
        lo."unpaidWorkCompletedHours":: FLOAT4 as unpaid_work_completed_hours,
        olo."termDays":: int as term_days,
        olo."termWeeks":: int as term_weeks,
        olo."termHours":: int as term_hours,
        olo."termMonths":: int as term_months,
        olo."termYears":: int as term_years,
        olo."outcomeAppealStatus":: Varchar(500) AS outcome_appeal_status,
        pb."bailStatus":: text as bail_status, 
        pb."startDate":: date AS bail_start_date, 
        pb."endDate":: date AS bail_end_date 
    FROM
        stg.yp_doc_item AS o
        LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON true
        LEFT JOIN o.document_item."policeBail" AS pb ON true 
        LEFT JOIN olo."lorequirements" as lo ON true
    WHERE
        document_item_type = 'offence'
)
,hearing AS (
    SELECT
        i.source_document_id AS source_document_id_h,
        i.document_item."hearingID":: text as hearing_id, 
        i.document_item."hearingDate":: date as hearing_date, 
        i.document_item."cmsremandDecision":: text as cms_remand_decision, 
        i.document_item."remandDecision":: text as remand_decision, 
        i.document_item."yjbremandProposalType":: text as yjb_remand_proposal_type, 
        i.document_item."courtName":: text as court_name, 
        i.document_item."courtType":: text as court_type,
        i.document_item."cmscourtDescription":: text as cms_court_description,
        sp."yjbsentenceProposalType":: text as yjb_sentence_proposal_type,
        sp."cmssentenceProposalDescription":: text as cms_sentence_proposal_description
    FROM
        stg.yp_doc_item as i,
        i.document_item."sentenceProposal" as sp
    WHERE
        document_item_type = 'hearing'
)
,hlink AS ( -- OD NEW 
SELECT
    hlink.source_document_id,
    document_item."offenceID":: text as offence_id,
    document_item."hearingID":: text as hearing_id
FROM
    stg.yp_doc_item AS hlink
WHERE
    document_item_type = 'link_hearing_offence'
)
,intervention_prog AS (
    SELECT
        yp_doc_item.source_document_id AS source_document_id_ip,
        document_item."interventionProgrammeID":: text AS intervention_programme_id, 
        document_item."startDate":: date AS intervention_start_date, 
        document_item."endDate":: date AS intervention_end_date, 
        document_item."cmsdisposalType":: text as cms_disposal_type, 
        document_item."disposalType":: text AS disposal_type,  
        document_item."sentenceGroup":: text as sentence_group, 
        document_item."kpi6SuccessfullyCompleted" AS kpi6_succesfully_completed,
        document_item."activity":: text AS activity, 
        document_item."identifiedVictim":: text AS identified_victim,
        document_item."accommodationStartDisposal":: text AS int_prog_accommodation_start,
        document_item."accommodationEndDisposal":: text AS int_prog_accommodation_end,
        document_item."etehoursOnProgrammeStart":: FLOAT4 AS int_prog_ete_hours_start,
        document_item."etehoursOnProgrammeEnd":: FLOAT4 AS int_prog_ete_hours_end,
        document_item."residenceOnProgrammeStart":: text AS int_prog_residence_start,
        document_item."residenceOnProgrammeEnd":: text AS int_prog_residence_end
    FROM
        stg.yp_doc_item
    WHERE
        document_item_type = 'intervention_programme'
)
,link AS( 
    SELECT
        link.source_document_id,
        document_item."offenceID":: text AS offence_id,
        document_item."interventionProgrammeID":: text AS intervention_programme_id
    FROM
        stg.yp_doc_item AS link
    WHERE
        document_item_type = 'link_offence_intervention_programme'
)
SELECT
    DISTINCT
    pd.*
    ,transfer.*
    ,offence.*
    ,hearing.*
    ,intervention_prog.*
    ,eth.ethnicitygroup AS ethnicity_group_mapped
    ,date_tbl.year_quarter_name as label_quarter
    FROM
        offence
        LEFT JOIN link 
            ON link.offence_id = offence.offence_id
            AND link.source_document_id = offence.source_document_id_offence
        LEFT JOIN intervention_prog 
            ON link.intervention_programme_id = intervention_prog.intervention_programme_id
            AND link.source_document_id = intervention_prog.source_document_id_ip
        LEFT JOIN hlink -- OD NEW 
            ON hlink.offence_id = offence.offence_id
            AND hlink.source_document_id = offence.source_document_id_offence
        LEFT JOIN hearing -- OD NEW
            ON hlink.hearing_id = hearing.hearing_id
            AND hlink.source_document_id = hearing.source_document_id_h
        LEFT JOIN pd 
            ON offence.source_document_id_offence = pd.source_document_id
        LEFT JOIN transfer 
            ON offence.source_document_id_offence = transfer.source_document_id_tr
        LEFT JOIN refdata.ethnicity_group AS eth --added
            ON pd.ethnicity = eth.ethnicity 
        LEFT JOIN yjb_returns.refdata.date_table AS date_tbl 
            ON CAST(intervention_prog.intervention_end_date AS date) = CAST(date_tbl.day_date AS date)
    WHERE intervention_prog.intervention_end_date >= '2023-04-01'

            AND intervention_prog.intervention_end_date <= GETDATE();	
/* RQEV2-THM4DFeRox */
CREATE MATERIALIZED VIEW yjb_ianda_team.data_quality_kpi10
distkey
    (source_document_id)
sortkey
    (source_document_id) as WITH kpi10 AS (
        SELECT
            victim.source_document_id as kpi10_source_document_id_victim,
            victim.document_item."victimID":: int as kpi10_victim_id,
            victim.document_item."engagedRJ":: text as kpi10_engaged_rj,
            victim.document_item."viewPrior":: text as kpi10_view_prior,
            victim.document_item."victimType":: text as kpi10_victim_type,
            victim.document_item."engagedRJEnd":: date as kpi10_engaged_rj_end,
            victim.document_item."engagedRJStart":: date as kpi10_engaged_rj_start,
            victim.document_item."yjscontactDate":: date as kpi10_yjs_contact_date,
            victim.document_item."commentedStatus":: text as kpi10_commented_status,
            victim.document_item."progressRequest":: text as kpi10_progress_request,
            victim.document_item."rjofferedStatus":: text as kpi10_rj_offered_status,
            victim.document_item."progressProvided":: text as kpi10_progress_provided,
            victim.document_item."consentYJSContact":: text as kpi10_consent_yjs_contact,
            victim.document_item."satisfactionLevel":: text as kpi10_satisfaction_level,
            victim.document_item."rjinterventionType":: text as kpi10_rj_intervention_type,
            victim.document_item."progressRequestDate":: date as kpi10_progress_request_date,
            victim.document_item."progressProvidedDate":: date as kpi10_progress_provided_date,
            victim.document_item."victimInterventionID":: int as kpi10_victim_intervention_id,
            victim.document_item."additionalSupportRequest":: text as kpi10_additional_support_request,
            victim.document_item."additionalSupportProvided":: text as kpi10_additional_support_provided
        FROM
            stg.yp_doc_item victim
        WHERE
            document_item_type = 'victim_intervention'
            AND victim.document_item."victimID" is not NULL
    ),
    link_victim AS(
        SELECT
            link.source_document_id as source_document_id_link_victim,
            document_item."offenceID":: text AS offence_id,
            document_item."victimInterventionID":: text as victim_intervention_id
        FROM
            stg.yp_doc_item AS link
        WHERE
            document_item_type = 'link_offence_victim_intervention'
    ),
    pd AS (
        SELECT
            header.source_document_id,
            document_item."currentYOTID":: text AS currentyotid,
            document_item."ypid":: text,
            yot.ou_code_names_standardised AS yot_code,
            yot.yjs_name_names_standardised AS yjs_name
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
            o.document_item."offenceID":: text AS offence_id,
            olo."outcomeDate":: date AS outcome_date,
            olo."legalOutcome":: Varchar(100) AS legal_outcome,
            olo."legalOutcomeGroup":: Varchar(100) AS legal_outcome_group,
            olo."cmslegalOutcome":: Varchar(100) AS cms_legal_outcome
        FROM
            stg.yp_doc_item AS o
            LEFT JOIN o.document_item."offenceLegalOutcome" AS olo ON TRUE
        WHERE
            document_item_type = 'offence'
    ),
    intervention_prog AS (
        SELECT
            yp_doc_item.source_document_id AS source_document_id_ip,
            document_item."interventionProgrammeID":: text AS intervention_programme_id,
            document_item."startDate":: date AS intervention_start_date,
            document_item."endDate":: date AS intervention_end_date,
            document_item."disposalType":: text AS disposal_type,
            document_item."kpi6SuccessfullyCompleted" AS kpi6_succesfully_completed
        FROM
            stg.yp_doc_item
        WHERE
            document_item_type = 'intervention_programme'
    ),
    link AS(
        SELECT
            link.source_document_id,
            document_item."offenceID":: text AS offence_id,
            document_item."interventionProgrammeID":: text AS intervention_programme_id
        FROM
            stg.yp_doc_item AS link
        WHERE
            document_item_type = 'link_offence_intervention_programme'
    ),
    combined AS(
        SELECT
            pd.*,
            offence.*,
            intervention_prog.*,
            date_tbl.year_quarter_name as label_quarter
        FROM
            offence
            LEFT JOIN link ON link.offence_id = offence.offence_id
            AND link.source_document_id = offence.source_document_id_offence
            LEFT JOIN intervention_prog ON link.intervention_programme_id = intervention_prog.intervention_programme_id
            AND link.source_document_id = intervention_prog.source_document_id_ip
            LEFT JOIN pd ON offence.source_document_id_offence = pd.source_document_id
            LEFT JOIN yjb_returns.refdata.date_table AS date_tbl ON CAST(intervention_prog.intervention_end_date AS date) = CAST(date_tbl.day_date AS date)
        WHERE
            intervention_prog.intervention_end_date >= '2023-04-01'
            AND intervention_prog.intervention_end_date <= GETDATE()
    )
SELECT
    DISTINCT kpi10.*,
    link_victim.victim_intervention_id,
    combined.*
FROM
    kpi10
    LEFT JOIN link_victim ON link_victim.victim_intervention_id = kpi10.kpi10_victim_intervention_id
    AND link_victim.source_document_id_link_victim = kpi10.kpi10_source_document_id_victim
    LEFT JOIN combined ON link_victim.offence_id = combined.offence_id
    AND link_victim.source_document_id_link_victim = combined.source_document_id;	
CREATE MATERIALIZED VIEW yjb_ianda_team.mvw_return_part_deleted_yps
COMPOUND
SORTKEY
    (source_return_id, currentyotid) AS

with deleted_yp_list as  
(
    SELECT 
        id, 
        split_to_array(rtrim(ltrim(deleted_yps,'{'),'}'),',')::super as deleted_yps
    FROM 
        "yjb_returns"."yjb_case_reporting_stg"."return"
    where 
        deleted_yps is not null 
        and deleted_yps <> '{}'
) 

SELECT 
    l.id::bigint as source_return_id, 
    deleted_yps::text as currentyotid
FROM 
    deleted_yp_list AS l
LEFT JOIN l.deleted_yps AS deleted_yps ON TRUE;
--RequestID=86089a40-d743-4dd6-afa7-cdc1d6a15487; TraceID=1-65140306-25a326bb5c3f9f6a4f776ac1;	
CREATE MATERIALIZED VIEW yjb_ianda_team.mvw_return_part_deleted_yps_ak
COMPOUND
SORTKEY
    (source_return_id, currentyotid) AS

with deleted_yp_list as  
(
    SELECT 
        id, 
        split_to_array(rtrim(ltrim(deleted_yps,'{'),'}'),',')::super as deleted_yps
    FROM 
        "yjb_returns"."yjb_case_reporting_stg"."return"
    where 
        deleted_yps is not null 
        and deleted_yps <> '{}'
) 

SELECT 
    l.id::bigint as source_return_id, 
    deleted_yps::text as currentyotid
FROM 
    deleted_yp_list AS l
LEFT JOIN l.deleted_yps AS deleted_yps ON TRUE;
--RequestID=8dbee428-4eb4-4890-899f-a1b9a2d487b0; TraceID=1-65250919-00c28b473aa5a2ed7ef7ef20;	
