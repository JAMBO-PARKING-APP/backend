# Plan: Country configuration, FCM, Pesapal (USD/EUR), and active parking UX

This document describes how the current system behaves, what is broken or incomplete, and how we will implement the requested behavior **before** code changes are merged. It is the agreed blueprint for backend and `parking_user_app` work.

---

## 1. Current architecture (as implemented)

### 1.1 Country and payment configuration

| Layer | Mechanism | Key locations |
|--------|-----------|----------------|
| **Database** | `User.country` FK, `Country`, `CountryConfig` (payment methods, exchange rate), `PaymentGatewayConfig` for Pesapal per country | `apps/common/models.py`, `apps/payments/models.py` |
| **API** | Authenticated endpoints: country detect/set, wallet balance returns currency, `get_country_config(country_code)` for payment methods | `apps/accounts/location_and_features_views.py`, `apps/common/views.py`, `apps/payments/api_views_v2.py` |
| **Request scoping** | Middleware sets `get_current_country()` from `request.user.country` | `apps/common/middleware.py` |
| **Mobile app** | Uses wallet API currency + user profile `countryName` string heuristics for showing Pesapal; **does not** send `X-Country-Code` or call `country-config/<code>/` on every cold start | `parking_user_app` — `start_parking_screen.dart`, `WalletService` |

**Gap:** “Country configuration” does not drive the app in a single source of truth. If `User.country` is unset, APIs default to Uganda/UGX-style behavior; `CountryConfig` missing defaults Pesapal to Uganda only in `get_country_config`. The Flutter UI mixes **wallet currency** with **substring checks on `countryName`**, which is fragile and not aligned with `CountryConfig.payment_methods`.

### 1.2 FCM (push notifications)

| Piece | Status |
|--------|--------|
| **Backend** | `firebase-admin`, `FIREBASE_ENABLED`, `FIREBASE_CREDENTIALS_PATH`; `send_notification_to_user_sync` requires `user.fcm_device_token` | `apps/notifications/firebase_service.py` |
| **Registration** | `POST user/notifications/fcm/register-token/` stores token on **User** | `apps/notifications/api_views.py`, `apps/common/api_urls_user.py` |
| **App** | `FCMService` requests permission, gets token, registers with backend; `syncTokenWithBackend()` after login | `parking_user_app/lib/core/fcm_service.dart` |

**Common reasons users see no pushes**

1. **`FIREBASE_ENABLED=False` or invalid/missing service account JSON** on the server.
2. **Token never registered** — e.g. user denied notifications, or registration runs before login and fails without retry.
3. **Single token field** — last device wins; secondary devices do not receive pushes.
4. **Payload shape** — on Android, data-only messages do not show a tray notification unless the client handles them; the backend should send both `notification` and `data` where a visible alert is required (current service supports notification payloads).
5. **Firebase project mismatch** — app’s `google-services.json` / iOS plist must match the project used by the Admin SDK credentials.

### 1.3 Pesapal and IPN

| Piece | Status |
|--------|--------|
| **API v2** | `PesapalPreWarmView`, `InitiatePesapalPaymentAPIView`, `PesapalUserCallbackView`, `PesapalIPNAPIView`; credentials from `PaymentGatewayConfig` via `PesapalService.get_config_for_country(country)` | `apps/payments/api_views_v2.py`, `apps/payments/pesapal_service.py` |
| **Parking start** | `payment_method == 'pesapal'` can create a Pesapal payment and return `redirect_url` | `apps/parking/api_views_v2.py` |

**Gap (USD/EUR store embed):** In `start_parking_screen.dart`, when currency is USD or EUR and the user picks Pesapal, the app **`launchUrl` to a static store page** and **does not** create a server-side `Transaction` tied to that checkout or wait for IPN before starting parking. That cannot satisfy “strictly backend + app” confirmation.

### 1.4 Active session and “realtime”

| Piece | Status |
|--------|--------|
| **REST** | `user/parking/sessions/?type=active` | `UserParkingSessionsAPIView` |
| **Dashboard** | If `active` session exists, Parking tab shows `ActiveSessionScreen`; otherwise zone list | `user_dashboard_screen.dart` |
| **Timer** | `Timer.periodic(1s)` + local `plannedEndTime` | `active_session_screen.dart` |
| **WebSocket** | Server broadcasts `parking_update` to `user_<id>` | `apps/notifications/consumers.py`, `tasks.py` |
| **Flutter** | **No** `WebSocket` client subscription found for parking updates |

**Gaps**

- Session state is **not** refreshed on a schedule or via WebSocket; only local clock + occasional refetch (e.g. after extend).
- **Progress ring bug:** `CircularProgressIndicator` uses `safe.inSeconds / (24 * 3600)`, which is not the fraction of **this** session’s duration remaining (see §3.2).

### 1.5 Zone list UI

- Zone image is a **full-width top banner**; the **P** icon lives in a `ListTile` **below** the image (`user_dashboard_screen.dart` `_ZoneCard`). The requested layout is **image inline** with the row that contains the P marker (e.g. leading row: thumbnail + P badge + text).

---

## 2. Target behavior (requirements mapping)

### 2.1 Country-driven behavior

1. **Single source of truth:** After login, the app loads **authenticated** country config (currency, `payment_methods`, Pesapal eligibility, optional embed flag) from the backend — derived from `User.country` + `CountryConfig` / `PaymentGatewayConfig`, not from parsing `countryName` strings.
2. **Backend:** Ensure every user has a correct `country_id`; admin or migration fixes existing rows. Optional: `GET /api/user/country-config/` that mirrors wallet + payment methods in one response to reduce round-trips.
3. **App:** Remove fragile `countryName.contains('uganda')` logic; drive dropdowns from API fields.

### 2.2 FCM reliability

1. **Operations:** Set `FIREBASE_ENABLED=True`, valid `FIREBASE_CREDENTIALS_PATH`, Celery workers for async sends if used.
2. **App:** Call `FCMService.syncTokenWithBackend()` after successful login **and** when token refreshes; optionally on app resume if token non-null but last register failed.
3. **Backend:** Log send failures; consider multi-device tokens (future `UserDevice` table) if product requires it.

### 2.3 Parking tab: active session only + true remaining time

1. **When `active` session exists:** Parking tab body shows only the active session view (already largely true); add **periodic refetch** (e.g. every 30–60s) or **WebSocket** subscription to merge server `planned_end` / status.
2. **Countdown and icon:** Compute `remaining = server_planned_end - now` using **NTP-safe** approach: optional `GET` returns `server_time` once; or refetch session periodically to correct drift.
3. **Progress ring:** `value = remaining / totalSessionDuration` where `totalSessionDuration = planned_end - start_time` (both from server), clamped to `[0,1]`.

### 2.4 Zone card: image inline with P

- Refactor `_ZoneCard` to a **horizontal** layout: left — rounded thumbnail (zone image or placeholder); center — P icon + title + subtitle; right — chevron. Keep responsive height and error placeholder for broken URLs.

### 2.5 Pesapal USD/EUR (store embed + IPN) — end-to-end

**Problem:** An arbitrary iframe to `store.pesapal.com` does not pass a **merchant reference** that your IPN can tie to a **pending parking top-up or session payment** unless Pesapal Store is configured to send **custom order reference** and your IPN handler recognizes it.

**Proposed flow (strictly backend-controlled)**

1. **App:** User chooses duration, vehicle, **card (Pesapal)** for USD/EUR country.
2. **Backend:** `POST` creates a `Transaction` (or `ParkingIntent`) with status `pending`, amount/currency, `merchant_reference` unique, `metadata` (zone_id, vehicle_id, duration). Returns `{ transaction_id, merchant_reference, checkout_mode: 'embed', embed_url }`.
   - `embed_url` may be the static store URL **plus** documented query parameters **if** Pesapal Store supports passing reference (must be verified in Pesapal Store / merchant docs). If the store **cannot** pass reference, use **API-initiated redirect** (existing `create_payment`) instead of iframe for USD/EUR — still IPN-driven.
3. **App:** Opens **in-app WebView** (not external browser) loading `embed_url` or shows HTML wrapper with iframe if required by Pesapal; listens for **return URL** or **polling**.
4. **IPN:** Existing `PesapalIPNAPIView` resolves status via Pesapal API; on `completed`, marks `Transaction` completed and **starts parking session** (or credits wallet then starts — product rule).
5. **App polling:** `GET payments/transactions/<id>/` or `GET parking/sessions/?type=active` until session appears or transaction fails — then navigate to active session screen.

**Prerequisite:** Confirm with Pesapal whether **Store embed** can attach **your** `merchant_reference` to the payment that IPN returns. If not, the compliant approach is **same IPN**, **hosted checkout URL** from `InitiatePesapalPaymentAPIView` (no iframe), which you already have.

---

## 3. Implementation phases (recommended order)

| Phase | Scope | Backend | App |
|-------|--------|---------|-----|
| **A** | Observability & FCM | Verify Firebase env on all workers; add structured logging on FCM send failures | Ensure post-login token sync; handle permission denial gracefully |
| **B** | Country config API | Expose one authenticated endpoint aggregating country + payment methods + currencies | On login/app start, fetch and cache; drive Pesapal/wallet UI |
| **C** | Active session sync | Optional: add `server_time` to session response; ensure `planned_end` is authoritative | Periodic poll or WebSocket client; fix progress ring math |
| **D** | Zone card UI | — | Inline thumbnail + P row |
| **E** | USD/EUR Pesapal | Pending transaction + IPN completion → session or wallet | WebView + polling; remove naked `launchUrl` without transaction id |

---

## 4. Suggestions to improve performance and speed

1. **Reduce round-trips:** One `/api/user/bootstrap/` returning user, country config, wallet, active session, and zone list (paginated) with HTTP caching headers where safe.
2. **WebSocket:** Subscribe the user app to `ws/parking/` to invalidate cache when session changes instead of polling every N seconds (lower latency, less load).
3. **Database:** Index `ParkingSession(user, status, planned_end)`; avoid N+1 on zone lists (`select_related('country')` already noted in API).
4. **Celery:** Keep FCM and IPN handling async; avoid blocking request cycle on Pesapal HTTP.
5. **CDN / images:** Serve zone images via CDN or signed URLs with fixed cache TTL; use `cached_network_image` in Flutter.
6. **Pesapal:** Pre-warm token (`PesapalPreWarmView`) on app foreground to shave latency on checkout.

---

## 5. Risks and decisions

| Topic | Decision needed |
|--------|------------------|
| Store iframe vs API checkout | If iframe cannot carry `merchant_reference`, use API redirect for USD/EUR |
| Wallet vs direct session payment | IPN completes wallet top-up first, then app calls `start` with wallet — clearer accounting |
| Multi-device FCM | Product call: single token (current) vs device table |

---

## 6. Acceptance checklist

- [ ] User with `country` set to a non-UG country sees correct currency and payment options from API, not hard-coded Uganda.
- [ ] FCM token registered after login; test push received on physical device (Android + iOS).
- [ ] Active session screen countdown matches server after extend; progress ring matches **session** duration.
- [ ] Zone list shows image aligned with P card row.
- [ ] USD/EUR card payment creates a **pending** backend transaction; IPN completes it; user can start or enter session only after confirmation; no orphan `launchUrl` without id.

---

*Document version: 1.0 — prepared as the pre-implementation agreement for backend and `parking_user_app`.*
