// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Plantilla Flutter';

  @override
  String get back => 'Atrás';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get retry => 'Reintentar';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInSubtitle =>
      'Bienvenido de nuevo. Inicia sesión para continuar donde lo dejaste.';

  @override
  String get signUpSubtitle =>
      'Crea una cuenta para sincronizar entre tus dispositivos.';

  @override
  String get termsFooter =>
      'Al continuar aceptas las Condiciones del servicio.';

  @override
  String get notesTitle => 'Notas';

  @override
  String get newNote => 'Nueva nota';

  @override
  String get notesEmptyTitle => 'Aún no hay notas';

  @override
  String get notesEmptyBody => 'Toca «Nueva nota» para escribir la primera.';

  @override
  String get notesLoadErrorTitle => 'No se pudieron cargar las notas';

  @override
  String get untitledNote => 'Nota sin título';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendientes',
      one: '1 pendiente',
    );
    return '$_temp0';
  }

  @override
  String get syncNowTooltip => 'Sincronizar ahora';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String syncSuccess(int up, int down) {
    return 'Sincronizado: $up subidas, $down bajadas.';
  }

  @override
  String syncPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizado, pero $count notas no se pudieron subir.',
      one: 'Sincronizado, pero 1 nota no se pudo subir.',
    );
    return '$_temp0';
  }

  @override
  String get syncFailed => 'Fallo al sincronizar. Comprueba tu conexión.';

  @override
  String get editNote => 'Editar nota';

  @override
  String get noteTitleLabel => 'Título';

  @override
  String get noteTitleHint => 'Ponle un nombre';

  @override
  String get noteBodyLabel => 'Nota';

  @override
  String get saveNote => 'Guardar nota';

  @override
  String get savingNote => 'Guardando…';

  @override
  String noteTitleTooLong(int max) {
    return 'El título es demasiado largo: máximo $max caracteres.';
  }

  @override
  String noteBodyTooLong(int max) {
    return 'La nota es demasiado larga: máximo $max caracteres.';
  }

  @override
  String get nothingToSave =>
      'No hay nada que guardar: añade un título o algo de texto.';

  @override
  String get saveFailedQueued =>
      'No se pudo guardar. La nota queda en este dispositivo y se reintentará.';

  @override
  String get deleteNoteTitle => '¿Eliminar la nota?';

  @override
  String get deleteNoteBody => 'Esta acción no se puede deshacer.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get signedOut => 'Sesión cerrada.';

  @override
  String get guest => 'Invitado';

  @override
  String get emailNotVerified => 'Correo no verificado';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get saveName => 'Guardar nombre';

  @override
  String get nameUpdated => 'Nombre actualizado.';

  @override
  String get nameUpdateFailed => 'No se pudo actualizar tu nombre.';

  @override
  String get enterNameFirst => 'Introduce un nombre primero.';

  @override
  String get uploadAvatar => 'Subir avatar';

  @override
  String get avatarUploaded => 'Avatar subido.';

  @override
  String get avatarUploadedProfileFailed =>
      'Se subió, pero el perfil no se actualizó.';

  @override
  String get avatarChooseSource => 'Cambiar avatar';

  @override
  String get avatarFromCamera => 'Hacer una foto';

  @override
  String get avatarFromGallery => 'Elegir de la galería';

  @override
  String get avatarPickFailed => 'No se pudo leer esa imagen.';

  @override
  String get avatarRemove => 'Quitar avatar';

  @override
  String get avatarRemoved => 'Avatar eliminado.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutBody => 'Tus datos seguirán sincronizados con tu cuenta.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto elimina tu cuenta de forma permanente y no se puede deshacer.';

  @override
  String get deleteAccountFailed =>
      'No se pudo eliminar la cuenta. Inicia sesión de nuevo e inténtalo otra vez.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get sectionNotifications => 'Notificaciones';

  @override
  String get pushTitle => 'Notificaciones push';

  @override
  String get pushSubtitle =>
      'Recibe un aviso cuando algo necesite tu atención.';

  @override
  String get pushBlocked => 'Bloqueadas en los ajustes del sistema.';

  @override
  String get pushOpenSettings => 'Abrir ajustes';

  @override
  String get sectionPrivacy => 'Privacidad';

  @override
  String get sectionSync => 'Sincronización';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get themeSystem => 'Según el sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get accentColour => 'Color de acento';

  @override
  String get languageSystem => 'Según el sistema';

  @override
  String get analyticsTitle => 'Compartir datos de uso';

  @override
  String get analyticsSubtitle =>
      'Ayuda a mejorar la app. Tu contenido nunca se envía.';

  @override
  String get waitingToUpload => 'Pendiente de subir';

  @override
  String get appVersion => 'Versión';

  @override
  String get environmentLabel => 'Entorno';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String get updateRequiredBody =>
      'Esta versión ya no es compatible. Actualiza para seguir usando la app.';

  @override
  String get updateOptionalTitle => 'Actualización disponible';

  @override
  String get updateOptionalBody => 'Hay una versión más reciente disponible.';

  @override
  String get updateAction => 'Actualizar ahora';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get pageNotFoundBody => 'Esa página no existe.';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get offlineBanner =>
      'Sin conexión: los cambios se guardan en este dispositivo';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingDone => 'Empezar';

  @override
  String get onboardingTitle1 => 'En todos tus dispositivos';

  @override
  String get onboardingBody1 =>
      'Usa cualquier dispositivo. Todo se sincroniza con tu cuenta automáticamente.';

  @override
  String get onboardingTitle2 => 'Funciona sin conexión';

  @override
  String get onboardingBody2 =>
      'Sigue trabajando sin conexión. Los cambios se suben en cuanto vuelvas.';

  @override
  String get onboardingTitle3 => 'Solo tuyas';

  @override
  String get onboardingBody3 =>
      'Tus datos viven en tu cuenta y solo tú puedes leerlos.';

  @override
  String get authInvalidEmail => 'Esa dirección de correo no es válida.';

  @override
  String get authUserDisabled => 'Esta cuenta ha sido deshabilitada.';

  @override
  String get authUserNotFound => 'No hay ninguna cuenta con ese correo.';

  @override
  String get authWrongPassword => 'Correo o contraseña incorrectos.';

  @override
  String get authEmailInUse => 'Ya existe una cuenta con ese correo.';

  @override
  String get authWeakPassword =>
      'Elige una contraseña de al menos 6 caracteres.';

  @override
  String get authRequiresRecentLogin =>
      'Inicia sesión de nuevo para completar este cambio.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Inténtalo de nuevo en unos minutos.';

  @override
  String get authNetworkFailed => 'Sin red. Comprueba tu conexión.';

  @override
  String get authOperationNotAllowed =>
      'Ese método de inicio de sesión no está habilitado.';

  @override
  String get authNotSignedIn => 'No has iniciado sesión.';

  @override
  String get authGeneric => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String get setupTitle => 'Se requiere configurar Firebase';

  @override
  String get setupBody =>
      'Esta app necesita Firebase para funcionar. La autenticación, tus datos y el almacenamiento de archivos dependen de él, así que nada funciona hasta que se configure.';

  @override
  String get setupStepsHeading =>
      'Ejecuta esto una vez, desde la raíz del proyecto:';

  @override
  String get setupRestartHint => 'Después detén la app y vuelve a ejecutarla.';

  @override
  String get setupChecklistHint => 'task.md → Hito 0 tiene la lista completa.';

  @override
  String get setupDetails => 'Detalles del error';

  @override
  String get setupCopied => 'Copiado al portapapeles';

  @override
  String get copy => 'Copiar';

  @override
  String get storageUnauthorized => 'No tienes permiso para hacer eso.';

  @override
  String get storageNotFound => 'Ese archivo ya no existe.';

  @override
  String get storageQuotaExceeded => 'Cuota de almacenamiento superada.';

  @override
  String get storageCanceled => 'Subida cancelada.';

  @override
  String get storageGeneric => 'La operación con el archivo ha fallado.';
}
