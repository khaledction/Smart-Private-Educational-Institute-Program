class AppSession {
  AppSession._();

  static String currentRole = 'المدير العام';

  static bool get isGeneralManager => currentRole == 'المدير العام';

  static bool get canViewFinancial {
    return currentRole == 'المدير العام' ||
        currentRole == 'المحاسبة' ||
        currentRole == 'محاسب';
  }
}
