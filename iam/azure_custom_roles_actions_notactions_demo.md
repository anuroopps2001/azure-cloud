# Azure Custom RBAC Roles -- Actions vs NotActions (Practical Guide)

## 🎯 Goal

This document explains:

-   How **custom roles** work in Azure RBAC
-   The meaning of **actions** and **notActions**
-   How permissions are cumulative
-   Real-world scenario:
    -   Junior developers (No Delete)
    -   Senior developers (Delete allowed)
    -   Role assignments at **Subscription** and **Group** levels

------------------------------------------------------------------------

# 🧠 Core RBAC Mental Model

Azure calculates permissions like this:

    Effective Permissions =
      ALL actions
      MINUS notActions
      PLUS permissions from other roles

Azure RBAC is **additive** --- permissions from multiple roles are
combined.

------------------------------------------------------------------------

# 🔑 What are `actions`?

    "actions": []

These define **what operations are allowed** at the control plane.

Examples:

    Microsoft.Compute/virtualMachines/write
    Microsoft.Network/virtualNetworks/read
    Microsoft.Storage/storageAccounts/write

Example:

``` json
"actions": ["Microsoft.Storage/*"]
```

Means:

    ✔ Create storage resources
    ✔ Update storage resources
    ✔ Read storage resources

------------------------------------------------------------------------

# ❌ What are `notActions`?

    "notActions": []

These REMOVE permissions from the allowed list.

Think:

    actions - notActions = final permissions

Example:

``` json
"actions": ["Microsoft.Storage/*"],
"notActions": ["Microsoft.Storage/storageAccounts/delete"]
```

Result:

    ✔ Create storage account
    ✔ Update storage account
    ❌ Delete storage account

------------------------------------------------------------------------

# ⚠️ Important: notActions is NOT a deny rule

If another role grants delete permission:

    Delete becomes allowed again.

Azure RBAC combines permissions from all roles.

------------------------------------------------------------------------

# 🧪 Custom Role Example -- Dev-NoDelete-Operator

Goal:

    ✔ Developers can create and update resources
    ❌ Developers cannot delete resources
    ❌ Developers cannot modify IAM

Example Role Definition:

``` json
{
  "properties": {
    "roleName": "Dev-NoDelete-Operator",
    "description": "Can manage resources but cannot delete or modify access",
    "assignableScopes": [
      "/subscriptions/<SUB-ID>"
    ],
    "permissions": [
      {
        "actions": ["*"],
        "notActions": [
          "*/delete",
          "Microsoft.Authorization/*"
        ],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```

Azure interprets this as:

    ALLOW everything
    MINUS delete operations
    MINUS IAM modifications

------------------------------------------------------------------------

# 👥 Real Scenario -- Junior Devs vs Senior Devs

## Groups

    dev-team        → Junior developers
    senior-devs     → Senior engineers

Both groups exist in Microsoft Entra ID.

------------------------------------------------------------------------

## Role Assignments at Subscription Level

    dev-team      → Dev-NoDelete-Operator
    senior-devs   → Contributor

------------------------------------------------------------------------

## User Membership

    JuniorUser  ∈ dev-team
    SeniorUser  ∈ dev-team + senior-devs

------------------------------------------------------------------------

# 🧮 Effective Permission Calculation

## Junior Developer

Roles:

    Dev-NoDelete-Operator

Result:

    ✔ Create resources
    ✔ Modify resources
    ❌ Delete resources

------------------------------------------------------------------------

## Senior Developer

Roles:

    Dev-NoDelete-Operator
    + Contributor

Azure combines permissions:

    ✔ Create resources
    ✔ Modify resources
    ✔ Delete resources

Contributor adds delete back.

------------------------------------------------------------------------

# 🏗️ Why Enterprises Use This Model

Instead of editing one role for everyone:

    Base Role (Safe) → dev-team
    Elevated Role    → senior-devs

Benefits:

-   Clear governance
-   Easier audits
-   No need to modify custom role repeatedly

------------------------------------------------------------------------

# 🧱 Scope and Inheritance

Roles can be assigned at:

    Management Group
    Subscription
    Resource Group
    Resource

Permissions flow downward:

    MG → Subscription → Resource Group → Resource

Azure calculates:

    All roles from all scopes + all groups = Effective permissions

------------------------------------------------------------------------

# 🚨 Common Mistakes

❌ Thinking notActions is a hard deny\
❌ Assigning roles directly to users instead of groups\
❌ Using "\*" without removing risky permissions\
❌ Expecting lower roles to override higher ones

------------------------------------------------------------------------

# ✅ Best Practices

-   Assign roles to **groups**, not individuals
-   Use custom roles when Contributor is too broad
-   Start narrow when designing roles
-   Use re-usable elevated groups (ex: senior-devs)

------------------------------------------------------------------------

# 📌 One-Line Summary

Custom roles in Azure define allowed actions, remove risky operations
using notActions, and final permissions are the cumulative result of all
roles assigned across scopes and group memberships.
