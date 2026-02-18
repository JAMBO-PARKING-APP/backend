# 🏙️ JAMBO PARK: Enterprise Intelligent Parking System

[![Django CI](https://github.com/jambo-park/system/actions/workflows/django.yml/badge.svg)](https://github.com/jambo-park/system/actions/workflows/django.yml)
[![Flutter CI](https://github.com/jambo-park/system/actions/workflows/flutter.yml/badge.svg)](https://github.com/jambo-park/system/actions/workflows/flutter.yml)
[![Live Demo](https://img.shields.io/badge/Demo-Live-brightgreen)](https://jambo-park.render.com)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)

> **JAMBO PARK** is a state-of-the-art, multi-tenant parking management ecosystem designed for municipal authorities and vehicle owners. Built for massive scalability, regional isolation, and real-time operations.

---

## 🏛️ Project Ecosystem

The system consists of three primary pillars, all integrated into a unified backend core.

- **[User Application](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/parking_user_app)**: Flutter-based consumer app for session management, payments, and navigation.
- **[Officer Application](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/parking_officer_app)**: Flutter tool for real-time enforcement, photo-evidence collection, and zone monitoring.
- **[Admin Dashboard](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/templates/dashboard)**: Responsive web interface for regional management and financial auditing.

---

## 📚 Technical Documentation Index

For detailed specifications, refer to the documents in the `docs/` directory:

| Document | Description |
|----------|-------------|
| 🏗️ **[Architecture](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/architecture.md)** | Infrastructure, Security, and Background Task logic. |
| 🚀 **[Features](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/features.md)** | Complete glossary of capabilities for Users, Officers, and Admins. |
| 📊 **[Diagrams](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/diagrams.md)** | Visual maps of system architectures and operational flows. |
| 🗄️ **[Database Schema](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/database_schema.md)** | Detailed ERD and table specifications for PostgreSQL. |
| 🎨 **[Design System](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/design_system.md)** | Branding tokens, Flutter glassmorphism, and web styling rules. |
| 🌐 **[i18n Guide](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/i18n_guide.md)** | Instructions for maintaining translations in 5+ languages. |
| 🛠️ **[Deployment](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/deployment_and_secrets.md)** | Setup guide for Docker, Render, and GitHub Actions. |

---

## 🧠 Jambo AI Pro (Local Intelligence)

One of JAMBO PARK's most advanced features is the **Jambo AI Pro Reasoning Engine**, which provides "Brain-like" intelligence without external API calls.

- **Instant Context**: AI reasons using real-time user data and local policy encyclopedia.
- **Zero Latency**: Processed entirely on the backend server stack.
- **Defensible Decisions**: Every AI response includes a reasoning justification trace.

---

## 🏗️ Repository Blueprint

```text
JAMBO PARK/
├── apps/                       # Backend Application Modules
│   ├── accounts/               # Identity & Multi-Tenancy Logic
│   ├── parking/                # core logic: Zones, Sessions, Slots
│   ├── enforcement/            # Officer logs & QR Verification
│   ├── rewards/                # Loyalty tiers & Transactions
│   ├── payments/               # Fiscal ledger (Stripe, Pesapal)
│   ├── support_chat/           # 🧠 Jambo AI Reasoning Core
│   └── common/                 # Regional Middleware & Local reverse-geocoding
├── parking_user_app/           # Flutter: Consumer Application
├── parking_officer_app/        # Flutter: Operational Enforcement Tool
├── docs/                       # Comprehensive Technical Specs
└── .github/workflows/          # Automated CI/CD (Django & Flutter)
```

---

## 🛡️ Enterprise-Grade Security
- **Single-Device Enforcement (SDE)**: Custom middleware ensures accounts are never shared across concurrent devices.
- **Regional Isolation**: Automated country-level partitioning ensures data sovereignty for multi-national operators.
- **Geofencing**: High-precision Haversine algorithm validates vehicle positions in real-time.

---

## 🛠️ Development Quick Start

```bash
# Install environment & dependencies
make install

# Initialize local database & regional data
make migrate
make seed-data

# Run all services (API, Celery, Redis)
make run
```

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary. v2.7*