import 'package:sembast_web/sembast_web.dart';

Future<Database> openGameDatabase() =>
    databaseFactoryWeb.openDatabase('building-management-tycoon-game');
