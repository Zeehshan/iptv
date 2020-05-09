import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';

import '../main.dart';



class DataDatabase {

  static final DataDatabase _instance = DataDatabase._internal();

  factory DataDatabase() => _instance;

  static Database _db;

  Future<Database> get dbAndrourl async {
    print("okay i am here");
    if (_db != null) {
      print("i am here 2");
      return _db;
    }
    _db = await initDBAndrourl();
    return _db;
  }

  Future<Database> get dbIOS async {
    if (_db != null) {
      return _db;
    }
    _db = await initIos();
    return _db;
  }



  DataDatabase._internal();

  Future<Database> initDBAndrourl() async {
    try{
      print("i am here 3");
      Directory documentsDirectory = await getExternalStorageDirectory();
      print("i am here 4");
      var knockDir = await new Directory(
          '${documentsDirectory.path}/iptv')
          .create(recursive: true)
          .catchError((err) {
        print(err);
      });
      print(knockDir.path);
      String path = join(knockDir.path, "main.db");
      print(path);
      var theDb = await openDatabase(path, version: 2, onCreate: _onCreate);
      print("here is okay 6");
      return theDb;
    }catch(e){
      print("here is the error");
      print(e);
    }
  }


  void _onCreate(Database db, int version) async {
    print("here is okay 5");
    await db.execute("CREATE TABLE Datas(title STRING PRIMARY KEY,url TEXT, logo TEXT, language TEXT, isFavorite TEXT)");

    print("Database was Created!");
  }

  Future<List<Data>> getDatasA() async {
    var dbClient = await dbAndrourl;
    print(dbClient.path);
    List<Map> res = await dbClient.query("Datas");
    print("data is comming or not");
    print(res);
    return res.map((m) => Data.fromDb(m)).toList();
  }

  Future<Data> getDataA(String url) async {
    var dbClient = await dbAndrourl;
    print("okay b was found");
    print(dbClient.path);
    var res = await dbClient.query("Datas", where: "url = ?", whereArgs: [url]);
    if (res.length == 0) return null;
    return Data.fromDb(res[0]);
  }

  Future<int> addDataA(Data data) async {
    var map = Map<String, dynamic>();
    print("================1");
    print(data.title);
    print(data.logo);
    print(data.isFavorite);
    print(data.language);
    print(data.url);
    print("================1");
    var dbClient = await dbAndrourl;
    try {
      int res = await dbClient.insert("Datas", {
      "title": data.title,
      "logo" : data.logo,
      "url" :  data.url,
      "language" :  data.language,
      "isFavorite" : data.isFavorite
      });
      print("Data added $res");
      return res;
    } catch (e) {
      print("data not added");
      print(e);
      int res = await updateDataA(data);
      return res;
    }
  }

  Future<int> updateDataA(Data data) async {
    var dbClient = await dbAndrourl;
    int res = await dbClient.update("Datas", {
      "title": data.title,
      "logo" : data.logo,
      "url" :  data.url,
      "language" :  data.language,
      "isFavorite" : data.isFavorite
      },
        where: "title = ?", whereArgs: [data.title]);
    print("Data updated $res");
    return res;
  }

  Future<int> deleteDataA(String title) async {
    var dbClient = await dbAndrourl;
    var res = await dbClient.delete("Datas", where: "title = ?", whereArgs: [title]);
    print("Data deleted $res");
    return res;
  }

  Future closeDbA() async {
    var dbClient = await dbAndrourl;
    dbClient.close();
  }


//  ====================================================
//  for ios



  Future<Database> initIos() async {
    Directory documentsDirectory = await getTemporaryDirectory();
    String path = join(documentsDirectory.path, "main.db");
    var theDb = await openDatabase(path, version: 0, onCreate: _onCreate);
    return theDb;
  }

  Future<List<Data>> getDatasIos() async {
    var dbClient = await dbIOS;
    List<Map> res = await dbClient.query("Datas");
    return res.map((m) => Data.fromDb(m)).toList();
  }

  Future<Data> getDataIos(String title) async {
    var dbClient = await dbIOS;
    var res = await dbClient.query("Datas", where: "title = ?", whereArgs: [title]);
    if (res.length == 0) return null;
    return Data.fromDb(res[0]);
  }

  Future<int> addDataIos(Data data) async {
    var dbClient = await dbIOS;
    try {
      int res = await dbClient.insert("Datas", {
      "title": data.title,
      "logo" : data.logo,
      "url" :  data.url,
      "language" :  data.language,
      "isFavorite" : data.isFavorite
      });
      print("Data added $res");
      return res;
    } catch (e) {
      int res = await updateDataA(data);
      return res;
    }
  }

  Future<int> updateDatav(Data data) async {
    var dbClient = await dbIOS;
    int res = await dbClient.update("Datas", {
      "title": data.title,
      "logo" : data.logo,
      "url" :  data.url,
      "language" :  data.language,
      "isFavorite" : data.isFavorite
      },
        where: "title = ?", whereArgs: [data.title]);
    print("Data updated $res");
    return res;
  }

  Future<int> deleteDatav(String url) async {
    var dbClient = await dbIOS;
    var res = await dbClient.delete("Datas", where: "url = ?", whereArgs: [url]);
    print("Data deleted $res");
    return res;
  }

  Future closeDbIos() async {
    var dbClient = await dbIOS;
    dbClient.close();
  }
}