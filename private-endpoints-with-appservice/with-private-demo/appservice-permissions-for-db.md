#### Login into postgresql as EntraID
```bash
TOKEN=$(az account get-access-token \
  --resource-type oss-rdbms \
  --query accessToken -o tsv)
```
```bash
psql "host=<postgres_host_url> \
port=5432 \
dbname=postgres \
user=<entraID_of_user> \
sslmode=require" \
password=$TOKEN
```

#### Now, Create role named with our "Appservice_Name"
```bash
SELECT * FROM pgaadauth_create_principal('<APP_SERVICE_NAME>', false, false);
```
```bash
GRANT ALL PRIVILEGES ON DATABASE postgres TO "<APP_SERVICE_NAME>"
```

**AZURE_POSTGRESQL_DBNAME=postgres**
**AZURE_POSTGRESQL_DBUSER=<APP_SERVICE_NAME**
**AZURE_POSTGRESQL_HOST=<DB_HOSTNAME>**
**WEBSITES_PORT=<Application port inside container>**
**WEBSITE_PULL_IMAGE_OVER_VNET=true**
**WEBSITE_VNET_ROUTE_ALL=1**