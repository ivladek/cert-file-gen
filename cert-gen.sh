#!bash

CONFIGfile=cert-gen.config
CONFIGfields="COUNTRYname LOCALITYname ORGname SERVICEbase SERVICEdescr SERVICEname"

echo -e "\n\nscrpt to generate certificate store files\n"

exit_script() {
	echo -e "\n\nscript with exit code $1"
	echo -e "\nusage:"
	echo -e "  $0 SERVICEname=\"fqdn\" SERVICEdescr=\"description\""
	echo -e "\nexit codes:"
	echo -e "\t 0 - success"
	echo -e "\t10 - not enough arguments"
	echo -e "\t20 - error in config file \"$CONFIGfile\""
	echo -e "\t30 - arguments are not confirmed"
	exit $1
}

SERVICEname=""
SERVICEdescr=""
for ScriptArg in "$@"; do
   KeyName=$(echo $ScriptArg | cut -f1 -d=)
   KeyValuePos=${#KeyName}+1
   KeyValue="${ScriptArg:$KeyValuePos}"
   export "$KeyName"="$KeyValue"
done

if [ -z "$SERVICEname" ] || [ -z "$SERVICEdescr" ]; then exit_script 10; fi

. $CONFIGfile

echo -e "\nCertificate data:"
for ConfigVar in $CONFIGfields; do
	echo -e "\t$ConfigVar = ${!ConfigVar}"
	if [ -z "$ConfigVar" ]; then exit_script 20; fi
done

read -p $'\nIs everything ok ? [print YES to continue] ' toContinue
if [ "$toContinue" != "YES" ]; then exit_script 30; fi

echo -e "\n\nYou are confirmed all input data for certificate generation"
echo -e "Certificate config file content:"
printf -- '-%.0s' {1..50}; printf "\n"
echo "$CERTcfgFile"
printf -- '-%.0s' {1..50}; printf "\n"

echo -e "\n\nall done. bye\n"
exit 0
