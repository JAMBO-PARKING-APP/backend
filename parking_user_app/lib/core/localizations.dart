import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      _getLocalization(locale.languageCode),
    );
  }

  static AppLocalizations _getLocalization(String languageCode) {
    switch (languageCode) {
      case 'sw':
        return _SwahiliLocalizations();
      case 'fr':
        return _FrenchLocalizations();
      case 'es':
        return _SpanishLocalizations();
      case 'de':
        return _GermanLocalizations();
      case 'ar':
        return _ArabicLocalizations();
      case 'en':
      default:
        return _EnglishLocalizations();
    }
  }

  // Common: Core UI strings
  String get appTitle;
  String get welcome;
  String get login;
  String get register;
  String get logout;
  String get phone;
  String get password;
  String get email;
  String get confirmPassword;
  String get firstName;
  String get lastName;
  String get next;
  String get back;
  String get save;
  String get delete;
  String get confirm;
  String get areYouSure;
  String get deleteAccount;
  String get deleteAccountDescription;

  // Auth related
  String get enterOtp;
  String get otpSent;
  String get resendOtp;
  String get verifyPhone;
  String get phoneVerified;

  // Parking related
  String get startParking;
  String get stopParking;
  String get endParking;
  String get parkingActive;
  String get parkingHistory;
  String get zones;
  String get selectZone;

  // Payments
  String get payments;
  String get transactions;
  String get wallet;
  String get balance;
  String get topUp;
  String get paymentMethod;

  // Chat & Support
  String get chat;
  String get support;
  String get startConversation;
  String get conversations;
  String get messages;
  String get sendMessage;
  String get noConversations;
  String get newMessage;

  // Settings
  String get settings;
  String get language;
  String get theme;
  String get darkMode;
  String get lightMode;
  String get notifications;
  String get about;

  // Errors
  String get error;
  String get errorOccurred;
  String get tryAgain;
  String get loading;

  // New keys for Home Screen
  String get activeParking;
  String get timeLeft;
  String get currentCost;
  String get view;
  String get upcomingReservation;
  String get navigateToZone;
  String get lookingForParking;
  String get findSpotsNearYou;
  String get searchDestination;
  String get quickActions;
  String get myVehicles;
  String get reservations;
  String get recentActivity;
  String get viewAll;
  String get noRecentSessions;
  String get unpaidViolations;
  String get payNow;

  // Added for SPACE Redesign
  String get selectLanguage;
  String get english;
  String get french;
  String get german;
  String get swahili;
  String get spanish;
  String get arabic;
  String get system;
  String get hostParkingSpace;
  String get hostParkingSpaceSubtitle;
  String get helpCenter;
  String get privacyPolicy;
  String get termsOfService;
  String get aboutSpacePark;
  String get secureParkingMadeEasy;
  String get alreadyHaveAccount;
  String get dontHaveAccount;
  String get joinSpacePark;
  String get iAcceptThe;
  String get terms;
  String get loginToYourAccount;
  String get forgotPassword;
  String get comingSoon;
  String get passwordResetSoon;
  String get confirmYourPasswordPrompt;
  String get passwordsDoNotMatch;
  String get passwordTooShort;
  String get registrationFailed;
  String get accountDeletionRequested;
  String get failedToRequestDeletion;
  String get permissionsUpdated;
  String get uploadingPhoto;
  String get photoUpdated;
  String get uploadFailed;
  String get deleteAccountConfirmation;
  String get yourDigitalPass;
  String get scanToVerify;
  String get name;
  String get vehicleLabel;
  String get partnerProgram;
  String get selectCountry;
  String get pleaseSelectCountry;
  String get continueText;
  String get nearestParking;
  String get km;
  String get walletBalance;
  String get activeSession;
  String get startNewSession;
  String get rate;
  String get slots;
  String get directions;
  String get viewOnMap;
  String get nearbyParking;
  String get searchParking;
  String get navigatingTo;
  String get remaining;
  String get unableToGetLocation;
  String get startParkingSession;
  String get startReservedSession;
  String get reservationConfirmed;
  String get selectVehicle;
  String get duration;
  String get minutes;
  String get startParkingNow;
  String get confirmBooking;
  String get confirmReservation;
  String get date;
  String get cancel;
  String get pleaseSelectVehicleAndZone;
  String get startTimeInFuture;
  String get reservationFailed;
  String get paymentSuccessful;
  String get processingReservation;
  String get initiatingPayment;
  String get oneClickSuccess;
  String get startReservedSessionPrompt;
  String get bookSpotPrompt;
  String get areYouSureEndSession;
  String get endSession;
  String get sessionEndedSuccess;
  String get extendDuration;
  String get additionalCost;
  String get insufficientBalance;
  String get parkingLocationSaved;
  String get noSavedLocation;
  String get viewVerificationQR;
  String get endSessionEarly;
  String get history;
  String get saveSpot;
  String get findCar;
  String get until;
  String get vehicle;
  String get extended;
  String get sessionExtendedBy;
  String get hours;
  String get sessionEnded;
  String get payAndExtendNow;
  String get processingPayment;
  String get sessionStarting;
  String get spotBooked;
  String get spotBookedSuccess;
  String get canStartNowPrompt;
  String get ok;
  String get bookSpot;
  String get time;
  String get showToOfficer;
  String get expiresAt;
  String get languagePreferences;
  String get themeSettings;
  String get current;
  String get appVersion;
  String get buildNumber;
  String get lastUpdated;
  String get account;
  String get preferences;

  // Language selection
  String get chooseYourLanguage;
  String get selectPreferredLanguage;
  String get selectLanguageForBestExperience;
  
  // Country-specific terms
  String get termsAndConditions;
  String get termsDescription;
  String get privacyDescription;
  String get countrySpecificTerms;
  String get localLawsNotice;
  
  // Country detection
  String get detectingLocation;
  String get detectingLocationSubtitle;
  String get spaceAvailableInCountry;
  String get spaceNotAvailableTitle;
  String spaceNotAvailableBody(String countryName);
  String get retryDetection;
  String get locationDetectionFailed;
  String get locationDetectionFailedSubtitle;
}

// English Localizations
class _EnglishLocalizations extends AppLocalizations {
  _EnglishLocalizations();

  @override
  String get viewOnMap => 'View on Map';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'Welcome to SPACE';
  @override
  String get login => 'Login';
  @override
  String get register => 'Register';
  @override
  String get logout => 'Logout';
  @override
  String get phone => 'Phone Number';
  @override
  String get password => 'Password';
  @override
  String get email => 'Email';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get firstName => 'First Name';
  @override
  String get lastName => 'Last Name';
  @override
  String get next => 'Next';
  @override
  String get back => 'Back';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get confirm => 'Confirm';
  @override
  String get areYouSure => 'Are you sure?';
  @override
  String get deleteAccount => 'Delete Account';
  @override
  String get deleteAccountDescription =>
      'This will permanently delete your account and all associated data.';

  @override
  String get enterOtp => 'Enter OTP';
  @override
  String get otpSent => 'OTP sent to your phone';
  @override
  String get resendOtp => 'Resend OTP';
  @override
  String get verifyPhone => 'Verify Phone Number';
  @override
  String get phoneVerified => 'Phone verified successfully';

  @override
  String get startParking => 'Start Parking';
  @override
  String get stopParking => 'Stop Parking';
  @override
  String get endParking => 'End Parking';
  @override
  String get parkingActive => 'Parking Active';
  @override
  String get parkingHistory => 'Parking History';
  @override
  String get zones => 'Zones';
  @override
  String get selectZone => 'Select a Zone';

  @override
  String get payments => 'Payments';
  @override
  String get transactions => 'Transactions';
  @override
  String get wallet => 'Wallet';
  @override
  String get balance => 'Balance';
  @override
  String get topUp => 'Top Up';
  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get chat => 'Chat';
  @override
  String get support => 'Support';
  @override
  String get startConversation => 'Start Conversation';
  @override
  String get conversations => 'Conversations';
  @override
  String get messages => 'Messages';
  @override
  String get sendMessage => 'Send Message';
  @override
  String get noConversations => 'No conversations yet';
  @override
  String get newMessage => 'New Message';

  @override
  String get settings => 'Settings';
  @override
  String get language => 'Language';
  @override
  String get theme => 'Theme';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get lightMode => 'Light Mode';
  @override
  String get notifications => 'Notifications';
  @override
  String get about => 'About';

  @override
  String get error => 'Error';
  @override
  String get errorOccurred => 'An error occurred';
  @override
  String get tryAgain => 'Try Again';
  @override
  String get loading => 'Loading...';

  @override
  String get activeParking => 'ACTIVE PARKING';
  @override
  String get timeLeft => 'Time Left';
  @override
  String get currentCost => 'Current Cost';
  @override
  String get view => 'View';
  @override
  String get upcomingReservation => 'UPCOMING RESERVATION';
  @override
  String get navigateToZone => 'Navigate to Zone';
  @override
  String get lookingForParking => 'Looking for parking?';
  @override
  String get findSpotsNearYou => 'Find the best spots near you';
  @override
  String get searchDestination => 'Search destination...';
  @override
  String get quickActions => 'Quick Actions';
  @override
  String get myVehicles => 'My Vehicles';
  @override
  String get reservations => 'Reservations';
  @override
  String get recentActivity => 'Recent Activity';
  @override
  String get viewAll => 'View All';
  @override
  String get noRecentSessions => 'No recent parking sessions';
  @override
  String get unpaidViolations => 'Unpaid Violations';
  @override
  String get payNow => 'Pay Now';

  @override
  String get selectLanguage => 'Select Language';
  @override
  String get english => 'English';
  @override
  String get french => 'French';
  @override
  String get german => 'German';
  @override
  String get swahili => 'Swahili';
  @override
  String get spanish => 'Spanish';
  @override
  String get arabic => 'Arabic';
  @override
  String get system => 'System Default';
  @override
  String get hostParkingSpace => 'Host a Parking Space';
  @override
  String get hostParkingSpaceSubtitle => 'Earn money by listing your empty space!';
  @override
  String get helpCenter => 'Help Center';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get termsOfService => 'Terms of Service';
  @override
  String get aboutSpacePark => 'About Space Park';
  @override
  String get secureParkingMadeEasy => 'SECURE PARKING MADE EASY';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get dontHaveAccount => 'Don\'t have an account?';
  @override
  String get joinSpacePark => 'Join Space Park';
  @override
  String get iAcceptThe => 'I accept the ';
  @override
  String get terms => 'Terms';
  @override
  String get loginToYourAccount => 'Login to your Space Park account';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get comingSoon => 'Coming soon!';
  @override
  String get passwordResetSoon => 'Password reset functionality coming soon!';
  @override
  String get confirmYourPasswordPrompt => 'Confirm your password';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get passwordTooShort => 'Password too short';
  @override
  String get registrationFailed => 'Registration failed';
  @override
  String get accountDeletionRequested => 'Account deletion requested.';
  @override
  String get failedToRequestDeletion => 'Failed to request deletion.';
  @override
  String get permissionsUpdated => 'Permissions updated';
  @override
  String get uploadingPhoto => 'Uploading photo...';
  @override
  String get photoUpdated => 'Photo updated';
  @override
  String get uploadFailed => 'Upload failed';
  @override
  String get deleteAccountConfirmation => 'Are you sure you want to delete your account? This action cannot be undone immediately, but your data will be kept for 30 days before permanent deletion.';
  @override
  String get yourDigitalPass => 'Your Digital Pass';
  @override
  String get scanToVerify => 'Scan this code to verify your identity';
  @override
  String get name => 'Name';
  @override
  String get vehicleLabel => 'Vehicle';
  @override
  String get partnerProgram => 'PARTNER PROGRAM';
  @override
  String get selectCountry => 'Select Your Country';
  @override
  String get pleaseSelectCountry => 'Please select your country to continue';
  @override
  String get nearestParking => 'Nearest Parking';
  @override
  String get km => 'km';
  @override
  String get walletBalance => 'Wallet Balance';
  @override
  String get activeSession => 'Active Session';
  @override
  String get startNewSession => 'Start New Session';
  @override
  String get rate => 'Rate';
  @override
  String get slots => 'slots';
  @override
  String get directions => 'Directions';
  @override
  String get nearbyParking => 'Nearby Parking';
  @override
  String get searchParking => 'Search for parking...';
  @override
  String get navigatingTo => 'Navigating to';
  @override
  String get remaining => 'Remaining';
  @override
  String get unableToGetLocation => 'Unable to get your location';
  @override
  String get startParkingSession => 'Start Parking Session';
  @override
  String get startReservedSession => 'Start Reserved Session';
  @override
  String get reservationConfirmed => 'Reservation Confirmed!';
  @override
  String get selectVehicle => 'Select Vehicle';
  @override
  String get duration => 'Duration';
  @override
  String get minutes => 'Minutes';
  @override
  String get startParkingNow => 'START PARKING NOW';
  @override
  String get confirmBooking => 'CONFIRM BOOKING';
  @override
  String get confirmReservation => 'Confirm Reservation';
  @override
  String get date => 'Date';
  @override
  String get cancel => 'Cancel';
  @override
  String get pleaseSelectVehicleAndZone => 'Please select a vehicle and a zone';
  @override
  String get startTimeInFuture => 'Start time must be in the future';
  @override
  String get reservationFailed => 'Reservation failed. Please check balance.';
  @override
  String get paymentSuccessful => 'Payment Successful!';
  @override
  String get processingReservation => 'Processing reservation...';
  @override
  String get initiatingPayment => 'Initiating payment...';
  @override
  String get oneClickSuccess => 'One-Click Success!';
  @override
  String get startReservedSessionPrompt =>
      'Do you want to start this parking session now?';
  @override
  String get bookSpotPrompt => 'Do you want to book this parking spot?';
  @override
  String get areYouSureEndSession =>
      'Are you sure you want to end this parking session?';
  @override
  String get endSession => 'End Session';
  @override
  String get sessionEndedSuccess =>
      'Your parking session has been stopped successfully.';
  @override
  String get extendDuration => 'Extend Duration';
  @override
  String get additionalCost => 'Additional Cost';
  @override
  String get insufficientBalance => 'Insufficient wallet balance. Please top up.';
  @override
  String get parkingLocationSaved => 'Parking location saved!';
  @override
  String get noSavedLocation =>
      'No saved location found. Tap "Save Spot" first.';
  @override
  String get viewVerificationQR => 'VIEW VERIFICATION QR';
  @override
  String get endSessionEarly => 'End Session Early';
  @override
  String get history => 'History';
  @override
  String get saveSpot => 'Save Spot';
  @override
  String get findCar => 'Find Car';
  @override
  String get until => 'until';
  @override
  String get vehicle => 'Vehicle';
  @override
  String get extended => 'Extended!';
  @override
  String get sessionExtendedBy => 'Parking session extended by';
  @override
  String get hours => 'hour(s)';
  @override
  String get sessionEnded => 'Session Ended';
  @override
  String get payAndExtendNow => 'Pay & Extend Now';
  @override
  String get processingPayment => 'Processing payment...';
  @override
  String get sessionStarting => 'Your parking session is starting now';
  @override
  String get spotBooked => 'Your spot has been booked';
  @override
  String get spotBookedSuccess => 'Your parking spot has been booked successfully.';
  @override
  String get canStartNowPrompt =>
      'You can start your session now since your time is near.';
  @override
  String get ok => 'OK';
  @override
  String get bookSpot => 'Book a Spot';
  @override
  String get time => 'Time';
  @override
  String get showToOfficer => 'Show this to the parking officer';
  @override
  String get expiresAt => 'Expires at';
  @override
  String get languagePreferences => 'Language Preferences';
  @override
  String get themeSettings => 'Theme Settings';
  @override
  String get current => 'Current';
  @override
  String get appVersion => 'App Version';
  @override
  String get buildNumber => 'Build Number';
  @override
  String get lastUpdated => 'Last Updated';
  @override
  String get account => 'Account';
  @override
  String get preferences => 'Preferences';

  @override
  String get chooseYourLanguage => 'Choose Your Language';
  @override
  String get selectPreferredLanguage => 'Select your preferred language for the best experience';
  @override
  String get selectLanguageForBestExperience => 'Select your preferred language for the best experience';
  @override
  String get continueText => 'Continue';

  @override
  String get termsAndConditions => 'Terms and Conditions';
  @override
  String get termsDescription => 'By using SPACE, you agree to our terms of service and comply with local parking regulations in your country.';
  @override
  String get privacyDescription => 'We respect your privacy and handle your data according to applicable privacy laws in your region.';
  @override
  String get countrySpecificTerms => 'Country-specific terms may apply based on your location.';
  @override
  String get localLawsNotice => 'Usage must comply with local parking laws and regulations.';

  @override
  String get detectingLocation => 'Detecting Your Location';
  @override
  String get detectingLocationSubtitle =>
      'We are identifying your country to serve you the best experience.';
  @override
  String get spaceAvailableInCountry => 'SPACE is available in your country!';
  @override
  String get spaceNotAvailableTitle =>
      'SPACE is not available in your region yet';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'We haven\'t launched in $countryName yet. We are working hard to bring SPACE to your area. Stay tuned!';
  @override
  String get retryDetection => 'Retry';
  @override
  String get locationDetectionFailed => 'Could Not Detect Location';
  @override
  String get locationDetectionFailedSubtitle =>
      'Please check your internet connection and try again.';
}

// Swahili Localizations
class _SwahiliLocalizations extends AppLocalizations {
  _SwahiliLocalizations();

  @override
  String get chooseYourLanguage => 'Chagua Lugha Yako';
  @override
  String get selectPreferredLanguage => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get selectLanguageForBestExperience => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get continueText => 'Endelea';
  @override
  String get termsAndConditions => 'Masharti na Hali';
  @override
  String get termsDescription => 'Kwa kutumia SPACE, unakubaliana na masharti yetu ya huduma na kufuata sheria za maegesho za ndani ya nchi yako.';
  @override
  String get privacyDescription => 'Tunaheshimu faragha yako na tunashughulikia data yako kulingana na sheria za faragha zinazotumika katika mkoa wako.';
  @override
  String get countrySpecificTerms => 'Masharti ya kipekee ya nchi yanaweza kutumika kulingana na mahali ulipo.';
  @override
  String get localLawsNotice => 'Matumizi yanapaswa kufuata sheria na kanuni za maegesho za ndini.';

  @override
  String get viewOnMap => 'Ona kwenye Ramani';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'Karibu kwenye SPACE';
  @override
  String get login => 'Ingia';
  @override
  String get register => 'Jisajili';
  @override
  String get logout => 'Toka';
  @override
  String get phone => 'Nambari ya Simu';
  @override
  String get password => 'Neno la Siri';
  @override
  String get email => 'Barua Pepe';
  @override
  String get confirmPassword => 'Thibitisha Neno la Siri';
  @override
  String get firstName => 'Jina la Kwanza';
  @override
  String get lastName => 'Jina la Mwisho';
  @override
  String get next => 'Inayofuata';
  @override
  String get back => 'Nyuma';
  @override
  String get save => 'Hifadhi';
  @override
  String get delete => 'Futa';
  @override
  String get confirm => 'Thibitisha';
  @override
  String get areYouSure => 'Je, una uhakika?';
  @override
  String get deleteAccount => 'Futa Akaunti';
  @override
  String get deleteAccountDescription =>
      'Hii itafuta kwa kabisa akaunti yako na data zote zinazohusiana.';

  @override
  String get enterOtp => 'Ingiza OTP';
  @override
  String get otpSent => 'OTP imetumwa kwenye simu yako';
  @override
  String get resendOtp => 'Tuma Tena OTP';
  @override
  String get verifyPhone => 'Thibitisha Nambari ya Simu';
  @override
  String get phoneVerified => 'Simu imethibitishwa kwa mafanikio';

  @override
  String get startParking => 'Anza Kueneza';
  @override
  String get stopParking => 'Simama Kueneza';
  @override
  String get endParking => 'Malizia Kueneza';
  @override
  String get parkingActive => 'Kueneza Kunashughulika';
  @override
  String get parkingHistory => 'Historia ya Kueneza';
  @override
  String get zones => 'Maeneo';
  @override
  String get selectZone => 'Chagua Eneo';

  @override
  String get payments => 'Malipo';
  @override
  String get transactions => 'Miamala';
  @override
  String get wallet => 'Pochi';
  @override
  String get balance => 'Salio';
  @override
  String get topUp => 'Jaza Salio';
  @override
  String get paymentMethod => 'Njia ya Kulipa';

  @override
  String get chat => 'Mazungumzo';
  @override
  String get support => 'Msaada';
  @override
  String get startConversation => 'Anza Mazungumzo';
  @override
  String get conversations => 'Mazungumzo';
  @override
  String get messages => 'Ujumbe';
  @override
  String get sendMessage => 'Tuma Ujumbe';
  @override
  String get noConversations => 'Hakuna mazungumzo bado';
  @override
  String get newMessage => 'Ujumbe Mpya';

  @override
  String get settings => 'Mipangilio';
  @override
  String get language => 'Lugha';
  @override
  String get theme => 'Mandhari';
  @override
  String get darkMode => 'Mandhari Nyeusi';
  @override
  String get lightMode => 'Mandhari ya Mwanga';
  @override
  String get notifications => 'Arifa';
  @override
  String get about => 'Kuhusu';

  @override
  String get error => 'Kosa';
  @override
  String get errorOccurred => 'Kosa liliotokea';
  @override
  String get tryAgain => 'Jaribu Tena';
  @override
  String get loading => 'Inapakia...';

  @override
  String get activeParking => 'KUENEZA KUNASHUGHULIKA';
  @override
  String get timeLeft => 'Muda Uliosalia';
  @override
  String get currentCost => 'Gharama ya Sasa';
  @override
  String get view => 'Angalia';
  @override
  String get upcomingReservation => 'UHIFADHI UJAO';
  @override
  String get navigateToZone => 'Elekea Eneo';
  @override
  String get lookingForParking => 'Unatafuta maegesho?';
  @override
  String get findSpotsNearYou => 'Pata sehemu bora karibu nawe';
  @override
  String get searchDestination => 'Tafuta unakoenda...';
  @override
  String get quickActions => 'Njia za Haraka';
  @override
  String get myVehicles => 'Magari Yangu';
  @override
  String get reservations => 'Uhifadhi';
  @override
  String get recentActivity => 'Shughuli za Hivi Karibuni';
  @override
  String get viewAll => 'Tazama Zote';
  @override
  String get noRecentSessions => 'Hakuna maegesho ya hivi karibuni';
  @override
  String get unpaidViolations => 'Ukiukaji Usiolipiwa';
  @override
  String get payNow => 'Lipa Sasa';

  @override
  String get selectLanguage => 'Chagua Lugha';
  @override
  String get english => 'Kiingereza';
  @override
  String get french => 'Kifaransa';
  @override
  String get german => 'Kijerumani';
  @override
  String get swahili => 'Kiswahili';
  @override
  String get spanish => 'Kihispania';
  @override
  String get arabic => 'Kiarabu';
  @override
  String get system => 'Mfumo Chaguomsingi';
  @override
  String get hostParkingSpace => 'Miliki Nafasi ya Maegesho';
  @override
  String get hostParkingSpaceSubtitle => 'Pata pesa kwa kuorodhesha nafasi yako tupu!';
  @override
  String get helpCenter => 'Kituo cha Msaada';
  @override
  String get privacyPolicy => 'Sera ya Faragha';
  @override
  String get termsOfService => 'Masharti ya Huduma';
  @override
  String get aboutSpacePark => 'Kuhusu Space Park';
  @override
  String get secureParkingMadeEasy => 'MAEGESHO SALAMA YALERAHISISHWA';
  @override
  String get alreadyHaveAccount => 'Tayari una akaunti?';
  @override
  String get dontHaveAccount => 'Hauna akaunti?';
  @override
  String get joinSpacePark => 'Jiunge na Space Park';
  @override
  String get iAcceptThe => 'Ninakubali ';
  @override
  String get terms => 'Masharti';
  @override
  String get loginToYourAccount => 'Ingia kwenye akaunti yako ya Space Park';
  @override
  String get forgotPassword => 'Umesahau Neno la Siri?';
  @override
  String get comingSoon => 'Inakuja hivi karibuni!';
  @override
  String get passwordResetSoon => 'Utendaji wa kuweka upya neno la siri unakuja hivi karibuni!';
  @override
  String get confirmYourPasswordPrompt => 'Thibitisha neno lako la siri';
  @override
  String get passwordsDoNotMatch => 'Neno la siri halilingani';
  @override
  String get passwordTooShort => 'Neno la siri ni fupi sana';
  @override
  String get registrationFailed => 'Usajili umeshindwa';
  @override
  String get accountDeletionRequested => 'Ombi la kufuta akaunti limetumwa.';
  @override
  String get failedToRequestDeletion => 'Imeshindwa kutuma ombi la kufuta.';
  @override
  String get permissionsUpdated => 'Ruhusa zimepata upya';
  @override
  String get uploadingPhoto => 'Inapakia picha...';
  @override
  String get photoUpdated => 'Picha imesasishwa';
  @override
  String get uploadFailed => 'Upakiaji umeshindwa';
  @override
  String get deleteAccountConfirmation => 'Je, una uhakika unataka kufuta akaunti yako? Hatua hii haiwezi kubadilishwa mara moja, lakini data yako itahifadhiwa kwa siku 30 kabla ya kufutwa kabisa.';
  @override
  String get yourDigitalPass => 'Pasi Yako ya Dijitali';
  @override
  String get scanToVerify => 'Skena msimbo huu ili kuthibitisha utambulisho wako';
  @override
  String get name => 'Jina';
  @override
  String get vehicleLabel => 'Chombo';
  @override
  String get partnerProgram => 'MPANGO WA WASHIRIKA';
  @override
  String get selectCountry => 'Chagua Nchi Yako';
  @override
  String get pleaseSelectCountry => 'Tafadhali chagua nchi yako ili kuendelea';
  @override
  String get nearestParking => 'Maegesho ya Karibu';
  @override
  String get km => 'km';
  @override
  String get walletBalance => 'Salio la Pochi';
  @override
  String get activeSession => 'Kipindi Kinachotumika';
  @override
  String get startNewSession => 'Anza Kipindi Kipya';
  @override
  String get rate => 'Kiwango';
  @override
  String get slots => 'nafasi';
  @override
  String get directions => 'Maelekezo';
  @override
  String get nearbyParking => 'Maegesho ya Karibu';
  @override
  String get searchParking => 'Tafuta maegesho...';
  @override
  String get navigatingTo => 'Kuelekea';
  @override
  String get remaining => 'zilizobaki';
  @override
  String get unableToGetLocation => 'Haiwezi kupata eneo lako';
  @override
  String get startParkingSession => 'Anza Kipindi cha Maegesho';
  @override
  String get startReservedSession => 'Anza Kipindi Kilichohifadhiwa';
  @override
  String get reservationConfirmed => 'Uhifadhi Umethibitishwa!';
  @override
  String get selectVehicle => 'Chagua Gari';
  @override
  String get duration => 'Muda';
  @override
  String get minutes => 'Dakika';
  @override
  String get startParkingNow => 'ANZA MAEGESHO SASA';
  @override
  String get confirmBooking => 'THIBITISHA UWEKAJI';
  @override
  String get confirmReservation => 'Thibitisha Uhifadhi';
  @override
  String get date => 'Tarehe';
  @override
  String get cancel => 'Ghairi';
  @override
  String get pleaseSelectVehicleAndZone => 'Tafadhali chagua gari na eneo';
  @override
  String get startTimeInFuture => 'Muda wa kuanza lazima uwe katika siku zijazo';
  @override
  String get reservationFailed => 'Uhifadhi umeshindwa. Tafadhali angalia salio.';
  @override
  String get paymentSuccessful => 'Malipo Yamefanikiwa!';
  @override
  String get processingReservation => 'Inashughulikia uhifadhi...';
  @override
  String get initiatingPayment => 'Inaanzisha malipo...';
  @override
  String get oneClickSuccess => 'Mafanikio kwa Mbofyo Mmoja!';
  @override
  String get startReservedSessionPrompt =>
      'Je, unataka kuanza kipindi hiki cha maegesho sasa?';
  @override
  String get bookSpotPrompt => 'Je, unataka kuhifadhi nafasi hii ya maegesho?';
  @override
  String get areYouSureEndSession =>
      'Je, una uhakika unataka kumaliza kipindi hiki cha maegesho?';
  @override
  String get endSession => 'Maliza Kipindi';
  @override
  String get sessionEndedSuccess =>
      'Kipindi chako cha maegesho kimesimamishwa kwa mafanikio.';
  @override
  String get extendDuration => 'Ongeza Muda';
  @override
  String get additionalCost => 'Gharama ya Ziada';
  @override
  String get insufficientBalance => 'Salio la pochi halitoshi. Tafadhali ongeza.';
  @override
  String get parkingLocationSaved => 'Eneo la maegesho limehifadhiwa!';
  @override
  String get noSavedLocation =>
      'Hakuna eneo lililohifadhiwa lililopatikana. Gusa "Hifadhi Eneo" kwanza.';
  @override
  String get viewVerificationQR => 'ONA QR YA UHAKIKISHO';
  @override
  String get endSessionEarly => 'Maliza Kipindi Mapema';
  @override
  String get history => 'Historia';
  @override
  String get saveSpot => 'Hifadhi Eneo';
  @override
  String get findCar => 'Pata Gari';
  @override
  String get until => 'hadi';
  @override
  String get vehicle => 'Gari';
  @override
  String get extended => 'Imeongezwa!';
  @override
  String get sessionExtendedBy => 'Kipindi cha maegesho kimeongezwa kwa';
  @override
  String get hours => 'saa';
  @override
  String get sessionEnded => 'Kipindi Kimeisha';
  @override
  String get payAndExtendNow => 'Lipa na Ongeza Sasa';
  @override
  String get processingPayment => 'Inashughulikia malipo...';
  @override
  String get sessionStarting => 'Kipindi chako cha maegesho kinaanza sasa';
  @override
  String get spotBooked => 'Nafasi yako imehifadhiwa';
  @override
  String get spotBookedSuccess =>
      'Nafasi yako ya maegesho imehifadhiwa kwa mafanikio.';
  @override
  String get canStartNowPrompt =>
      'Unaweza kuanza kipindi chako sasa kwa sababu muda wako uko karibu.';
  @override
  String get ok => 'Sawa';
  @override
  String get bookSpot => 'Hifadhi Nafasi';
  @override
  String get time => 'Muda';
  @override
  String get showToOfficer => 'Onyesha hili kwa ofisa wa maegesho';
  @override
  String get expiresAt => 'Inaisha saa';
  @override
  String get languagePreferences => 'Mapendeleo ya Lugha';
  @override
  String get themeSettings => 'Mipangilio ya Mandhari';
  @override
  String get current => 'Sasa';
  @override
  String get appVersion => 'Toleo la Programu';
  @override
  String get buildNumber => 'Nambari ya Toleo';
  @override
  String get lastUpdated => 'Ilisasishwa Mwisho';
  @override
  String get account => 'Akaunti';
  @override
  String get preferences => 'Mapendeleo';

  @override
  String get detectingLocation => 'Kutambua Eneo Lako';
  @override
  String get detectingLocationSubtitle =>
      'Tunabainisha nchi yako ili kukupa uzoefu bora.';
  @override
  String get spaceAvailableInCountry => 'SPACE inapatikana katika nchi yako!';
  @override
  String get spaceNotAvailableTitle =>
      'SPACE haijapatikana katika eneo lako bado';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'Bado hatujaanzisha katika $countryName. Endelea kutazama!';
  @override
  String get retryDetection => 'Jaribu Tena';
  @override
  String get locationDetectionFailed => 'Haiwezekani Kutambua Eneo';
  @override
  String get locationDetectionFailedSubtitle =>
      'Tafadhali angalia muunganisho wako wa intaneti na ujaribu tena.';
}

// French Localizations
class _FrenchLocalizations extends AppLocalizations {
  _FrenchLocalizations();

  @override
  String get viewOnMap => 'Voir sur la carte';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'Bienvenue à SPACE';
  @override
  String get login => 'Connexion';
  @override
  String get register => 'S\'inscrire';
  @override
  String get logout => 'Déconnexion';
  @override
  String get phone => 'Numéro de Téléphone';
  @override
  String get password => 'Mot de passe';
  @override
  String get email => 'E-mail';
  @override
  String get confirmPassword => 'Confirmer le Mot de passe';
  @override
  String get firstName => 'Prénom';
  @override
  String get lastName => 'Nom de Famille';
  @override
  String get next => 'Suivant';
  @override
  String get back => 'Retour';
  @override
  String get save => 'Enregistrer';
  @override
  String get delete => 'Supprimer';
  @override
  String get confirm => 'Confirmer';
  @override
  String get areYouSure => 'Êtes-vous sûr?';
  @override
  String get deleteAccount => 'Supprimer le Compte';
  @override
  String get deleteAccountDescription =>
      'Cela supprimera définitivement votre compte et toutes les données associées.';

  @override
  String get enterOtp => 'Entrez OTP';
  @override
  String get otpSent => 'OTP envoyé à votre téléphone';
  @override
  String get resendOtp => 'Renvoyer OTP';
  @override
  String get verifyPhone => 'Vérifier le Numéro de Téléphone';
  @override
  String get phoneVerified => 'Téléphone vérifié avec succès';

  @override
  String get startParking => 'Démarrer le Stationnement';
  @override
  String get stopParking => 'Arrêter le Stationnement';
  @override
  String get endParking => 'Terminer le Stationnement';
  @override
  String get parkingActive => 'Stationnement Actif';
  @override
  String get parkingHistory => 'Historique de Stationnement';
  @override
  String get zones => 'Zones';
  @override
  String get selectZone => 'Sélectionnez une Zone';

  @override
  String get payments => 'Paiements';
  @override
  String get transactions => 'Transactions';
  @override
  String get wallet => 'Portefeuille';
  @override
  String get balance => 'Solde';
  @override
  String get topUp => 'Recharger';
  @override
  String get paymentMethod => 'Méthode de Paiement';

  @override
  String get chat => 'Chat';
  @override
  String get support => 'Support';
  @override
  String get startConversation => 'Démarrer une Conversation';
  @override
  String get conversations => 'Conversations';
  @override
  String get messages => 'Messages';
  @override
  String get sendMessage => 'Envoyer un Message';
  @override
  String get noConversations => 'Pas encore de conversations';
  @override
  String get newMessage => 'Nouveau Message';

  @override
  String get settings => 'Paramètres';
  @override
  String get language => 'Langue';
  @override
  String get theme => 'Thème';
  @override
  String get darkMode => 'Mode Sombre';
  @override
  String get lightMode => 'Mode Clair';
  @override
  String get notifications => 'Notifications';
  @override
  String get about => 'À Propos';

  @override
  String get error => 'Erreur';
  @override
  String get errorOccurred => 'Une erreur s\'est produite';
  @override
  String get tryAgain => 'Réessayer';
  @override
  String get loading => 'Chargement...';

  @override
  String get activeParking => 'STATIONNEMENT ACTIF';
  @override
  String get timeLeft => 'Temps Restant';
  @override
  String get currentCost => 'Coût Actuel';
  @override
  String get view => 'Voir';
  @override
  String get upcomingReservation => 'RÉSERVATION À VENIR';
  @override
  String get navigateToZone => 'Naviguer vers la Zone';
  @override
  String get lookingForParking => 'Vous cherchez une place?';
  @override
  String get findSpotsNearYou => 'Trouvez les meilleures places près de chez vous';
  @override
  String get searchDestination => 'Rechercher une destination...';
  @override
  String get quickActions => 'Actions Rapides';
  @override
  String get myVehicles => 'Mes Véحicules';
  @override
  String get reservations => 'Réservations';
  @override
  String get recentActivity => 'Activité Récente';
  @override
  String get viewAll => 'Voir Tout';
  @override
  String get noRecentSessions => 'Aucune session de stationnement récente';
  @override
  String get unpaidViolations => 'Violations Non Payées';
  @override
  String get payNow => 'Payer Maintenant';

  @override
  String get selectLanguage => 'Choisir la langue';
  @override
  String get english => 'Anglais';
  @override
  String get french => 'Français';
  @override
  String get german => 'Allemand';
  @override
  String get swahili => 'Swahili';
  @override
  String get spanish => 'Espagnol';
  @override
  String get arabic => 'Arabe';
  @override
  String get system => 'Par Défaut';
  @override
  String get hostParkingSpace => 'Accueillir une Place';
  @override
  String get hostParkingSpaceSubtitle => 'Gagnez de l\'argent en listant votre espace!';
  @override
  String get helpCenter => 'Centre d\'Aide';
  @override
  String get privacyPolicy => 'Confidentialité';
  @override
  String get termsOfService => 'Conditions d\'Utilisation';
  @override
  String get aboutSpacePark => 'À Propos';
  @override
  String get secureParkingMadeEasy => 'PARKING SÉCURISÉ SIMPLIFIÉ';
  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';
  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';
  @override
  String get joinSpacePark => 'Rejoindre Space Park';
  @override
  String get iAcceptThe => 'J\'accepte les ';
  @override
  String get terms => 'Conditions';
  @override
  String get loginToYourAccount => 'Connectez-vous à votre compte';
  @override
  String get forgotPassword => 'Mot de passe oublié ?';
  @override
  String get comingSoon => 'Bientôt disponible !';
  @override
  String get passwordResetSoon => 'Réinitialisation bientôt disponible !';
  @override
  String get confirmYourPasswordPrompt => 'Confirmez votre mot de passe';
  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';
  @override
  String get passwordTooShort => 'Mot de passe trop court';
  @override
  String get registrationFailed => 'Échec de l\'inscription';
  @override
  String get accountDeletionRequested => 'Suppression de compte demandée.';
  @override
  String get failedToRequestDeletion => 'Échec de la demande de suppression.';
  @override
  String get permissionsUpdated => 'Autorisations mises à jour';
  @override
  String get uploadingPhoto => 'Téléchargement de la photo...';
  @override
  String get photoUpdated => 'Photo mise à jour';
  @override
  String get uploadFailed => 'Échec du téléchargement';
  @override
  String get deleteAccountConfirmation => 'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action ne peut pas être annulée immédiatement, mais vos données seront conservées pendant 30 jours avant suppression définitive.';
  @override
  String get yourDigitalPass => 'Votre Pass Numérique';
  @override
  String get scanToVerify => 'Scannez ce code pour vérifier votre identité';
  @override
  String get name => 'Nom';
  @override
  String get vehicleLabel => 'Véhicule';
  @override
  String get partnerProgram => 'PROGRAMME PARTENAIRE';
  @override
  String get selectCountry => 'Sélectionnez votre pays';
  @override
  String get pleaseSelectCountry =>
      'Veuillez sélectionner votre pays pour continuer';

  @override
  String get nearestParking => 'Parking le plus proche';
  @override
  String get km => 'km';
  @override
  String get walletBalance => 'Solde du portefeuille';
  @override
  String get activeSession => 'Session active';
  @override
  String get startNewSession => 'Démarrer une nouvelle session';
  @override
  String get rate => 'Tarif';
  @override
  String get slots => 'places';
  @override
  String get directions => 'Itinéraire';
  @override
  String get nearbyParking => 'Parkings à proximité';
  @override
  String get searchParking => 'Rechercher un parking...';
  @override
  String get navigatingTo => 'Navigation vers';
  @override
  String get remaining => 'restants';
  @override
  String get unableToGetLocation => 'Impossible d\'obtenir votre position';
  @override
  String get startParkingSession => 'Démarrer une session de parking';
  @override
  String get startReservedSession => 'Démarrer la session réservée';
  @override
  String get reservationConfirmed => 'Réservation confirmée !';
  @override
  String get selectVehicle => 'Sélectionner le véhicule';
  @override
  String get duration => 'Durée';
  @override
  String get minutes => 'Minutes';
  @override
  String get startParkingNow => 'STATIONNER MAINTENANT';
  @override
  String get confirmBooking => 'CONFIRMER LA RÉSERVATION';
  @override
  String get confirmReservation => 'Confirmer la réservation';
  @override
  String get date => 'Date';
  @override
  String get cancel => 'Annuler';
  @override
  String get pleaseSelectVehicleAndZone =>
      'Veuillez sélectionner un véhicule et une zone';
  @override
  String get startTimeInFuture => 'L\'heure de début doit être dans le futur';
  @override
  String get reservationFailed => 'Échec de la réservation. Veuillez vérifier le solde.';
  @override
  String get paymentSuccessful => 'Paiement réussi !';
  @override
  String get processingReservation => 'Traitement de la réservation...';
  @override
  String get initiatingPayment => 'Initiation du paiement...';
  @override
  String get oneClickSuccess => 'Succès en un clic !';
  @override
  String get startReservedSessionPrompt =>
      'Voulez-vous démarrer cette session de stationnement maintenant ?';
  @override
  String get bookSpotPrompt =>
      'Voulez-vous réserver cet emplacement de stationnement ?';
  @override
  String get areYouSureEndSession =>
      'Êtes-vous sûr de vouloir terminer cette session de stationnement ?';
  @override
  String get endSession => 'Terminer la session';
  @override
  String get sessionEndedSuccess =>
      'Votre session de stationnement a été arrêtée avec succès.';
  @override
  String get extendDuration => 'Prolonger la durée';
  @override
  String get additionalCost => 'Coût supplémentaire';
  @override
  String get insufficientBalance => 'Solde du portefeuille insuffisant. Veuillez recharger.';
  @override
  String get parkingLocationSaved => 'Emplacement de stationnement enregistré !';
  @override
  String get noSavedLocation =>
      'Aucun emplacement enregistré trouvé. Appuyez d\'abord sur "Enregistrer l\'emplacement".';
  @override
  String get viewVerificationQR => 'VOIR LE QR DE VÉRIFICATION';
  @override
  String get endSessionEarly => 'Terminer la session plus tôt';
  @override
  String get history => 'Historique';
  @override
  String get saveSpot => 'Enregistrer';
  @override
  String get findCar => 'Trouver';
  @override
  String get until => 'jusqu\'à';
  @override
  String get vehicle => 'Véhicule';
  @override
  String get extended => 'Prolongé !';
  @override
  String get sessionExtendedBy => 'Session de stationnement prolongée de';
  @override
  String get hours => 'heure(s)';
  @override
  String get sessionEnded => 'Session terminée';
  @override
  String get payAndExtendNow => 'Payer et prolonger maintenant';
  @override
  String get processingPayment => 'Traitement du paiement...';
  @override
  String get sessionStarting => 'Votre session de stationnement commence maintenant';
  @override
  String get spotBooked => 'Votre place a été réservée';
  @override
  String get spotBookedSuccess =>
      'Votre place de stationnement a été réservée avec succès.';
  @override
  String get canStartNowPrompt =>
      'Vous pouvez commencer votre session maintenant car votre heure est proche.';
  @override
  String get ok => 'OK';
  @override
  String get bookSpot => 'Réserver une place';
  @override
  String get time => 'Heure';
  @override
  String get showToOfficer => 'Montrez ceci à l\'officier de stationnement';
  @override
  String get expiresAt => 'Expire à';
  @override
  String get languagePreferences => 'Préférences linguistiques';
  @override
  String get themeSettings => 'Paramètres du thème';
  @override
  String get current => 'Actuel';
  @override
  String get appVersion => 'Version de l\'application';
  @override
  String get buildNumber => 'Numéro de build';
  @override
  String get lastUpdated => 'Dernière mise à jour';
  @override
  String get account => 'Akaunti';
  @override
  String get preferences => 'Mapendekezo';

  @override
  String get chooseYourLanguage => 'Chagua Lugha Yako';
  @override
  String get selectPreferredLanguage => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get selectLanguageForBestExperience => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get continueText => 'Endelea';
  @override
  String get termsAndConditions => 'Masharti na Hali';
  @override
  String get termsDescription => 'Kwa kutumia SPACE, unakubaliana na masharti yetu ya huduma na kufuata sheria za maegesho za ndani ya nchi yako.';
  @override
  String get privacyDescription => 'Tunaheshimu faragha yako na tunashughulikia data yako kulingana na sheria za faragha zinazotumika katika mkoa wako.';
  @override
  String get countrySpecificTerms => 'Masharti ya kipekee ya nchi yanaweza kutumika kulingana na mahali ulipo.';
  @override
  String get localLawsNotice => 'Matumizi yanapaswa kufuata sheria na kanuni za maegesho za ndini.';

  @override
  String get detectingLocation => 'Kutambua Mahali Panako';
  @override
  String get detectingLocationSubtitle =>
      'Nous identifions votre pays pour vous offrir la meilleure expérience.';
  @override
  String get spaceAvailableInCountry => 'SPACE est disponible dans votre pays!';
  @override
  String get spaceNotAvailableTitle =>
      'SPACE n\'est pas encore disponible dans votre région';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'Nous n\'avons pas encore lancé en $countryName. Restez à l\'affut!';
  @override
  String get retryDetection => 'Réessayer';
  @override
  String get locationDetectionFailed => 'Impossible de détecter l\'emplacement';
  @override
  String get locationDetectionFailedSubtitle =>
      'Vérifiez votre connexion internet et réessayez.';
}

// Spanish Localizations
class _SpanishLocalizations extends AppLocalizations {
  _SpanishLocalizations();

  @override
  String get viewOnMap => 'Ver en el mapa';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'Bienvenido a SPACE';
  @override
  String get login => 'Iniciar Sesión';
  @override
  String get register => 'Registrarse';
  @override
  String get logout => 'Cerrar Sesión';
  @override
  String get phone => 'Número de Teléfono';
  @override
  String get password => 'Contraseña';
  @override
  String get email => 'Correo Electrónico';
  @override
  String get confirmPassword => 'Confirmar Contraseña';
  @override
  String get firstName => 'Nombre';
  @override
  String get lastName => 'Apellido';
  @override
  String get next => 'Siguiente';
  @override
  String get back => 'Atrás';
  @override
  String get save => 'Guardar';
  @override
  String get delete => 'Eliminar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get areYouSure => '¿Estás seguro?';
  @override
  String get deleteAccount => 'Eliminar Cuenta';
  @override
  String get deleteAccountDescription =>
      'Esto eliminará permanentemente tu cuenta y todos los datos asociados.';

  @override
  String get enterOtp => 'Ingresa OTP';
  @override
  String get otpSent => 'OTP enviado a tu teléfono';
  @override
  String get resendOtp => 'Reenviar OTP';
  @override
  String get verifyPhone => 'Verificar Número de Teléfono';
  @override
  String get phoneVerified => 'Teléfono verificado exitosamente';

  @override
  String get startParking => 'Comenzar Estacionamiento';
  @override
  String get stopParking => 'Detener Estacionamiento';
  @override
  String get endParking => 'Finalizar Estacionamiento';
  @override
  String get parkingActive => 'Estacionamiento Activo';
  @override
  String get parkingHistory => 'Historial de Estacionamiento';
  @override
  String get zones => 'Zonas';
  @override
  String get selectZone => 'Selecciona una Zona';

  @override
  String get payments => 'Pagos';
  @override
  String get transactions => 'Transacciones';
  @override
  String get wallet => 'Billetera';
  @override
  String get balance => 'Saldo';
  @override
  String get topUp => 'Recargar';
  @override
  String get paymentMethod => 'Método de Pago';

  @override
  String get chat => 'Chat';
  @override
  String get support => 'Soporte';
  @override
  String get startConversation => 'Iniciar Conversación';
  @override
  String get conversations => 'Conversaciones';
  @override
  String get messages => 'Mensajes';
  @override
  String get sendMessage => 'Enviar Mensaje';
  @override
  String get noConversations => 'Sin conversaciones aún';
  @override
  String get newMessage => 'Nuevo Mensaje';

  @override
  String get settings => 'Configuración';
  @override
  String get language => 'Idioma';
  @override
  String get theme => 'Tema';
  @override
  String get darkMode => 'Modo Oscuro';
  @override
  String get lightMode => 'Modo Claro';
  @override
  String get notifications => 'Notificaciones';
  @override
  String get about => 'Acerca de';

  @override
  String get error => 'Error';
  @override
  String get errorOccurred => 'Ocurrió un error';
  @override
  String get tryAgain => 'Intentar de Nuevo';
  @override
  String get loading => 'Cargando...';

  @override
  String get activeParking => 'ESTACIONAMIENTO ACTIVO';
  @override
  String get timeLeft => 'Tiempo Restante';
  @override
  String get currentCost => 'Costo Actual';
  @override
  String get view => 'Ver';
  @override
  String get upcomingReservation => 'PRÓXIMA RESERVACIÓN';
  @override
  String get navigateToZone => 'Navegar a la Zona';
  @override
  String get lookingForParking => '¿Buscas estacionamiento?';
  @override
  String get findSpotsNearYou => 'Encuentra los mejores lugares cerca de ti';
  @override
  String get searchDestination => 'Buscar destino...';
  @override
  String get quickActions => 'Acciones Rápidas';
  @override
  String get myVehicles => 'Mis Vehículos';
  @override
  String get reservations => 'Reservaciones';
  @override
  String get recentActivity => 'Actividad Reciente';
  @override
  String get viewAll => 'Ver Todo';
  @override
  String get noRecentSessions => 'Sin sesiones de estacionamiento recientes';
  @override
  String get unpaidViolations => 'Violaciones No Pagadas';
  @override
  String get payNow => 'Pagar Ahora';

  @override
  String get selectLanguage => 'Seleccionar idioma';
  @override
  String get english => 'Inglés';
  @override
  String get french => 'Francés';
  @override
  String get german => 'Alemán';
  @override
  String get swahili => 'Swahili';
  @override
  String get spanish => 'Español';
  @override
  String get arabic => 'Árabe';
  @override
  String get system => 'Sistema';
  @override
  String get hostParkingSpace => 'Alquilar una Plaza';
  @override
  String get hostParkingSpaceSubtitle => '¡Gane dinero alquilando su espacio!';
  @override
  String get helpCenter => 'Centro de Ayuda';
  @override
  String get privacyPolicy => 'Privacidad';
  @override
  String get termsOfService => 'Condiciones';
  @override
  String get aboutSpacePark => 'Acerca de';
  @override
  String get secureParkingMadeEasy => 'ESTACIONAMIENTO SEGURO FÁCIL';
  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';
  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';
  @override
  String get joinSpacePark => 'Únete a Space Park';
  @override
  String get iAcceptThe => 'Acepto los ';
  @override
  String get terms => 'Términos';
  @override
  String get loginToYourAccount => 'Inicia sesión en tu cuenta';
  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';
  @override
  String get comingSoon => '¡Próximamente!';
  @override
  String get passwordResetSoon => '¡Restablecimiento próximamente!';
  @override
  String get confirmYourPasswordPrompt => 'Confirma tu contraseña';
  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';
  @override
  String get passwordTooShort => 'Contraseña demasiado corta';
  @override
  String get registrationFailed => 'Error en el registro';
  @override
  String get accountDeletionRequested => 'Eliminación de cuenta solicitada.';
  @override
  String get failedToRequestDeletion => 'Error al solicitar la eliminación.';
  @override
  String get permissionsUpdated => 'Permisos actualizados';
  @override
  String get uploadingPhoto => 'Subiendo foto...';
  @override
  String get photoUpdated => 'Foto actualizada';
  @override
  String get uploadFailed => 'Error al subir';
  @override
  String get deleteAccountConfirmation => '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer de inmediato, pero tus datos se guardarán durante 30 días antes de la eliminación permanente.';
  @override
  String get yourDigitalPass => 'Tu Pase Digital';
  @override
  String get scanToVerify => 'Escanea este código para verificar tu identidad';
  @override
  String get name => 'Nombre';
  @override
  String get vehicleLabel => 'Vehículo';
  @override
  String get partnerProgram => 'PROGRAMA DE SOCIOS';
  @override
  String get selectCountry => 'Selecciona tu país';
  @override
  String get pleaseSelectCountry => 'Por favor, selecciona tu país para continuar';
  @override
  String get continueText => 'CONTINUAR';

  @override
  String get termsAndConditions => 'Términos y Condiciones';
  @override
  String get termsDescription => 'Al usar SPACE, aceptas nuestros términos de servicio y cumples con las regulaciones de estacionamiento locales de tu país.';
  @override
  String get privacyDescription => 'Respetamos tu privacidad y manejamos tus datos según las leyes de privacidad aplicables en tu región.';
  @override
  String get countrySpecificTerms => 'Pueden aplicarse términos específicos del país según tu ubicación.';
  @override
  String get localLawsNotice => 'El uso debe cumplir con las leyes y regulaciones locales de estacionamiento.';
  
  @override
  String get detectingLocation => 'Detectando Tu Ubicación';
  @override
  String get detectingLocationSubtitle => 'Estamos identificando tu país para brindarte la mejor experiencia.';
  @override
  String get spaceAvailableInCountry => '¡SPACE está disponible en tu país!';
  @override
  String get nearestParking => 'Estacionamiento más cercano';
  @override
  String get km => 'km';
  @override
  String get walletBalance => 'Saldo de billetera';
  @override
  String get activeSession => 'Sesión activa';
  @override
  String get startNewSession => 'Iniciar nueva sesión';
  @override
  String get rate => 'Tarifa';
  @override
  String get slots => 'plazas';
  @override
  String get directions => 'Direcciones';
  @override
  String get nearbyParking => 'Estacionamiento cercano';
  @override
  String get searchParking => 'Buscar estacionamiento...';
  @override
  String get navigatingTo => 'Navegando a';
  @override
  String get remaining => 'restantes';
  @override
  String get unableToGetLocation => 'No se pudo obtener su ubicación';
  @override
  String get startParkingSession => 'Iniciar sesión de estacionamiento';
  @override
  String get startReservedSession => 'Iniciar sesión reservada';
  @override
  String get reservationConfirmed => '¡Reserva confirmada!';
  @override
  String get selectVehicle => 'Seleccionar vehículo';
  @override
  String get duration => 'Duración';
  @override
  String get minutes => 'Minutos';
  @override
  String get startParkingNow => 'ESTACIONAR AHORA';
  @override
  String get confirmBooking => 'CONFIRMER RESERVA';
  @override
  String get confirmReservation => 'Confirmar reserva';
  @override
  String get date => 'Fecha';
  @override
  String get cancel => 'Cancelar';
  @override
  String get pleaseSelectVehicleAndZone =>
      'Por favor, seleccione un vehículo y una zona';
  @override
  String get startTimeInFuture => 'La hora de inicio debe ser en el futuro';
  @override
  String get reservationFailed =>
      'Error en la reserva. Por favor, compruebe el saldo.';
  @override
  String get paymentSuccessful => '¡Pago exitoso!';
  @override
  String get processingReservation => 'Procesando reserva...';
  @override
  String get initiatingPayment => 'Iniciando pago...';
  @override
  String get oneClickSuccess => '¡Éxito en un clic!';
  @override
  String get startReservedSessionPrompt =>
      '¿Desea iniciar esta sesión de estacionamiento ahora?';
  @override
  String get bookSpotPrompt => '¿Desea reservar este lugar de estacionamiento?';
  @override
  String get areYouSureEndSession =>
      '¿Está seguro de que desea finalizar esta sesión de estacionamiento?';
  @override
  String get endSession => 'Finalizar sesión';
  @override
  String get sessionEndedSuccess =>
      'Su sesión de estacionamiento se ha detenido con éxito.';
  @override
  String get extendDuration => 'Extender duración';
  @override
  String get additionalCost => 'Costo adicional';
  @override
  String get insufficientBalance =>
      'Saldo de billetera insuficiente. Por favor recargue.';
  @override
  String get parkingLocationSaved => '¡Ubicación de estacionamiento guardada!';
  @override
  String get noSavedLocation =>
      'No se encontró ninguna ubicación guardada. Toque "Guardar lugar" primero.';
  @override
  String get viewVerificationQR => 'VER QR DE VERIFICACIÓN';
  @override
  String get endSessionEarly => 'Finalizar sesión antes';
  @override
  String get history => 'Historial';
  @override
  String get saveSpot => 'Guardar lugar';
  @override
  String get findCar => 'Encontrar auto';
  @override
  String get until => 'hasta';
  @override
  String get vehicle => 'Vehículo';
  @override
  String get extended => '¡Extendido!';
  @override
  String get sessionExtendedBy => 'Sesión de estacionamiento extendida por';
  @override
  String get hours => 'hora(s)';
  @override
  String get sessionEnded => 'Sesión finalizada';
  @override
  String get payAndExtendNow => 'Pagar y extender ahora';
  @override
  String get processingPayment => 'Procesando pago...';
  @override
  String get sessionStarting => 'Su sesión de estacionamiento está comenzando ahora';
  @override
  String get spotBooked => 'Su lugar ha sido reservado';
  @override
  String get spotBookedSuccess =>
      'Su lugar de estacionamiento ha sido reservado con éxito.';
  @override
  String get canStartNowPrompt =>
      'Puede iniciar su sesión ahora ya que su hora está cerca.';
  @override
  String get ok => 'OK';
  @override
  String get bookSpot => 'Reservar un lugar';
  @override
  String get time => 'Hora';
  @override
  String get showToOfficer => 'Muestre esto al oficial de estacionamiento';
  @override
  String get expiresAt => 'Expira a las';
  @override
  String get languagePreferences => 'Preferencias de idioma';
  @override
  String get themeSettings => 'Ajustes de tema';
  @override
  String get current => 'Actual';
  @override
  String get appVersion => 'Versión de la aplicación';
  @override
  String get buildNumber => 'Número de compilación';
  @override
  String get lastUpdated => 'Última actualización';
  @override
  String get account => 'Cuenta';
  @override
  String get preferences => 'Mapendekezo';

  @override
  String get chooseYourLanguage => 'Chagua Lugha Yako';
  @override
  String get selectPreferredLanguage => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get selectLanguageForBestExperience => 'Chagua lugha yako unayopendeleza kwa uzoefu bora';
  @override
  String get spaceNotAvailableTitle => 'SPACE aún no está disponible en tu región';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'Aún no hemos lanzado en $countryName. ¡Estamos trabajando para llegar a tu área!';
  @override
  String get retryDetection => 'Reintentar';
  @override
  String get locationDetectionFailed => 'No se pudo detectar la ubicación';
  @override
  String get locationDetectionFailedSubtitle =>
      'Por favor, revisa tu conexión a internet e inténtalo de nuevo.';
}

// German Localizations
class _GermanLocalizations extends AppLocalizations {
  _GermanLocalizations();

  @override
  String get viewOnMap => 'Auf der Karte anzeigen';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'Willkommen bei SPACE';
  @override
  String get login => 'Anmelden';
  @override
  String get register => 'Registrieren';
  @override
  String get logout => 'Abmelden';
  @override
  String get phone => 'Telefonnummer';
  @override
  String get password => 'Passwort';
  @override
  String get email => 'E-Mail';
  @override
  String get confirmPassword => 'Passwort bestätigen';
  @override
  String get firstName => 'Vorname';
  @override
  String get lastName => 'Nachname';
  @override
  String get next => 'Weiter';
  @override
  String get back => 'Zurück';
  @override
  String get save => 'Speichern';
  @override
  String get delete => 'Löschen';
  @override
  String get confirm => 'Bestätigen';
  @override
  String get areYouSure => 'Sind Sie sicher?';
  @override
  String get preferences => 'Einstellungen';

  @override
  String get detectingLocation => 'Standort wird ermittelt';
  @override
  String get detectingLocationSubtitle =>
      'Wir identifizieren Ihr Land, um Ihnen das beste Erlebnis zu bieten.';
  @override
  String get spaceAvailableInCountry => 'SPACE ist in Ihrem Land verfügbar!';
  @override
  String get spaceNotAvailableTitle => 'SPACE ist in Ihrer Region noch nicht verfügbar';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'Wir sind noch nicht in $countryName verfügbar. Wir arbeiten hart daran!';
  @override
  String get retryDetection => 'Erneut versuchen';
  @override
  String get locationDetectionFailed => 'Standort konnte nicht erkannt werden';
  @override
  String get locationDetectionFailedSubtitle =>
      'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';
  @override
  String get deleteAccount => 'Konto löschen';
  @override
  String get deleteAccountDescription =>
      'Dies wird Ihr Konto und alle zugehörigen Daten dauerhaft löschen.';

  @override
  String get enterOtp => 'OTP eingeben';
  @override
  String get otpSent => 'OTP an Ihr Telefon gesendet';
  @override
  String get resendOtp => 'OTP erneut senden';
  @override
  String get verifyPhone => 'Telefonnummer verifizieren';
  @override
  String get phoneVerified => 'Telefon erfolgreich verifiziert';

  @override
  String get startParking => 'Parkvorgang starten';
  @override
  String get stopParking => 'Stoppen';
  @override
  String get endParking => 'Beenden';
  @override
  String get parkingActive => 'Parken aktiv';
  @override
  String get parkingHistory => 'Parkhistorie';
  @override
  String get zones => 'Zonen';
  @override
  String get selectZone => 'Zone auswählen';

  @override
  String get payments => 'Zahlungen';
  @override
  String get transactions => 'Transaktionen';
  @override
  String get wallet => 'Geldbörse';
  @override
  String get balance => 'Guthaben';
  @override
  String get topUp => 'Aufladen';
  @override
  String get paymentMethod => 'Zahlungsmethode';

  @override
  String get chat => 'Chat';
  @override
  String get support => 'Support';
  @override
  String get startConversation => 'Gespräch beginnen';
  @override
  String get conversations => 'Gespräche';
  @override
  String get messages => 'Nachrichten';
  @override
  String get sendMessage => 'Nachricht senden';
  @override
  String get noConversations => 'Noch keine Gespräche';
  @override
  String get newMessage => 'Neue Nachricht';

  @override
  String get settings => 'Einstellungen';
  @override
  String get language => 'Sprache';
  @override
  String get theme => 'Design';
  @override
  String get darkMode => 'Dunkelmodus';
  @override
  String get lightMode => 'Heller Modus';
  @override
  String get notifications => 'Benachrichtigungen';
  @override
  String get about => 'Über uns';

  @override
  String get error => 'Fehler';
  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get loading => 'Laden...';

  @override
  String get activeParking => 'AKTIVES PARKEN';
  @override
  String get timeLeft => 'Verbleibende Zeit';
  @override
  String get currentCost => 'Aktuelle Kosten';
  @override
  String get view => 'Ansehen';
  @override
  String get upcomingReservation => 'BEVORSTEHENDE RESERVIERUNG';
  @override
  String get navigateToZone => 'Zur Zone navigieren';
  @override
  String get lookingForParking => 'Suchen Sie einen Parkplatz?';
  @override
  String get findSpotsNearYou => 'Finden Sie die besten Plätze in Ihrer Nähe';
  @override
  String get searchDestination => 'Ziel suchen...';
  @override
  String get quickActions => 'Schnellzugriff';
  @override
  String get myVehicles => 'Meine Fahrzeuge';
  @override
  String get reservations => 'Reservierungen';
  @override
  String get recentActivity => 'Letzte Aktivitäten';
  @override
  String get viewAll => 'Alle ansehen';
  @override
  String get noRecentSessions => 'Keine letzten Parkvorgänge';
  @override
  String get unpaidViolations => 'Unbezahlte Verstöße';
  @override
  String get payNow => 'Jetzt bezahlen';

  @override
  String get selectLanguage => 'Sprache wählen';
  @override
  String get english => 'Englisch';
  @override
  String get french => 'Französisch';
  @override
  String get german => 'Deutsch';
  @override
  String get swahili => 'Swahili';
  @override
  String get spanish => 'Spanisch';
  @override
  String get arabic => 'Arabisch';
  @override
  String get system => 'Systemstandard';
  @override
  String get hostParkingSpace => 'Parkplatz vermieten';
  @override
  String get hostParkingSpaceSubtitle => 'Geld verdienen durch Vermietung!';
  @override
  String get helpCenter => 'Hilfe-Center';
  @override
  String get privacyPolicy => 'Datenschutz';
  @override
  String get termsOfService => 'AGB';
  @override
  String get aboutSpacePark => 'Über Space Park';
  @override
  String get secureParkingMadeEasy => 'SICHERES PARKEN EINFACH GEMACHT';
  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto?';
  @override
  String get dontHaveAccount => 'Haben Sie noch kein Konto?';
  @override
  String get joinSpacePark => 'Space Park beitreten';
  @override
  String get iAcceptThe => 'Ich akzeptiere die ';
  @override
  String get terms => 'Bedingungen';
  @override
  String get loginToYourAccount => 'In Ihr Konto einloggen';
  @override
  String get forgotPassword => 'Passwort vergessen?';
  @override
  String get comingSoon => 'Demnächst verfügbar!';
  @override
  String get passwordResetSoon => 'Passwort-Reset demnächst verfügbar!';
  @override
  String get confirmYourPasswordPrompt => 'Passwort bestätigen';
  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';
  @override
  String get passwordTooShort => 'Passwort zu kurz';
  @override
  String get registrationFailed => 'Registrierung fehlgeschlagen';
  @override
  String get accountDeletionRequested => 'Kontolöschung angefordert.';
  @override
  String get failedToRequestDeletion => 'Anforderung fehlgeschlagen.';
  @override
  String get permissionsUpdated => 'Berechtigungen aktualisiert';
  @override
  String get uploadingPhoto => 'Foto wird hochgeladen...';
  @override
  String get photoUpdated => 'Foto aktualisiert';
  @override
  String get uploadFailed => 'Upload fehlgeschlagen';
  @override
  String get deleteAccountConfirmation => 'Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion kann nicht sofort rückgängig gemacht werden, aber Ihre Daten werden 30 Tage lang aufbewahrt, bevor sie endgültig gelöscht werden.';
  @override
  String get yourDigitalPass => 'Ihr digitaler Pass';
  @override
  String get scanToVerify => 'Scannen Sie diesen Code, um Ihre Identität zu verfälschen';
  @override
  String get name => 'Name';
  @override
  String get vehicleLabel => 'Fahrzeug';
  @override
  String get partnerProgram => 'PARTNERPROGRAMM';
  @override
  String get selectCountry => 'Wählen Sie Ihr Land';
  @override
  String get pleaseSelectCountry => 'Bitte wählen Sie Ihr Land aus, um fortzufahren';
  @override
  String get continueText => 'WEITER';

  @override
  String get chooseYourLanguage => 'Wählen Sie Ihre Sprache aus';
  @override
  String get selectPreferredLanguage => 'Wählen Sie Ihre bevorzugte Sprache für die beste Erfahrung';
  @override
  String get selectLanguageForBestExperience => 'Wählen Sie Ihre bevorzugte Sprache für die beste Erfahrung';
  @override
  String get termsAndConditions => 'Allgemeine Geschäftsbedingungen';
  @override
  String get termsDescription => 'Durch die Nutzung von SPACE stimmen Sie unseren Nutzungsbedingungen zu und halten sich an lokale Parkvorschriften in Ihrem Land.';
  @override
  String get privacyDescription => 'Wir respektieren Ihre Privatsphäre und verarbeiten Ihre Daten gemäß den geltenden Datenschutzgesetzen Ihrer Region.';
  @override
  String get countrySpecificTerms => 'Länderspezifische Bedingungen können je nach Standort gelten.';
  @override
  String get localLawsNotice => 'Die Nutzung muss lokalen Parkgesetzen und -vorschriften entsprechen.';
  @override
  String get nearestParking => 'Nächster Parkplatz';
  @override
  String get km => 'km';
  @override
  String get walletBalance => 'Wallet-Guthaben';
  @override
  String get activeSession => 'Aktive Sitzung';
  @override
  String get startNewSession => 'Neue Sitzung starten';
  @override
  String get rate => 'Tarif';
  @override
  String get slots => 'plätzen';
  @override
  String get directions => 'Wegbeschreibung';
  @override
  String get nearbyParking => 'Parkplätze in der Nähe';
  @override
  String get searchParking => 'Suche nach Parkplätzen...';
  @override
  String get navigatingTo => 'Navigation zu';
  @override
  String get remaining => 'verbleibend';
  @override
  String get unableToGetLocation => 'Ihre Position konnte nicht ermittelt werden';
  @override
  String get startParkingSession => 'Parksitzung starten';
  @override
  String get startReservedSession => 'Reservierte Sitzung starten';
  @override
  String get reservationConfirmed => 'Reservierung bestätigt!';
  @override
  String get selectVehicle => 'Fahrzeug auswählen';
  @override
  String get duration => 'Dauer';
  @override
  String get minutes => 'Minuten';
  @override
  String get startParkingNow => 'JETZT PARKEN';
  @override
  String get confirmBooking => 'BUCHUNG BESTÄTIGEN';
  @override
  String get confirmReservation => 'Reservierung bestätigen';
  @override
  String get date => 'Datum';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get pleaseSelectVehicleAndZone =>
      'Bitte wählen Sie ein Fahrzeug und eine Zone aus';
  @override
  String get startTimeInFuture => 'Startzeit muss in der Zukunft liegen';
  @override
  String get reservationFailed => 'Reservierung fehlgeschlagen. Bitte Guthaben prüfen.';
  @override
  String get paymentSuccessful => 'Zahlung erfolgreich!';
  @override
  String get processingReservation => 'Reservierung wird verarbeitet...';
  @override
  String get initiatingPayment => 'Zahlung wird eingeleitet...';
  @override
  String get oneClickSuccess => 'Ein-Klick-Erfolg!';
  @override
  String get startReservedSessionPrompt => 'Möchten Sie diese Parksitzung jetzt starten?';
  @override
  String get bookSpotPrompt => 'Möchten Sie diesen Parkplatz buchen?';
  @override
  String get areYouSureEndSession =>
      'Sind Sie sicher, dass Sie diese Parksitzung beenden möchten?';
  @override
  String get endSession => 'Sitzung beenden';
  @override
  String get sessionEndedSuccess => 'Ihre Parksitzung wurde erfolgreich beendet.';
  @override
  String get extendDuration => 'Dauer verlängern';
  @override
  String get additionalCost => 'Zusätzliche Kosten';
  @override
  String get insufficientBalance => 'Unzureichendes Guthaben. Bitte aufladen.';
  @override
  String get parkingLocationSaved => 'Parkplatz gespeichert!';
  @override
  String get noSavedLocation =>
      'Kein gespeicherter Standort gefunden. Tippen Sie zuerst auf "Parkplatz speichern".';
  @override
  String get viewVerificationQR => 'VERIFIZIERUNGS-QR ANZEIGEN';
  @override
  String get endSessionEarly => 'Sitzung vorzeitig beenden';
  @override
  String get history => 'Verlauf';
  @override
  String get saveSpot => 'Speichern';
  @override
  String get findCar => 'Auto finden';
  @override
  String get until => 'bis';
  @override
  String get vehicle => 'Fahrzeug';
  @override
  String get extended => 'Verlängert!';
  @override
  String get sessionExtendedBy => 'Parksitzung verlängert um';
  @override
  String get hours => 'Stunde(n)';
  @override
  String get sessionEnded => 'Sitzung beendet';
  @override
  String get payAndExtendNow => 'Jetzt bezahlen & verlängern';
  @override
  String get processingPayment => 'Zahlung wird verarbeitet...';
  @override
  String get sessionStarting => 'Ihre Parksitzung beginnt jetzt';
  @override
  String get spotBooked => 'Ihr Platz wurde gebucht';
  @override
  String get spotBookedSuccess => 'Ihr Parkplatz wurde erfolgreich gebucht.';
  @override
  String get canStartNowPrompt =>
      'Sie können Ihre Sitzung jetzt starten, da Ihre Zeit nahe ist.';
  @override
  String get ok => 'OK';
  @override
  String get bookSpot => 'Platz buchen';
  @override
  String get time => 'Zeit';
  @override
  String get showToOfficer => 'Zeigen Sie dies dem Parkplatzwächter';
  @override
  String get expiresAt => 'Läuft ab um';
  @override
  String get languagePreferences => 'Spracheinstellungen';
  @override
  String get themeSettings => 'Theme-Einstellungen';
  @override
  String get current => 'Aktuell';
  @override
  String get appVersion => 'App-Version';
  @override
  String get buildNumber => 'Build-Nummer';
  @override
  String get lastUpdated => 'Zuletzt aktualisiert';
  @override
  String get account => 'Konto';
}

// Arabic Localizations
class _ArabicLocalizations extends AppLocalizations {
  _ArabicLocalizations();

  @override
  String get viewOnMap => 'عرض على الخريطة';
  @override
  String get appTitle => 'SPACE';
  @override
  String get welcome => 'مرحباً بكم في SPACE';
  @override
  String get login => 'تسجيل الدخول';
  @override
  String get register => 'إنشاء حساب';
  @override
  String get logout => 'تسجيل الخروج';
  @override
  String get phone => 'رقم الهاتف';
  @override
  String get password => 'كلمة المرور';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get confirmPassword => 'تأكيد كلمة المرور';
  @override
  String get firstName => 'الاسم الأول';
  @override
  String get lastName => 'اسم العائلة';
  @override
  String get next => 'التالي';
  @override
  String get back => 'رجوع';
  @override
  String get save => 'حفظ';
  @override
  String get delete => 'حذف';
  @override
  String get confirm => 'تأكيد';
  @override
  String get areYouSure => 'هل أنت متأكد؟';
  @override
  String get deleteAccount => 'حذف الحساب';
  @override
  String get deleteAccountDescription =>
      'سيؤدي هذا إلى حذف حسابك وجميع البيانات المرتبطة به نهائياً.';

  @override
  String get enterOtp => 'أدخل رمز التحقق';
  @override
  String get otpSent => 'تم إرسال رمز التحقق إلى هاتفك';
  @override
  String get resendOtp => 'إعادة إرسال رمز التحقق';
  @override
  String get verifyPhone => 'التحقق من رقم الهاتف';
  @override
  String get phoneVerified => 'تم التحقق من الهاتف بنجاح';

  @override
  String get startParking => 'بدء الوقوف';
  @override
  String get stopParking => 'إيقاف';
  @override
  String get endParking => 'إنهاء';
  @override
  String get parkingActive => 'الوقوف نشط';
  @override
  String get parkingHistory => 'سجل الوقوف';
  @override
  String get zones => 'المناطق';
  @override
  String get selectZone => 'اختر المنطقة';

  @override
  String get payments => 'المدفوعات';
  @override
  String get transactions => 'المعاملات';
  @override
  String get wallet => 'المحفظة';
  @override
  String get balance => 'الرصيد';
  @override
  String get topUp => 'شحن الرصيد';
  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get chat => 'المحادثة';
  @override
  String get support => 'الدعم';
  @override
  String get startConversation => 'بدء محادثة';
  @override
  String get conversations => 'المحادثات';
  @override
  String get messages => 'الرسائل';
  @override
  String get sendMessage => 'إرسال رسالة';
  @override
  String get noConversations => 'لا توجد محادثات بعد';
  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get settings => 'الإعدادات';
  @override
  String get language => 'اللغة';
  @override
  String get theme => 'المظهر';
  @override
  String get darkMode => 'الوضع الداكن';
  @override
  String get lightMode => 'الوضع الفاتح';
  @override
  String get notifications => 'التنبيهات';
  @override
  String get about => 'حول التطبيق';

  @override
  String get error => 'خطأ';
  @override
  String get errorOccurred => 'حدث خطأ ما';
  @override
  String get tryAgain => 'إعادة المحاولة';
  @override
  String get loading => 'جاري التحميل...';

  @override
  String get activeParking => 'الوقوف النشط';
  @override
  String get timeLeft => 'الوقت المتبقي';
  @override
  String get currentCost => 'التكلفة الحالية';
  @override
  String get view => 'عرض';
  @override
  String get upcomingReservation => 'الحجز القادم';
  @override
  String get navigateToZone => 'التوجه إلى المنطقة';
  @override
  String get lookingForParking => 'تبحث عن موقف؟';
  @override
  String get findSpotsNearYou => 'ابحث عن أفضل الأماكن القريبة منك';
  @override
  String get searchDestination => 'البحث عن الوجهة...';
  @override
  String get quickActions => 'إجراءات سريعة';
  @override
  String get myVehicles => 'مركباتي';
  @override
  String get reservations => 'الحجوزات';
  @override
  String get recentActivity => 'النشاط الأخير';
  @override
  String get viewAll => 'عرض الكل';
  @override
  String get noRecentSessions => 'لا توجد جلسات وقوف أخيرة';
  @override
  String get unpaidViolations => 'مخالفات غير مدفوعة';
  @override
  String get payNow => 'ادفع الآن';

  @override
  String get selectLanguage => 'اختر اللغة';
  @override
  String get english => 'الإنجليزية';
  @override
  String get french => 'الفرنسية';
  @override
  String get german => 'الألمانية';
  @override
  String get swahili => 'السواحيلية';
  @override
  String get spanish => 'الإسبانية';
  @override
  String get arabic => 'العربية';
  @override
  String get system => 'النظام';
  @override
  String get hostParkingSpace => 'تأجير مساحة وقوف';
  @override
  String get hostParkingSpaceSubtitle => 'اربح المال عن طريق عرض مساحتك!';
  @override
  String get helpCenter => 'مركز المساعدة';
  @override
  String get privacyPolicy => 'سياسة الخصوصية';
  @override
  String get termsOfService => 'شروط الخدمة';
  @override
  String get aboutSpacePark => 'حول سبيس بارك';
  @override
  String get secureParkingMadeEasy => 'مواقف آمنة وسهلة';
  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';
  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';
  @override
  String get joinSpacePark => 'انضم إلى سبيس بارك';
  @override
  String get iAcceptThe => 'أنا أقبل ';
  @override
  String get terms => 'الشروط';
  @override
  String get loginToYourAccount => 'تسجيل الدخول إلى حسابك';
  @override
  String get forgotPassword => 'هل نسيت كلمة السر؟';
  @override
  String get comingSoon => 'قريباً!';
  @override
  String get passwordResetSoon => 'خاصية استعادة كلمة السر قادمة قريباً!';
  @override
  String get confirmYourPasswordPrompt => 'تأكيد كلمة المرور';
  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';
  @override
  String get passwordTooShort => 'كلمة السر قصيرة جداً';
  @override
  String get registrationFailed => 'فشل التسجيل';
  @override
  String get accountDeletionRequested => 'تم طلب حذف الحساب.';
  @override
  String get failedToRequestDeletion => 'فشل طلب الحذف.';
  @override
  String get permissionsUpdated => 'تم تحديث الأذونات';
  @override
  String get uploadingPhoto => 'جاري رفع الصورة...';
  @override
  String get photoUpdated => 'تم تحديث الصورة';
  @override
  String get uploadFailed => 'فشل الرفع';
  @override
  String get deleteAccountConfirmation => 'هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء فوراً، ولكن سيتم الاحتفاظ ببياناتك لمدة 30 يوماً قبل الحذف الدائم.';
  @override
  String get yourDigitalPass => 'بطاقتك الرقمية';
  @override
  String get scanToVerify => 'امسح هذا الرمز للتحقق من هويتك';
  @override
  String get name => 'الاسم';
  @override
  String get vehicleLabel => 'المركبة';
  @override
  String get partnerProgram => 'برنامج الشركاء';
  @override
  String get selectCountry => 'اختر بلدك';
  @override
  String get pleaseSelectCountry => 'يرجى اختيار بلدك للمتابعة';
  @override
  String get continueText => 'استمر';

  @override
  String get chooseYourLanguage => 'اختر لغتك';
  @override
  String get selectPreferredLanguage => 'اختر لغتك المفضلة للحصول على أفضل تجربة';
  @override
  String get selectLanguageForBestExperience => 'اختر لغتك المفضلة للحصول على أفضل تجربة';
  @override
  String get termsAndConditions => 'الشروط والأحكام';
  @override
  String get termsDescription => 'باستخدام SPACE، فإنك توافق على شروط الخدمة الخاصة بنا وتلتزم باللوائح المحلية للوقوف في بلدك.';
  @override
  String get privacyDescription => 'نحترم خصوصيتك ونعالج بياناتك وفقاً لقوانين الخصوصية المعمول بها في منطقتك.';
  @override
  String get countrySpecificTerms => 'قد تنطبق شروط خاصة بالبلد بناءً على موقعك.';
  @override
  String get localLawsNotice => 'يجب أن تلتزم الاستخدام بقوانين ولوائح الوقوف المحلية.';
  @override
  String get nearestParking => 'أقرب موقف سيارات';
  @override
  String get km => 'كم';
  @override
  String get walletBalance => 'رصيد المحفظة';
  @override
  String get activeSession => 'جلسة نشطة';
  @override
  String get startNewSession => 'بدء جلسة جديدة';
  @override
  String get rate => 'السعر';
  @override
  String get slots => 'فتحات';
  @override
  String get directions => 'الاتجاهات';
  @override
  String get nearbyParking => 'مواقف السيارات القريبة';
  @override
  String get searchParking => 'البحث عن موقف سيارات...';
  @override
  String get navigatingTo => 'التنقل إلى';
  @override
  String get remaining => 'المتبقي';
  @override
  String get unableToGetLocation => 'تعذر الحصول على موقعك';
  @override
  String get startParkingSession => 'بدء جلسة وقوف السيارات';
  @override
  String get startReservedSession => 'بدء الجلسة المحجوزة';
  @override
  String get reservationConfirmed => 'تم تأكيد الحجز!';
  @override
  String get selectVehicle => 'اختر السيارة';
  @override
  String get duration => 'المدة';
  @override
  String get minutes => 'دقائق';
  @override
  String get startParkingNow => 'ابدأ الوقوف الآن';
  @override
  String get confirmBooking => 'تأكيد الحجز';
  @override
  String get confirmReservation => 'تأكيد الحجز';
  @override
  String get date => 'التاريخ';
  @override
  String get cancel => 'إلغاء';
  @override
  String get pleaseSelectVehicleAndZone => 'يرجى اختيار سيارة ومنطقة';
  @override
  String get startTimeInFuture => 'يجب أن يكون وقت البدء في المستقبل';
  @override
  String get reservationFailed => 'فشل الحجز. يرجى التحقق من الرصيد.';
  @override
  String get paymentSuccessful => 'تم الدفع بنجاح!';
  @override
  String get processingReservation => 'جاري معالجة الحجز...';
  @override
  String get initiatingPayment => 'جاري بدء الدفع...';
  @override
  String get oneClickSuccess => 'نجاح بنقرة واحدة!';
  @override
  String get startReservedSessionPrompt => 'هل تريد بدء جلسة وقوف السيارات هذه الآن؟';
  @override
  String get bookSpotPrompt => 'هل تريد حجز موقف السيارات هذا؟';
  @override
  String get areYouSureEndSession => 'هل أنت متأكد أنك تريد إنهاء جلسة وقوف السيارات هذه؟';
  @override
  String get endSession => 'إنهاء الجلسة';
  @override
  String get sessionEndedSuccess => 'تم إيقاف جلسة وقوف السيارات الخاصة بك بنجاح.';
  @override
  String get extendDuration => 'تمديد المدة';
  @override
  String get additionalCost => 'تكلفة إضافية';
  @override
  String get insufficientBalance => 'رصيد المحفظة غير كافٍ. يرجى التعبئة.';
  @override
  String get parkingLocationSaved => 'تم حفظ موقع وقوف السيارات!';
  @override
  String get noSavedLocation => 'لم يتم العثور على موقع محفوظ. اضغط على "حفظ الموقع" أولاً.';
  @override
  String get viewVerificationQR => 'عرض رمز التحقق QR';
  @override
  String get endSessionEarly => 'إنهاء الجلسة مبكرًا';
  @override
  String get history => 'السجل';
  @override
  String get saveSpot => 'حفظ الموقع';
  @override
  String get findCar => 'البحث عن السيارة';
  @override
  String get until => 'حتى';
  @override
  String get vehicle => 'السيارة';
  @override
  String get extended => 'تم التمديد!';
  @override
  String get sessionExtendedBy => 'تم تمديد جلسة الوقوف بمقدار';
  @override
  String get hours => 'ساعة';
  @override
  String get sessionEnded => 'انتهت الجلسة';
  @override
  String get payAndExtendNow => 'ادفع ومدد الآن';
  @override
  String get processingPayment => 'جاري معالجة الدفع...';
  @override
  String get sessionStarting => 'تبدأ جلسة الوقوف الخاصة بك الآن';
  @override
  String get spotBooked => 'تم حجز مكانك';
  @override
  String get spotBookedSuccess => 'تم حجز موقع الوقوف الخاص بك بنجاح.';
  @override
  String get canStartNowPrompt => 'يمكنك بدء جلستك الآن لأن وقتك اقترب.';
  @override
  String get ok => 'موافق';
  @override
  String get bookSpot => 'حجز مكان';
  @override
  String get time => 'الوقت';
  @override
  String get showToOfficer => 'أظهر هذا لمسؤول وقوف السيارات';
  @override
  String get expiresAt => 'تنتهي الصلاحية في';
  @override
  String get languagePreferences => 'تفضيلات اللغة';
  @override
  String get themeSettings => 'إعدادات المظهر';
  @override
  String get current => 'الحالي';
  @override
  String get appVersion => 'اصدار التطبيق';
  @override
  String get buildNumber => 'رقم البناء';
  @override
  String get lastUpdated => 'آخر تحديث';
  @override
  String get account => 'الحساب';
  @override
  String get preferences => 'التفضيلات';

  @override
  String get detectingLocation => 'تحديد موقعك';
  @override
  String get detectingLocationSubtitle => 'نحن نحدد بلدك لنقدم لك أفضل تجربة.';
  @override
  String get spaceAvailableInCountry => 'سبيس متاح في بلدك!';
  @override
  String get spaceNotAvailableTitle => 'سبيس غير متاح في منطقتك بعد';
  @override
  String spaceNotAvailableBody(String countryName) =>
      'لم نطلق بعد في $countryName. نعمل بجد لإحضار سبيس إلى منطقتك!';
  @override
  String get retryDetection => 'إعادة المحاولة';
  @override
  String get locationDetectionFailed => 'تعذر تحديد الموقع';
  @override
  String get locationDetectionFailedSubtitle => 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
}

// Localizations Delegate
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sw', 'fr', 'es', 'de', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
