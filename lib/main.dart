import 'package:final_project/page1.dart';
import 'package:final_project/page2.dart';
import 'package:final_project/page3.dart';
import 'package:final_project/page4.dart';
import 'package:final_project/page5.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'auth.dart';

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
        primaryColor: Colors.black, // set the color here
        primarySwatch: Colors.blue,
          canvasColor: Colors.black,
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the Navigation Demo App',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/page1');
              },
              child: Text('Go to Page 1'),
            ),
          ],
        ),
      ),
    );
  }
}