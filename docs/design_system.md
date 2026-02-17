# 🎨 Mobile Design System (Enterprise spec)

The JAMBO PARK Design System is a comprehensive set of tokens, components, and layout rules designed for high-performance Flutter mobile applications.

---

## 🛑 1. Brand Tokens (Colors)

We utilize a Material 3 palette optimized for readability in outdoor environments.

| Token | Value | Hex | Usage |
|-------|-------|-----|-------|
| `primary` | Blue 6 | `#1890FF` | Primary actions, state indicators. |
| `success` | Green 6 | `#52C41A` | Paid sessions, slot availability. |
| `warning` | Gold 6 | `#FAAD14` | Approaching expiry, pending payment. |
| `error` | Red 6 | `#FF4D4F` | Illegal parking, system failure alerts. |
| `background`| Neutral 1 | `#FAFAFA` | Main screen surface. |

---

## 📐 2. Layout & Geometry

All components follow a strict geometric grid to ensure visual harmony.

- **Corner Radius**: Standardized **12px** for all interactive elements (Cards, Dialogs, Inputs).
- **Edge Insets**: 
  - Page Padding: `16px`
  - Internal Card Padding: `12px`
  - Vertical Spacing (Small): `8px`
  - Vertical Spacing (Large): `24px`

---

## 🛠️ 3. Component Specifications

### 3.1 Buttons
- **Primary Elevated**: Uses `primaryColor` with a 30% alpha tinted shadow.
- **Outlined**: Uses `#D9D9D9` borders for secondary actions (e.g., Cancel).

```dart
// Standard Button Implementation
ElevatedButton(
  style: AppTheme.lightTheme.elevatedButtonTheme.style,
  onPressed: () {},
  child: const Text('START PARKING'),
)
```

### 3.2 Cards
- **Architecture**: `elevation: 1` with a `0.5px` border of `dividerColor`.
- **Logic**: Used for grouping logically related data (e.g., Active Session details).

### 3.3 Inputs (Forms)
- **Filled State**: Light grey background (`#FAFAFA`) to differentiate from page background.
- **Focus State**: `2px` primary blue border to comply with accessibility standards.

---

## 🌗 4. Dark Mode Strategy

The apps utilize an **OLED-optimized** dark theme.

| Light Component | Dark Value | Rationale |
|-----------------|------------|-----------|
| `background` | `#141414` | True black for battery savings. |
| `surface` | `#1F1F1F` | Subtle elevation contrast. |
| `textPrimary` | `#EBEBEB` | Off-white to reduce eye strain. |

---

## ♿ 5. Accessibility (A11y)

- **Touch Targets**: Minimum `48x48px` for all interactive elements.
- **Contrast**: Text-to-background ratio maintained above **4.5:1**.
- **Haptics**: Integration of `HapticFeedback.mediumImpact()` on critical transactions (Payment start, Session end).

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary.*
