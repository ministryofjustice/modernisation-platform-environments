prompt Find Tablespace used space > 95 percent used  with 'autoextend on'.
set pages 90
set lines 132
select TABLESPACE_NAME,round(TABLESPACE_SIZE*8192/1024/1024/1024,2) "TS_SIZE(GB)",
round(USED_SPACE*8192/1024/1024/1024,2) "USED_SPACE(GB)",
round((TABLESPACE_SIZE*8192/1024/1024/1024)-(USED_SPACE*8192/1024/1024/1024),2) "FREE_SPACE(GB)",
round(USED_PERCENT,2) "USED%",'ALERT' as status
from dba_tablespace_usage_metrics
where round(USED_PERCENT,2) > 94.75
and TABLESPACE_NAME not like 'UNDO%'
order by 5 desc
/