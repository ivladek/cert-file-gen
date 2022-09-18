#!/bin/bash

# v06.10.00 18.09.2022
# Script to generate certificate request and pack results to common formats
# usage without any restrictions
# created by Vladislav Kirilin, ivladek@me.com



# ======= DATA BLOCK begin =======

# required parameters
CERTparams1=(
	CERTmode
	CERTstore
	CERTfqdn
	CERTpwd
)

# parameters required only for certificate request generation
CERTparams2=(
	CERTcountry
	CERTlocality
	CERTorg
	CERTservice
)

# optional parameters
CERTparams3=(
	KEYlen
	CERTdays
)

# sample values for script parameters
CERTparams_sample=(
	"CSR EXT SELF"
	"~/Documents/cert store"
	"mail.cloudinside.net, post.cloudinside.net"
	"certST0RE+sample#pass!"
	"KZ"
	"Almaty"
	"BiTime LLC"
	"CloudInside Service Provider. Mail Server"
	"4096"
	"5000"
)

# script exit codes
EXITcodes=(
	"[00] success"
	"[01] certificate parameters are not confirmed"
	"[02] certificate store path is not accessible"
	"[03] exit to wait for passing certificate request to CA and getting certificate"
	"[04] not enough certificates in chain"
	"[05] chain is not valid"
	"[06] certificate does not match key"
	"[07] private key does not exist"
	"[08] certificate request must not exists for EXT mode"
	"[09] certificate already exits"
	"[10] unknown scrpt mode"
	"[11] certificate directory is not empty"
	"[12] not enough parameters"
)

# internal data for certificates processing
CERTfields=(
	"Subject:"
	"Not Before"
	"Not After"
	" bit"
)


# max length of parameter name calculation
ParamMaxLen=0
for param in ${CERTparams1[@]} ${CERTparams2[@]} ${CERTparams3[@]}; do (( ${#param} > $ParamMaxLen )) && ParamMaxLen=${#param}; done

# ======= DATA BLOCK end =======



# ======= FUNCTIONS BLOCK begin =======

# csr generation
gen_FILEcfg () {
	echo -n "[ req ]
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
commonName = $CERTfqdn" > "$CERTbase.cfg"
	[[ "$CERTmode" == "SELF" ]] && (echo -n "subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints       = CA:TRUE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
issuerAltName          = issuer:copy" > "$CERTbase.ext")
	if [[ ${#CERTsan[@]} > 1 ]]
	then
		[[ "$CERTmode" == "SELF" ]] && (echo -n "
subjectAltName         = DNS:$CERTfqdn" >> "$CERTbase.ext")
		[[ "$CERTmode" != "SELF" ]] && (echo -n "

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]" >> "$CERTbase.cfg")
		for i in $(seq 1 ${#CERTsan[@]})
		do
			if [[ "$CERTmode" == "SELF" ]]
			then ([[ ${CERTsan[$i]} ]] && echo -n ", DNS:${CERTsan[$i]}" >> "$CERTbase.ext")
			else echo -e -n "\nDNS.$i = ${CERTsan[$i-1]}" >> "$CERTbase.cfg"
			fi
		done
	fi

}

# cat file in $1 parameter
show_FILE() {
	for i in $(seq 1 $2); do printf "\t"; done
	echo -e "\033[2m\033[4m$1\033[0m\033[2m"
	while read -r l || [[ -n $l ]]
	do
		for i in $(seq 1 $2); do printf "\t"; done
		echo "$l"
	done < "$1"
	echo -e -n "\033[0m"
	sleep 5
}

# exit script with code $1
exit_script() {
	echo -e "\n\033[2m\033[4musage\033[0m\033[2m: $(pwd)/$(basename "$0") [parameters]"
	echo -e "\033[2m\033[4mparameters\033[0m\033[2m:"
	i=0
	for param in ${CERTparams1[@]} ${CERTparams2[@]} ${CERTparams3[@]}
	do
		printf "\t%-${ParamMaxLen}s = \"%-s\"\n" "$param" "${CERTparams_sample[$((i++))]}"
		if [[ "$param" == "CERTmode" ]]
		then
			printf "\t%-${ParamMaxLen}s    %s\n" " " "CSR: you provide data for request and post CSR to external CA"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      reqired for STEP1: $(echo ${CERTparams1[@]} ${CERTparams2[@]})"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      reqired for STEP2: $(echo ${CERTparams1[@]})"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      optional         : $(echo ${CERTparams3[@]})"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "EXT: external CA provides all data, including CSR and private key"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      reqired          : $(echo ${CERTparams1[@]})"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "SELF: self-signed sertificate"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      reqired          : $(echo ${CERTparams1[@]} ${CERTparams2[@]})"
			printf "\t%-${ParamMaxLen}s    %s\n" " " "      optional         : $(echo ${CERTparams3[@]})"
		fi
	done
	echo -e "\033[2m\033[4mexit codes\033[0m\033[2m:"
	for i in ${!EXITcodes[@]}; do
		if [[ $i == $1 ]]
			then echo -e "\t\033[1m${EXITcodes[$i]}\033[0m"
			else echo -e "\t\033[2m${EXITcodes[$i]}\033[0m"
		fi
	done
	CertStore_lockin
	echo -e "\033[0m\033[1m\033[4mSEE YOU\033[0m"
	exit $1
}

# certificate store lock in
CertStore_lockin() {
	find "$CERTpath" -type f -exec chmod 400 {} + 
	chmod 500 "$CERTpath"
	echo -e "\033[2mcertificates store is locked in\033[0m"
}

# certificate store lock out
CertStore_lockout() {
	chmod 750 "$CERTpath"
	find "$CERTpath" -type f -exec chmod 640 {} + 
	echo -e "\t\033[2mcertificates store is locked out\033[0m"
}

# ======= FUNCTIONS BLOCK end =======



# ======= MAIN{} begin =======

echo -e "\n\n\033[1m\033[4mScript inittialisation\033[0m"

echo -e "\t\033[2mread parameters from command line\t\033[0m"
KEYlen=4096
CERTdays=5000
for param in "$@"
do
	KeyName=$(echo $param | cut -f1 -d=)
	KeyValuePos=${#KeyName}+1
	KeyValue="${param:$KeyValuePos}"
	export "${KeyName}"="$KeyValue"
	printf "\t\t\033[2m%-${ParamMaxLen}s: \"%-s\"\033[0m\n" "$KeyName" "${!KeyName}"
done
echo -e "\t\033[2mcheck required script parameters\033[0m"
for param in ${CERTparams1[@]}; do [[ -z ${!param} ]] && exit_script 12; done
echo -e "\t\033[2mdetect primary fqdn and SANs\033[0m"
CERTsan=()
for san in $(echo "${CERTfqdn//,/ }"); do CERTsan+=("$san"); done
CERTfqdn=${CERTsan[0]}
echo -e "\t\t$CERTfqdn"
for san in ${CERTsan[@]:1}; do echo -e "\t\t\033[2m${san}\033[0m"; done
echo -e "\t\033[2mdetect script mode\033[0m"
CERTmode=$(echo $CERTmode | tr '[:lower:]' '[:upper:]')
if   [[ "$CERTmode" == "CSR" ]];  then echo -e "\t\t\033[1m$CERTmode\033[0m\033[2m - prepare request, send to external CA and generate all files\033[0m"
elif [[ "$CERTmode" == "EXT" ]];  then echo -e "\t\t\033[1m$CERTmode\033[0m\033[2m - all data receiving from external service in text format, usual via email\033[0m"
elif [[ "$CERTmode" == "SELF" ]]; then echo -e "\t\t\033[1m$CERTmode\033[0m\033[2m - self signed from provided data\033[0m"
else exit_script 10; fi

echo -e "\t\033[2mdirectory for certificate store\033[0m"
[[ "${CERTstore:0:1}" == "~" ]] && CERTstore="${HOME}/${CERTstore:1}"
[[ ! -d "$CERTstore" ]] && mkdir -p "$CERTstore"
[[ ! -d "$CERTstore" ]] && exit_script 2
CERTstore="$(cd "$CERTstore"; pwd)"
CERTpath="$CERTstore/$CERTfqdn"
CERTbase="$CERTpath/$CERTfqdn"
echo -e "\t\t\033[2m\"$CERTpath\"\033[0m"
[[ -d "$CERTstore" ]]  && CertStore_lockout
[[ ! -d "$CERTpath" ]] && mkdir -p "$CERTpath"
[[ ! -d "$CERTpath" ]] && exit_script 2
if [[ $(ls "$CERTpath") ]]
then
	echo -e "\t\t\033[2mtarget directory is not empty\033[0m"
	echo -e -n "\t\033[2mtype \033[0mDELETE\033[2m to delete all content \033[0m"
	read -n6 -t10 toContinue
	echo ""
	if [[ "$toContinue" == "DELETE" ]]
	then
		rm -rf "$CERTpath"
		mkdir  "$CERTpath"
		echo -e "\t\t\033[2mtarget directory cleaned\033[0m"
	else
		[[ "$CERTmode" != "CSR" ]] && exit_script 11
		[[ -f "$CERTbase.cer" ]]   && exit_script 9
	fi
fi
echo -e "\t\033[2mpassword saving to \"$CERTbase.enc\"\033[0m"
echo "$CERTpwd" > "$CERTbase.enc"
echo -e "\033[2mok\033[0m"

if [[ "$CERTmode" != "EXT" && ! -f "$CERTbase.csr" ]]
then #step 1 of 1
	echo -e "\n\033[1mSTEP 1/2\033[0m\033[2m - certificate request generation\033[0m"

	echo -e "\t\033[2mcheck required parameters\033[0m"
	for param in ${CERTparams2[@]}; do [[ -z ${!param} ]] && exit_script 12; done
	for param in ${CERTparams1[@]} ${CERTparams2[@]} ${CERTparams3[@]}
	do
		printf "\t\t\033[2m%-${ParamMaxLen}s = \"%-s\"\033[0m\n" "$param" "${!param}"
		[[ "$param" == "CERTfqdn" ]] && for san in ${CERTsan[@]:1}; do printf "\t\t\033[2m%-${ParamMaxLen}s   \"%-s\"\033[0m\n" " " "$san"; done
	done
	echo -e -n "\t\033[2mpress \033[1mENTER\033[0m\033[2m to continue or any other stop\033[0m"
	read -n1 -t5 toContinue
	[[ "$toContinue" ]] || exit_script 1

	echo -e "\t\033[2mgenerate certificate config file\033[0m"
	gen_FILEcfg
	show_FILE "$CERTbase.cfg" 2
	[[ "$CERTmode" == "SELF" ]] && show_FILE "$CERTbase.ext" 2

	echo -e "\t\033[2mgenerate certificate request file\033[0m"
	openssl req -new -nodes -config "$CERTbase.cfg" -keyout "$CERTbase.key" -out "$CERTbase.csr"
	openssl rsa -aes256 -in "$CERTbase.key" -out "$CERTbase.key" -passout file:"$CERTbase.enc"

	# exit to send request to the external CA for CSR mode
	echo -e "\033[2mok\033[0m"
	[[ "$CERTmode" == "CSR" ]] &&  exit_script 3
fi

echo -e "\n\033[1mSTEP 2/2\033[0m\033[2m - certificate stores generation\033[0m"
if [[ "$CERTmode" == "EXT" || "$CERTmode" == "CSR" && -f "$CERTbase.csr" ]]
then # STEP 2 of 2
	echo -e "\t\033[2mPlease paste here content of email(s) ond/or file(s) with cetificates including chain\033[0m"
	echo -e "\t\033[2mFor finish type \033[1m...\033[0m\033[2m in a new line and press ENTER\033[0m"
	WRITEcer=false
	WRITEkey=false
	WRITEcsr=false
	CERTfile[0]=0
	while [[ "$l" != "..." ]]
	do
		if [[ "$CERTmode" == "EXT" ]]
		then
			[[ "$l" == "-----BEGIN CERTIFICATE REQUEST-----" ]] && WRITEcsr=true
			$WRITEcsr && echo "$l" >> "$CERTbase.csr"
			[[ "$l" == "-----END CERTIFICATE REQUEST-----" ]]   && WRITEcsr=false
			[[ "$l" == "-----BEGIN RSA PRIVATE KEY-----" ]]     && WRITEkey=true
			$WRITEkey && echo "$l" >> "$CERTbase.key"
			[[ "$l" == "-----END RSA PRIVATE KEY-----" ]]       && WRITEkey=false
		fi
		if [[ "$l" == "-----BEGIN CERTIFICATE-----" ]]
		then
			WRITEcer=true
			((CERTfile[0]++))
			CERTfile[${CERTfile[0]}]="$CERTbase.c${CERTfile[0]}"
		fi
		$WRITEcer && echo "$l" >> "${CERTfile[${CERTfile[0]}]}"
		[[ "$l" == "-----END CERTIFICATE-----" ]] && WRITEcer=false
		read -s -r l
	done

	echo -e "\t\033[2mcertificates count is ${CERTfile[0]}\033[0m"
	[[ ! -f "$CERTbase.key" ]] && exit_script 7
	[[ ${CERTfile[0]} < 2 ]]   && exit_script 4

	for c in $(seq 1 ${CERTfile[0]})
	do
		echo -e "\t\033[2mcertificate ${CERTfile[$c]}:\033[0m"
		CERTsubj[$c]="$(openssl   x509 -in "${CERTfile[$c]}" -noout -subject | sed 's/^subject= *//')"
		CERTissuer[$c]="$(openssl x509 -in "${CERTfile[$c]}" -noout -issuer  | sed 's/^issuer= *//')"
		CERTvalid="$(openssl      x509 -in "${CERTfile[$c]}" -noout -enddate | sed 's/^notAfter=*//')"
		echo -e "\t\t\033[2msubject   : ${CERTsubj[$c]}\033[0m"
		echo -e "\t\t\033[2missuer    : ${CERTissuer[$c]}\033[0m"
		echo -e "\t\t\033[2mvalid thru: ${CERTvalid}\033[0m"
	done

	if [[ "$CERTmode" == "EXT" ]]
	then
		CSRdata="$(openssl req -in "$CERTbase.csr" -x509 -key "$CERTbase.key" -text -noout)"
		for i in ${!CERTfields[@]}; do echo -e "\t\t\033[2m$(echo "$CSRdata" | grep "${CERTfields[$i]}" | awk '{$1=$1};1')\033[0m"; done
		echo -e "\t\033[2mprivate key has encryped with provided password"
		openssl rsa -in "$CERTbase.key" -out "$CERTbase.key" -aes256 -passout file:"$CERTbase.enc"
		echo -e -n "\033[0m"
	fi
	
	echo -e "\t\033[2mcertificates chain\033[0m"
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
			printf  "\t\t\033[2m%-s\033[0m\n" "${CERTsubj[$c]}"
		else
			n=$((n + 4))
			printf  "\t\t\033[2m%-${n}s%-s\033[0m\n" " " "|"
			printf  "\t\t\033[2m%-${n}s%-s%-s\033[0m\n" " " "|-->${CERTsubj[$c]}"
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

	echo -e "\t\033[2mgenerated files:\033[0m"
	for e in cer chain pem; do echo -e "\t\t\033[2m\"$CERTbase.$e\"\033[0m"; done

	echo -e "\t\033[2mcheck private key and certificate matching\033[0m"
	HASHkey=$(openssl  rsa -in "$CERTbase.key" -passin file:"$CERTbase.enc" -noout -modulus | openssl md5)
	HASHcer=$(openssl x509 -in "$CERTbase.cer"                              -noout -modulus | openssl md5)
	echo -e "\t\t\033[2mprivate key  hash is \"$HASHkey\"\033[0m"
	echo -e "\t\t\033[2mcertificate  hash is \"$HASHcer\"\033[0m"
	[[ "$HASHkey" != "$HASHcer" ]] && exit_script 6
else # SELF
	echo -e "\t\033[2mgenerate self signed certificate \"$CERTbase.enc\"\033[0m"
	openssl x509 -req -in "$CERTbase.csr" -extfile "$CERTbase.ext" -signkey "$CERTbase.key" -passin file:"$CERTbase.enc" -out "$CERTbase.cer" -days $CERTdays
	cp "$CERTbase.cer" "$CERTbase.pem"
	CERTdata="$(openssl x509 -in "$CERTbase.cer" -text -noout)"
	for i in ${!CERTfields[@]}; do echo -e "\t\t\033[2m$(echo "$CERTdata" | grep "${CERTfields[$i]}" | awk '{$1=$1};1')\033[0m"; done
fi

echo -e "\t\033[2mcreating PKCS12 store\033[0m"
openssl rsa -in "$CERTbase.key" -passin file:"$CERTbase.enc" -out "$CERTbase.temp"
openssl pkcs12 -in "$CERTbase.pem" -inkey "$CERTbase.temp" -export -out "$CERTbase.pfx" -passout file:"$CERTbase.enc"
rm "$CERTbase.temp"
echo -e "\t\t\033[2m\"$CERTbase.pfx\" has been created\033[0m"
echo -e "\033[2mok\033[0m"


echo ""
CertStore_lockin
echo -e "\033[2m\033[4m${CERTpath}\033[0m\033[2m"
ls -lh "$CERTpath" | while read -r l; do echo -e "\t$l"; done
echo -e "\033[0m\033[1m\033[4mALL DONE\033[0m"
exit 0

# ======= MAIN{} end =======
