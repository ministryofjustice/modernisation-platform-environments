locals {
  rowleveldata_columns = [{
          name = "GroupName"
          type = "STRING"
      },      
      {
          name = "yotoucode"
          type = "STRING"
       }
  ]
}

resource "aws_quicksight_data_set" "rowleveldata" {
  data_set_id = "rowleveldata"
  name        = "RowLevelkData"
  import_mode = "DIRECT_QUERY"

   physical_table_map {
    physical_table_map_id = "rowleveldata"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.postgresql.arn
      name = "RowLevelData"

      sql_query = <<EOT
      select distinct "GroupName", CASE WHEN "GroupName" = 'yot_f00' then  '' ELSE ltrim(rtrim(yotoucode)) END AS "yotoucode"
      from auth.quicksight_rls_yjs
      group by "GroupName", CASE WHEN "GroupName" = 'yot_f00' then  '' ELSE ltrim(rtrim(yotoucode)) END
      norder by "GroupName"
      EOT

      dynamic "columns" {
        for_each = local.rowleveldata_columns
        content {
          name = columns.value["name"]
          type = columns.value["type"]
        }

      }
    }
  }
}

locals {
     personal_columns = [
        {
            name: "ypid",
            type: "STRING"
        },
        {
            name: "yotoucode",
            type: "STRING"
        },
        {
            name: "yot_name",
            type: "STRING"
        },
        {
            name: "currentyotid",
            type: "STRING"
        },
        {
            name: "pncnumber",
            type: "STRING"
        },
        {
            name: "gender_name",
            type: "STRING"
        },
        {
            name: "gender_sex",
            type: "INTEGER"
        },
        {
            name: "ethnicity",
            type: "STRING"
        },
        {
            name: "ethnicitygroup",
            type: "STRING"
        },
        {
            name: "sortorder",
            type: "INTEGER"
        },
        {
            name: "date_of_birth",
            type: "DATETIME"
        },
        {
            name: "age_at_arrest_or_offence",
            type: "INTEGER"
        },
        {
            name: "age_at_first_hearing",
            type: "INTEGER"
        },
        {
            name: "finyear",
            type: "STRING"
        },
        {
            name: "number",
            type: "INTEGER"
        }
      ]
}

/*
# This commended out as it is not currently working. To be fixed after merging with main.
resource "aws_quicksight_data_set" "personal_data" {
  data_set_id = "personal_data"
  name        = "Personal Data"
  import_mode = "SPICE"

  row_level_permission_data_set {
    arn               = aws_quicksight_data_set.rowleveldata.arn
    permission_policy = "GRANT_ACCESS"
    format_version    = "VERSION_1"
    namespace         = "default"
    status            = "ENABLED"
  }

  data_set_usage_configuration {
    disable_use_as_direct_query_source  = false
    disable_use_as_imported_source      = false
  }

  physical_table_map {
    physical_table_map_id = "personal_data"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.redshift.arn
      name            = "Persaonal Data"
      sql_query = <<EOT
        -- Personal Data
        
        SELECT distinct np.ypid,y.yotoucode,y.yot_name,p.currentyotid,p.pncnumber, 
          --year_number,
          CASE WHEN (CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender 
          end ) = '1' THEN 'Male'
          WHEN (CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender 
           end ) = '2' then 'Female' else 'Unknown' end as Gender_Name,
          CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender
           end as Gender_Sex,
           isnull(p.ethnicity,  'INFORMATION_NOT_OBTAINABLE') as ethnicity,
           --ETH.Ethnicitygroup,
           
           CASE WHEN ETH.Ethnicitygroup = 'Information not obtainable' THEN 'Not Known'
           WHEN ETH.Ethnicitygroup = 'Other Ethnic Group' THEN 'Other'
           WHEN ETH.Ethnicitygroup = 'Asian or Asian British' THEN 'Asian'
           WHEN ETH.Ethnicitygroup = 'Black or Black British' THEN 'Black'
           WHEN ETH.Ethnicitygroup IS NULL THEN 'Not Known'
            else ETH.Ethnicitygroup END AS Ethnicitygroup,
            
            CASE WHEN ETH.Ethnicitygroup = 'Asian or Asian British' THEN 1
            WHEN ETH.Ethnicitygroup = 'Black or Black British' THEN 2
            WHEN ETH.Ethnicitygroup LIKE '%Mixed%' THEN 3
            WHEN ETH.Ethnicitygroup LIKE '%Other%' THEN 4
            WHEN ETH.Ethnicitygroup = 'White' THEN 5
            WHEN ETH.Ethnicitygroup = 'Information not obtainable' then 6
            WHEN ETH.Ethnicitygroup = 'Not Known'  then 6
            WHEN ETH.Ethnicitygroup is null THEN 6 else 7 end as SortOrder,
            
            --CAST(p.date_of_birth AS NVARCHAR) AS date_of_birth,
            p.date_of_birth,
            max(age_at_arrest_or_offence) as age_at_arrest_or_offence,
            max(age_at_first_hearing) as age_at_first_hearing,
             --RANK() OVER(PARTITION BY p.ypid ORDER BY o.age_at_arrest_or_offence + o.age_at_first_hearing desc) as [AgeTotalFlag],
             --year(dateadd(month, -3, CAST(o.outcome_date AS DATE))) as FiscalYear,
             
             
             -- Need to point and Ref Table once Fin Year added
             CASE WHEN o.outcome_date::date BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17' WHEN o.outcome_date::date BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
              WHEN o.outcome_date::date BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19' WHEN o.outcome_date::date BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
              WHEN o.outcome_date::date BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21' WHEN o.outcome_date::date BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22' 
              WHEN o.outcome_date::date BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23' WHEN o.outcome_date::date BETWEEN '2023-04-01' AND '2024-03-31' THEN '2023/24' 
              WHEN o.outcome_date::date BETWEEN '2024-04-01' AND '2025-03-31' THEN '2024/25' WHEN o.outcome_date::date BETWEEN '2025-04-01' AND '2026-03-31' THEN '2025/26' 
              WHEN o.outcome_date::date BETWEEN '2026-04-01' AND '2027-03-31' THEN '2026/27' WHEN o.outcome_date::date BETWEEN '2027-04-01' AND '2028-03-31' THEN '2027/28' 
              WHEN o.outcome_date::date BETWEEN '2028-04-01' AND '2029-03-31' THEN '2028/29' WHEN o.outcome_date::date BETWEEN '2029-04-01' AND '2030-03-31' THEN '2029/30' 
              \nWHEN o.outcome_date::date BETWEEN '2030-04-01' AND '2031-03-31' THEN '2030/31' WHEN o.outcome_date::date BETWEEN '2031-04-01' AND '2032-03-31' THEN '2031/32' 
              \nWHEN o.outcome_date::date BETWEEN '2032-04-01' AND '2033-03-31' THEN '2032/33' WHEN o.outcome_date::date BETWEEN '2033-04-01' AND '2034-03-31' THEN '2033/34' 
              \nWHEN o.outcome_date::date BETWEEN '2034-04-01' AND '2035-03-31' THEN '2034/35' WHEN o.outcome_date::date BETWEEN '2035-04-01' AND '2036-03-31' THEN '2035/36' 
              \nELSE '' END AS [FinYear],
              
              
                  --DateAdd(month,-10,o.outcome_date::date,2) as test
                  --convert(char(2),DateAdd(month,+ 2,o.outcome_date::date,2) as year,
                      
                  --select * from refdata.date_table where day_date = '2023-04-01'
                  
                  --case when extract('month' from (to_date(o.outcome_date,'yy-mm'))) > 4
                    --then (to_date(o.outcome_date,'yy-mm')) + interval '-1' year\
                    -else (to_date(o.outcome_date,'yy-mm'))
                      --            end as test,
                       1 as Number
                       
                       from yjb_case_reporting.mvw_yp_latest_record as l
                       inner join yjb_case_reporting.mvw_yp_person_details as p on p.source_document_id = l.source_document_id
                       inner join yjb_case_reporting.mvw_yp_offence as o on l.source_document_id = o.source_document_id
                       left join refdata.yotoucodes as y on y.yotoucode = p.yotoucode\r\nleft join refdata.ethnicity_group  as ETH on CAST(p.ethnicity AS NVARCHAR) = CAST(ETH.ethnicity AS NVARCHAR)
                       
                       left join refdata.date_table as DT on o.outcome_date::date =  DT.day_date
                       
                       
                       Where legal_outcome_group in ('First-tier', 'Custody', 'Community', 'Pre-Court')\r\nand o.residence_on_legal_outcome_date <> 'OTHER' 
                       and o.outcome_appeal_status <> 'Changed on appeal'
                       and o.age_at_arrest_or_offence >=10 and o.age_at_arrest_or_offence <=17
                       and o.age_at_first_hearing <=17
                       and o.outcome_date::date >= '2020-04-01'
                       
                       --and y.yot_name like '%Barking%'
                       --AND ETH.Ethnicitygroup = 'White'
                       
                       group by 
                       
                       p.ypid,
                       y.yotoucode,
                       y.yot_name,
                       p.currentyotid,   
                       p.pncnumber, 
                       CASE WHEN (CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender 
                       end ) = '1' THEN 'Male'
                       WHEN (CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender 
                       end ) = '2' then 'Female' else 'Unknown' end ,
                       CASE WHEN p.gender is null and p.sex is not null then p.sex else p.gender 
                       end ,
                       isnull(p.ethnicity,  'INFORMATION_NOT_OBTAINABLE'),
                       --ETH.Ethnicitygroup,
                       
                       
                       CASE WHEN ETH.Ethnicitygroup = 'Information not obtainable' THEN 'Not Known'
                       WHEN ETH.Ethnicitygroup = 'Other Ethnic Group' THEN 'Other'
                       WHEN ETH.Ethnicitygroup = 'Asian or Asian British' THEN 'Asian'
                       WHEN ETH.Ethnicitygroup = 'Black or Black British' THEN 'Black'
                       WHEN ETH.Ethnicitygroup IS NULL THEN 'Not Known' 
                       else ETH.Ethnicitygroup END,
                       
                       CASE WHEN ETH.Ethnicitygroup = 'Asian or Asian British' THEN 1
                       WHEN ETH.Ethnicitygroup = 'Black or Black British' THEN 2
                       WHEN ETH.Ethnicitygroup LIKE '%Mixed%' THEN 3
                       WHEN ETH.Ethnicitygroup LIKE '%Other%' THEN 4
                       WHEN ETH.Ethnicitygroup = 'White' THEN 5
                       WHEN ETH.Ethnicitygroup = 'Information not obtainable' then 6
                       WHEN ETH.Ethnicitygroup = 'Not Known'  then 6
                       WHEN ETH.Ethnicitygroup is null THEN 6 else 7 end ,
                       
                       --CAST(p.date_of_birth AS NVARCHAR),
                       p.date_of_birth,
                       CASE WHEN o.outcome_date::date BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17' WHEN o.outcome_date::date BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18' 
                       WHEN o.outcome_date::date BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19' WHEN o.outcome_date::date BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20' 
                       WHEN o.outcome_date::date BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21' WHEN o.outcome_date::date BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22' 
                       WHEN o.outcome_date::date BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23' WHEN o.outcome_date::date BETWEEN '2023-04-01' AND '2024-03-31' THEN '2023/24' 
                       WHEN o.outcome_date::date BETWEEN '2024-04-01' AND '2025-03-31' THEN '2024/25' WHEN o.outcome_date::date BETWEEN '2025-04-01' AND '2026-03-31' THEN '2025/26' 
                       WHEN o.outcome_date::date BETWEEN '2026-04-01' AND '2027-03-31' THEN '2026/27' WHEN o.outcome_date::date BETWEEN '2027-04-01' AND '2028-03-31' THEN '2027/28' 
                       WHEN o.outcome_date::date BETWEEN '2028-04-01' AND '2029-03-31' THEN '2028/29' WHEN o.outcome_date::date BETWEEN '2029-04-01' AND '2030-03-31' THEN '2029/30' 
                       WHEN o.outcome_date::date BETWEEN '2030-04-01' AND '2031-03-31' THEN '2030/31' WHEN o.outcome_date::date BETWEEN '2031-04-01' AND '2032-03-31' THEN '2031/32' 
                       WHEN o.outcome_date::date BETWEEN '2032-04-01' AND '2033-03-31' THEN '2032/33' WHEN o.outcome_date::date BETWEEN '2033-04-01' AND '2034-03-31' THEN '2033/34' 
                       WHEN o.outcome_date::date BETWEEN '2034-04-01' AND '2035-03-31' THEN '2034/35' WHEN o.outcome_date::date BETWEEN '2035-04-01' AND '2036-03-31' THEN '2035/36' 
                       ELSE '' END"
      EOT

      dynamic "columns" {
        for_each = local.personal_columns
        content {
          name = columns.value["name"]
          type = columns.value["type"]
        }
      }
    }
  }
}  
*/

/*
   *     "ImportMode": "SPICE",
        "ConsumedSpiceCapacityInBytes": 19600740,
        "FieldFolders": {},
        "RowLevelPermissionDataSet": {
            "Namespace": "default",
            "Arn": "arn:aws:quicksight:eu-west-2:066012302209:dataset/7d6329ad-b523-4c4e-ad6b-86d8b1a06f81",
            "PermissionPolicy": "GRANT_ACCESS",
            "FormatVersion": "VERSION_1",
            "Status": "ENABLED"
        },
        "DataSetUsageConfiguration": {
            "DisableUseAsDirectQuerySource": false,
            "DisableUseAsImportedSource": false
        }

*/