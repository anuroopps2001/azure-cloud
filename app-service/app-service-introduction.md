## 1. Why is App Service used? (The "Why")
In the old days, to host your Go app, you had to:

- Rent a Virtual Machine (VM).

- Install Linux.

- Install Go, Docker, and Web Servers (Nginx).

- Patch the OS every week.

**App Service (PaaS - Platform as a Service)** removes all that. It’s used because it allows DevOps engineers to focus on the Application rather than the Server.


## 2. Using App Service WITHOUT Docker (Code-Based)
When you deploy "Code Only" (e.g., Python, Node.js, .NET), Azure provides a pre-configured environment.

- How it works: You push your source code via GitHub or Zip.

- The Runtime: Azure has a "Built-in Image" (a pre-made container) that knows how to run your specific language.

- The Benefit: Extremely simple. You don't even need to know what Docker is.

- The Downside: You are limited to the versions and configurations Azure provides.

## 3. Using App Service WITH Docker (Container-Based)
This is what you did with your Go app. Instead of giving Azure your code, you gave it a Container.

- How it works: You package your Go app, its dependencies, and its OS settings into an image and store it in Azure Container Registry (ACR).

- The Handover: You tell App Service: "Go pull this specific image from ACR and run it."

- The Benefit: Total Control. If your Go app needs a specific Linux library or a custom port (like 8080), it’s all inside the container. It works exactly the same on your laptop as it does in Azure.

## 4. How Traffic Flows "Inside" the App Service
This is the part we discussed yesterday, but let's look at the "hidden" layer.

Even when you use Docker, there is a Front-End Load Balancer (part of the App Service Infrastructure) that sits in front of your container.

1. The Arrival: Traffic hits the App Service Public URL (or your Gateway IP).

2. The Routing: A "System-level" Reverse Proxy (called Kudu or the App Service Frontend) receives the request.

3. The Translation: It looks at the WEBSITES_PORT setting.

4. The Delivery: It forwards the traffic into your Docker container.


## 5. App Service Plan (The "Server Instance")
The App Service Plan (ASP) represents the physical or virtual resources (CPU, RAM, Storage) allocated to run your applications.

- What it is: It is the "Engine Room." When you choose a "Size" (like B1, P1v2), you are deciding how much horsepower your server has.

- The Billing Unit: You pay for the Plan, not the individual apps.

- Multi-tenancy: You can host multiple App Service Apps on a single Plan. It’s like having one big computer and running five different programs on it.

## 6. App Service App (The "Website/Container")
The App Service App is the actual logic, code, or Docker container that you want to show to the world.

- **What it is**: The "Tenant" living in the house. It contains your Go code, your environment variables (like `WEBSITES_PORT`), and your specific URL.

- **Isolation**: While apps share the CPU/RAM of the Plan, they are isolated from each other. App A cannot see the files of App B.


## 7. When to use which? (The Strategy)
### Scenario A: Cost Saving (Development)
You have 3 small internal apps (a Go API, a Python dashboard, and a React frontend).

- Setup: Create ONE App Service Plan (e.g., Standard S1).

- Action: Deploy all 3 Apps into that same Plan.

- Result: You pay for 1 server, but run 3 apps.

### Scenario B: High Performance (Production)
You have a high-traffic Go API that needs 100% of the CPU.

- Setup: Create a DEDICATED App Service Plan (e.g., Premium P2v3).

- Action: Deploy only the Go App into this Plan.

- Result: The app doesn't have to "fight" other apps for resources.

## 8. How it relates to Docker
- The Plan: Provides the Docker Engine and the Linux OS environment.

- The App: Points to the specific Docker Image in your ACR and defines how that container should run.