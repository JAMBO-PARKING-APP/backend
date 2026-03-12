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
}

// English Localizations
class _EnglishLocalizations extends AppLocalizations {
  _EnglishLocalizations();

  @override
  String get appTitle => 'Spave Park';
  @override
  String get welcome => 'Welcome to Spave Park';
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

  // New keys for Home Screen
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
}

// Swahili Localizations
class _SwahiliLocalizations extends AppLocalizations {
  _SwahiliLocalizations();

  @override
  String get appTitle => 'Spave Park';
  @override
  String get welcome => 'Karibu kwenye Spave Park';
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

  // New keys for Home Screen
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
}

// French Localizations
class _FrenchLocalizations extends AppLocalizations {
  _FrenchLocalizations();

  @override
  String get appTitle => 'Spave Park';
  @override
  String get welcome => 'Bienvenue à Spave Park';
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

  // New keys for Home Screen
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
  String get findSpotsNearYou =>
      'Trouvez les meilleures places près de chez vous';
  @override
  String get searchDestination => 'Rechercher une destination...';
  @override
  String get quickActions => 'Actions Rapides';
  @override
  String get myVehicles => 'Mes Véhicules';
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
}

// Spanish Localizations
class _SpanishLocalizations extends AppLocalizations {
  _SpanishLocalizations();

  @override
  String get appTitle => 'Spave Park';
  @override
  String get welcome => 'Bienvenido a Spave Park';
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

  // New keys for Home Screen
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
}

// German Localizations
class _GermanLocalizations extends AppLocalizations {
  _GermanLocalizations();

  @override
  String get appTitle => 'Spave Park';
  @override
  String get welcome => 'Willkommen bei Spave Park';
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
}

// Arabic Localizations
class _ArabicLocalizations extends AppLocalizations {
  _ArabicLocalizations();

  @override
  String get appTitle => 'Space';
  @override
  String get welcome => 'مرحباً بكم في Space';
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
}

// Localizations Delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
