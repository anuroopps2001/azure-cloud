**If a human wants to access a resource, they use a User Account. If an application (like your App Service, a script, or an external server) wants to access a resource, it uses an `App Registration`**

* When you create an App Registration in Microsoft Entra ID, Azure automatically creates a `Service Principal`

**App Registration**: The global definition of the app (the "Template").

**Service Principal**: The actual local "identity" in your specific tenant that you give permissions to (the "User Account" for the app).

### 🌍 Internal vs. External Access
1. **Internal (Managed Identity)**: If your app is inside Azure (like your App Service), you use Managed Identity. It’s basically an App Registration that Azure manages for you—you never see a password in order to allow Appservice to talk to other Azure services.

2. **External (App Registration + Secret)**: If your app is outside Azure (e.g., a server in your basement or on AWS), you create an App Registration in Azure under EntraID, generate a Client Secret, and give those credentials to the external app. So that those external services can talk to the Azure services.


### 🛡️ How it works: The "Token" Exchange
1. **Perform AppRegistration on behalf of External Service Under Azure EntraID**: It will generate, Client ID, Object ID, Tenant ID
2. **Configure the creds on service which wants to talk to Azure Services**
2. **The Request**: The external app sends its Client ID and Client Secret to Entra ID
3. **The Token**: Entra ID verifies the secret and sends back an Access Token.
4. **The Access**: The app shows this token to the Azure Resource (like your Postgres DB or a Storage Account).
5. **The Permission**: The resource checks the token and says, "Okay, you have permission to Read, but not Delete."


### 🛠️ The "Object ID" Confusion
When you do an App Registration, you get two different IDs that look similar but have different jobs:

**Application (Client) ID**: This is for Authentication. Jenkins uses this to "log in."

**Object ID (Service Principal ID)**: This is for Authorization. This is the ID you use when you go to the "Access Control (IAM)" tab in the Azure Portal to assign roles like "Contributor."