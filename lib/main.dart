import 'package:dio/dio.dart';
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
    UserProfileScreen(),
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
              label: 'Profile',
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
              onPressed: () async {
                // Collect the selected seats
                List<int> selectedSeats = [];
                for (var row in seats) {
                  for (var seat in row['seats']) {
                    if (seat['isSelected'] ?? false) {
                      selectedSeats.add(seat['id']);
                    }
                  }
                }

                if (selectedSeats.isEmpty) {
                  // No seats were selected, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select at least one seat.'),
                    ),
                  );
                } else {
                  // Send the booking request to the server
                  String? accessToken =
                  await SharedPreferences.getInstance().then(
                        (prefs) => prefs.getString('access_token'),
                  );

                  Dio dio = Dio();
                  dio.options.headers["Authorization"] = "Bearer $accessToken";
                  Map<String, dynamic> requestBody = {
                    "seats": selectedSeats,
                    "sessionId": widget.session['id'].toString()
                  };

                  // Make the POST request

                    Response response = await dio.post(
                      "https://fs-mt.qwerty123.tech/api/movies/book",
                      data: requestBody,
                    );
                    print("Response status: ${response.statusCode}");
                    print("Response data: ${response.data}");

                  if (response.statusCode == 200) {
                    // Booking successful, show the payment screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentScreen(
                              accessToken: accessToken,
                              sessionId: widget.session['id'],
                              seats: selectedSeats,
                            ),
                      ),
                    );
                  } else {
                    // Booking failed, show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.toString()),
                      ),
                    );
                  }
                }
              },
              child: Text('Confirm Selection'),
            ),
          ],
        ),
      ),
    );
  }
}



class PaymentScreen extends StatefulWidget {
  final String? accessToken;
  final int sessionId;
  final List<int> seats;

  PaymentScreen({
    required this.accessToken,
    required this.sessionId,
    required this.seats,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _cvvController = TextEditingController();
  String _email = '';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expirationDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "Bearer ${widget.accessToken}";
    Map<String, dynamic> requestBody = {
      'seats': widget.seats.map((seat) => seat.toString()).toList(),
      'sessionId': widget.sessionId.toString(),
      'email': _email,
      'cardNumber': _cardNumberController.text,
      'expirationDate': _expirationDateController.text,
      'cvv': _cvvController.text,
    };

    try {
      // Make the POST request
      Response response = await dio.post(
        "https://fs-mt.qwerty123.tech/api/movies/buy",
        data: requestBody,
      );

      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200) {
        // Payment successful, navigate to start screen
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else {
        // Payment failed, show error message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('An error occurred during payment processing.'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      // An error occurred during the payment process
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred during payment processing.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email'),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 16),
                  Text('Card number'),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _cardNumberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your card number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Expiration date'),
                  TextFormField(
                    keyboardType: TextInputType.datetime,
                    controller: _expirationDateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your card\'s expiration date';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Text('CVV'),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _cvvController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your card\'s CVV code';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _submitPayment();
                      }
                    },
                    child: Text('Submit Payment'),
                  ),
                ],
              ),
            )
        ),
      ),
    );
  }
}


class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? accessToken;
  bool isLoading = true;
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');

    String url = 'https://fs-mt.qwerty123.tech/api/user';

    http.Response response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      setState(() {
        userData = jsonResponse['data'];
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Name'),
            subtitle: Text(userData['name'] ?? ""),
          ),
          ListTile(
            title: Text('Phone Number'),
            subtitle: Text(userData['phoneNumber'] ?? ""),
          ),
          ListTile(
            title: Text('Created At'),
            subtitle: Text(
              DateTime.fromMillisecondsSinceEpoch(
                userData['createdAt'] * 1000,
              ).toString(),
            ),
          ),
          ListTile(
            title: Text('Updated At'),
            subtitle: Text(
              DateTime.fromMillisecondsSinceEpoch(
                userData['updatedAt'] * 1000,
              ).toString(),
            ),
          ),
        ],
      ),
    );
  }
}