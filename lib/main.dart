import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import to use rootBundle
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/sidebar.dart';
import 'phone_auth_page.dart';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';// Import url_launcher
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysql1/mysql1.dart';

// Replace with your Google Places API key
const String googlePlacesApiKey = 'AIzaSyC7aWM0FKpPSbBGkRf2UDCA19Y0aMbjmJA';
const String googleApiKey = 'AIzaSyC7aWM0FKpPSbBGkRf2UDCA19Y0aMbjmJA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  // await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //     databaseURL: 'https://gtcroute-default-rtdb.firebaseio.com',
  //     apiKey: "AIzaSyB-Kn50GCTUi2B49sogD75UjJOiiA6pzIk",
  //     appId: "1:126538889952:android:f57102d80584285dcbae85",
  //     messagingSenderId: "126538889952",
  //     projectId: "gtcroute",
  //   ),
  // );

  if(GetPlatform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        databaseURL: 'https://gtcroute-default-rtdb.firebaseio.com',
        apiKey: "AIzaSyB-Kn50GCTUi2B49sogD75UjJOiiA6pzIk",
        appId: "1:126538889952:android:f57102d80584285dcbae85",
        messagingSenderId: "126538889952",
        projectId: "gtcroute",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrderProvider(),
      child: MaterialApp(
        title: 'Route Planner App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return PhoneAuthPage();
          }else {
            return HomePage();
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}


// Future<void> saveUserToFirestore(String userId, String username, String email, String phoneNumber) async {
//   final firestore = FirebaseFirestore.instance;
//
//   try {
//     await firestore.collection('users').doc(userId).set({
//       'username': username,
//       'email': email,
//       'phoneNumber': phoneNumber,
//     });
//   } catch (e) {
//     print('Error saving user to Firestore: $e');
//   }
// }

// Future<void> saveUserToMySQL(String userId, String username, String email, String phoneNumber) async {
//   final connection = await MySqlConnection.connect(ConnectionSettings(
//     host: 'your-mysql-host',
//     port: 3306,
//     user: 'your-mysql-user',
//     db: 'your-database',
//     password: 'your-mysql-password',
//   ));
//
//   try {
//     await connection.query(
//       'INSERT INTO users (userId, username, email, phoneNumber) VALUES (?, ?, ?, ?)',
//       [userId, username, email, phoneNumber],
//     );
//   } catch (e) {
//     print('Error saving user to MySQL: $e');
//   } finally {
//     await connection.close();
//   }
// }

Future<void> _saveOrder(Order order) async {
  await _saveOrderToFirestore(order);
  await _saveOrderToMySQL(order);
}

Future<void> _saveOrderToFirestore(Order order) async {
  final firestore = FirebaseFirestore.instance;

  try {
    await firestore.collection('orders').doc(order.id.toString()).set({
      'address': order.address,
      'latitude': order.latitude,
      'longitude': order.longitude,
      'instructions': order.instructions,
      'isSelected': order.isSelected,
      'positionId': order.positionId,
      'status': order.status,
      'serialNumber': order.serialNumber,
      'customerName': order.customerName,
      'customerInfo': order.customerInfo,
      'customerPhoneNumber': order.customerPhoneNumber,
      'deliverByTime': order.deliverByTime,
      'noOfPackages': order.noOfPackages,
      'packageLocationInVehicle': order.packageLocationInVehicle,
      'orderType': order.orderType,
      'timeAtStop': order.timeAtStop,
      'username': order.username,
      'useremail': order.useremail,
      'userphonenumber': order.userphonenumber,
    });
  } catch (e) {
    print('Error saving order to Firestore: $e');
  }
}

Future<void> _saveOrderToMySQL(Order order) async {
  final connection = await MySqlConnection.connect(ConnectionSettings(
    host: 'your-mysql-host',
    port: 3306,
    user: 'your-mysql-user',
    db: 'your-database',
    password: 'your-mysql-password',
  ));

  try {
    await connection.query(
      'INSERT INTO orders (id, address, latitude, longitude, instructions, isSelected, positionId, status, serialNumber, customerName, customerInfo, customerPhoneNumber, deliverByTime, noOfPackages, packageLocationInVehicle, orderType, timeAtStop, username, useremail, userphonenumber) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        order.id,
        order.address,
        order.latitude,
        order.longitude,
        order.instructions,
        order.isSelected,
        order.positionId,
        order.status,
        order.serialNumber,
        order.customerName,
        order.customerInfo,
        order.customerPhoneNumber,
        order.deliverByTime,
        order.noOfPackages,
        order.packageLocationInVehicle,
        order.orderType,
        order.timeAtStop,
        order.username,
        order.useremail,
        order.userphonenumber,
      ],
    );
  } catch (e) {
    print('Error saving order to MySQL: $e');
  } finally {
    await connection.close();
  }
}

Future<Uint8List?> _loadDefaultSignature() async {
  ByteData data = await rootBundle.load('assets/mapicons/nosign.jpg');
  return data.buffer.asUint8List();
}

class Order {
  final String id;
  final String address;
  final double latitude;
  final double longitude;
  final String instructions;
  bool isSelected;
  int positionId;
  String status;
  Uint8List? signatureImage;
  Uint8List? proofOfDeliveryImage;
  int serialNumber = 0; // Initialize directly here
  String? customerName;
  String? customerInfo;
  String? customerPhoneNumber; // New field
  DateTime? deliverByTime;
  int? noOfPackages;
  String? packageLocationInVehicle;
  String? orderType;
  DateTime? timeAtStop;
  String? username;
  String? useremail;
  String? userphonenumber;

  Order({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.instructions = '', // Default value for new field
    this.isSelected = false,
    this.positionId = 0,
    this.status = 'Pending',
    this.username,
    this.useremail,
    this.userphonenumber,
  }){
    _loadDefaultSignature().then((defaultSignatureData) {
      signatureImage = defaultSignatureData;
    });

    // Set initial serialNumber to positionId
    serialNumber = positionId;


  }

}

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<LatLng> _optimizedRoute = [];

  List<Order> get orders => _orders;
  List<LatLng> get optimizedRoute => _optimizedRoute;
  int _nextOrderId = 1;
  int _nextPositionId = 1;
  String? username;
  String? useremail;
  String? userphonenumber;

  void addOrder(Order order) async {
    order.positionId = _nextPositionId++;
    order.serialNumber = order.positionId;
    _orders.add(order);
    notifyListeners();
    await _saveOrderToFirestore(order);
    await _saveOrderToMySQL(order);
  }
  void setUserInfo(String? username, String? email, String? phoneNumber) {
    this.username = username;
    this.useremail = email;
    this.userphonenumber = phoneNumber;
  }

  Future<void> _saveOrderToFirestore(Order order) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('orders').doc(order.id).set({
      'address': order.address,
      'latitude': order.latitude,
      'longitude': order.longitude,
      'instructions': order.instructions,
      'isSelected': order.isSelected,
      'positionId': order.positionId,
      'status': order.status,
      'serialNumber': order.serialNumber,
      'customerName': order.customerName,
      'customerInfo': order.customerInfo,
      'customerPhoneNumber': order.customerPhoneNumber,
      'deliverByTime': order.deliverByTime,
      'noOfPackages': order.noOfPackages,
      'packageLocationInVehicle': order.packageLocationInVehicle,
      'orderType': order.orderType,
      'timeAtStop': order.timeAtStop,
      'username': order.username,
      'useremail': order.useremail,
      'userphonenumber': order.userphonenumber,
    });
  }


  Future<void> _saveOrderToMySQL(Order order) async {
    final connection = await MySqlConnection.connect(ConnectionSettings(
      host: 'your-mysql-host',
      port: 3306,
      user: 'your-mysql-user',
      db: 'your-database',
      password: 'your-mysql-password',
    ));

    await connection.query(
      'INSERT INTO orders (id, address, latitude, longitude, instructions, isSelected, positionId, status, serialNumber, customerName, customerInfo, customerPhoneNumber, deliverByTime, noOfPackages, packageLocationInVehicle, orderType, timeAtStop, username, useremail, userphonenumber) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        order.id,
        order.address,
        order.latitude,
        order.longitude,
        order.instructions,
        order.isSelected,
        order.positionId,
        order.status,
        order.serialNumber,
        order.customerName,
        order.customerInfo,
        order.customerPhoneNumber,
        order.deliverByTime,
        order.noOfPackages,
        order.packageLocationInVehicle,
        order.orderType,
        order.timeAtStop,
        order.username,
        order.useremail,
        order.userphonenumber,
      ],
    );

    await connection.close();
  }
  void removeOrder(Order order) {
    _orders.remove(order);
    clearOptimizedRoute();
    if(_orders.isEmpty) { // Check if all orders are deleted
      _nextPositionId = 1; // Reset position ID counter
    }
    notifyListeners();
  }

  void removeSelectedOrders() {
    _orders.removeWhere((order) => order.isSelected);
    clearOptimizedRoute();
    if (_orders.isEmpty) { // Check if all orders are deleted
      _nextPositionId = 1; // Reset position ID counter
    }
    notifyListeners();
  }

  void toggleOrderSelection(String id, bool isSelected) {
    for (var order in _orders) {
      if (order.id == id) {
        order.isSelected = isSelected;
      }
    }
    notifyListeners();
  }

  void selectAllOrders(bool isSelected) {
    for (var order in _orders) {
      order.isSelected = isSelected;
    }
    notifyListeners();
  }

  Future<void> optimizeRoute(LatLng startLocation) async {
    if (_orders.isEmpty) return;

    String waypoints = _orders
        .map((order) => '${order.latitude},${order.longitude}')
        .toList()
        .join('|');

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${_orders.last.latitude},${_orders.last.longitude}&waypoints=optimize:true|$waypoints&key=$googlePlacesApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        _optimizedRoute = [];
        var route = data['routes'][0];
        var legs = route['legs'];
        var waypointOrder = data['routes'][0]['waypoint_order']; // Get the optimized waypoint order

        // Reorder the _orders list based on waypoint_order
        List<Order> reorderedOrders = [];
        for (var index in waypointOrder) {
          reorderedOrders.add(_orders[index]);
        }
        _orders = reorderedOrders; // Update the _orders list

        for (var leg in legs) {
          var steps = leg['steps'];
          for (var step in steps) {
            var polyline = step['polyline']['points'];
            _optimizedRoute.addAll(_decodePolyline(polyline));
          }
        }

        // Update serial numbers after reordering
        for (int i = 0; i < _orders.length; i++) {
          _orders[i].serialNumber = i + 1;
        }
      } else {
        throw Exception('Error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to load directions');
    }



    notifyListeners();
  }

  void clearOptimizedRoute() {
    _optimizedRoute = [];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5), (lng / 1E5));
      poly.add(p);
    }

    return poly;
  }
}

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<dynamic>> autocomplete(String input) async {
    final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return data['predictions'];
      } else {
        throw Exception('Error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  Future<Map<String, dynamic>> getDetails(String placeId) async {
    final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'];
    } else {
      throw Exception('Failed to load place details');
    }
  }
}



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  loc.LocationData? _currentPosition;
  loc.Location _locationTracker = loc.Location();
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _getCurrentLocation();
    _fetchUserData();
    // Get the current user on initialization
  }
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final username = user.displayName;
      final email = user.email;
      final phoneNumber = user.phoneNumber;

      Provider.of<OrderProvider>(context, listen: false).setUserInfo(username, email, phoneNumber);
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      if (await Permission.location.request().isGranted) {
        _getCurrentLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission is required to use this app.')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      var position = await _locationTracker.getLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var orders = Provider.of<OrderProvider>(context).orders;
    var userInfo = Provider.of<OrderProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Gtc Route Planner'),
        leading: Padding(
          padding: EdgeInsets.only(left: 8.0), // Adjust padding value as needed
          child:Image.asset('assets/mapicons/logo.png',
            height: 50, // Adjust the height as needed
            width:50,  // Adjust the width as needed
          ),),
        actions: [


            PopupMenuButton(
              icon: Icon(Icons.menu),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Sidebar(),
                  value: 'sidebar',
                ),
              ],
            ),

          // TextButton(
          //   onPressed: () {
          //     if (_currentPosition != null) {
          //       Provider.of<OrderProvider>(context, listen: false).optimizeRoute(
          //         LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
          //       );
          //     }
          //   },
          //   style: TextButton.styleFrom(),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Icon(Icons.refresh),
          //       SizedBox(width: 8),
          //       Text("Optimize Route"),
          //     ],
          //   ),
          // ),
          // IconButton(
          //   icon: Icon(Icons.delete),
          //   onPressed: () {
          //     Provider.of<OrderProvider>(context, listen: false).removeSelectedOrders();
          //   },
          // ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userInfo.username ?? 'No Name'),
              accountEmail: Text(userInfo.useremail ?? 'No Email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  userInfo.username != null ? userInfo.username![0] : '?',
                  style: TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Add other drawer items here if needed
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PhoneAuthPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: OptimizedMap(orders: orders, currentPosition: _currentPosition),
          ),
          Expanded(
            flex: 1,
            child: OrderList(),
          ),
        ],
      ),
      floatingActionButton:  Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[

          const SizedBox(width: 16),
          // An example of the extended floating action button.
          //
          // https://m3.material.io/components/extended-fab/specs#686cb8af-87c9-48e8-a3e1-db9da6f6c69b
          FloatingActionButton.extended(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            onPressed: () {
              if (_currentPosition != null) {
                Provider.of<OrderProvider>(context, listen: false).optimizeRoute(
                  LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
                );
              }
            },
            label: const Text('Optimize Route'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),


    );
  }
}

class OrderList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var orders = Provider.of<OrderProvider>(context).orders;

    return Column(
      children: [

        GestureDetector(
          onTap: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddOrderPage()),
          );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: "Add Order or Find Order Stop",
                prefixIcon:Icon(Icons.add),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
        ),
        Text("Total Orders : ${Provider.of<OrderProvider>(context, listen: false).orders.length}"),
        Row(
          children: [


            Expanded( // Allow CheckboxListTile to take available space
              child: CheckboxListTile(
                title: Text("Select All"),
                value: orders.every((order) => order.isSelected),
                onChanged: (value) {
                  Provider.of<OrderProvider>(context, listen: false).selectAllOrders(value!);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                Provider.of<OrderProvider>(context, listen: false).removeSelectedOrders();
              },
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              return ListTile(
                leading: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('S.No:${order.serialNumber}'),
                    ),
                    Expanded(
                      flex: 1,
                      child: Checkbox(
                        value: order.isSelected,
                        onChanged: (value) {
                          Provider.of<OrderProvider>(context, listen: false)
                              .toggleOrderSelection(order.id, value!);
                        },
                      ),
                    ),
                  ],
                ),

                // Column(
                //   mainAxisSize: MainAxisSize.min,
                //   // Use a Column to arrange widgets vertically
                //   children: [
                //     Expanded( // Wrap the Text widget with Expanded
                //       child: Text('S.No:${order.serialNumber}'),
                //     ),
                //     Checkbox(
                //       value: order.isSelected,
                //       onChanged: (value) {
                //         Provider.of<OrderProvider>(context, listen: false)
                //             .toggleOrderSelection(order.id, value!);
                //       },
                //     ),
                //   ],),
                title: Text('Parcel Id: ${order.positionId}'),
                subtitle: Text(order.address + '\nOrder ID: ${order.id} \n ${order.latitude}, ${order.longitude}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    Provider.of<OrderProvider>(context, listen: false).removeOrder(order);
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                      order: order,
                      onOrderUpdated: () {
                        //setState(() {}); // Refresh HomePage when an order is updated
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AddOrderPage extends StatefulWidget {
  @override
  _AddOrderPageState createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final PlacesService placesService = PlacesService(googlePlacesApiKey);
  List<dynamic> autocompleteResults = [];
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isAddressSelected = false;
  final customerNameController = TextEditingController();
  final customerInfoController = TextEditingController();
  final customerPhoneNumberController = TextEditingController();
  final noOfPackagesController = TextEditingController();
  final packageLocationController = TextEditingController();
  final _timeAtStopController = TextEditingController();
  DateTime? selectedDeliverByTime;
  DateTime? selectedTimeAtStop;
  String? selectedOrderType; // For dropdown
  Future<void> _onSearchChanged() async {
    if (addressController.text.isEmpty) {
      setState(() {
        autocompleteResults = [];
        isAddressSelected = false;
      });
      return;
    }

    var results = await placesService.autocomplete(addressController.text);
    setState(() {
      autocompleteResults = results;
    });
  }

  @override
  void initState() {
    super.initState();
    addressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    addressController.removeListener(_onSearchChanged);
    addressController.dispose();
    instructionsController.dispose();
    super.dispose();
  }


  // Method to select deliver by time
  Future<void> _selectDeliverByTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDeliverByTime ?? DateTime.now(),firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          selectedDeliverByTime = selectedDateTime;
        });
      }
    }
  }

  // Method to select time at stop
  Future<void> _selectTimeAtStop(BuildContext context) async {final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedTimeAtStop ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      final DateTime selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      setState(() {
        selectedTimeAtStop = selectedDateTime;
      });
    }
  }
  }

  Future<void> _createOrder() async {
    setState(() {
      isLoading = true;
    });

    try {
      var results = autocompleteResults.firstWhere(
            (result) => result['description'] == addressController.text,
        orElse: () => null,
      );

      if (results != null) {
        var details = await placesService.getDetails(results['place_id']);
        var location = details['geometry']['location'];
        var uuid = Uuid();
        var order = Order(
          id: uuid.v4(),
          // id: Provider.of<OrderProvider>(context, listen: false).orders.length + 1,
          address: details['formatted_address'],
          latitude: location['lat'],
          longitude: location['lng'],
          instructions: instructionsController.text,
          positionId: 0,
        );

        Provider.of<OrderProvider>(context, listen: false).addOrder(order);
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Add Order'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Enter address'),
            ),
            if (isAddressSelected) ...[
              TextField(
                controller: instructionsController,
                decoration: InputDecoration(labelText: 'Enter instructions(Optional)',
                  hintText: 'Optional',),
              ),
              SizedBox(height: 8),
              TextField(
                controller: customerNameController,
                decoration: InputDecoration(labelText: 'Customer Name(Optional)',hintText: 'Optional',),
              ),
              SizedBox(height: 8),
              TextField(
                controller: customerInfoController,
                decoration: InputDecoration(labelText: 'Customer Info(Optional)',hintText: 'Optional',),
              ),


              SizedBox(height: 8),
              TextField(
                controller: customerPhoneNumberController,
                decoration: InputDecoration(labelText: 'Customer Phone Number(Optional)',hintText: 'Optional',),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 8),
              TextField(
                controller: noOfPackagesController,
                decoration: InputDecoration(labelText: 'No of Packages(Optional)',hintText: 'Optional',),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextField(
                controller: packageLocationController,
                decoration: InputDecoration(labelText: 'Package Location in Vehicle(Optional)',hintText: 'Optional',),
              ),
              SizedBox(height: 8),
              // ElevatedButton(
              //   onPressed: () => _selectDeliverByTime(context),
              //   child: Text(
              //     'Select Deliver By Time: ${selectedDeliverByTime != null ? DateFormat('yyyy-MM-dd hh:mm a').format(selectedDeliverByTime!) : "Not Selected"}',
              //   ),
              // ),

              TextFormField(
                readOnly: true, // Prevent direct editing
                controller: TextEditingController(
                  text: selectedDeliverByTime != null
                      ? DateFormat('yyyy-MM-dd hh:mm a').format(selectedDeliverByTime!)
                      : "Not Selected",
                ),
                decoration: InputDecoration(
                  labelText: 'Deliver By Time(Optional)',
                  suffixIcon: IconButton(
                    onPressed: () => _selectDeliverByTime(context),
                    icon: Icon(Icons.calendar_today), // Or any suitable icon
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                readOnly: true, // Prevent direct editing
                controller: TextEditingController(
                  text: selectedTimeAtStop != null
                      ? DateFormat('yyyy-MM-dd hh:mm a').format(selectedTimeAtStop!)
                      : "Not Selected",
                ),
                decoration: InputDecoration(
                  labelText: 'Time at Stop(Optional)',
                  suffixIcon: IconButton(
                    onPressed: () => _selectTimeAtStop(context),
                    icon: Icon(Icons.calendar_today), // Or any suitable icon
                  ),
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Order Type(Optional)'),
                value: selectedOrderType,
                onChanged: (newValue) {
                  setState(() {
                    selectedOrderType = newValue;
                  });
                },
                items: <String>['Type 1', 'Type 2', 'Type 3'] // Replace with your actual order types
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createOrder,
                child: isLoading ? CircularProgressIndicator() : Text('Add Order'),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: autocompleteResults.length,
                  itemBuilder: (context, index) {
                    var result = autocompleteResults[index];
                    return ListTile(
                      title: Text(result['description']),
                      onTap: () async {
                        setState(() {
                          addressController.text = result['description'];
                          isAddressSelected = true;
                          autocompleteResults = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class OptimizedMap extends StatefulWidget {
  final List<Order> orders;
  final loc.LocationData? currentPosition;

  OptimizedMap({required this.orders, this.currentPosition});

  @override
  _OptimizedMapState createState() => _OptimizedMapState();
}

class _OptimizedMapState extends State<OptimizedMap> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon(); // Load the custom icon
    if (widget.currentPosition != null) {
      _animateToUser(widget.currentPosition!);
    }
  }

  Future<void> _loadCustomIcon() async {
    // Load the image from assets
    final ByteData byteData = await rootBundle.load('assets/mapicons/current_location_icon.png');
    final Uint8List imageData = byteData.buffer.asUint8List();

    // Resize the image if necessary
    final ui.Codec codec = await ui.instantiateImageCodec(imageData, targetWidth: 40); // Adjust targetWidth as needed
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedByteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedImageData = resizedByteData!.buffer.asUint8List();

    // Create the BitmapDescriptor for the custom icon
    _customIcon = BitmapDescriptor.fromBytes(resizedImageData);
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.black;
    final double radius = 35.0;

    // Draw a circle as the background
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw the text
    TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);    painter.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: 35.0, color: Colors.white, fontWeight: FontWeight.bold),
    );
    painter.layout();
    painter.paint(canvas, Offset(radius - painter.width / 2, radius - painter.height / 2));

    // Convert to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(2 * radius.toInt(), 2 * radius.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageData = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(imageData);
  }

  void _animateToUser(loc.LocationData position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude!, position.longitude!),
            zoom: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var optimizedRoute = Provider.of<OrderProvider>(context).optimizedRoute;

    LatLng initialPosition;
    if (widget.orders.isNotEmpty) {
      initialPosition = LatLng(widget.currentPosition?.latitude ?? widget.orders[0].latitude,
          widget.currentPosition?.longitude ?? widget.orders[0].longitude);
    } else if (widget.currentPosition != null) {
      initialPosition = LatLng(widget.currentPosition!.latitude!, widget.currentPosition!.longitude!);
    } else {
      // Default position if no orders and no current location
      initialPosition = LatLng(widget.currentPosition!.latitude!, widget.currentPosition!.longitude!);
    }

    return FutureBuilder(
      future: _generateMarkers(), // Future that generates markers with custom icons
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            markers: snapshot.data as Set<Marker>,
            polylines: {
              if (optimizedRoute.isNotEmpty)

                Polyline(
                  polylineId: PolylineId('optimized_route'),
                  points: optimizedRoute,
                  color: Colors.black,
                  width: 2,
                  // patterns: [PatternItem.dash(10), PatternItem.gap(10)], // Dashed line
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  zIndex: 2,
                ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
              if (widget.currentPosition != null) {
                _animateToUser(widget.currentPosition!);
              }
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false, // Disable default location marker
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<Set<Marker>> _generateMarkers() async {
    Set<Marker> markers = {};
    for (var order in widget.orders) {
      final customIcon = await _createCustomMarkerBitmap(order.positionId.toString());
      markers.add(
        Marker(
          markerId: MarkerId(order.id.toString()),
          position: LatLng(order.latitude, order.longitude),
          infoWindow: InfoWindow(title: order.address),
          icon: customIcon,
        ),
      );
    }

    if (widget.currentPosition != null && _customIcon != null) {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(widget.currentPosition!.latitude!, widget.currentPosition!.longitude!),
          icon: _customIcon!,
        ),
      );
    }

    return markers;
  }
}


class MapPage extends StatefulWidget {
  final Order order;
  final VoidCallback onOrderUpdated;

  MapPage({required this.order, required this.onOrderUpdated});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  BitmapDescriptor? _customIcon;
  String _orderStatus = 'Pending';
  String? _signatureImagePath;
  final String _defaultSignatureImagePath = 'assets/mapicons/nosign.jpg'; //


  @override
  bool get wantKeepAlive => true;
  XFile? _imageFile;
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  void initState() {
    _orderStatus = widget.order.status;
    _setMarkers();
    super.initState();_loadCustomIcon();  // Load the custom icon
    _getCurrentLocation();
    _initializeMap();
  }
  Future<void> _initializeMap() async {
    await _getCurrentLocation(); // Await current location
    _setMarkers();
    _getDirections();
  }

  Future<void> _pickImageFromCamera() async {
    if (await Permission.camera.request().isGranted) {
      final picker = ImagePicker();
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          setState(() {
            _imageFile = pickedFile;
            print("Image Path: ${_imageFile?.path}"); // Check the path
          });
        }
      } catch (e) {
        print("Error capturing image: $e");
      }
    } else {
      // Handle permission denial
    }
  }


  Future<void> _pickImageFromGallery() async{
    var status = await Permission.photos.request(); // Request photos permission

    if (status.isGranted) {
      // Permission granted, proceed with image picking
      final picker = ImagePicker();
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _imageFile = pickedFile;
            print("Image Path: ${_imageFile?.path}"); // Check the path
          });
        }
      } catch (e) {
        // Handle potential errorsduring image picking
        print("Error picking image from gallery: $e");
        // You could show a SnackBar or Dialog here to inform the user
      }
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, guide user to app settings
      openAppSettings();
      // You could show a SnackBar or Dialog here explaining why the permission is needed
    } else {
      // Permission denied, handle accordingly
      print('Photos permission denied');
      // You could show a SnackBar or Dialog here to inform the user
    }
  }


  void _showProofOfDeliveryPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Wrap with StatefulBuilder
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Proof of Delivery'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker Buttons
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _pickImageFromCamera();
                            setState(() {}); // Rebuild after picking image
                          },
                          child: Text('Camera'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _pickImageFromGallery();
                            setState(() {}); // Rebuild after picking image
                          },
                          child: Text('Gallery'),
                        ),
                      ],
                    ),
                    if (_imageFile != null) // Display preview if image is selected
                      Image.file(
                        File(_imageFile!.path),
                        height: 50,
                        fit: BoxFit.cover,
                      ),

                    SizedBox(height: 20),

                    // Signature Pad
                    SfSignaturePad(
                      key: _signaturePadKey,
                      backgroundColor: Colors.grey[200]!,
                      minimumStrokeWidth: 1.0,
                      maximumStrokeWidth: 5.0,
                      strokeColor: Colors.black,
                    ),
                    ElevatedButton(
                      onPressed: () => _signaturePadKey.currentState?.clear(),
                      child: Text('Clear Signature'),
                    ),
                  ],
                ),
              ),actions: [
              TextButton(
                onPressed: () async {

                  // Handle Proof of Delivery
                  if (_imageFile != null) {
                    // Read image file data
                    Uint8List imageData = await File(_imageFile!.path).readAsBytes();
                    widget.order.proofOfDeliveryImage = imageData; // Store in Order object
                  }


                  // Save signature as image
                  // Capture signature
                  ui.Image? signatureImage = await _signaturePadKey.currentState?.toImage();
                  if (signatureImage != null) {
                    ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData != null) {
                      widget.order.signatureImage = byteData.buffer.asUint8List(); // Update Order object
                      Navigator.of(context).pop(); // Close the dialog
                    }
                  }

                  // Mark as delivered
                  _markOrderDelivered();
                  Navigator.of(context).pop(); // Use context directly
                  // Close the dialog
                },
                child: Text('Mark Delivered'),
              ),

              TextButton(
                onPressed: () async {

                  // Handle Proof of Delivery
                  if (_imageFile != null) {
                    // Read image file data
                    Uint8List imageData = await File(_imageFile!.path).readAsBytes();
                    widget.order.proofOfDeliveryImage = imageData; // Store in Order object
                  }

                  // Save signature as image
                  // Capture signature
                  ui.Image? signatureImage = await _signaturePadKey.currentState?.toImage();
                  if (signatureImage != null) {
                    ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData != null) {
                      widget.order.signatureImage = byteData.buffer.asUint8List(); // Update Order object
                      Navigator.of(context).pop(); // Close the dialog
                    }
                  }

                  // Mark as delivered
                  _markOrderDelivered();
                  _navigateToNextOrder();// Close the dialog
                },
                child: Text('Mark Delivered & Go Next'),
              ),

              TextButton(
                onPressed: () {
                  // Mark as failed and go to next order
                  _markOrderFailed(); // Implement this function
                  _navigateToNextOrder(); // Implement this function
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Mark Failed & Go Next'),
              ),
            ],
            );
          },
        );
      },
    );
  }



  void _markOrderDelivered() {
    setState(() {
      _orderStatus = 'Delivered';
      _updateOrderInProvider();
    });

  }

  void _markOrderFailed() {
    setState(() {
      _orderStatus = 'Failed';
      _updateOrderInProvider();
    });
    _navigateToNextOrder();
  }
  void onOrderUpdated() {
    // Only update the state of MapPage, no navigation here
    setState(() {}); // Or any other state update logic
  }

  void _navigateToNextOrder() {
    var orderProvider = Provider.of<OrderProvider>(context, listen: false);
    var currentOrderIndex = orderProvider.orders.indexWhere((o) => o.id == widget.order.id);
    if (currentOrderIndex != -1 && currentOrderIndex < orderProvider.orders.length - 1) {
      var nextOrder = orderProvider.orders[currentOrderIndex + 1];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            order: nextOrder,
            onOrderUpdated: () {}, // You might need to adjust this callback
          ),
        ),
      );
    }
  }


  void _updateOrderInProvider() {
    var orderProvider = Provider.of<OrderProvider>(context, listen: false);
    var orderIndex = orderProvider.orders.indexWhere((o) => o.id == widget.order.id);
    if (orderIndex != -1) {
      orderProvider.orders[orderIndex].status = _orderStatus;
      orderProvider.notifyListeners(); // Notify listeners about the change
    }
    widget.onOrderUpdated(); // Notify parent widget (MapPage)
  }

  Future<void> _loadCustomIcon() async {
    // Load the image from assets
    // final ByteData byteData = await rootBundle.load('assets/mapicons/current_location_icon.png');
    // final Uint8List imageData = byteData.buffer.asUint8List();
    // _customIcon = BitmapDescriptor.fromBytes(imageData);

    final ByteData byteData = await rootBundle.load('assets/mapicons/current_location_icon.png');
    final Uint8List imageData = byteData.buffer.asUint8List();

    // Resize the image
    final ui.Codec codec = await ui.instantiateImageCodec(imageData, targetWidth: 35); // Change targetWidth to adjust size
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedByteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedImageData = resizedByteData!.buffer.asUint8List();

    _customIcon = BitmapDescriptor.fromBytes(resizedImageData);
  }

  void _setMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId(widget.order.id.toString()),
        position: LatLng(widget.order.latitude, widget.order.longitude),
        infoWindow: InfoWindow(
          title: widget.order.instructions,
          snippet: widget.order.address,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    final location = loc.Location();
    try {
      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14),
        );
        _getDirections();
        if (_customIcon != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('current_location'),
              position: _currentLocation!,
              icon: _customIcon!,
            ),
          );
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getDirections() async {
    if (_currentLocation == null) return;

    final startLatLng = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    final endLatLng = '${widget.order.latitude},${widget.order.longitude}';

    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$startLatLng&destination=$endLatLng&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final polylinePoints = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              color: Colors.black,
              width: 5,
              points: polylinePoints,
            ),
          );
        });
      } else {
        print('Error: ${data['status']}');
      }
    } else {
      print('Failed to load directions');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5), (lng / 1E5));
      poly.add(p);
    }

    return poly;
  }

  Future<void> _launchNavigation() async {
    if (_currentLocation == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${widget.order.latitude},${widget.order.longitude}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order: Parcel Id: ${widget.order.positionId} - S No: (${widget.order.serialNumber}/${Provider.of<OrderProvider>(context, listen: false).orders.length})',style: TextStyle(fontSize: 15), // Adjust the font size as needed
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(widget.order.latitude, widget.order.longitude),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _getCurrentLocation(); // Ensure current location is set
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false, // Disable the default location button
          ),
          Positioned(
            bottom: 16,
            left: 0, // Add this for horizontal centering
            right: 0, // Add this for horizontal centering
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // This will center the children
              children: <Widget>[
                FloatingActionButton.extended(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  onPressed: _launchNavigation,
                  label: const Text('Navigate'),
                  icon: const Icon(Icons.navigation),
                ),
              ],
            ),
          ) ,Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Status: $_orderStatus'),
            ),
          ),

        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.0),
        child:  Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(widget.order.instructions),
              subtitle: Text(
                '${widget.order.address}\nOrder ID: ${widget.order.id}\n${widget.order.latitude}, ${widget.order.longitude}',
              ),
            ),


            Row(
              children: [

                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      widget.order.proofOfDeliveryImage != null
                          ? Image.memory(widget.order.proofOfDeliveryImage!, height: 50): Image.asset(_defaultSignatureImagePath, height: 50),
                      Text(
                        // Display the image name here
                        'Proof Of Delivery Image', // Replace with actual image name property
                        style: TextStyle(fontSize: 12), // Adjust style as needed
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      widget.order.signatureImage != null
                          ? Image.memory(widget.order.signatureImage!, height: 50)
                          : Image.asset(_defaultSignatureImagePath, height: 50),
                      Text(
                        // Display the image name here
                        'Signature Image', // Replace with actual image name property
                        style: TextStyle(fontSize: 12), // Adjust style as needed
                      ),
                    ],
                  ),
                ),

              ],
            ),


            if (_orderStatus != 'Delivered') ...[
              ElevatedButton(
                onPressed: () {
                  _showProofOfDeliveryPopup();
                },
                child: Text('Mark Delivered', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              ),
              ElevatedButton(
                onPressed: () {
                  _markOrderFailed();
                  _navigateToNextOrder();
                },
                child: Text('Mark Failed & Go to Next Order',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

