#!/bin/bash

# v05.01.03 23.07.2022
# Script to generate certificate request and pack results to common formats
# usage without any restrictions
# created by Vladislav Kirilin, ivladek@me.com

KEYlen=4096
CERTdays=5000

CERTparams1=(
	CERTmode
	CERTstore
	CERTfqdn
)

CERTparams2=(
	CERTpwd
	CERTcountry
	CERTlocality
	CERTorg
	CERTservice
)

CERTfields=(
	"Subject:"
	"Not Before"
	"Not After"
	" bit"
)

CERTparams_sample=(
	"CSR EXT SELF"
	"~/Documents/certs"
	"certST0RE+sample#pass!"
	"KZ"
	"Almaty"
	"BiTime LLC"
	"CloudInside Service Provider. Mail Server"
	"mail.cloudinside.net"
)

EXITcodes=(
	"[00] success"
	"[01] certificate parameters are not confirmed"
	"[02] certificate store path is not accessible"
	"[03] exit to wait for passing certificate request to CA and getting certificate"
	"[04] certificate is not valid"
	"[05] chain is not valid"
	"[06] certificate does not match key"
	"[07] private key must not exists for EXT mode"
	"[08] certificate request must not exists for EXT mode"
	"[09] password does not defined for EXT mode"
	"[10] unknown mode"
	"[11] certificate directory must be empty"
)

RUNpath=$(pwd)
ParamMaxLen=0
for param in ${CERTparams1[@]} ${CERTparams2[@]}; do (( ${#param} > $ParamMaxLen )) && ParamMaxLen=${#param}; done


gen_FILEcfg () {
echo "
[ req ]
default_bits = $KEYlen
default_keyfile = private.key
distinguished_name = req_distinguished_name
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
	echo -e "\n\033[2m\033[4m$1\033[0m\033[2m"
	cat "$1"
	printf "^%.0s" {1..64}
	echo -e "\033[0m\n"
}

exit_script() {
	echo -e "\nusage: $RUNpath/$(basename "$0") [parameters]"
	cd "$RUNpath"
	echo -e "parameters:"
	for param in ${CERTparams1[@]} ${CERTparams2[@]}; do printf "\t%-${ParamMaxLen}s = \033[2m\"%-s\"\033[0m\n" "$param" "${!param}"; done
	echo -e "CERTmode:"
	echo -e "\tCSR: you provide data for request and post CSR to external CA"
	echo -e "\t\treqired for STEP1: all above"
	echo -e "\t\treqired for STEP2: ${CERTparams1[@]}"
	echo -e "\tEXT: external CA provides all data, including CSR and private key"
	echo -e "\t\treqired: ${CERTparams1[@]} CERTpwd"
	echo -e "\tSELF: self-signed sertificate"
	echo -e "\t\treqired: all above"

	echo -e "exit codes:"
	for i in ${!EXITcodes[@]}; do
		if [[ $i == $1 ]]
			then echo -e "\t\033[1m\033[5m${EXITcodes[$i]}\033[0m"
			else echo -e "\t${EXITcodes[$i]}"
		fi
	done
	chmod -R 400 ${CERTstore/ /\\ /}/*
	chmod 500 ${CERTstore/ /\\ /}
	cd $RUNpath
	echo -e "\nbye"
	exit $1
}


echo -e "\n\n\033[1m\033[4mScript paramaters inittialisation\033[0m"


echo -e "\033[2mparameters read from command line\t\033[0m"
for param in "$@"; do
	KeyName=$(echo $param | cut -f1 -d=)
	KeyValuePos=${#KeyName}+1
	KeyValue="${param:$KeyValuePos}"
	export "${KeyName}"="$KeyValue"
	printf "\t\033[2m%-${ParamMaxLen}s: \"%-s\"\033[0m\n" "$KeyName" "${!KeyName}"
done
echo -e "\033[2mok\033[0m"


CERTmode=$(echo $CERTmode | tr '[:lower:]' '[:upper:]')
echo -e "\n\033[4mScript mode is $CERTmode\033[0m"
if [[ "$CERTmode" == "CSR" ]];    then echo -e "\033[2mprepare request, send to external CA and generate all files\033[0m"
elif [[ "$CERTmode" == "EXT" ]];  then echo -e "\033[2mall data receiving from external service in text format, usual via email\033[0m"
elif [[ "$CERTmode" == "SELF" ]]; then echo -e "\033[2mself signed from provided data\033[0m"
else exit_script 10; fi


echo -e "\n\033[2mcheck directory for certificate store\033[0m"
for param in ${CERTparams1[@]}; do if [ ! -n "${!param}" ]; then read "please define \"$param\" " ${param}; fi; done
CERTstore="${HOME}/${CERTstore#"~/"}"
STOREpath=$(dirname "$CERTstore")
STOREname=$(basename "$CERTstore")
for store in STOREpath STOREname CERTfqdn; do mkdir -p "${!store}"; cd "${!store}"; if [[ $? != 0 ]]; then exit_script 2; fi; done
CERTstore="$(pwd)"
CERTbase="$CERTstore/$CERTfqdn"
echo -e "\t\033[2mcurrent directory now is \"$CERTbase\"\033[0m"
chmod 755 ${CERTstore/ /\\ /}
if [[ $? != 0 ]]; then exit_script 2; fi
chmod -R 400 ${CERTstore/ /\\ /}/*
if [[ $? != 0 ]]; then exit_script 2; fi
echo -e "\033[2mok\033[0m"


if [[ "$CERTmode" == "EXT" && ! -f "$CERTbase.enc" ]]
then
	echo -e "\033[2mEXT mode\033[0m"
	if [[ -z $CERTpwd ]]; then exit_script 9; fi
	echo -e "\t\033[2mpassword saving to \"$CERTbase.enc\"\033[0m"
	echo "$CERTpwd" > "$CERTbase.enc"
	if [[ $? != 0 ]]
	then
		echo -e "\t\033[1m\033[5mcan not write password to file\033[0m"
		exit_script 2
	fi	
	echo -e "\033[2mok\033[0m"
fi


CERTstep=0
if [[ ! -f "$CERTbase.csr" && "$CERTmode" != "EXT" ]]
then #step 1 of 1
	CERTstep=1
	echo -e "\n\033[1m\033[4mSTEP 1/2 - certificate request generation\033[0m"

	echo -e "\033[2mcheck command line parameters\033[0m"
	for param in ${CERTparams2[@]}; do while [[ -z ${!param} ]]; do read "please define \"$param\" " ${param}; done; done
	echo -e "\nplease confirm command line parameters"
	for param in ${CERTparams1[@]} ${CERTparams2[@]}; do printf "\t%-${ParamMaxLen}s = \"%-s\"\n" "$param" "${!param}"; done
	read -p $'\ntype YES to continue ' toContinue
	if [ "$toContinue" != "YES" ]; then exit_script 1; fi
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mcheck destination directory \"$CERTstore\"\033[0m"
	if [ "$(ls -A .)" ]; then exit_script 11; fi
	echo -e "\t\033[2mok\033[0m"

	echo -e "\033[2msave encryption password to file \"$CERTbase.enc\"\033[0m"
	echo "$CERTpwd" > "$CERTbase.enc"
	if [[ $? != 0 ]]; then exit_script 2; fi	
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mgenerate certificate config file \"$CERTbase.cfg\"\033[0m"
	gen_FILEcfg "$CERTbase.cfg"
	show_FILE "$CERTbase.cfg"
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mgenerate certificate request file \"$CERTbase.csr\"\033[0m"
	openssl req -new -nodes -config "$CERTbase.cfg" -keyout "$CERTbase.key" -out "$CERTbase.csr"
	openssl rsa -aes256 -in "$CERTbase.key" -out "$CERTbase.key" -passout file:"$CERTbase.enc"
	show_FILE "$CERTbase.csr"
	echo -e "\033[2mok\033[0m"

	if (( "$CERTmode" != "SELF" )); then exit_script 3; fi
fi


if [[ ! -f "$CERTbase.cer" ]] && [[ "$CERTmode" == "EXT" || (($CERTstep == 0)) && -f "$CERTbase.csr" ]]
then # STEP 2 of 2
	CERTstep=2
	echo -e "\n\033[1m\033[4mSTEP 2/2 - certificate stores generation\033[0m"

	if [[ "$CERTmode" == "EXT" ]]
	then
		echo -e "\033[2mcheck for mode EXT - when all data provided by external service\033[0m"
		if [[ -f "$CERTbase.key" ]]
		then
			read -p $'\nEXT MODE but private key exists ! Would you overwrite .key file ?  [type YES to continue] ' toContinue
			if [ "$toContinue" != "YES" ]; then exit_script 7; fi
			rm "$CERTbase.key"
		fi
		echo -e "\t\033[2mprivate key does not exist - ok for EXT mode\033[0m"
		if [[ -f "$CERTbase.csr" ]]
		then
			read -p $'\nEXT MODE but certificate request exists ! Would you overwrite .csr file ?  [type YES to continue] ' toContinue
			if [ "$toContinue" != "YES" ]; then exit_script 7; fi
			rm "$CERTbase.csr"
		fi
		echo -e "\t\033[2mcertificate request does not exist - ok for EXT mode\033[0m"
		echo -e "\033[2mok\033[0m"
	fi

	echo -e "\nPlease paste here content of email(s) ond/or file(s) with cetificates including chain"
	echo -e "For finish type \033[1m\033[5m...\033[0m in a new line and press ENTER\033[2m"
	WRITEcer=false
	WRITEkey=false
	WRITEcsr=false
	CERTfile[0]=0
	while [[ "$l" != "..." ]]
	do
		if [[ "$CERTmode" == "EXT" ]]
		then
			if [[ "$l" == "-----BEGIN CERTIFICATE REQUEST-----" ]]; then WRITEcsr=true; fi
			if $WRITEcsr; then echo "$l" >> "$CERTbase.csr"; fi
			if [[ "$l" == "-----END CERTIFICATE REQUEST-----" ]]; then WRITEcsr=false; fi
			if [[ "$l" == "-----BEGIN RSA PRIVATE KEY-----" ]]; then WRITEkey=true; fi
			if $WRITEkey; then echo "$l" >> "$CERTbase.key"; fi
			if [[ "$l" == "-----END RSA PRIVATE KEY-----" ]]; then WRITEkey=false; fi
		fi
		if [[ "$l" == "-----BEGIN CERTIFICATE-----" ]]; then WRITEcer=true; ((CERTfile[0]++)); CERTfile[${CERTfile[0]}]="$CERTbase.c${CERTfile[0]}"; fi
		if $WRITEcer; then echo "$l" >> "${CERTfile[${CERTfile[0]}]}"; fi
		if [[ "$l" == "-----END CERTIFICATE-----" ]]; then WRITEcer=false; fi
		read -r l
	done

	echo -e "\033[2mcertiticate data have been received\033[0m"
	echo -e "\t\033[2mcertificates count is ${CERTfile[0]}\033[0m"
	if (( ${CERTfile[0]} < 2 )); then exit_script 4; fi
	for c in $(seq 1 ${CERTfile[0]})
	do
		echo -e "\t\033[2mcertificate ${CERTfile[$c]}:\033[0m"
		CERTsubj[$c]="$(openssl   x509 -in "${CERTfile[$c]}" -noout -subject | sed 's/^subject= *//')"
		if (( $? != 0 )); then exit_script 4; fi
		CERTissuer[$c]="$(openssl x509 -in "${CERTfile[$c]}" -noout -issuer  | sed 's/^issuer= *//')"
		CERTvalid="$(openssl      x509 -in "${CERTfile[$c]}" -noout -enddate | sed 's/^notAfter=*//')"
		echo -e "\t\t\033[2msubject   : ${CERTsubj[$c]}\033[0m"
		echo -e "\t\t\033[2missuer    : ${CERTissuer[$c]}\033[0m"
		echo -e "\t\t\033[2mvalid thru: ${CERTvalid}\033[0m"
	done
	if [[ "$CERTmode" == "EXT" ]]
	then
		echo -e "\t\033[2mEXT mode: csr provided by external service\033[0m"
		CSRdata="$(openssl req -in "$CERTbase.csr" -x509 -key "$CERTbase.key" -text -noout)"
		for i in ${!CERTfields[@]}; do echo -e "\t\t\033[2m$(echo "$CSRdata" | grep "${CERTfields[$i]}" | awk '{$1=$1};1')\033[0m"; done
		echo -e "\t\033[2mEXT mode: private key provided by external service and encryped with provided password\033[0m"
		openssl rsa -in "$CERTbase.key" -out "$CERTbase.key" -aes256 -passout file:"$CERTbase.enc"
	fi
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mcertificates chain\033[0m"
	for c in $(seq 1 ${CERTfile[0]}); do CERTchild[$c]=0; CERTparent[$c]=0; done
	CERTcert=0
	CERTroot=0
	for c in $(seq 1 ${CERTfile[0]})
	do
		for c1 in $(seq 1 ${CERTfile[0]})
		do
			if [[ "${CERTsubj[$c]}" == "${CERTissuer[$c1]}" && (($c != $c1)) ]]
			then
				CERTchild[$c]=$c1
				CERTparent[$c1]=$c
			fi
		done
		if [[ "${CERTsubj[$c]}" == "${CERTissuer[$c]}" ]]; then CERTroot=$c; CERTparent[$c]=$c; fi
		if (( ${CERTchild[$c]} == 0 )); then CERTcert=$c; fi
	done
	for c in $(seq 1 ${CERTfile[0]}); do if (( ${CERTparent[$c]} * $CERTcert * $CERTroot == 0)); then exit_script 5; fi; done
	c=$CERTroot
	n=0
	CERTchain=""
	while (( $c != 0 ))
	do
		if (( $c == $CERTroot ))
		then
			printf  "\t\033[2m%-s\033[0m\n" "${CERTsubj[$c]}"
		else
			n=$((n + 4))
			printf  "\t\033[2m%-${n}s%-s\033[0m\n" " " "|"
			printf  "\t\033[2m%-${n}s%-s%-s\033[0m\n" " " "|-->${CERTsubj[$c]}"
		fi
		if (( ${CERTchild[$c]} == 0 ))
		then
			echo "$CERTchain" > "$CERTbase.chain"
			cat "${CERTfile[$c]}" > "$CERTbase.cer"
		fi
		CERTchain="$(cat "${CERTfile[$c]}")"$'\n'"$CERTchain"
		rm "${CERTfile[$c]}"
		c=${CERTchild[$c]}
	done
	echo "$CERTchain" > "$CERTbase.pem"
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mgenerated files:\033[0m"
	for e in cer chain pem; do echo -e "\t\033[2m\"$CERTbase.$e\"\033[0m"; done
	echo -e "\033[2mok\033[0m"

	echo -e "\033[2mcheck private key and certificate matching\033[0m"
	HASHkey=$(openssl  rsa -in "$CERTbase.key" -passin file:"$CERTbase.enc" -noout -modulus | openssl md5)
	HASHcer=$(openssl x509 -in "$CERTbase.cer"                              -noout -modulus | openssl md5)
	echo -e "\t\033[2mprivate key  hash is \"$HASHkey\"\033[0m"
	echo -e "\t\033[2mcertificate  hash is \"$HASHcer\"\033[0m"
	if [[ "$HASHkey" != "$HASHcer" ]]; then exit_script 6; fi
	echo -e "\033[2mok\033[0m"
elif [[ "$CERTmode" == "SELF" && ! -f "$CERTbase.cer" ]]
then
	CERTstep=2
	echo -e "\033[2generate self signed certificate \"$CERTbase.enc\"\033[0m"
	openssl x509 -req -in "$CERTbase.csr" -signkey "$CERTbase.key" -passin file:"$CERTbase.enc" -out "$CERTbase.cer" -days $CERTdays
	cp "$CERTbase.cer" "$CERTbase.pem"
	CERTdata="$(openssl x509 -in "$CERTbase.cer" -text -noout)"
	for i in ${!CERTfields[@]}; do echo -e "\t\t\033[2m$(echo "$CERTdata" | grep "${CERTfields[$i]}" | awk '{$1=$1};1')\033[0m"; done
	echo -e "\033[2mok\033[0m"
fi


if [[ (($CERTstep == 2)) && ! -f "$CERTbase.pfx" ]]
then
	echo -e "\033[2mcreating PKCS12 store\033[0m"
	openssl rsa -in "$CERTbase.key" -passin file:"$CERTbase.enc" -out "$CERTbase.temp"
	openssl pkcs12 -in "$CERTbase.pem" -inkey "$CERTbase.temp" -export -out "$CERTbase.pfx" -passout file:"$CERTbase.enc"
	rm "$CERTbase.temp"
	echo -e "\t\033[2m\"$CERTbase.pfx\" has been created\033[0m"
	echo -e "\033[2mok\033[0m"
fi


echo -e "\n\n\033[4mtarget directory \""$CERTstore"\" content\033[0m"
chmod -R 400 ${CERTstore/ /\\ /}/*
chmod 500 ${CERTstore/ /\\ /}
ls -lh "$CERTstore"


echo -e "\033[2mok\033[0m"
echo -e "\n\nall done. bye\n"
cd $RUNpath
exit 0
