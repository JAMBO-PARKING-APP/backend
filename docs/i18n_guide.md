# 🌍 Jambo Park i18n Guide

This document explains the internationalization (i18n) system implemented in the Jambo Park mobile applications.

## 🛠️ Architecture

Both the **User App** and the **Officer App** use a custom `AppLocalizations` class and a `SettingsProvider` to manage multi-language support.

### Supported Languages
- 🇬🇧 English (`en`)
- 🇹🇿 Swahili (`sw`)
- 🇫🇷 French (`fr`)
- 🇪🇸 Spanish (`es`)
- 🇩🇪 German (`de`)
- 🇸🇦 Arabic (`ar`)

## 🚀 How to Add New Strings

1.  **Open `lib/core/localizations.dart`** in the respective app.
2.  **Add a new getter** to the abstract `AppLocalizations` class:
    ```dart
    String get myNewKey;
    ```
3.  **Implement the getter** in each localization subclass:
    - `_EnglishLocalizations`
    - `_SwahiliLocalizations`
    - `_FrenchLocalizations`
    - `_SpanishLocalizations`

## 🎨 Usage in UI

Always use the `AppLocalizations.of(context)` helper to access strings.

```dart
Text(AppLocalizations.of(context).appTitle)
```

## ⚙️ System Language Detection

By default, the `SettingsProvider` initializes with `null` for the locale, which tells Flutter to follow the device's system language.

If the system language is not supported, it falls back to **English**.

## 🔄 Switching Languages

Use the `SettingsProvider` to manually change the app language:

```dart
Provider.of<SettingsProvider>(context, listen: false).setLocale('sw');
```

To revert to system language:
```dart
Provider.of<SettingsProvider>(context, listen: false).setLocale('system');
```
