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
  List<dynamic> sessions = [];

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

  void getSessions(int movieId) async {
    var date = DateTime.now().toString().split(" ")[0];
    var sessionResponse = await http.get(
        Uri.parse(
            'https://fs-mt.qwerty123.tech/api/movies/sessions?movieId=$movieId&date=$date'),
        headers: {'Authorization': 'Bearer $accessToken'});
    var sessionResult = jsonDecode(sessionResponse.body);
    setState(() {
      sessions = sessionResult['data'];
    });

    // Create a separate async function to retrieve seat information
    Future<void> retrieveSeats(session) async {
      var seatResponse = await http.get(
          Uri.parse(
              'https://fs-mt.qwerty123.tech/api/movies/sessions/${session['id']}/seats'),
          headers: {'Authorization': 'Bearer $accessToken'});
      var seatResult = jsonDecode(seatResponse.body);
      session['seats'] = seatResult['data'];
    }

    // Call the async function for each session
    for (var session in sessions) {
      await retrieveSeats(session);
    }

    setState(() {
      // Update the state with the new session information
      sessions = sessions;
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
                  onTap: () {
                    getSessions(movies[index]['id']);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (BuildContext context, int index) {
                var session = sessions[index];
                var room = session['room'];
                var rows = room['rows'];
                var totalAvailableSeats = 0;
                var totalSeats = 0;
                rows.forEach((row) {
                  var seats = row['seats'];
                  totalSeats = (totalSeats + seats.length) as int;
                  seats.forEach((seat) {
                    if (seat['isAvailable']) {
                      totalAvailableSeats++;
                    }
                  });
                });
                return ListTile(
                  title: Text('${room['name']} - ${session['type']}'),
                  subtitle: Text(
                      'Available Seats: $totalAvailableSeats/$totalSeats | Min Price: ${session['minPrice']} UAH'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Pass the session and room information to the seat selection screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeatSelectionScreen(
                            session: session,
                            room: room,
                          ),
                        ),
                      );
                    },
                    child: Text('Select Seats'),
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


class SeatSelectionScreen extends StatefulWidget {
  final dynamic session;
  final dynamic room;

  const SeatSelectionScreen({
    Key? key,
    required this.session,
    required this.room,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<dynamic> seats = [];

  @override
  void initState() {
    super.initState();
    // Retrieve seat information for the selected session and room
    getSeats();
  }

  void getSeats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    var seatResponse = await http.get(
        Uri.parse(
            'https://fs-mt.qwerty123.tech/api/movies/sessions/${widget.session['id']}'),
        headers: {'Authorization': 'Bearer $accessToken'});
    var seatResult = jsonDecode(seatResponse.body);
    setState(() {
      seats = seatResult['data']['room']['rows']
          .toList();
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seat Selection'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Select Seats for ${widget.room['name']} - ${widget.session['type']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            seats.isEmpty
                ? CircularProgressIndicator() // Show a progress indicator while seats are being loaded
                : Flexible(
              child: ListView.builder(
                itemCount: seats.length,
                itemBuilder: (BuildContext context, int rowIndex) {
                  var row = seats[rowIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${row['index']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GridView.builder(
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8, // Number of columns
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 50, // Height of each row
                        ),
                        itemCount: row['seats'].length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int seatIndex) {
                          var seat = row['seats'][seatIndex];
                          return GestureDetector(
                            onTap: () {
                              if (seat['isAvailable']) {
                                setState(() {
                                  seat['isSelected'] = !(seat['isSelected'] ?? false);
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: seat['isAvailable'] ?? false
                                    ? seat['isSelected'] ?? false
                                    ? Colors.blue
                                    : Colors.grey
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  '${seat['index']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Confirm Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
