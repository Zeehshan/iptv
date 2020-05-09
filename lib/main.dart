import 'package:floating_search_bar/floating_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:m3u/m3u.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'database/db.dart';

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class Data {
  String title;
  String logo;
  String url;
  String language;
  String isFavorite;

  Data(this.title, this.logo, this.url, this.language, this.isFavorite);

  factory Data.fromJson(entry){
    return Data(
        entry.title,
        entry.attributes['tvg-logo'],
        entry.link,
        entry.attributes['tvg-language'],
        'false'
    );
  }

   Data.fromDb(Map map) :
      title = map["title"],
      logo = map["logo"],
      url = map["url"],
      language = map["language"],
      isFavorite = map["isFavorite"];

}

List<Data> datas = [];
List<Data> filteredDatas = [];
final debouncer = Debouncer(milliseconds: 500);
String pressFavourite;
Image favBack = Image.asset('images/loveFolder.png');

Future<List<Data>> getData() async {
  final response =
      await http.get('https://iptv-org.github.io/iptv/index.country.m3u');
  final m3u = await M3uParser.parse(response.body);
  for (final entry in m3u) {
    print(entry.runtimeType);
    Data data = Data.fromJson(entry);
    datas.add(data);
  }

  return datas;
}

void main() {
  return runApp(
    MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.refresh),
        ),
        backgroundColor: Colors.white,
        body: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DataDatabase db = DataDatabase();
  @override
  void initState() {
    super.initState();
    getData().then((usersFromServer) {
      setState(() {
        datas = usersFromServer;
        filteredDatas = datas;
      });
    });
  }


  bool _progress = false;
  List<Data> filtered = List();
  setupList() async {
    setState(() {
      _progress = true;
    });
    filtered = await db.getDatasA();
    setState(() {
      filteredDatas = filtered;
      _progress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: filteredDatas.isEmpty ?
      Center(child: CircularProgressIndicator()) :
      Column(
        children: <Widget>[
          Expanded(
            child: FloatingSearchBar.builder(
              trailing: GestureDetector(
                onTap: () {
                  if (pressFavourite == "false" || pressFavourite == null) {
                    pressFavourite = "true";
                    favBack = Image.asset('images/backButton.png');
//                    setState(() {
//                      filteredDatas = datas
//                          .where((u) => (u.isFavorite
//                          .toLowerCase()
//                          .contains("true") ||
//                          u.isFavorite.toLowerCase().contains('true')))
//                          .toList();
//                    });
                  setState(() {
                    filteredDatas = [];
                  });
                    setupList();
                  } else {
                    setState(() {
                      filteredDatas = [];
                    });
                    pressFavourite = "false";
                    favBack = Image.asset('images/loveFolder.png');
                    setState(() {
                      filteredDatas = datas
                          .where(
                              (u) => (u.isFavorite.toLowerCase().contains('')))
                          .toList();
                    });

                  }
                },
                child: favBack,
              ),
              onChanged: (string) {
                if (pressFavourite == "true" ) {
                  debouncer.run(() {
                    setState(() {
                      filteredDatas = datas
                          .where((u) => (u.isFavorite
                          .toLowerCase()
                          .contains("true") &&
                          u.title.toLowerCase().contains(string.toLowerCase())))
                          .toList();
                    });
                  });
                } else {
                  debouncer.run(() {
                    setState(() {
                      filteredDatas = datas
                          .where((u) => (u.title
                          .toLowerCase()
                          .contains(string.toLowerCase()) &&
                          u.title.toLowerCase().contains(string.toLowerCase())))
                          .toList();
                    });
                  });
                }
              },
              itemBuilder: (context, index) {
                return ListTile(
                  trailing: Container(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filteredDatas[index].isFavorite == 'false') {
                            setState(() {
                              filteredDatas[index].isFavorite = 'true';
                            });
                            db.addDataA(filteredDatas[index]);
                          } else {
                            setState(() {
                              filteredDatas[index].isFavorite = 'false';
                            });
                            db.deleteDataA(filteredDatas[index].title);
                          }
                        });
                      },
                      child: filteredDatas[index].isFavorite == 'true'
                          ? Icon(Icons.favorite, color: Colors.red)
                          : Icon(
                              Icons.favorite_border,
                              color: Colors.red,
                            ),
                    ),
                  ),
                  leading: CachedNetworkImage(
                    width: 25,
                    height: 25,
                    imageUrl: filteredDatas[index].logo,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Image.network(
                      'https://img.icons8.com/clouds/50/000000/tv.png',
                      width: 25,
                      height: 25,
                    ),
                  ),
                  subtitle: Text(filteredDatas[index].language != ""
                      ? filteredDatas[index].language
                      : 'International'),
                  title: Text(filteredDatas[index].title),
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) =>
                                DetailPage(filteredDatas[index].url)));
                  },
                );
              },
              itemCount: filteredDatas.length,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String link;

  DetailPage(this.link);

  @override
  Widget build(BuildContext context) {
    String url = link;
    try {
      url = link;
    } catch (e) {
      print(e);
      url = "https://www.youtube.com/embed/BVFlOeXV-iI?list=RDMMBVFlOeXV-iI";
    }
    print(url);
    return Scaffold(
      appBar: AppBar(
        title: Text(link),
      ),
      body: Container()
    );
  }
}
