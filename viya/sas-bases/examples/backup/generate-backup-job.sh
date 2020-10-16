#!/bin/bash

set -e
TYPE_ADHOC=adhoc
TYPE_SCHEDULED=scheduled
TYPE_SCAN=scan
SUFFIX=`head /dev/urandom | tr -dc a-z0-9 | head -c 8`
JOB_TYPE=$1

if [[ ${TYPE_ADHOC} == ${JOB_TYPE} ]]; then

  JOB_NAME=sas-adhoc-backup-$SUFFIX
  JOB_TEMPLATE_FILE_NAME=sas-adhoc-backup-job-template.yaml
  sed -e "s%{{ JOB_NAME }}%${JOB_NAME}%" ${JOB_TEMPLATE_FILE_NAME} > ${JOB_NAME}.yaml

elif [[ ${TYPE_SCHEDULED} == ${JOB_TYPE} ]]; then

  CRON_EXPRESSION=$2
  if [[ -z "${CRON_EXPRESSION}" ]]; then

    echo 'ERROR: Cron expression cannot be empty!'
    echo 'Command to generate scheduled backup job is:'
    echo './generate-backup-job.sh scheduled "<cron expression>"'
    exit 1

  fi

  JOB_NAME=sas-scheduled-backup-$SUFFIX
  JOB_TEMPLATE_FILE_NAME=sas-scheduled-backup-job-template.yaml

  sed -e "s%{{ JOB_NAME }}%${JOB_NAME}%" -e "s%{{ SCHEDULE_CRON_EXPR }}%${CRON_EXPRESSION}%" ${JOB_TEMPLATE_FILE_NAME} > ${JOB_NAME}.yaml

elif [[ ${TYPE_SCAN} == ${JOB_TYPE} ]]; then

  USER=$2
  if [[ -z "${USER}" ]]; then

    echo 'ERROR: User value cannot be empty! Enter SASAdministrator LDAP user name stored in credentials'
    echo 'Command to generate scan job is:'
    echo './generate-backup-job.sh scan "<user>" "<compare>"'
    exit 1

  fi

  COMPARE=$3
  if [[ ! -z "${COMPARE}" && ${COMPARE} != "3" &&  ${COMPARE} != "4" ]]; then

  echo 'ERROR: Invalid compare value! Valid values are "3", "4" or empty.'
  echo 'Command to generate scan job is:'
  echo './generate-backup-job.sh scan "<user>" "<compare>"'

  exit 1

  fi

  JOB_NAME=sas-scan-job-$SUFFIX
  JOB_TEMPLATE_FILE_NAME=sas-scan-job-template.yaml
  sed -e "s%{{ JOB_NAME }}%${JOB_NAME}%" -e "s%{{ USER }}%${USER//%/\\%}%" -e "s%{{ COMPARE }}%${COMPARE}%" ${JOB_TEMPLATE_FILE_NAME} > ${JOB_NAME}.yaml

else

  echo 'ERROR: Invalid command!'
  echo 'Allowed commands:'
  echo './generate-backup-job.sh adhoc'
  echo './generate-backup-job.sh scheduled "<cron expression>"'
  echo './generate-backup-job.sh scan "<user>" "<compare>"'
  exit 1

fi
echo "Manifest file ${JOB_NAME}.yaml generated."