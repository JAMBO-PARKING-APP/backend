# 🚀 JAMBO PARK: Feature Glossary

This document provides a comprehensive list of all features available in the JAMBO PARK ecosystem, categorized by target user.

---

## 📱 1. User Application (Drivers)

The primary interface for vehicle owners to manage their parking lifecycle.

### 🅿️ Parking Management
- **Live Zone Map**: Real-time visualization of parking zones with dynamic availability indicators.
- **Smart Session Start**: Start a session by selecting a zone, vehicle, and duration. Supports automated geofence verification.
- **Dynamic Timer**: A live countdown timer with glassmorphic aesthetics that keeps the user informed of remaining time.
- **Auto-Extension**: One-tap session extension before expiry.
- **Find My Car**: Detailed map marker showing exactly where the vehicle was left.
- **QR Receipting**: Digital QR code generated for every session for quick officer verification.

### 💰 Financials & Wallet
- **Managed Wallet**: Secure digital wallet for instant payments and refunds.
- **Multi-Gateway Support**: Top up via Mobile Money (MTN/Airtel), Stripe, or Pesapal.
- **Automatic Refunds**: Partial refunds for sessions ended early (prorated by minute).
- **Loyalty Program**: Earn points for every minute parked; tier-based rewards for frequent users.

### 🔔 Intelligence & Notifications
- **Geofence Alerts**: Instant "Don't Forget" notifications if the user moves >1km away from an active session.
- **Expiry Warnings**: Push notifications at 10, 5, and 1 minute before session end.
- **Leave Prompts**: Location-aware alerts asking users to vacate the spot if they are still within the zone radius post-session.
- **i18n Support**: Full localization in English, Luganda, Swahili, German, and Arabic.

---

## 👮 2. Officer Application (Enforcement)

The operational tool for parking officers and municipal agents.

### 🔍 Field Operations
- **Zone Live Tracking**: Tabbed view showing "Active Sessions" vs. "Overdue Users" for their assigned zone.
- **QR Verification**: Instant scanning of driver QR codes to verify session validity.
- **Manual Plate Check**: Search by license plate to verify status if QR is unavailable.
- **Real-time Occupancy**: Visual heatmaps of zone occupancy.

### ⚠️ Enforcement & Violations
- **Session Detail View**: Deep-dive into any session (User info, timeline, history).
- **Violation Issuance**: Digital ticket generation with support for:
    - **Photo Evidence**: Capture and upload multiple angles of the violation.
    - **GPS Tagging**: Automatic coordinate attachment for legal defensibility.
    - **Voice Notes**: (Planned) Audio descriptions for violations.
- **Clamping Workflow**: Specialized statuses for clamped or towed vehicles.

### 📊 Coordination & Safety
- **Regional Transition**: App automatically switches context when an officer crosses regional borders.
- **Officer Presence**: Real-time GPS broadcasting of officer location to management.
- **Shift Stats**: Daily summary of violations issued and sessions verified.

---

## 🖥️ 3. Admin Dashboard (Operators)

The centralized control center for system management.

### 🌍 Global Management
- **Regional Context Switcher**: Seamlessly toggle between "Uganda", "Kenya", "Tanzania" contexts as a superuser.
- **Zone Configuration**: Drag-and-drop map interface for defining and resizing parking zones.
- **Rate Management**: Dynamic pricing support (peak/off-peak rates).

### 📈 Analytics & Fiscal
- **Revenue Heatmaps**: Visualize peak revenue hours and high-yield zones.
- **Violation Auditing**: Review and approve/dismiss violations with full evidence trails.
- **User Support**: Context-aware AI assistant helping admins navigate policies and system logs.

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary.*
