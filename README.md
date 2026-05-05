# 🏙️ JAMBO PARK: Enterprise Intelligent Parking System

[![Django CI](https://github.com/jambo-park/system/actions/workflows/django.yml/badge.svg)](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/.github/workflows/django.yml)
[![Flutter CI](https://github.com/jambo-park/system/actions/workflows/flutter.yml/badge.svg)](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/.github/workflows/flutter.yml)
[![Live Demo](https://img.shields.io/badge/Demo-Live-brightgreen)](https://jambo-park.render.com)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)

> **JAMBO PARK** is a state-of-the-art, multi-tenant parking management ecosystem designed for municipal authorities and vehicle owners. Built for massive scalability, regional isolation, and real-time operations.

---

## 🏛️ Project Ecosystem

The system consists of three primary pillars, all integrated into a unified backend core.

*   📱 **[User Application](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/parking_user_app)**: Flutter-based consumer app for session management, payments, and navigation.
*   👮 **[Officer Application](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/parking_officer_app)**: Flutter tool for real-time enforcement, photo-evidence collection, and zone monitoring.
*   🖥️ **[Admin Dashboard](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/templates/dashboard)**: Responsive web interface for regional management and financial auditing.

---

## 📚 Technical Documentation Index

For detailed specifications, refer to the documents in the `docs/` directory:

| Document | Icon | Description |
|----------|------|-------------|
| 🏗️ **[Architecture](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/architecture.md)** | 🏭 | Infrastructure, Security, and Background Task logic. |
| 🚀 **[Features](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/features.md)** | 🛠️ | Complete glossary of capabilities for Users, Officers, and Admins. |
| 📊 **[Diagrams](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/diagrams.md)** | 📈 | Visual maps of system architectures and operational flows. |
| 🗄️ **[Database Schema](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/database_schema.md)** | 🐘 | Detailed ERD and table specifications for PostgreSQL. |
| 🎨 **[Design System](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/design_system.md)** | 🎨 | Branding tokens, Flutter glassmorphism, and web styling rules. |
| 🌐 **[i18n Guide](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/i18n_guide.md)** | 🌍 | Instructions for maintaining translations in 5+ languages. |
| 🛠️ **[Deployment](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/docs/deployment_and_secrets.md)** | 🚀 | Setup guide for Docker, Render, and GitHub Actions. |
| � **[CI: Django](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/.github/workflows/django.yml)** | 🐍 | Automated backend testing and linting configuration. |
| 🤖 **[CI: Flutter](file:///c:/Users/tutum/Downloads/JAMBO%20PARK/.github/workflows/flutter.yml)** | 📱 | Automated mobile app analysis and testing configuration. |
| 📖 **[API Documentation](https://backend.p-space.ai/api/docs/)** | 📑 | Interactive Swagger UI for all system endpoints. |

---

## 🌟 Key Features

### 🅿️ Smart Parking
- **Live Occupancy**: Real-time slot availability tracking.
- **Geofencing**: Automated session end when leaving the zone.
- **QR Verification**: Instant officer verification via digital receipts.

### 💰 Trusted Payments
- **Multi-Gateway**: Support for Mobile Money, Stripe, and Pesapal.
- **Atomic Wallets**: Race-condition-safe balance management.
- **Loyalty Rewards**: Comprehensive points system for frequent use.

### 👮 Enforcement Excellence
- **Photo Evidence**: Secure capture of violation evidence.
- **Overdue Tracking**: Real-time listing of users remaining in zones post-session.
- **Regional Context**: Automatic regional switching for cross-border operations.

### 🧠 Jambo AI Pro (Local Intelligence)
Operating entirely within the Python/Django stack (no external API), the AI engine uses a multi-stage reasoning pipeline:
- **Intent Detection**: Classifies user queries (Financial, Support, Policy).
- **Context Loading**: Pulls relevant system data (User status, Policy entries).
- **Reasoning Trace**: Accumulates a logic trail to justify responses.

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
├── templates/                  # Django Responsive Web Templates
└── .github/workflows/          # Automated CI/CD (Django & Flutter)
```

---

## �️ Development Quick Start

### 1. Prerequisites
- Python 3.11+
- Flutter SDK (stable)
- Docker & Docker Compose
- PostgreSQL 15 & Redis 7

### 2. Setup
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
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary. v2.8*