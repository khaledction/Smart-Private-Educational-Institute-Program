import 'package:flutter/foundation.dart';

class AppSession extends ChangeNotifier {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const String managementUser = 'الإدارة';
  static const String coursesUser = 'الدورات';
  static const String accountingUser = 'المحاسبة';
  static const String studentsUser = 'الطلاب';

  String _currentUser = '';

  bool get isLoggedIn => _currentUser.isNotEmpty;
  String get currentUser => _currentUser;

  static List<String> get availableUsers => const [
        managementUser,
        coursesUser,
        accountingUser,
        studentsUser,
      ];

  static String get currentRole => instance._currentUser.isEmpty ? 'غير مسجل' : instance._currentUser;

  static bool get isGeneralManager => currentRole == managementUser;
  static bool get isCoursesManager => currentRole == coursesUser;
  static bool get isAccounting => currentRole == accountingUser;
  static bool get isStudentsAffairs => currentRole == studentsUser;

  static bool get canViewFinancial => isGeneralManager || isAccounting || currentRole == 'محاسب';
  static bool get canApproveCourses => isGeneralManager;
  static bool get canAccessDashboard => isGeneralManager;
  static bool get canAccessCourses => isGeneralManager || isCoursesManager;
  static bool get canAccessStudents => isGeneralManager || isStudentsAffairs;
  static bool get canAccessRegistration => isGeneralManager || isStudentsAffairs;
  static bool get canAccessAccountingArea => isGeneralManager || isAccounting;

  static Set<int> get allowedNavIndexes {
    if (isGeneralManager) {
      return <int>{for (var i = 0; i < 13; i++) i};
    }
    if (isCoursesManager) {
      return const <int>{3};
    }
    if (isAccounting) {
      return const <int>{8, 9};
    }
    if (isStudentsAffairs) {
      return const <int>{1, 2};
    }
    return const <int>{0};
  }

  static int get homeIndex => allowedNavIndexes.first;

  static void loginAs(String user) {
    instance._currentUser = user;
    instance.notifyListeners();
  }

  static void logout() {
    instance._currentUser = '';
    instance.notifyListeners();
  }

  static String get roleSubtitle {
    if (isGeneralManager) return 'صلاحيات مطلقة على كل الأقسام واعتماد الدورات';
    if (isCoursesManager) return 'إنشاء وتعديل الدورات فقط، والاعتماد من الإدارة';
    if (isAccounting) return 'الوصول إلى الفواتير والأقساط والمحاسبة فقط';
    if (isStudentsAffairs) return 'الوصول إلى الطلاب والتسجيل والانتظار فقط';
    return 'يرجى اختيار مستخدم للدخول';
  }
}
