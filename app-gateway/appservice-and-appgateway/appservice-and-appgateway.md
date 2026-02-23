### Confirming communication between AppGateway and AppService

## Azure Appservice with Application Gateway with TLS Termination at AppGateway

### 1. Go Application as Webservice

Web server that will show us:

* That the app is running.

* What Headers the Application Gateway is sending (so we can see the "Host Rewrite" in action).

**Note**: Find the source code in go related files and Dockerfile for containarization.

### 2. What happens when we hit the AppGateway IP on browser.



### 3. Create the App Service (The Destination)
When you create the App Service, you'll point it to your Go image in ACR.

Basics: Select Docker Container as the Publish type and Linux as the OS.

Docker Tab:

Image Source: Azure Container Registry.

Registry: Select your ACR name.

Image/Tag: Select your Go app and the latest tag.

Networking: Ensure "Public Access" is On for now (we will lock it down later).


### 4. Create the Application Gateway (The Front Door)
Step-by-Step: Creating the Application Gateway
1. Basics Tab
Tier: Standard V2 (or WAF V2 if you want to show off the firewall features to your manager).

Autoscaling: You can set the minimum to 0 or 1 to save costs for this lab.

Virtual Network: Select the VNet you created for the App Service.

Subnet: Select your dedicated GatewaySubnet.

2. Frontends Tab
Frontend IP address type: Public.

Public IP address: Create a new one (e.g., pip-appgw-prod).

3. Backends Tab
Add a backend pool:

Name: bp-golang-app.

Target type: App Services.

Target: Select the App Service you just created.

4. Configuration Tab (The "Engine Room")
Click Add a routing rule. This is where you connect the dots.

A. Listener (The Ear)

Name: https-listener.

Protocol: HTTPS.

Certificate: Upload your .pfx file and enter the password.

Listener Type: Basic.

B. Backend Targets (The Logic)

Backend setting: Click Add new.

Name: be-settings-appservice.

Port: 80.

Override with new host name: Yes.

Host name override: Pick host name from backend target.

(Crucial: This tells the Gateway to use the .azurewebsites.net name internally so the App Service recognizes the request).

5. Add the "Bouncer" (HTTP to HTTPS Redirection)
After you finish the first rule, add a second rule for the "Bouncer" logic:

Listener: Port 80 (HTTP).

Backend Target:

Target type: Redirection.

Redirection type: Permanent (301).

Target listener: Select your https-listener.


### 5. Grant ACR Permissions (The "Handshake")
For the App Service to stay updated, it needs permission to pull from ACR.

5.1 Go to your App Service > Deployment Center.

5.2 Ensure Managed Identity is enabled for the connection to ACR. Azure usually handles this automatically if you created the app via the portal, but it’s good to verify.


### 6. The "Pro" Lockdown (Access Restrictions)
Once you verify that you can see your Go app via the Gateway's Public IP, it's time to hide the "Back Door."

Go to your App Service > Networking > Access Restrictions.

Click + Add.

Name: Allow-Only-AppGw.

Action: Allow.

Type: Service Tag.

Service Tag: Select AzureApplicationGateway.

Priority: 100.

**Why use a Service Tag instead of an IP?** If your Application Gateway scales out or changes its internal IP, the "Service Tag" stays valid, so your app won't break.


### 7. How to verify it's working

Once the Gateway moves from "Updating" to "Running" (this usually takes 5-7 minutes):

Check Backend Health: Go to the Monitoring section of the Gateway. If it's "Healthy," your Host Overrides are correct.

The Browser Test: Type http://<Your-Public-IP>.

It should automatically flip to https://.

You should see your Go app's output.

The Header Check: Look at the "Host" header printed by your Go app. It should show your xxxx.azurewebsites.net address.

```bash
Request Headers:
Sec-Ch-Ua: "Not(A:Brand";v="8", "Chromium";v="144", "Google Chrome";v="144"
X-Forwarded-Tlsversion: 1.3
X-Client-Ip: 223.181.119.123
Max-Forwards: 10
Sec-Ch-Ua-Mobile: ?0
Sec-Ch-Ua-Platform: "Windows"
Sec-Fetch-Site: none
Client-Ip: 223.181.119.123:27699
X-Site-Deployment-Id: AppService
Was-Default-Hostname: appservice-eceucjhzf7bcfyfn.centralindia-01.azurewebsites.net
Sec-Fetch-Mode: navigate
Sec-Fetch-User: ?1
Sec-Fetch-Dest: document
X-Arr-Ssl: 2048|256|CN=Microsoft Azure RSA TLS Issuing CA 04, O=Microsoft Corporation, C=US|CN=*.azurewebsites.net, O=Microsoft Corporation, L=Redmond, S=WA, C=US
X-Forwarded-For: 223.181.119.123:27699
X-Original-Url: /
Accept-Encoding: gzip, deflate, br, zstd
Cache-Control: max-age=0
X-Arr-Log-Id: 206d8674-d9a0-4eab-bfe7-50a83b758969
Disguised-Host: appservice-eceucjhzf7bcfyfn.centralindia-01.azurewebsites.net
X-Forwarded-Proto: https
X-Appservice-Proto: https
X-Waws-Unencoded-Url: /
X-Client-Port: 27699
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36
Accept-Language: en-GB,en-US;q=0.9,en;q=0.8
```

**Explanation** :
There are specific headers here that only appear when an Application Gateway (or Azure's load balancing layer) is involved:

* X-Forwarded-For: 223.181.119.123:27699: This is the most important one. It shows your actual Public IP. The Gateway adds this so your Go app knows who the real user is, rather than just seeing the Gateway's internal IP.

* X-Forwarded-Proto: https: This proves TLS Termination worked. You connected to the Gateway via HTTPS, and the Gateway told the Go app, "Don't worry, the user's connection was secure."

* X-Arr-Ssl: This is a specific header added by Azure's Application Request Routing (ARR). It contains details about the SSL certificate used for the connection.

* X-Original-Url: /: This shows the path the user originally requested before any potential internal routing.

### 8. Behind the Scenes

#### The "Apartment Building" Analogy
Imagine you are trying to visit a friend, "Go-App", who lives in a massive apartment complex called "Azure App Service".

- The Address (The Public IP): You drive to the street address of the building. This is your Application Gateway's Public IP.

- The Front Desk (The Listener): You walk into the lobby. The security guard at the desk (the Listener) checks if you’re using the right door (Port 80 or 443).

- The Problem: The building has 10,000 apartments, but they all share the same front door. If you just say "I'm here for a friend," the guard won't know where to send you.

- The "Host Name Override": This is the guard saying, "Oh, you're at the front door for 'YourCompany.com', but inside this building, that friend is in Apartment 'appservice-xyz.azurewebsites.net'." 5. The Delivery: The guard (Gateway) puts a sticky note on your back with the apartment number and sends you up the elevator.


**Real Process Behind the scenes**
Let’s follow a single click from our laptop to our Go code:

* Step A: The Entry (TLS Termination)
You type https://<Gateway-IP>.

The Gateway receives this on Port 443.

It uses your .pfx certificate to "unlock" (decrypt) the request.

Result: The Gateway now sees the "naked" HTTP request.

* Step B: The Transformation (Host Override)
The Gateway looks at its Backend Settings (the screenshot you sent).

It sees the instruction: “Hey, before you send this to the App Service, change the 'Host' label to appservice-...azurewebsites.net.”

Result: The request is re-labeled so the App Service won't reject it.

* Step C: The Internal Handover
The Gateway sends the request over Port 80 (HTTP) to the App Service.

Because you turned off "HTTPS Only" on the App Service, it accepts this Port 80 traffic from the Gateway.

Step D: The App Service to Container
The App Service sees the "Host" label, matches it to your specific app, and passes it into our Docker Container.

our Go App receives it and prints those headers you saw!


#### Real Flow From Appservice into Containers inside AppService
1. The "Platform" vs. The "Container"
When the Application Gateway sends the request to Azure, it doesn't hit your Go code immediately. It hits the Azure App Service Front-End first.

The Front-End's Job: It looks at the Host Header (appservice-xxx.azurewebsites.net). It says, "Okay, I know this app. It lives on Worker Server #502."

The Handover: It forwards the request to that specific Worker Server where your Docker container is running.

2. The "Docker Port Bridge"
Inside that Worker Server, your Docker container is running. This is where the Port 80 configuration becomes critical.

Incoming: The App Service platform receives the request on Port 80.

The Tunnel: It looks at your configuration. By default, App Service "tunnels" that traffic into your container.

The Go Server: Your Go app is "listening" inside the container (usually on port 80 or 8080). When the request crosses that "bridge," your http.HandleFunc in Go finally "sees" the data.

3. Why the Headers are there
When the Go app receives the request, it’s like receiving a physical letter. The App Service Platform has already added "stamps" (headers) to that letter before handing it to your Go code.

The Gateway added X-Forwarded-For.

The App Service added X-Site-Deployment-Id.

Your Go App simply opens the letter and prints everything it finds inside.



1. How the Bridge Works
Azure App Service runs a specialized "Sidecar" or a Reverse Proxy (often based on Nginx or IIS) on the host machine.

The External Face: The App Service platform listens on Port 80 and Port 443 for the outside world (or your Gateway).

The Internal Face: It looks at your Docker container. It needs to know which "internal door" to push the traffic through.

The Bridge: It takes the traffic from Port 80 and "re-routes" it to Port 8080 inside your container.

2. How does Azure know to use 8080?
Azure is actually very smart about this. It tries to "guess" your port, but as a DevOps Engineer, you shouldn't leave it to guesswork.

You tell Azure about your "Go port" using an Environment Variable called WEBSITES_PORT.

If you don't set it: Azure scans your Docker image. If it sees EXPOSE 8080 in your Dockerfile, it tries to use that.

The Professional Way: You go to your App Service > Configuration > Application Settings and add:

Name: WEBSITES_PORT

Value: 8080

Once you set this, Azure builds a direct "pipe" from its Port 80 to your Go app's Port 8080.

3. The Full Request Journey (Port Edition)
Let’s look at the "Baton Pass" one last time, focusing on the port numbers:

User Browser: Sends request to Gateway IP on Port 443.

App Gateway: Receives on 443, decrypts it, and sends it to the App Service on Port 80.

App Service Platform: Receives on Port 80. It sees your WEBSITES_PORT=8080 setting.

Docker Bridge: It "translates" the port from 80 to 8080.

Your Go App: Receives the request on 8080 via os.Getenv("PORT").

### 9. Issues

1. * Browser resolving ip to hostname and then adding port 80

When you hit the Gateway IP, the Gateway sends the request to the App Service. If the App Service "sees" the request and decides it wants to be helpful, it might try to redirect you to its own internal hostname (appservice-xxx.azurewebsites.net).

Once the browser sees that specific hostname, it remembers if you’ve ever visited it over HTTP before and tries to "help" by sticking a port on it.

Why you see :80 and a Hostname
If you type the IP and it suddenly changes to appservice-xxx.azurewebsites.net:80, it means your Host Name Override is working, but the TLS Termination is causing a "Redirect Loop" or a "Protocol Mismatch."

The App Service is essentially saying: "I see you're trying to talk to me, but I'm an App Service and I prefer to be reached at my own name on the standard web port."

How to Fix This (The "Pro" Way)
To stop the App Service from "stealing" the connection away from the Gateway, you need to toggle one specific setting on the App Service itself:

Go to your App Service in the Azure Portal.

On the left menu, go to Configuration (or Settings > Configuration).

Go to the General Settings tab.

Find HTTPS Only and set it to Off.

Wait, why turn it Off? Because the Application Gateway is already handling the "Secure" part. If the App Service also tries to force HTTPS, they start "fighting" over the connection. The Gateway talks to the App Service over Port 80 (HTTP), but if the App Service says "No! Talk to me on HTTPS!", it sends a redirect back to your browser, which causes the URL change and the error you see.

