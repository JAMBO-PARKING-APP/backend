import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

abstract class AppLocalizations {
  const AppLocalizations();

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
}

// English Localizations
class _EnglishLocalizations extends AppLocalizations {
  _EnglishLocalizations();

  @override
  String get appTitle => 'Jambo Park';
  @override
  String get welcome => 'Welcome to Jambo Park';
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
}

// Swahili Localizations
class _SwahiliLocalizations extends AppLocalizations {
  _SwahiliLocalizations();

  @override
  String get appTitle => 'Jambo Park';
  @override
  String get welcome => 'Karibu kwenye Jambo Park';
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
}

// French Localizations
class _FrenchLocalizations extends AppLocalizations {
  _FrenchLocalizations();

  @override
  String get appTitle => 'Jambo Park';
  @override
  String get welcome => 'Bienvenue à Jambo Park';
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
}

// Spanish Localizations
class _SpanishLocalizations extends AppLocalizations {
  _SpanishLocalizations();

  @override
  String get appTitle => 'Jambo Park';
  @override
  String get welcome => 'Bienvenido a Jambo Park';
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
}

// Localizations Delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sw', 'fr', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
