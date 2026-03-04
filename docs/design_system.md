# 🎨 JAMBO PARK: Design System & UI/UX Specs

JAMBO PARK follows a "Premium Utility" design philosophy—balancing high-density data visualization with sleek, modern aesthetics across Web and Mobile.

---

## 💎 Design Tokens (Brand Identity)

| Token | Value | usage |
|-------|-------|-------|
| **Primary** | `#2D5CFE` | Main branding, buttons, active states. |
| **Primary Soft**| `#E9EFFF` | Background for primary buttons, highlights. |
| **Danger** | `#FC5185` | Violations, errors, critical alerts. |
| **Success** | `#3FC1C9` | Confirmed sessions, payments. |
| **Surface** | `#FFFFFF` | Card backgrounds, elevated surfaces. |
| **Text Primary**| `#1A1A1B` | Main headings and body text. |

---

## 📱 Mobile (Flutter) Components

### 1. Glassmorphic Cards
Used in the `User App` to provide a premium, modern feel.
- **Implementation**: Uses `BackdropFilter` with `ImageFilter.blur`.
- **Properties**: `sigmaX: 10, sigmaY: 10`.
- **Border**: Thin 1px white border with 20% opacity.

### 2. Skeleton Loaders
Implemented globally for data fetching states.
- **Library**: `shimmer` package.
- **Pattern**: Matching the exact geometry of the loaded card to prevent layout shifts.

### 3. Animated Transitions
- **Hero Animations**: License plates animate from list view to detail view.
- **Slide Transitions**: Used for tab switching in `ZoneSessionsScreen`.

---

## 🌐 Web (Django Admin) Styling

### 1. Responsive Layout
The dashboard uses **Bootstrap 5** with custom glassmorphism overrides.
- **Sidebar**: High-contrast dark theme with hover-state indicators.
- **Stats Cards**: Animated number counting on load.

### 2. Typography
- **Primary**: `Inter`, Sans-serif.
- **Secondary**: `Roboto Mono` for license plates and transaction IDs.

---

## 🛠️ Implementation Snippets

### Flutter Glassmorphism Mixin
```dart
Widget glassBox({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: child,
      ),
    ),
  );
}
```

### CSS Utility: Glassmorphism
```css
.glass-panel {
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.3);
}
```

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary. v2.2*
