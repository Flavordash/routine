// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Rutina - Selector de Reloj 24 Horas';

  @override
  String get homeTitle => 'Selector de Reloj 24 Horas';

  @override
  String get settings => 'Configuración';

  @override
  String get yourTimeSlots => 'Tus Franjas Horarias';

  @override
  String get noTimeSlotsYet =>
      'Aún no hay franjas horarias. ¡Toca + para crear una o arrastra en el círculo!';

  @override
  String get routineSlots => 'Espacios de Rutina';

  @override
  String get signInToSync => 'Inicia sesión para sincronizar tus rutinas';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get cancel => 'Cancelar';

  @override
  String get signInWithEmail => 'Iniciar Sesión con Correo';

  @override
  String get signUpWithEmail => 'Registrarse con Correo';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get upgradeToProButton => 'Actualizar a Pro';

  @override
  String get proMember => 'MIEMBRO PRO';

  @override
  String get freeUser => 'USUARIO GRATUITO';

  @override
  String get addNewRoutineSlot => 'Añadir Nueva Rutina';

  @override
  String get currentlyActive => 'Actualmente Activo';

  @override
  String get tapToActivate => 'Toca para activar';

  @override
  String get rename => 'Renombrar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get delete => 'Eliminar';

  @override
  String get renameRoutine => 'Renombrar Rutina';

  @override
  String get routineName => 'Nombre de la Rutina';

  @override
  String get save => 'Guardar';

  @override
  String get deleteRoutine => 'Eliminar Rutina';

  @override
  String deleteRoutineConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String get createTimeSlot => 'Crear Franja Horaria';

  @override
  String get editTimeSlot => 'Editar Franja Horaria';

  @override
  String get titleOfThisTime => 'Título de este tiempo';

  @override
  String get titleHint => 'ej., Trabajo, Ejercicio, Dormir...';

  @override
  String get descriptionOfThisTime => 'Descripción de este tiempo';

  @override
  String get descriptionHint =>
      'ej., Rutina de ejercicio matutino, Reunión de equipo...';

  @override
  String get adjustTime => 'Ajustar tiempo:';

  @override
  String get from => 'Desde: ';

  @override
  String get to => 'Hasta: ';

  @override
  String get chooseColor => 'Elegir un color:';

  @override
  String get enableNotifications => 'Habilitar notificaciones';

  @override
  String get create => 'Crear';

  @override
  String get update => 'Actualizar';

  @override
  String duration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String durationSuffix(String duration) {
    return '$duration duración';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get helpAndSupport => 'Ayuda y Soporte';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get learnHowToUse => 'Aprende cómo usar la aplicación';

  @override
  String get about => 'Acerca de';

  @override
  String get developedBy => 'Desarrollado por Kwanhoon Lee';

  @override
  String get copyright => '© 2025 - Hecho para mí y para TI';

  @override
  String languageChanged(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get welcomeToRoutine => 'Bienvenido a Rutina 24';

  @override
  String get planYourDay =>
      'Planifica tu día con nuestra interfaz de reloj interactivo de 24 horas.';

  @override
  String get creatingTimeSlots => 'Creando Franjas Horarias';

  @override
  String get creatingTimeSlotsDesc =>
      'Toca y arrastra en el reloj para crear franjas horarias para tus actividades. El anillo exterior representa las horas (0-23).';

  @override
  String get managingYourSchedule => 'Gestionando tu Horario';

  @override
  String get managingYourScheduleDesc =>
      'Tus franjas horarias aparecerán con horas de inicio y fin. Toca en las franjas existentes para modificarlas o eliminarlas.';

  @override
  String get settingsCustomization => 'Configuración y Personalización';

  @override
  String get settingsCustomizationDesc =>
      'Toca el botón de configuración en la esquina superior derecha para acceder al cambio de tema, opciones de idioma y más funciones de personalización.';

  @override
  String get proSubscriptionBenefits => 'Beneficios de la Suscripción PRO';

  @override
  String get proSubscriptionBenefitsDesc =>
      'Suscríbete a PRO por \$6.99/año para desbloquear espacios de rutina ilimitados, experiencia sin anuncios y funciones premium. Los usuarios gratuitos obtienen 1 espacio.';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get freeUsersOneSlot =>
      'Los usuarios gratuitos pueden usar 1 espacio. Actualiza a Pro para espacios ilimitados.';

  @override
  String get proFeatures => 'Las funciones Pro incluyen:';

  @override
  String get unlimitedSlots => '• Espacios de rutina ilimitados';

  @override
  String get duplicateRoutines => '• Duplicar rutinas';

  @override
  String get prioritySupport => '• Soporte prioritario';

  @override
  String get advancedCustomization => '• Personalización avanzada';

  @override
  String get later => 'Más tarde';

  @override
  String get upgradeNow => 'Actualizar Ahora';

  @override
  String get thanksForSupporting =>
      '¡Gracias por apoyar Rutina 24! Disfruta de espacios ilimitados y experiencia sin anuncios.';

  @override
  String get advertisementSpace => 'Espacio Publicitario';

  @override
  String get upgradeToProAd =>
      '¡Actualiza a Pro por \$6.99/año - Sin anuncios, espacios ilimitados!';

  @override
  String get signInSuccess => '¡Sesión iniciada exitosamente!';

  @override
  String get signOutSuccess => 'Sesión cerrada exitosamente';

  @override
  String get accountCreatedSuccess => '¡Cuenta creada exitosamente!';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get upgradeToProUnlimited =>
      'Actualizar a Pro para espacios ilimitados';

  @override
  String get mediaNotFound => 'Medio no encontrado';

  @override
  String get or => 'o';

  @override
  String get defaultRoutine => 'Rutina Predeterminada';

  @override
  String get scheduleSpecificDaysFull =>
      'Schedule routine for specific days (Mon-Sun)';

  @override
  String get advancedNotificationsFull =>
      'Advanced notification with vibration';

  @override
  String get getUnlimitedAccess => 'Get Unlimited Access';

  @override
  String get removeAllAds => 'Remove all advertisements';

  @override
  String get scheduleSpecificDays => 'Schedule Specific Days';

  @override
  String get advancedNotifications => 'Advanced Notifications';

  @override
  String get cloudSyncBackup => 'Cloud Sync & Backup';

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get monthlyPlan => 'Monthly Plan';

  @override
  String get monthlyPrice => '\$0.99/month';

  @override
  String get yearlyPlan => 'Yearly Plan';

  @override
  String get yearlyPrice => '\$6.99/year';

  @override
  String get savingsText => 'Save 42%';

  @override
  String get restore => 'Restore';

  @override
  String get popular => 'Popular';

  @override
  String get processingPurchase => 'Processing Purchase...';

  @override
  String get purchasePlaceholder => 'Processing your purchase. Please wait...';

  @override
  String get restorePlaceholder => 'Restoring your purchases. Please wait...';
}
