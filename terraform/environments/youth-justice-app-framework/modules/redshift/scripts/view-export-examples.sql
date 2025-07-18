from pg_catalog.pg_views
 where schemaname = 'yjb_ianda_team'
 and viewname not in ('mvw_return_part_deleted_yps','mvw_return_part_deleted_yps_ak','data_quality_kpi10','data_quality_general','data_quality_bs_costs','data_quality_bs_staff_by_contract','data_quality_bs_gender_ethnicity')
 and viewname not in ('kpi1','residence_distinct','yjs_family_unpivoted','yjs_family_unpivoted_v2')
 and viewname  in ('custodies_since_2014','fte_redshift','sexual_offences_since_2016','sexual_offences_since_2016_all_offences','sv_2020_2024','yro_moj_jb')


order by viewname;


select top 15 * --definition
/*'grant select on ' + schemaname + '.' + viewname + ' to group yjb_data_science;',
'grant select on ' + schemaname + '.' + viewname + ' to group yjb_ianda_team;',
'grant select on ' + schemaname + '.' + viewname + ' to "IAMR:redshift-serverless-yjb-reporting-moj_ap";'
*/
from pg_catalog.pg_views
 where schemaname = 'yjb_kpi_case_level'
 and viewname not in ('.kpi1_acc_template','kpi2_ete_template','kpi3_sendaln_template','kpi5_substance_m_template','kpi6_oocd_template','kpi7_wider_services_template',
                'yjb_kpi_case_level.kpi8_summary','kpi9_sv_template','kpi10_victim_template','kpi2_ete_template_v8')
and viewname = 'kpi4_mh_case_level_v8'
and viewname not in ('person_details_v8', 'person_details', 'kpi1_acc_summary_v8','kpi1_acc_case_level_v8_access','kpi10_victim_summary_v8')
and viewname not in ('kpi1_acc_summary', 'kpi1_acc_summary_long', 'kpi1_acc_template','kpi1_acc_template_v8')
--and viewname not in ('kpi10_victim_summary_v8, kpi10_victim_summary_v8, kpi1_acc_case_level,kpi1_acc_case_level_v8 kpi1_acc_case_level_v8_access kpi1_acc_summary kpi1_acc_summary_long 
 --               kpi1_acc_summary_v8

and viewname not in ('kpi2_ete_summary_v8','kpi3_sendaln_template_v8', 'kpi3_sendaln_summary_v8')

and viewname not in ('kpi4_mh_case_level_v8','kpi5_substance_m_summary_v8','kpi6_oocd_summary_v8','kpi6_oocd_template_v8')
and viewname > 'kpi4_mh_summary_long'

order by viewname;
