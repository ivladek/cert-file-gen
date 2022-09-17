#!/bin/bash

./certgen.sh \
	CERTmode=CSR \
	CERTstore="sample certs store" \
	CERTpwd="P@ssword4_CSR-withSANs" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="Testing Corp. Web Server" \
	CERTfqdn="ivladek.com, www.ivladek.com"

./certgen.sh \
	CERTmode=CSR \
	CERTstore="sample certs store" \
	CERTpwd="P@ssword4_CSR-withouSANs" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="Testing Corp. Mail Server" \
	CERTfqdn="mail.ivladek.com"

./certgen.sh \
	CERTmode=EXT \
	CERTstore="sample certs store" \
	CERTpwd="P@ssword4_EXT" \
	CERTfqdn="portal.ivladek.com"

./certgen.sh \
	CERTmode=SELF \
	CERTstore="sample certs store" \
	CERTpwd="P@ssword4_SELF-withSANs" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="Testing Corp. Mail Server" \
	CERTfqdn="test.ivladek.com, lab.ivladek.com, try.ivladek.com" \
	KEYlen="4096" \
	CERTdays="5000"

./certgen.sh \
	CERTmode=SELF \
	CERTstore="sample certs store" \
	CERTpwd="P@ssword4_SELF-withoutSANs" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="Testing Corp. Mail Server" \
	CERTfqdn="report.ivladek.com" \
	KEYlen="4096" \
	CERTdays="5000"
