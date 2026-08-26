
SET enable_case_sensitive_identifier TO true;

/* RQEV2-shn7UwcXjh */
CREATE MATERIALIZED VIEW stg.mvw_etl_process_record_counts as
select
    e.etl_process_id,
    (
        select
            count(*)
        from
            stg.return_part
        where
            etl_process_id = e.etl_process_id
    ) return_part_count,
    (
        select
            count(*)
        from
            stg.yp_doc_header
        where
            etl_process_id = e.etl_process_id
    ) yp_doc_headers_count,
    (
        select
            count(*)
        from
            stg.yp_doc_item
        where
            etl_process_id = e.etl_process_id
    ) yp_doc_item_count -- , (select count(*) from stg.yp_doc_header doc inner join yjb_case_reporting.mvw_yp_person_details v on doc.source_document_id = v.source_document_id where doc.etl_process_id = e.etl_process_id) as mvw_yp_person_details
,
    (
        select
            count(*)
        from
            stg.yp_doc_header doc
            inner join yjb_case_reporting.mvw_yp_offence v on doc.source_document_id = v.source_document_id
        where
            doc.etl_process_id = e.etl_process_id
    ) as mvw_yp_offence,
    (
        select
            count(*)
        from
            stg.yp_doc_header doc
            inner join yjb_case_reporting.mvw_yp_hearing v on doc.source_document_id = v.source_document_id
        where
            doc.etl_process_id = e.etl_process_id
    ) as mvw_yp_hearing,
    (
        select
            count(*)
        from
            stg.yp_doc_header doc
            inner join yjb_case_reporting.mvw_yp_link_hearing_offence v on doc.source_document_id = v.source_document_id
        where
            doc.etl_process_id = e.etl_process_id
    ) as mvw_yp_link_hearing_offence
from
    stg.etl_process e;


grant all on table stg.mvw_etl_process_record_counts to  group "yjb_data_science" --"IAMR:redshift-serverless-yjb-reporting-moj_ap"
