import 'package:final_project/page1.dart';
import 'package:final_project/page2.dart';
import 'package:final_project/page3.dart';
import 'package:final_project/page4.dart';
import 'package:final_project/page5.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionToken = await AuthHelper.getSessionToken();
  final accessToken = await AuthHelper.getAccessToken(sessionToken);
  await AuthHelper.storeAccessToken(accessToken);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? accessToken1 = prefs.getString('access_token');
  debugPrint('accessToken1: $accessToken1');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomePage(),
    Page1(),
    Page2(),
    Page3(),
    Page4(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: _pages.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              label: 'Page 1',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Page 2',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.accessibility),
              label: 'Page 3',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              label: 'Page 4',
            ),
          ],
        ),
      ),
      routes: {
        '/page1': (context) => Page1(),
        '/page2': (context) => Page2(),
        '/page3': (context) => Page3(),
        '/page4': (context) => Page4(),
        '/page5': (context) => Page5(),
      },
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? accessToken;
  TextEditingController searchController = TextEditingController();
  List<dynamic> movies = [];

  @override
  void initState() {
    super.initState();
    getToken();
  }

  void getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
  }

  void searchMovies(String query) async {
    var date = DateTime.now().toString().split(" ")[0];
    var response = await http.get(
        Uri.parse(
            'https://fs-mt.qwerty123.tech/api/movies?date=$date&query=$query'),
        headers: {'Authorization': 'Bearer $accessToken'});
    var result = jsonDecode(response.body);
    setState(() {
      movies = result['data'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Film Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for movies',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              searchMovies(searchController.text);
            },
            child: Text('Search'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: movies.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: Image.network(movies[index]['smallImage']),
                  title: Text(movies[index]['name']),
                  subtitle: Text(
                      '${movies[index]['duration']} minutes | ${movies[index]['genre']}'),
                  trailing: Text(
                    '${movies[index]['rating']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}