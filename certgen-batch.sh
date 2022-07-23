#!/bin/bash

./certgen.sh \
	CERTmode=CSR \
	CERTstore="~/Documents/certs store" \
	CERTpwd="7ikWh4yAP!-jWKwqW2ER" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="CloudInside Service Provider, Web Server" \
	CERTfqdn="cloudinside.net"

./certgen.sh \
	CERTmode=EXT \
	CERTstore="~/Documents/certs store" \
	CERTpwd="Z_s_*u3fZbCuC2P2XDZ_" \
	CERTfqdn="portal.cloudinside.net"

./certgen.sh \
	CERTmode=SELF \
	CERTstore="~/Documents/certs store" \
	CERTpwd="YRxY7nM!B6PPPiz9jD46" \
	CERTcountry="KZ" \
	CERTlocality="Almaty" \
	CERTorg="BiTime LLC" \
	CERTservice="CloudInside Service Provider, Test Server" \
	CERTfqdn="test.cloudinside.net"
