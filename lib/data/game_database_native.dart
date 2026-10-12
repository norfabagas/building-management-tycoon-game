import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

Future<Database> openGameDatabase() async {
  final directory = await getApplicationSupportDirectory();
  return getDatabaseFactorySqflite(sqlite.databaseFactory)
      .openDatabase('${directory.path}/tycoon-game.db');
}
