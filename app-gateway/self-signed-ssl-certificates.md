## Steps to create self signed SSL certificates and converting into .pfx Format

* Create the certificate and private key:
```bash
openssl req -x509 -newkey rsa:2048 -nodes -keyout appgw.key -out appgw.crt -days 365 -subj "/CN=www.contoso.com"
```

*  Export to .pfx format (The Gateway needs this): `You will be asked to create a password here. Remember it!`
```bash
openssl pkcs12 -export -out appgw.pfx -inkey appgw.key -in appgw.crt
```