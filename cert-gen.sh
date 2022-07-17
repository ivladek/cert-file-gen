#!/bin/bash

# v2.0 17.07.2022
# Script to generate certificate request and pack results to common formats
# usage without any restrictions
# created by Vladislav Kirilin, ivladek@me.com

CERTparams=(\
	CERTstore\
	CERTpwd\
	CERTcountry\
	CERTlocality\
	CERTorg\
	CERTservice\
	CERTfqdn\
)

CERTparams_sample=(\
	"~/Documents/certs"\
	"certST0RE+sample#pass!"\
	"RU"\
	"Moscow"\
	"BiTime LLC"\
	"CloudInside Service Provider. Mail Server"\
	"mail.cloudinside.net"\
)

EXITcodes=(\
	"success"\
	"not enough arguments"\
	"certificate parameters are not confirmed"\
	"certificate store path is not accessible"\
)

CERTstore_testfile="cert_store_test_file"


RUNpath=$(pwd)
ParamMaxLen=0
for param in ${CERTparams[@]}; do (( ${#param} > $ParamMaxLen )) && ParamMaxLen=${#param}; done


gen_FILEcfg () {
echo "
[ req ]
default_bits = 2048
default_keyfile = cert.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth

[ req_distinguished_name ]
countryName = $CERTcountry
localityName = $CERTlocality
stateOrProvinceName = $CERTlocality
organizationName = $CERTorg
organizationalUnitName = $CERTservice
commonName = $CERTfqdn
" > "$1"
}

show_FILE () {
	echo -e "\n\033[4m\"$1\"\033[0m"
	cat "$1"
	printf '^%.0s' {1..75}; printf "\n"
}

exit_script() {
	echo -e "\nusage: $0 [parameters]"
	echo -e "sample parameters (all are required):"
	for i in ${!CERTparams[@]}; do printf "\t%-${ParamMaxLen}s = \"%-s\"\n" "${CERTparams[$i]}" "${CERTparams_sample[$i]}"; done
	echo -e "exit codes:"
	for i in ${!EXITcodes[@]}; do
		if [[ $i == $1 ]]; then printf "\033[1m\033[5m"; fi
		echo -e "\t$i: ${EXITcodes[$i]}"
		if [[ $i == $1 ]]; then printf "\033[0m"; fi
	done
	cd $RUNpath
	exit $1
}


echo -e "\n\nscrpt to generate certificate store files\n"


echo -e "\nread command line paramenters"
for param in "$@"; do
	KeyName=$(echo $param | cut -f1 -d=)
	KeyValuePos=${#KeyName}+1
	KeyValue="${param:$KeyValuePos}"
	export "${KeyName}"="$KeyValue"
done
echo -e "\033[2mok\033[0m"


echo -e "\ncheck command line paramenters"
EXITcode=0
for param in ${CERTparams[@]}; do
	if [ -n "${!param}" ]
	then
		printf "\t%-${ParamMaxLen}s = \"%-s\"\n" "${param}" "${!param}"
	else
		echo -e "\033[1m\033[5m\t${param}: not defined\033[0m"
		EXITcode=1
	fi
done
if [[ $EXITcode > 0 ]]; then exit_script $EXITcode; fi
echo -e "\033[2mok\033[0m"


read -p $'\nIs everything ok ? [print YES to continue] ' toContinue
if [ "$toContinue" != "YES" ]; then exit_script 2; fi
echo -e "\033[2mYou are confirmed all data needed for certificate generation\033[0m"


echo -e "\ncheck directory for storing certificates"
if [[ ${CERTstore::1} == "~" ]]; then CERTstore="$(cd; pwd)${CERTstore:1}"; fi
CERTstore="${CERTstore%/}/$CERTfqdn"
if [ -f "$CERTstore" ]
then
	echo -e "\t\033[1m\033[5m$\"CERTstore\" is a file\033[0m"
	exit_script 3
fi
if [ -d "$CERTstore" ]
then
	echo -e "\t\033[2mdirectory \"$CERTstore\" exists\033[0m"
else
	mkdir -p "$CERTstore"
	if [[ $? != 0 ]]
	then
		echo -e "\t\033[1m\033[5mcan not create \"$CERTstore\"\033[0m"
		exit_script 3
	fi
	echo -e "\t\033[2mdirectory\"$CERTstore\" created\033[0m"
fi
cd "$CERTstore"
CERTstore=$(pwd)
echo -e "\t\033[1mabsolute path is \"$CERTstore\"\033[0m"
if [ -f "$CERTstore/$CERTstore_testfile" ]
then
	rm -f "$CERTstore/$CERTstore_testfile"
	if [[ $? != 0 ]]
	then
		echo -e "\t\033[1m\033[5mcan not delete test file \"$CERTstore/$CERTstore_testfile\"\033[0m"
		exit_script 3
	fi
	echo -e "\t\033[2mtest file \"$CERTstore/$CERTstore_testfile\" deleted\033[0m"
fi	
touch "$CERTstore/$CERTstore_testfile"
if [[ $? != 0 ]]
then
	echo -e "\t\033[1m\033[5mcan not create test file \"$CERTstore/$CERTstore_testfile\" is a file\033[0m"
	exit_script 3
fi	
echo -e "\t\033[2mtest file \"$CERTstore/$CERTstore_testfile\" created\033[0m"
rm -f "$CERTstore/$CERTstore_testfile"
if [[ $? != 0 ]]
then
	echo -e "\t\033[1m\033[5mcan not delete test file \"$CERTstore/$CERTstore_testfile\"\033[0m"
	exit_script 3
fi	
echo -e "\t\033[2mtest file \"$CERTstore/$CERTstore_testfile\" deleted\033[0m"
if [ "$(ls -A .)" ]
then
	echo -e "\t\033[1m\033[5mdirectory \"$CERTstore\" is not empty\033[0m"
	exit_script 3
fi
echo -e "\t\033[2mdirectory \"$CERTstore\" is empty\033[0m"
echo -e "\033[2mok\033[0m"


echo -e "\ncreate certificate config file"
FILEcfg="$CERTstore/$CERTfqdn.cfg"
gen_FILEcfg "$FILEcfg"
show_FILE "$FILEcfg"
echo -e "\033[2mok\033[0m"

echo -e "\ncreate certificate config file"
echo -e "\033[2mok\033[0m"


echo -e "\n\nall done. bye\n"
cd $RUNpath
exit 0
