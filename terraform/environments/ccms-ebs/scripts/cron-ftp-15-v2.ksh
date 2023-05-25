#
# This job runs out of cron and sequentially runs jobs every 15 minutes.
#
# RBS Outbound
#/export/home/aebsprod/scripts/curl-ftp-v2.ksh 001
#
# Allpay Outbound
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 002
#
# Eckoh Outbound
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 003
#
# Rossendales Outbound
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 004
#
#TDX Outbound
# added this script to cope with files owned by oebsprod and unix2dos them
# psb 14sep2016
/export/home/aebsprod/scripts/unix2dos.ksh
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 008
#
# Microgen Bacway Outbound RBS
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 010
#
# RBS Inbound
/export/home/aebsprod/scripts/curl-ftp-v2.ksh 011
#
# Citibank Inbound
## js /export/home/aebsprod/scripts/curl-ftp-v2.ksh 012
#
# LFFramework Inbound
## js /export/home/aebsprod/scripts/curl-ftp-v2.ksh 013
#
# Barclaycard Inbound
## js /export/home/aebsprod/scripts/curl-ftp-v2.ksh 014
#
# Barclaycard Outbound
## js /export/home/aebsprod/scripts/curl-ftp-v2.ksh 007
#
# Test Outbound
##/export/home/aebsprod/scripts/curl-ftp-v2.ksh 098
#
# Test Inbound
##/export/home/aebsprod/scripts/curl-ftp-v2.ksh 099
