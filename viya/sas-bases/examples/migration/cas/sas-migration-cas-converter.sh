#!/bin/bash

#
# sas-migration-cas-converter.sh - CAS Migration Conversion Utility
# 2020
#
# This script will take 3.x CAS Server definitions in as input, and
# produce k8s-compatible CAS CRs for Viya 4.

function echo_line()
{
    line_out="$(date) - $1"
    printf "%s\n" "$line_out"
}

version="1.3"

case "$1" in
        --version | -v)
                echo "${version}"
                exit
                ;;
        --help | -h)
                echo "Flags:"
                echo "  -h  --help     help"
                echo "  -f, --file     input file"
                echo "  -o, --output   output location"
                echo "  -v, --version  CAS Migration Conversion Utility version"
                exit
                ;;
esac

echo_line "_________________________________________________"
echo_line "| sas-migration-cas-converter.sh - start         |"
echo_line "|________________________________________________|"

# declaring a couple of associative arrays
declare -A arguments=();  
declare -A variables=();

# declaring an index integer
declare -i index=1;

variables["-o"]="output";  
variables["--output"]="output";  
variables["-f"]="file";  
variables["--file"]="file";

# $@ here represents all arguments passed in
for i in "$@"  
do  
  arguments[$index]=$i;
  prev_index="$(expr $index - 1)";

  # this if block does something akin to "where $i contains ="
  # "%=*" here strips out everything from the = to the end of the argument leaving only the label
  if [[ $i == *"="* ]]
    then argument_label=${i%=*} 
    else argument_label=${arguments[$prev_index]}
  fi

  exec 2> /dev/null
  # this if block only evaluates to true if the argument label exists in the variables array
  if [[ -n ${variables[$argument_label]} ]]
    then
        # dynamically creating variables names using declare
        # "#$argument_label=" here strips out the label leaving only the value
        if [[ $i == *"="* ]]
            then declare ${variables[$argument_label]}=${i#$argument_label=} 
            else declare ${variables[$argument_label]}=${arguments[$index]}
        fi
  fi
  exec 2> /dev/tty

  index=index+1;
done;

echo_line "file = $file"

if [ ! -f ${file} ]; then
    echo "File not found: ${file}"
    exit
fi

if [ ! -z "${output}" ]; then
    echo_line "output = $output"
fi
echo_line "reading intput from $file"
input="$file"
while IFS= read -r line
do
  echo_line "$line"
done < "$input"

echo_line "input complete"

echo_line "sourcing yaml.sh"
source yaml.sh

# Debug
DEBUG="$1"

function is_debug() {
    [ "$DEBUG" = "--debug" ] && return 0 || return 1
}

echo_line "running parse_yaml against $1..."
parse_yaml $file && echo

# Execute
echo_line "running create_variables..."
create_variables $file

if [[ "${hasBackupController}" == "false" ]]; then
    backupControllers=0 
elif [[ "${hasBackupController}" == "true" ]]; then
    backupControllers=1
else
    backupControllers="0"
fi

echo_line "backupControllers = $backupControllers"
echo_line "numberOfNodes = $numberOfNodes"

numberOfNodes="$((numberOfNodes-1-backupControllers))"

if [ ! -z "${output}" ]; then
    echo_line "copy the cr template to $output"
    output=$output"/"
    #echo_line "fixed output = $output"
    
                  if [ -d "${output}/cas-components" ]; then
    echo ""
    while true; do
        read -p "Content already exists in the specified output location.  Continuing will overwrite the existing content.  Do you want to continue? (y/n) " yn
        case $yn in
            [Yy]* ) make install; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    fi

    if [ ! -d "$output" ]; then
        echo "output directory does not exist: ${output}"
        echo "creating directory: ${output}"
        mkdir -p ${output}
    fi
    
    cp cas-cr-template.yaml.orig ${output}${casServer}-migration-cr.yaml
    cp kustomization.yaml ${output}kustomization.yaml
    cp -R cas-components ${output}

else
    echo_line "copy the cr template"
    cp cas-cr-template.yaml.orig ${casServer}-migration-cr.yaml
fi

echo_line "Converting $file into ${casServer}-migration-cr.yaml..."
echo_line ".................."

sed -i "s/\${casServer}/\"${casServer}\"/" ${output}${casServer}-migration-cr.yaml
sed -i "s/\${deploymentType}/\"${deploymentType}\"/" ${output}${casServer}-migration-cr.yaml
sed -i "s/\${hasBackupController}/\"${hasBackupController}\"/" ${output}${casServer}-migration-cr.yaml

sed -i "s/\${casServerVirtualPath}/\"${casServer}-http\"/" ${output}${casServer}-migration-cr.yaml

sed -i "s/\${numberOfNodes}/${numberOfNodes}/" ${output}${casServer}-migration-cr.yaml

sed -i "s/\${backupControllers}/${backupControllers}/" ${output}${casServer}-migration-cr.yaml

sed -i "s/\${_memTotal_KB}/\"${_memTotal_KB}Ki\"/" ${output}${casServer}-migration-cr.yaml
sed -i "s/\${_cpus}/\"${_cpus}000m\"/" ${output}${casServer}-migration-cr.yaml

permStoreLocation_escaped_path=$(echo ${permStoreLocation} | sed 's_/_\\/_g')
sed -i "s/\${permStoreLocation}/\"${permStoreLocation_escaped_path}\"/" ${output}${casServer}-migration-cr.yaml

#echo "casDataDir = ${casDataDir}"
casDataDir_escaped_path=$(echo ${casDataDir} | sed 's_/_\\/_g')
#echo "casDataDir_escaped_path = $casDataDir_escaped_path"
sed -i "s/\${casDataDir}/\"${casDataDir_escaped_path}\"/" ${output}${casServer}-migration-cr.yaml

echo_line "_________________________________________________"
echo_line "| sas-migration-cas-converter.sh - complete!     |"
echo_line "|________________________________________________|"

exit 0