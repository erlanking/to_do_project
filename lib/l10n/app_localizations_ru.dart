// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'TaskFlow';

  @override
  String get loginTitle => 'Вход';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get name => 'Имя';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get login => 'Войти';

  @override
  String get registration => 'Регистрация';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get myTasks => 'Мои задачи';

  @override
  String get addTask => 'Добавить задачу';

  @override
  String get newTask => 'Новая задача';

  @override
  String get editTask => 'Изменить задачу';

  @override
  String get save => 'Сохранить';

  @override
  String get update => 'Обновить';

  @override
  String get taskText => 'Текст задачи';

  @override
  String get logout => 'Выйти';

  @override
  String get noTasks => 'Нет задач';

  @override
  String get fillAllFields => 'Пожалуйста, заполните все поля';

  @override
  String get passwordsDontMatch => 'Пароли не совпадают';

  @override
  String get registrationSuccess => 'Регистрация успешна';

  @override
  String get networkError => 'Ошибка сети';

  @override
  String get enterTask => 'Введите задачу';

  @override
  String get tokenMissing => 'Нет токена';

  @override
  String get unauthorized => 'Не авторизован';

  @override
  String get searchHint => 'Поиск';
}
