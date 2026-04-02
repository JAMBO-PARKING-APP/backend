# Comprehensive Feature Implementation Plan

## Current Status ✅
- Login works and navigates to HomeScreen
- FCM token registration works
- Session persists (StorageManager saves tokens)
- Data fetching works (zones, sessions, wallet, payments)

## Features to Implement

### PHASE 1: Session & Persistence (HIGH PRIORITY)
- [x] Tokens saved to secure storage
- [ ] Verify token refresh on app restart
- [ ] Auto-logout on token expiration
- [ ] Handle 401 errors gracefully

### PHASE 2: Location & Country Detection (HIGH PRIORITY)  
- [ ] Background location tracking service
- [ ] Auto-detect country from GPS coordinates
- [ ] Allow manual country override on profile
- [ ] Store user's current location
- [ ] Use Redis for caching location data

### PHASE 3: Profile Page (HIGH PRIORITY)
New Profile Page UI Components:
- [ ] Profile header (avatar, name, phone, country)
- [ ] Edit profile button
- [ ] Notifications section (in-app notifications)
- [ ] Profile picture management (upload/change)
- [ ] Support/Help section (link to support chat)
- [ ] Reservations section (view/manage booking)
- [ ] Settings/Preferences

### PHASE 4: Reservations Management (MEDIUM)
- [ ] New ReservationProvider for state management
- [ ] Reservations list view in profile
- [ ] Reservation details page
- [ ] Cancel reservation functionality
- [ ] Reservation history

### PHASE 5: Host Parking Page (MEDIUM)
Separate page for parking lot owners:
- [ ] List user's hosted parking zones
- [ ] Earnings/revenue dashboard
- [ ] Active reservations at their lots
- [ ] Analytics (occupancy, price trends)
- [ ] Settings for each parking zone

### PHASE 6: WebSocket & Redis Optimization (ADVANCED)
- [ ] Redis caching for:
  - User session data
  - Location coordinates (TTL: 5 min)
  - Zone availability data (TTL: 10 min)
  - User preferences
- [ ] WebSocket for:
  - Real-time parking availability
  - Live reservation notifications
  - Location updates from other drivers

---

## Detailed Implementation Tasks

### Session Persistence (Already ~80% done)
```
✅ Tokens stored in FlutterSecureStorage
✅ User JSON cached locally
✅ Auth status preserved across app restarts
⚠️ TODO: Test token refresh on network changes
⚠️ TODO: Handle 401 + token refresh automatically
```

### Location Tracking Service
**Files to Create:**
- `parking_user_app/lib/core/location_service.dart`
- Implement background location updates
- Update server with lat/long every 30 seconds
- Cache last known location

**Backend Endpoint Needed:**
```
PUT/POST /api/user/location/
Body: {
  "latitude": 0.3476,
  "longitude": 32.5825,
  "accuracy": 10.0,
  "timestamp": "2026-04-02T09:47:00Z"
}
```

### Country Detection
**Flow:**
1. Get user's GPS coordinates
2. Reverse geocode to get country
3. Compare with `user.country` in backend
4. If different, prompt user to confirm/update
5. Cache result with TTL of 24 hours

### Profile Page Structure
```
ProfilePage/
├── ProfileHeader (avatar, name, country)
├── EditProfileButton
├── Tabs:
│   ├── Overview (notifications, reservations)
│   ├── Notifications (notification list)
│   ├── Reservations (active + history)
│   ├── Support (chat, FAQ, support tickets)
│   └── Settings (country, preferences, language)
└── ProfilePictureUpdateModal
```

### Host Parking Page
```
HostParkingPage/
├── TabBar:
│   ├── Dashboard (earnings, occupancy)
│   ├── Active Reservations (real-time)
│   ├── Analytics (charts, trends)
│   └── Settings (price, capacity, hours)
└── ZoneListView (swipe to see details)
```

### Redis Usage Strategy
```
Cache Keys:
- user:{user_id}:location → GPS coordinates (TTL: 5m)
- user:{user_id}:country → Country data (TTL: 24h)
- user:{user_id}:preferences → User settings (TTL: 24h)
- zone:{zone_id}:availability → Current status (TTL: 10m)
- parking_session:{session_id} → Active session (TTL: 30d)

Real-time updates via WebSocket:
- location_update → Broadcast to nearby drivers
- availability_changed → Zone status changes
- reservation_confirmed → Instant notification
```

### WebSocket Channels
```
Connections:
- /ws/user/{user_id}/ → Personal notifications
- /ws/zone/{zone_id}/ → Zone availability updates
- /ws/driver/{driver_id}/ → Real-time location for other drivers
- /ws/host/{host_id}/earnings → Real-time earnings updates
```

---

## Implementation Priority

### Week 1 (ASAP)
1. ✅ Login fixes (DONE)
2. Session token refresh
3. Location tracking service
4. Country detection/validation

### Week 2
1. Profile page UI
2. Edit profile functionality
3. Profile picture upload
4. Notifications view

### Week 3
1. Reservations management
2. Reservations in profile
3. Reservation history

### Week 4
1. Host parking page
2. Host dashboard
3. Host settings

### Week 5+
1. WebSocket optimization
2. Redis caching strategy
3. Performance tuning
4. Real-time features

---

## Backend Changes Needed

### Existing Endpoints to Enhance:
1. `PUT /api/user/profile/` - Add country override
2. `GET /api/user/profile/` - Return notifications count
3. `POST /api/user/location/` - Store and cache location

### New Endpoints to Create:
1. `GET /api/user/reservations/` - List reservations
2. `GET /api/user/reservations/{id}/` - Get details
3. `POST /api/user/reservations/{id}/cancel/` - Cancel reservation
4. `GET /api/user/country/detect/` - Server-side country detection
5. `GET /api/user/notifications/` - Get notifications list
6. `GET /api/host/parking/zones/` - Host's parking zones
7. `GET /api/host/dashboard/` - Host analytics

### WebSocket Handlers:
1. `connect` - Authenticate WebSocket client
2. `location_update` - Receive location from app
3. `availability_update` - Send zone status to app
4. `notification_dispatch` - Send notifications to connected clients

---

## Questions & Clarifications

1. **Country Override**: Should users be able to manually select country if the detected one is wrong?
   - YES / NO / ASK THEM

2. **Location Privacy**: How often should location be sent? (Every 30s? Every 5m?)
   - Current suggestion: 30 seconds for parking zones, 5 minutes otherwise

3. **Host Parking**: Can any user become a host, or is this role-based?
   - Assuming: Role-based (only users with role='host' or 'parking_owner')

4. **Notifications**: What types should be shown?
   - Reservations (confirmed, cancelled, updated)
   - Parking alerts (zone full, availability, etc.)
   - System notifications (app updates, maintenance)
   - Support responses

5. **Profile Picture**: Max file size? Supported formats?
   - Suggestion: 5MB, JPEG/PNG only

---

## File Structure to Create

```
parking_user_app/lib/
├── core/
│   ├── location_service.dart (NEW)
│   ├── country_detector.dart (NEW)
│   └── redis_client.dart (NEW - if needed)
│
├── features/
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart (NEW)
│   │   │   ├── edit_profile_screen.dart (NEW)
│   │   │   └── notifications_screen.dart (NEW)
│   │   ├── providers/
│   │   │   └── profile_provider.dart (NEW)
│   │   └── widgets/
│   │       ├── profile_header.dart (NEW)
│   │       └── notification_item.dart (NEW)
│   │
│   ├── host_parking/
│   │   ├── screens/
│   │   │   ├── host_dashboard.dart (NEW)
│   │   │   ├── host_analytics.dart (NEW)
│   │   │   └── host_settings.dart (NEW)
│   │   └── providers/
│   │       └── host_provider.dart (NEW)
│   │
│   └── reservations/
│       ├── screens/
│       │   ├── reservations_list.dart (NEW)
│       │   └── reservation_details.dart (NEW)
│       └── providers/
│           └── reservation_provider.dart (NEW)
```

---

## Next Steps

1. Confirm login persistence is working ✅
2. Start with Location Service (Phase 2)
3. Then Profile Page (Phase 3)  
4. Then Reservations (Phase 4)
5. Finally Host Parking (Phase 5) and WebSocket optimization (Phase 6)

Would you like me to start implementing Phase 2 (Location & Country Detection)?
