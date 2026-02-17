### DATE: 16-02-26
```bash
$ az group create --name myapp-rg -l centralindia
{
  "id": "/subscriptions/cc076e9a-89bc-4a47-86e4-09c6d0967bd8/resourceGroups/myapp-rg",
  "location": "centralindia",
  "managedBy": null,
  "name": "myapp-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

```bash
$ az postgres flexible-server create \
  -g myapp-rg \
  --name myapp-db-server-anuroop \
  -l centralindia \
  --admin-user myadmin \
  --admin-password Anuroopps@2108 \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --public-access 0.0.0.0

  
Checking the existence of the resource group 'myapp-rg'...
Resource group 'myapp-rg' exists ? : True 
Creating PostgreSQL Server 'myapp-db-server-anuroop' in group 'myapp-rg'...
Your server 'myapp-db-server-anuroop' is using sku 'Standard_B1ms' (Paid Tier). Please refer to https://aka.ms/postgres-pricing for pricing details
Configuring server firewall rule, 'azure-access', to accept connections from all Azure resources...
Make a note of your password. If you forget, you would have to reset your password with "az postgres flexible-server update -n myapp-db-server-anuroop -g myapp-rg -p <new-password>".
Try using 'az postgres flexible-server connect' command to test out connection.
{
  "connectionString": "postgresql://myadmin:Anmyapp-db-server-anuroop.postgres.database.azure.com/postgres?sslmode=require",       
  "databaseName": "postgres",
  "firewallName": "AllowAllAzureServicesAndResourcesWithinAzureIps_2026-2-16_9-55-29",
  "host": "myapp-db-server-anuroop.postgres.database.azure.com",
  "id": "/subscriptions/cc076e9a-89bc-4a47-86e4-09c6d0967bd8/resourceGroups/myapp-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/myapp-db-server-anuroop",
  "location": "Central India",
  "password": "<REDACTED>",
  "resourceGroup": "myapp-rg",
  "skuname": "Standard_B1ms",
  "username": "myadmin",
  "version": "18"
}
```

### StoragAccount 
**Pupose**: Azure Functions are stateless. This means when Azure spins up a tiny container to run your code, that container is empty. It needs a place to pull your code from and a place to write logs.

The Storage Account serves three main purposes for the Function App:

- ode Storage: When you run func azure functionapp publish, your Python files are zipped up and stored in the Storage Account. When the function "wakes up," it reaches into the storage, grabs the zip, and runs it.

- Coordination (The "Lease"): For your Timer Trigger, Azure needs to make sure only one instance of your function runs at 6 PM. It uses the Storage Account to create a "lock" file so that if you have multiple instances of the function app, they don't all try to shut down the database at the same time.

- Logging & State: It stores execution metadata and small bits of state needed to keep the function healthy. 
```bash
$ az storage account create \
> --name stappdevanuroop2026 \
> -l centralindia \
> -g myapp-rg \
> --sku Standard_LRS
```

### Create App Insights first
```bash
az monitor app-insights component create \
  --app my-insights \
  --location centralindia \
  --resource-group myapp-rg
```

### Create the Function App (Flex Consumption is best for Python)
```bash
az functionapp create \
  --name my-devops-func-anuroop \
  --resource-group myapp-rg \
  --storage-account stappdevanuroop2026 \   # This is the specific 'Hard Drive' I want this Function App to use.
  --runtime python \
  --runtime-version 3.11 \
  --os-type Linux \
  --app-insights my-insights \
  --flexconsumption-location centralindia \
  --instance-memory 512
```

**If you didn't have that storage account and its State Locking, and you scaled your Function App to 10 instances, you would have 10 "alarm clocks" going off at once, all trying to stop the same database simultaneously. That would cause API conflicts and wasted resources.**

How the State Locking Works
The storage account uses a feature called Blob Leases. Here is the play-by-play of what happens behind the scenes:

1. The Race: When the timer (08:06:00) hits, all active instances of your function look at a specific hidden file in the storage account (inside the azure-webjobs-hosts/locks container).

2. The Lock: The first instance to reach the file "grabs the lease" (locks it).

3. The Winner: Only the instance that holds the lock is allowed to execute the Python code inside friday_db_cleanup.

4. The Losers: The other instances see the file is locked and simply stand down. They realize, "Someone else is already handling the Friday cleanup."


**We built the "Hardware" in the cloud, and now it's time to install the "Software."**

### The "Local Folder" Check
Before running the deployment command, make sure your folder on your laptop looks exactly like this:

- function_app.py (The code we finalized with the API and the Timer).

- requirements.txt (Crucial: This tells Azure to install psycopg2-binary, azure-identity, and azure-mgmt-postgresqlflexibleservers).

- host.json (The config file that tells Azure this is a v2 Python function).

- host.json: This is for Azure's engine. It tells the cloud "This is a version 2.0 app" and "Please download the tools needed for Python and Timers."

- local.settings.json: This is for Your Code. It stores the "Secrets" (Connection Strings) and "Schedules" so your Python code can read them as Environment Variables.

***In the Azure Functions world, host.json is for global configuration (like the extension bundles), while local.settings.json is where your environment variables (like connection strings and schedules) live during local development.***


### Deploy the Code
First, make sure you are in the folder containing your `function_app.py`. Run:
```bash
$ func azure functionapp publish <YOUR_FUNCTION_APP_NAME> --python



Local python version '3.14.0' is different from the version expected for your deployed Function App. This may result in 'ModuleNotFound' errors in Azure Functions. Please create a Python Function App for version 3.14 or change the virtual environment on your local machine to match '3.11'.
Getting site publishing info...
[2026-02-16T05:37:07.157Z] Starting the function app deployment...
[2026-02-16T05:37:07.165Z] Creating archive for current directory...
Performing remote build for functions project.
Deleting the old .python_packages directory
Uploading 2.86 KB [###############################################################################]
Deployment in progress, please wait...
Starting deployment pipeline.
[Kudu-SourcePackageUriDownloadStep] Skipping download. Zip package is present at /tmp/zipdeploy/f4493405-f5ca-43df-9fd4-3f860e8d9dbc.zip        
[Kudu-ValidationStep] starting.
[Kudu-ValidationStep] completed.
[Kudu-ExtractZipStep] starting.
[Kudu-ExtractZipStep] completed.
[Kudu-ContentValidationStep] starting.
[Kudu-ContentValidationStep] completed.
[Kudu-PreBuildValidationStep] starting.
[Kudu-PreBuildValidationStep] completed.
[Kudu-OryxBuildStep] starting.
[Kudu-OryxBuildStep] completed.
[Kudu-PostBuildValidationStep] starting.
[Kudu-PostBuildValidationStep] completed.
[Kudu-PackageZipStep] starting.
[Kudu-PackageZipStep] completed.
[Kudu-UploadPackageStep] starting.
[Kudu-UploadPackageStep] completed. Uploaded package to storage successfully.
[Kudu-RemoveWorkersStep] starting.
[Kudu-RemoveWorkersStep] completed.
[Kudu-SyncTriggerStep] starting.
[Kudu-CleanUpStep] starting.
[Kudu-CleanUpStep] completed.
Finished deployment pipeline.
[Kudu-SyncTriggerStep] completed.
Checking the app health...Host status endpoint: https://my-devops-func-anuroop.azurewebsites.net/admin/host/status
. done
Host status: {"id":"b426953b0e0b0b20796916eeb6f183a3","state":"Running","version":"4.1046.100.25616","versionDetails":"4.1046.100+c9b95f32abaeb2f441c42464c43ce959e6afc9d8","platformVersion":"","instanceId":"1--88abb24d-680f-4920-867c-5c3c9b686fcd","computerName":"","processUptime":857491,"functionAppContentEditingState":"NotAllowed","extensionBundle":{"id":"Microsoft.Azure.Functions.ExtensionBundle","version":"4.31.0"}}
[2026-02-16T05:39:43.892Z] The deployment was successful!
Functions in my-devops-func-anuroop:
    friday_db_cleanup - [timerTrigger]

    postgres_get - [httpTrigger]
        Invoke url: https://my-devops-func-anuroop.azurewebsites.net/api/getusers

    postgres_insert - [httpTrigger]
        Invoke url: https://my-devops-func-anuroop.azurewebsites.net/api/adduser
```


### Listing env variabls set for Azure Appfunction
```bash
$ az functionapp config appsettings list   --name my-devops-func-anuroop   --resource-group myapp-rg   --output tsv
AzureWebJobsStorage     False   DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=stappdevanuroop2026;AccountKey=<REDACTED>+pceEkRyPL+AStEn+iBw==
APPLICATIONINSIGHTS_CONNECTION_STRING   False   InstrumentationKey=0ac<REDACTED>e3a1a;IngestionEndpoint=https://centralindia-0.in.applicationinsights.azure.com/;LiveEndpoint=https://centralindia.livediagnostics.monitor.azure.com/;ApplicationId=120974ac-03a8-4d4f-8162-abb60f33550b
DEPLOYMENT_STORAGE_CONNECTION_STRING    False   DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=stappdevanuroop2026;AccountKey=QAiauby1<REDACTED>Eqt+pceEkRyPL+AStEn+iBw==
```

### Adding new env variables into Azure AppFunction
```bash
$ az functionapp config appsettings set \
> --name my-devops-func-anuroop \
> --resource-group myapp-rg \
> --settings \
> PostgresConnectionString="host=azureunctionserver.postgres.database.azure.com dbname=postgres user=myadmin password=<REDACTED>8 port=5432 s
slmode=require" \
> CleanupSchedule="0 */5 * * *" \
> AZURE_SUBSCRIPTION_ID= "cc076e<REDACTED>0967bd8" \
> "DB_RESOURCE_GROUP"= "myapp-rg" \
> DB_SERVER_NAME= "myapp-db-server-anuroop"
```


### Assign system-assigned Managed identity to App Function 
- Navigate to your Function App in the Azure portal.
- In the left menu, under Settings, select Identity.
- On the System assigned tab, switch the Status to On.
- Select Save, and then select Yes in the confirmation prompt. 


### Now Allow Azure AppFunction at postgres Flexi server to invoke stopping of DB in our Example
- Go to your PostgreSQL Flexible Server in the Portal. 
- Click Access Control (IAM) -> Add -> Add role assignment.
- Select Contributor
- Select Managed Identity as the assignee
- Select your Function App name
- Save

