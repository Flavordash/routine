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
      'Suscríbete a PRO por \$6.99/año para desbloquear espacios de rutina ilimitados, experiencia sin anuncios, compartir plantillas comunitarias, alarmas avanzadas, sincronización en la nube y más funciones premium. Los usuarios gratuitos obtienen 1 espacio.';

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
      'Programar rutina para días específicos (Lun-Dom)';

  @override
  String get advancedNotificationsFull =>
      'Notificaciones avanzadas con vibración';

  @override
  String get getUnlimitedAccess => 'Obtener Acceso Ilimitado';

  @override
  String get removeAllAds => 'Eliminar todos los anuncios';

  @override
  String get scheduleSpecificDays => 'Programar Días Específicos';

  @override
  String get advancedNotifications => 'Notificaciones Avanzadas';

  @override
  String get cloudSyncBackup => 'Sincronización y Respaldo en la Nube';

  @override
  String get chooseYourPlan => 'Elige Tu Plan';

  @override
  String get monthlyPlan => 'Plan Mensual';

  @override
  String get monthlyPrice => '\$3.99/mes';

  @override
  String get yearlyPlan => 'Plan Anual';

  @override
  String get yearlyPrice => '\$7.99/año';

  @override
  String get savingsText => 'Ahorra 42%';

  @override
  String get restore => 'Restaurar';

  @override
  String get popular => 'Popular';

  @override
  String get processingPurchase => 'Procesando Compra...';

  @override
  String get purchasePlaceholder => 'Procesando tu compra. Por favor espera...';

  @override
  String get restorePlaceholder =>
      'Restaurando tus compras. Por favor espera...';

  @override
  String get shareTemplates =>
      '• Comparte tus propias plantillas con la comunidad';

  @override
  String get advancedAlarmFeatures =>
      '• Funciones avanzadas de alarma con pre-alarma e Intervalos Inteligentes';

  @override
  String get browseImportTemplates =>
      '• Explora e importa plantillas de la comunidad';

  @override
  String get removeAllAdsFull => '• Elimina todos los anuncios';

  @override
  String get cloudSyncBackupFull => '• Sincronización y respaldo en la nube';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationPermissions => 'Permisos de Notificación';

  @override
  String get notificationsEnabled => 'Habilitadas';

  @override
  String get notificationsDisabled => 'Deshabilitadas';

  @override
  String get notificationSettings => 'Configuración de Notificaciones';

  @override
  String get notificationPermissionDescription =>
      'Permitir notificaciones para recibir alarmas y recordatorios de tus rutinas';

  @override
  String get openSettings => 'Abrir Configuración';

  @override
  String get notificationPermissionGranted =>
      '¡Las notificaciones están habilitadas! Recibirás alarmas para tus rutinas.';

  @override
  String get notificationPermissionDenied =>
      'Por favor habilita las notificaciones en la configuración de tu dispositivo para recibir alarmas.';

  @override
  String get preAlarm => 'Pre-Alarma';

  @override
  String get preAlarmTime => 'Tiempo de pre-alarma:';

  @override
  String get smartIntervals => 'Intervalos Inteligentes';

  @override
  String get intervalDuration => 'Duración del Intervalo:';

  @override
  String get silentIntervals => 'Intervalos Silenciosos';

  @override
  String get progressMessages => 'Mensajes de Progreso';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String timesCount(int count) {
    return '$count veces';
  }

  @override
  String get advancedAlarmPromoText =>
      'Obtén funciones avanzadas de alarma con avisos de pre-alarma y funcionalidad de Intervalos Inteligentes.';

  @override
  String get fillFreeTime => 'Llenar Tiempo Libre';

  @override
  String get browseTemplates => 'Explorar Plantillas';

  @override
  String get filledFreeTime => '¡Período de 24 horas llenado con Tiempo Libre!';

  @override
  String get noFreeTimeGaps =>
      'No se encontraron espacios de tiempo libre para llenar';

  @override
  String get purchaseSuccessful => '¡Compra exitosa! Ahora tienes acceso PRO.';

  @override
  String purchaseFailed(String error) {
    return 'Compra falló: $error';
  }

  @override
  String get purchasesRestored => '¡Compras restauradas exitosamente!';

  @override
  String restoreFailed(String error) {
    return 'Restauración falló: $error';
  }

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get selectDaysActive =>
      'Selecciona los días en que esta rutina debe estar activa:';

  @override
  String get newest => 'Más Recientes';

  @override
  String get mostLiked => 'Más Gustados';

  @override
  String get mostUsed => 'Más Usados';

  @override
  String get searchPlaceholder => 'Buscar plantillas...';

  @override
  String get category => 'Categoría';

  @override
  String get lifestyle => 'Estilo de Vida';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get loadingTemplates => 'Cargando plantillas...';

  @override
  String get noTemplatesFound => 'No se encontraron plantillas';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get noTemplatesAvailable => 'No hay plantillas disponibles';

  @override
  String get retry => 'Reintentar';

  @override
  String templateCategory(String category) {
    return 'Categoría: $category';
  }

  @override
  String failedToLoadTemplates(String error) {
    return 'Error al cargar algunas plantillas: $error';
  }

  @override
  String get all => 'Todos';

  @override
  String get colorSettings => 'Color Settings';

  @override
  String get shareAsTemplate => 'Share as Template';

  @override
  String get daySettings => 'Day Settings';

  @override
  String get renameRoutineDialog => 'Rename Routine';

  @override
  String get deleteRoutineDialog => 'Delete Routine';

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String daySettingsFor(String name) {
    return 'Day Settings for $name';
  }

  @override
  String chooseColorFor(String name) {
    return 'Choose Color for $name';
  }

  @override
  String get defaultColor => 'Default';

  @override
  String get templateName => 'Template Name';

  @override
  String get description => 'Description';

  @override
  String get enterTemplateName => 'Enter template name...';

  @override
  String get describeRoutine => 'Describe this routine...';

  @override
  String get lifestyleType => 'Lifestyle Type';

  @override
  String get sharingTemplate => 'Sharing template...';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterTemplateName => 'Please enter a template name';

  @override
  String templateSharedSuccess(String name) {
    return 'Template \"$name\" shared successfully!';
  }

  @override
  String get templateShareFailed =>
      'Failed to share template. Please try again.';

  @override
  String get everyDay => 'Every day';

  @override
  String get noDaysSelected => 'No days selected';

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShortFormat => 'm';
}
