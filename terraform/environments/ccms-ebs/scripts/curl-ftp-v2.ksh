#!/bin/ksh
#
################################################################################
#
#       Author  : Ken Woods
#       Date    : 24th September 2012
#       Project : LSC IDP (Atos)
#       Version : 0.2
#       File    : curl-ftp.ksh
#
################################################################################
#
# This is a modification of the script written by Robin Soper calld ftps_get
#
# This script comes with jobs file called 'curl-ftp.jobs.v2' that contains the
# parameters required to send files to or retrieve files from another server.
#
# The script is designed to move any files found in a source directory on one
# server to a destination directory on another server. Only files are moved
# and they can be pushed or pulled. Any directories that are found are ignored.
#
# After a file has been transfered the size of the source and destination files
# is compared an only if they match is the source file deleted. If they do not
# match then both files are retained and cURL diagnostic information is written
# to the log. A failure of this nature does not terminate the job and any other
# files will be transfered.
#
# Any other failure will terminate the run.
#
#
################################################################################
#
# When          Who             Comments
# ----          ---             --------
# 24-09-2012    Ken Woods       Initial Version
# 20160831: M.Irving: updating to handle files with spaces.
# 20161024: M.Irving: adding facitity to werite error to log file so that it
#         : can be monitored and used to cut incident ticket.
# 12mar2019 : psb : new version to handle S3 comms via Linux server
# 25May2023     Sahid Khan      Slight adjustments to use with Linux instead of Solaris
################################################################################

################################################################################
#
# Variables
#
################################################################################

BASE_DIR=/export/home/aebsprod/scripts  # The location of the this script.
CURL_TMP="${BASE_DIR}/curl-tmp"         # Directory for temporary cURL files.
CURL="curl -k"                          # cURL executable.
JOBS="${BASE_DIR}/ftp.jobs.v2"          # Parameter file containing jobs.
CACERT=${BASE_DIR}/.ftps/cacert.crt     # SSL certificate for ftps.
LOGFILE="${BASE_DIR}/curl-ftp_v2.log"   # Logfile for all actions performed.
LOGLINE="------------------------------------------------------------"
LOGTICKETFILE="${BASE_DIR}/curl-ftp-ticket.log"
#
# turn incident ticketing on or off
#TICKETS=on
TICKETS=off

#
# Set to true for debug on all functions or set to the names of one or more
# functions that you want to debug.
#
DEBUG="false"
#DEBUG="getRemoteFileList"

################################################################################
#
# Functions
#
################################################################################

#
# Function:-    debug
# Parameters:-  $1 = calling function name
#
debug() {
        # Check for functions to be debuged.
        for debug_func in ${DEBUG} ; do
                if [ "${debug_func}" = "true" ] ; then
                        return 0
                elif [ "${debug_func}" = "$1" ] ; then
                        return 0
                fi
        done

        # If we get here then no debugging to be done.
        return 1
}

#
# Function:- logerror
# Parameters:- variable containing error text
#
# print error message to stdout and to second logfile for monitoring to read and raise an incident ticket.
#
logerror() {
print "\n$*\n"
if [[ "$TICKETS" = on ]] ; then
    print "$(date): Alert: server $(hostname):${0}: $* : Check $(hostname):$LOGFILE" >> $LOGTICKETFILE
    /bin/rm ${CURL_TMP}/OK_${jobid}
fi
}

#
# Function:-    checkJobsFile
# Parameters:-  None
#
# Make sure we have the required parameter file.
#
checkJobsFile() {
        # Check for debug requirement
        debug checkJobsFile && set -x

        if [[ ! -f ${JOBS} ]] ; then
                message="The job file '${JOBS}' does not exist."
                logerror $message
                exit 1
        fi
}

#
# Function:-    checkJob
# Parameters:-  $1 Job number
#
# Check a Job Number was supplied and that it is valid.
#
checkJob() {
        # Check for debug requirement
        debug checkJob && set -x

        if [[ -z ${1} ]] ; then
                message="Usage:- ${0} <Job Number>"
                logerror $message
                exit 1
        elif [[ `grep -wc ^${1} ${JOBS}` -eq 1 ]] ; then
                print "Job Number : ${1}"
                return
        elif [[ `grep -wc ^${1} ${JOBS}` -eq 0 ]] ; then
                message="Job Number : ${1} not found."
                logerror $message
                exit 1
        elif [[ `grep -wc ^${1} ${JOBS}` -gt 1 ]] ; then
                message="Job Number : ${1} found more than once in jobs file:"
                logerror $message
                print "\t${JOBS}\n"
                grep -w ^${1} ${JOBS}
                print "\n"
                exit 1
        fi
}

#
# Function:-    getJob
# Parameters:-  $1 Job Number
#
# Load up the job parameters.
#
getJob() {
        # Check for debug requirement
        debug getJob && set -x

        param_check_fail=0

        job="`grep -w ^${1} ${JOBS}`"

        jobid=`echo ${job} | cut -d, -f1`

        customer=`echo ${job} | cut -d, -f2`
        checkParam "customer" "${customer}"

        server=`echo ${job} | cut -d, -f3`
        checkParam "server" "${server}"

        local=`echo ${job} | cut -d, -f4`
        checkParam "local" "${local}"

        remote=`echo ${job} | cut -d, -f5`
        checkParam "remote" "${remote}"

        type=`echo ${job} | cut -d, -f6`
        checkParam "type" "${type}"

        port=`echo ${job} | cut -d, -f7`
        checkParam "port" "${port}"

        direction=`echo ${job} | cut -d, -f8`
        checkParam "direction" "${direction}"

        retain=`echo ${job} | cut -d, -f9`
        checkParam "retain" "${retain}"

        userid=`echo ${job} | cut -d, -f10`
        checkParam "userid" "${userid}"

        password=`echo ${job} | cut -d, -f11`
        checkParam "password" "${password}"

        if [[ param_check_fail -eq 1 ]] ; then
                message="Job ${jobid} terminated due to missing parameter."
                logerror $message
                exit 1
        else
                print ""
        fi
}

#
# Function:-    checkParam
# Parameters:-  $1 Parameter name
#               $2 Value
#
# Check to see if th variable is set and return 1 if not.
#
checkParam() {
        # Check for debug requirement
        debug checkParam && set -x

        if [[ -z "${2}" ]] ; then
                param_check_fail=1
        fi

        # If this is a password, don't print it.
        [[ "${1}" = "password" ]] && return

        printf "%10s : %s\n" ${1} ${2}
}

#
# Function:-    getRemoteFileList
# Parameters:-  None
#
# Create a list of files in the remote directory and report any errors.
#
getRemoteFileList() {
        # Check for debug requirement
        debug getRemoteFileList && set -x

        # Create the curl command to use. It is placed in ${curl_cmd}.
        curlConnect ${type}

        # Create temporary files for remote file list and any errors.
        print "Getting remote file information.\n${LOGLINE}"
        curl_tmp=`mktemp ${CURL_TMP}/remote.XXXXXX`
        curl_err=`mktemp ${CURL_TMP}/error.XXXXXX`

        # Get the list of remote files.
        ${CURL} -o ${curl_tmp} ${curl_cmd}/${remote} 2>${curl_err}
        if [[ $? -ne 0 ]] ; then
                message="Job ${jobid} Terminated getting list of remote files."
                logerror $message
                cat ${curl_err}
                rm ${curl_tmp} ${curl_err}
                exit 1
        fi

        # List the files found in the remote directory and create a list of
        # files and sizes.
        egrep -v '^d|<DIR>' ${curl_tmp}
        if grep -q '220 Microsoft FTP Service' ${curl_err} ; then
                unset remote_file_list; egrep -v '^d|<DIR>' ${curl_tmp}|while read date time size fl;
                do
                  [[ -z "${remote_file_list}" ]] &&  remote_file_list="$size $fl" || remote_file_list="$remote_file_list
                $size $fl"
                done
        else
                remote_file_list="$(cat ${curl_tmp} | awk '/^-/ {print $5, $9}')"
        fi

        # Check to see if we have a directory called backup.
        if egrep '^d|<DIR>' ${curl_tmp} | \
                grep -qw BACKUP ; then
                backup=BACKUP
        else
                backup=""
        fi

        # Tidy up temporary files.
        rm ${curl_tmp} ${curl_err}
}

#
# Function:- getLocalFileList
# Parameters:-  $1 Local directory
#
# Check the directory exists and then create a list of files and sizes.
#
getLocalFileList() {
        # Check for debug requirement
        debug getJob && set -x

        # Check that the directory exists.
        if [[ ! -d ${1} ]] ; then
                message="Job ${jobid} Terminated Local directory does not exist :${1}"
                logerror $message
                print "Job Terminated."
                exit 1
        else
                # Create list of files and sizes
                print "Getting local file information.\n${LOGLINE}"
                ls -l ${1} | grep '^-'
                ls -1p ${1} | grep -v '\/$'| while read fl ; do
                        size=$(ls -l "${1}/${fl}" | awk '{print $5}')

                        # We don\'t want a blank first record.
                        if [[ -z "${local_file_list}" ]] ; then
                                local_file_list="${size} ${fl}"
                        else
                                local_file_list="${local_file_list}
                                ${size} ${fl}"
                        fi
                done
        fi
}

#
# Function:-    curlConnect
# Parameters:-  $1 Type of transfer
#
# Create a command line for the requested service.
#
curlConnect() {
        # Check for debug requirement
        debug curlConnect && set -x

        # Set verbose for cURL then we can display it if required.
        opts="-v"

        # Create curl command line relating to service.
        case ${1} in
                ftp)
                curl_cmd="${opts} --ftp-skip-pasv-ip \
                --user ${userid}:${password} ftp://${server}:${port}"
                ;;
                ftps)
                curl_cmd="${opts} --ftp-ssl-control -k -v --ftp-ssl \
                --user ${userid}:${password} ftps://${server}:${port}"
                checkCacert
                ;;
                wftps)
                curl_cmd="${opts} --ftp-ssl-reqd --cacert ${CACERT} \
                --user ${userid}:${password} ftp://${server}:${port}"
                checkCacert
                ;;
                *)
                message="Job ${jobid} Terminated Unknown transport method : ${1}"
                logerror $message
                print "Job Terminated."
                exit 1
                ;;
        esac
}

#
# Function:-    checkCacert
# Parameters:-  None
#
# Check that the named cacert fil exists.
#
checkCacert() {
        # Check for debug requirement
        debug checkCacert && set -x

        if [[ ! -s ${CACERT} ]] ; then
                message="Job ${jobid} Terminated o certificate file available for ftps."
                logerror $message
                print "Job Terminated."
                exit 1
        fi
}

#
# Function:-    retrieveFiles
# Parameters:-  None
#
# Retrieve the files from the remote host.
#
retrieveFiles() {
        # Check for debug requirement
        debug retrieveFiles && set -x

        # Move to local destination.
        if [[ -d ${local} ]] ; then
                cd ${local}
        else
                message="Job ${jobid} Terminated Local destination directory does not exist:${local}"
                logerror $message
                print "Job Terminated."
                exit 1
        fi

        # Create temporary file for any errors.
        curl_err=`mktemp ${CURL_TMP}/error.XXXXXX`

        # Retrieve files, check sizes and then remove remote copy.
        print "\nRetieving files.\n${LOGLINE}"
        echo "${remote_file_list}" | \
        while read r_size r_file ; do
                ${CURL} -O ${curl_cmd}/${remote}/"${r_file}" 2>${curl_err}
                if [[ $? -eq 0 ]] ; then
                        l_size=$(ls -l "${r_file}" | awk '{print $5}')
                        if [[ ${l_size} -eq ${r_size} ]] ; then
                                print "Received File : ${r_file}"
                                backupRemoveRemoteFile ${r_file}
                        else
                                print "\n\tFile Received : ${r_file}"
                                print "\n\tFile size incorrect : ${l_size}"
                                print "\n\tFile size should be : ${r_size}"
                        fi
                else
                        print "File transfer failed for : ${r_file}"
                        cat ${curl_err}
                fi
        done

        # Tidy up temporary files.
        rm ${curl_err}
}

#
# Function:-    backupRemoveRemoteFile
# Parameters:-  $1 Remote file name
#
# Remove the remote file name.
#
backupRemoveRemoteFile() {
        # Check for debug requirement
        debug backupRemoveRemoteFile && set -x

        # Create temporary files for remote file list and any errors.
        curl_tmp1=`mktemp ${CURL_TMP}/remote.XXXXXX`
        curl_err1=`mktemp ${CURL_TMP}/error.XXXXXX`

        if [[ "${retain}" = "delete" ]] ; then
                # Delete remote file.
                ${CURL} -o ${curl_tmp1} -Q "CWD ${remote}" -X "DELE ${r_file}" ${curl_cmd} 2>${curl_err1}
                RETURN=$?
               if [[ ${RETURN} -ne 0 && ${RETURN} -ne 19 ]] ; then
                        print "FAILED to delete remote file : ${r_file}"
                        cat ${curl_err1} ${curl_tmp1}
                else
                        print "File removed from remote server."
                fi
        elif [[ "${retain}" = "retain" ]] ; then
                # Create the backup directory if it does not exist.
                if [[ "${backup}" != "BACKUP" ]] ; then
                        # Create the backup directory BACKUP if required.
                        ${CURL} -o ${curl_tmp1} -Q "CWD ${remote}" -Q "-MKD BACKUP" ${curl_cmd} 2>${curl_err1}
                        if [[ $? -ne 0 ]] ; then
                                print "Failed to create the backup directory: BACKUP"
                                cat ${curl_err1} ${curl_tmp1}
                        fi
                        cat /dev/null > ${curl_err1}
                        cat /dev/null > ${curl_tmp1}
                fi

                # Backup the remote file.
                ${CURL} -o ${curl_tmp1} -Q "-RNFR ${remote}/${r_file}" -Q "-RNTO ${remote}/BACKUP/${r_file}" ${curl_cmd} 2>${curl_err1}
                if [[ $? -ne 0 ]] ; then
                        print "Failed to move '${r_file}' to backup directory: BACKUP"
                        cat ${curl_err1} ${curl_tmp1}
                else
                        print "File moved to backup directory: BACKUP"
                fi
        fi

        # Tidy up temporary files.
        rm ${curl_err1} ${curl_tmp1}
}

#
# Function:-    sendFiles
# Parameters:-  None
#
# Check that the local and remote diretories exist and then send files
# found in the local directory.
#
sendFiles() {
        # Check for debug requirement
        debug sendFiles && set -x

        # Create the curl command to use. It is placed in ${curl_cmd}.
        curlConnect ${type}

        # Create temporary files for remote file list and any errors.
        curl_tmp=`mktemp ${CURL_TMP}/remote.XXXXXX`
        curl_err=`mktemp ${CURL_TMP}/error.XXXXXX`

        ${CURL} -o ${curl_tmp} ${curl_cmd}/${remote} 2>${curl_err}
        if [[ $? -ne 0 ]] ; then
                message="Job ${jobid} terminated getting remote destination directory:${remote}"
                logerror $message
                cat ${curl_tmp1} ${curl_err}
                print "Job Terminated."
                rm ${curl_tmp1} ${curl_err}
                exit 1
        fi

        # Move to local destination.
        if [[ -d ${local} ]] ; then
                cd ${local}
        else
                message="Job ${jobid} Terminated Local source directory does not exist:${local}"
                logerror $message
                print "Job Terminated."
                exit 1
        fi

        # Initialise temporary files.
        cat /dev/null > ${curl_tmp}
        cat /dev/null > ${curl_err}

        # Send files, check sizes and then remove local copy.
        print "\nSending files.\n${LOGLINE}"

        echo "${local_file_list}" | \
        while read l_size l_file ; do
                # Send file
                ${CURL} -T "${l_file}" ${curl_cmd}/${remote} 2>${curl_err}
                if [[ $? -eq 0 ]] ; then
                        # Get size of remote file.
                        ${CURL} -o ${curl_tmp} -I ${curl_cmd}/${remote}/"${l_file}" 2>${curl_err}
                        cat ${curl_tmp}
                        r_size=$(cat ${curl_tmp} | awk '/Content/ {print $2}' | tr -d \\015) 
                        echo "RSize: ${r_size}"
                        echo "LSize: ${l_size}"
                        # Check sizes are equal and remove or backup local file.
                        if [[ ${l_size} -eq ${r_size} ]] ; then
                                print "Sent File : ${l_file}"
                                backupRemoveLocalFile
                        else
                                print "\n\tFile Sent : ${l_file}"
                                print "\n\tFile size incorrect : ${r_size}"
                                print "\n\tFile size should be : ${l_size}"
                        fi
                else
                        print "File transfer failed for : ${l_file}"
                        cat ${curl_tmp} ${curl_err}
                fi
        done

        # Remove temporary files.
        #rm ${curl_tmp} ${curl_err}
}

#
# Function:-    backupRemoveLocalFile
# Parameters:-  None
#
# Depending on the value of ${retain} remove the local file or place it in the
# backup directory.
#
backupRemoveLocalFile() {
        # Check for debug requirement
        debug sendFiles && set -x

        if [[ "${retain}" = "delete" ]] ; then
                if rm ${local}/"${l_file}" ; then
                        print "File removed from local server."
                else
                        print "Failed to delete local file : ${l_file}"
                fi
        elif [[ "${retain}" = "retain" ]] ; then
                [[ ! -d ${local}/BACKUP ]] && mkdir ${local}/BACKUP
                if mv ${local}/"${l_file}" ${local}/BACKUP/ ; then
                        print "File moved to BACKUP directory on local server."
                else
                        print "Failed to move file to BACKUP directory on local server."
                fi
        else
                message="Job ${jobid} Terminated Invalid prameter specified for 'Retain': ${retain}"
                logerror $message
                exit 1
        fi
}

################################################################################
#
# Main Section
#
################################################################################

# Log all output from the script to ${LOGFILE}
# Comment out the line below if you want output to go to the screen.
exec >> ${LOGFILE} 2>&1

print "\n${LOGLINE}\nSTART : `date`\n${LOGLINE}"

# Check that we have the required job file.
checkJobsFile

# Check the job number.
checkJob $1

# Get job parameters.
getJob $1

# Make sure that ${CURL_TMP} exists.
if [[ ! -d ${CURL_TMP} ]] ; then
        mkdir -p ${CURL_TMP}
fi

# Are we pushing or pulling?
if [[ "${direction}" = "pull" ]] ; then
        getRemoteFileList
        if [[ "${remote_file_list}" = "" ]] ; then
                print "No files to retrieve."
        else
                retrieveFiles
        fi
elif [[ "${direction}" = "push" ]] ; then
        getLocalFileList ${local}
        if [[ "${local_file_list}" = "" ]] ; then
                print "No files to transfer."
        else
                sendFiles
        fi
else
        message="Invalid parameter : ${direction}"
        logerror $message
        print "Job ${jobid} Terminated The direction parameter must be push or pull.\n"
        print "Job Terminated."
        exit 1
fi

if ! [[ -f ${CURL_TMP}/OK_${jobid} ]]; then
        print "$(date): OK: ${0##*/}: Job $jobid" >> $LOGTICKETFILE
        touch ${CURL_TMP}/OK_${jobid}
fi
print "\n${LOGLINE}\nFINISH: `date`\n${LOGLINE}"
