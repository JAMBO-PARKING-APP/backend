# 📊 JAMBO PARK: System Structures & Visual Flows

This document centralizes the visual representations of the JAMBO PARK ecosystem, from high-level infrastructure to granular operational sequences.

---

## 🏗️ 1. High-Level System Architecture
This diagram shows how the mobile clients, web dashboard, and backend services interact through the API and Messaging layers.

```mermaid
graph TD
    subgraph "Clients (Frontend)"
        UserApp["📱 Flutter User App"]
        OfficerApp["👮 Flutter Officer App"]
        AdminWeb["🖥️ Web Dashboard (Django)"]
    end

    subgraph "API & Logic (Backend)"
        DRF["⚡ REST API (DRF)"]
        WS["📡 WebSockets (Channels)"]
        JamboAI["🧠 AI Reasoning Engine"]
    end

    subgraph "Data & Tasks"
        Postgres[("🐘 PostgreSQL 15")]
        RedisC[("🔴 Redis Cache")]
        RedisQ[("🔄 Redis Task Queue")]
        Celery["⚙️ Celery Workers"]
    end

    UserApp -->|HTTPS| DRF
    OfficerApp -->|HTTPS/WSS| DRF
    OfficerApp -->|WSS| WS
    AdminWeb -->|Internal| DRF
    
    DRF --> JamboAI
    DRF --> Postgres
    DRF --> RedisC
    DRF --> RedisQ
    
    RedisQ --> Celery
    Celery --> Postgres
    Celery --> RedisC
```

---

## 🔄 2. Parking Session Lifecycle
The sequence of events from a user starting a session to the automated cleanup and notification.

```mermaid
sequenceDiagram
    participant User as 📱 Driver
    participant API as ⚡ Backend API
    participant DB as 🐘 Database
    participant Celery as ⚙️ Background Worker
    participant FCM as 🔔 Firebase (Push)

    User->>API: POST /api/parking/start/
    API->>API: 🧠 AI: Check Budget & Geofence
    API->>DB: Create Session (Status: Active)
    API-->>User: 201 Created (Verification QR)

    loop Every 60s
        Celery->>DB: Query Expired Sessions
        alt Session Expired
            Celery->>DB: Status: Expired
            Celery->>FCM: Push Expiry Alert
            FCM-->>User: Notification Received
        end
    end

    User->>API: POST /api/parking/end/
    API->>DB: Calculate Refund & Status: Completed
    API-->>User: 200 OK (Refund Confirmed)
```

---

## 👮 3. Enforcement & Verification Flow
How officers verify vehicle status and issue violations.

```mermaid
graph TD
    Start([Officer Patrols Zone]) --> Scan{Scan QR/Plate?}
    Scan -->|QR| API1[Verify Session via API]
    Scan -->|Plate| API2[Search Plate Status]
    
    API1 --> Valid{Valid?}
    API2 --> Valid
    
    Valid -->|Yes| End([Log Interaction])
    Valid -->|No| Viol[Generate Violation]
    
    Viol --> Photo[Capture Photo Evidence]
    Photo --> GPSTag[Attach GPS Coordinates]
    GPSTag --> Submit[Submit to Revenue Ledger]
    Submit --> Notify[User Notified via SMS/Push]
```

---

## 🌐 4. Regional Multi-Tenancy Isolation
How the system partitions data across different countries (Metadata-based isolation).

```mermaid
graph LR
    User[Request from User] --> MW[Regional Middleware]
    MW --> Context{Identify Country_ID}
    
    subgraph "Logical Data Isolation"
        Context --> UG[(Uganda Context)]
        Context --> KE[(Kenya Context)]
        Context --> TZ[(Tanzania Context)]
    end

    UG -->|Auto-Filter| DB[PostgreSQL]
    KE -->|Auto-Filter| DB
    TZ -->|Auto-Filter| DB
```

---

## 🧠 5. Jambo AI Reasoning Pipeline
The internal "Think" process for local intelligence.

```mermaid
graph LR
    Input[Query] --> Class[Intent Classifier]
    Class --> Policy[Policy Lookup]
    Policy --> Trace[Reasoning Trace Accumulator]
    Trace --> Logic[Executive Logic Synthesis]
    Logic --> Output[Professional Response]
```

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary. v1.0*
