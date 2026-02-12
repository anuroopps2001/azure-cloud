# Azure Application Gateway -- Detailed Concept Guide

## 🎯 Goal

This document provides a clear understanding of **Azure Application
Gateway**, its architecture, components, and how traffic flows before
moving into hands‑on labs.

This is written with a practical Cloud/DevOps perspective and also maps
concepts to OpenShift ingress where helpful.

------------------------------------------------------------------------

# 🧠 What is Azure Application Gateway?

Azure Application Gateway is a **Layer 7 (HTTP/HTTPS) load balancer**
that manages web traffic.

Instead of exposing backend servers directly:

    Client → Application Gateway → Backend Servers

It understands:

-   HTTP / HTTPS
-   URLs
-   Hostnames
-   SSL Certificates
-   Path-based routing
-   Web Application Firewall (WAF)

------------------------------------------------------------------------

# 🔥 Why Use Application Gateway?

## Key Benefits

-   Central SSL termination
-   Path-based routing
-   Secure ingress architecture
-   Backend health monitoring
-   Zero public exposure for VMs
-   Web Application Firewall support

------------------------------------------------------------------------

# 🧱 Core Components

Understanding these components is essential before deployment.

------------------------------------------------------------------------

## 1️⃣ Frontend IP

Entry point for user traffic.

Contains:

-   Public IP or Private IP
-   Ports (80 / 443)

Example:

    https://contoso.com → Application Gateway

------------------------------------------------------------------------

## 2️⃣ Listener

Defines:

-   Protocol (HTTP / HTTPS)
-   Port
-   Hostname (optional)
-   SSL certificate (for HTTPS)

Listener = "Where to listen for traffic".

------------------------------------------------------------------------

## 3️⃣ Backend Pool

Backend Pool is a collection of servers where traffic is forwarded.

Example:

    ImageServerPool:
       VM1
       VM2

    VideoServerPool:
       VM3
       VM4

This is similar to:

    OpenShift service endpoints

------------------------------------------------------------------------

## 4️⃣ Backend Settings (HTTP Settings)

Defines how Gateway talks to backend:

-   Backend port
-   Protocol (HTTP or HTTPS)
-   Session affinity
-   Timeout

------------------------------------------------------------------------

## 5️⃣ Routing Rules

Routing rule connects:

    Listener → Backend Pool

Types:

-   Basic rule
-   Path-based rule

------------------------------------------------------------------------

# 🧭 Path-Based Routing (Very Important)

Application Gateway can route traffic based on URL paths.

Example:

    /images/* → ImageServerPool
    /video/*  → VideoServerPool

This allows a single gateway to serve multiple services.

------------------------------------------------------------------------

# 🔐 SSL Termination

Application Gateway can terminate HTTPS.

Flow:

    Client (HTTPS)
         ↓
    Application Gateway (decrypts SSL)
         ↓
    Backend Servers (HTTP or HTTPS)

Benefits:

-   Centralized certificate management
-   Reduced backend complexity

------------------------------------------------------------------------

# 🛡️ Web Application Firewall (WAF)

Optional security layer.

Protects against:

-   SQL Injection
-   XSS
-   Common web attacks

Acts like an external WAF in front of applications.

------------------------------------------------------------------------

# 🧠 Traffic Flow Architecture

    Internet
       ↓
    Application Gateway (L7 Load Balancer)
       ↓
    Backend Pool (Multiple VMs)

Gateway performs:

-   SSL termination
-   Health probing
-   Load balancing
-   Path routing

------------------------------------------------------------------------

# ⚖️ Application Gateway vs Azure Load Balancer

  Feature              Application Gateway   Load Balancer
  -------------------- --------------------- ---------------------
  Layer                Layer 7               Layer 4
  Protocol Awareness   HTTP/HTTPS            TCP/UDP
  SSL Termination      Yes                   No
  Path Routing         Yes                   No
  WAF Support          Yes                   No
  Use Case             Web apps / APIs       Raw network traffic

------------------------------------------------------------------------

# 🔄 Mapping to OpenShift Concepts

  OpenShift                     Azure
  ----------------------------- ---------------------
  Router / Ingress Controller   Application Gateway
  Secure Route                  HTTPS Listener
  Backend Pods                  Backend Pool VMs
  Path Routing                  URL-based routing

If you understand OpenShift routes, Application Gateway will feel
familiar.

------------------------------------------------------------------------

# 🧪 Minimal Lab Architecture (Upcoming)

We will build:

    VNet
     ├── Subnet-AppGW
     └── Subnet-Backend

    Application Gateway
       ↓
    Backend Pool
       ├── VM1
       └── VM2

Goal:

-   Observe traffic distribution
-   Understand listener → backend mapping

------------------------------------------------------------------------

# ⚠️ Important Design Rules

-   Application Gateway requires a **dedicated subnet**
-   Do NOT place VMs in the same subnet as the gateway
-   Backend VMs should use private IPs

------------------------------------------------------------------------

# 🎯 What You Should Understand Before the Lab

You should be clear on:

-   What is a listener?
-   What is a backend pool?
-   What is SSL termination?
-   Difference between Layer 4 and Layer 7 load balancing

------------------------------------------------------------------------

# 📌 One-Line Summary

Azure Application Gateway is a Layer 7 traffic manager that provides
secure, intelligent routing of HTTP/HTTPS traffic to backend
applications, similar to an external ingress controller.
