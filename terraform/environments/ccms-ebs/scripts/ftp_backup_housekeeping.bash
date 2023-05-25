#!/bin/bash
# Housekeeping for ftp jobs backups

find /export/home/aebsprod/Outbound/CCMS/Citibank/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/Rossendales/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/TDX/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/RBS/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/Allpay/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/Eckoh/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/IOS/BACKUP -type f -mtime +31 -exec rm -rf {} \;
find /export/home/aebsprod/Outbound/CCMS/IOS/ADHOC/BACKUP -type f -mtime +31 -exec rm -rf {} \;
