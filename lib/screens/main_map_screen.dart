import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainMapPage extends StatefulWidget {
  const MainMapPage({super.key});

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  late GoogleMapController mapController;
  static final LatLng _center = const LatLng(45.521563, -122.677433);
  final Set<Marker> _markers = {};
  LatLng _currentMapPosition = _center;
  late BuildContext auxContext;

  FirebaseFirestore  db = FirebaseFirestore.instance;
  FirebaseAuth  auth = FirebaseAuth.instance;
  User  user = FirebaseAuth.instance.currentUser!;

  String email = '';
  String name = '';

  void _onAddMarkerButtonPressed() {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(_currentMapPosition.toString()),
        position: _currentMapPosition,
        infoWindow: InfoWindow(
          title: 'Interesting Event',
          snippet: 'View more details here!',
          onTap: () {
            Scaffold.of(auxContext).openEndDrawer();
          },
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<dynamic> getUserDetails () async {
    await FirebaseFirestore.instance.collection("userData").doc(user.uid).get().then(( DocumentSnapshot snapshot) {
      email = snapshot.get('email');
      name = snapshot.get('name');
    });
  }

  @override
  void initState() {
    super.initState();
    
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    getUserDetails();

    final Future<String> _calculation = Future<String>.delayed(
    const Duration(seconds: 2),
    () => 'Data Loaded',
  );


    return FutureBuilder<String>(
      future: _calculation,
      builder: (context, AsyncSnapshot<String> snapshot) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text(
                'Marker Mapper',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.black87,
              leading: Builder(
                builder: (context) {
                  auxContext = context;
                  return IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    currentAccountPicture: CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/vectors/default_profile.png')),
                    accountEmail: Text(email),
                    accountName: Text(
                      name,
                      style: TextStyle(fontSize: 24.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text(
                      'Add Marker',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.filter_list),
                    title: const Text(
                      'Filter Marker',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_box),
                    title: const Text(
                      'Account Details',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text(
                      'About Us',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
            ),
            endDrawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const UserAccountsDrawerHeader(
                    currentAccountPicture: CircleAvatar(
                      backgroundImage:
                          AssetImage('assets/vectors/default_profile.png'),
                    ),
                    accountEmail: Text('best.post@example.com'),
                    accountName: Text(
                      'Best Postington',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.house),
                    title: const Text(
                      'Houses',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.apartment),
                    title: const Text(
                      'Apartments',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 10.0,
                    ),
                    markers: _markers,
                    onCameraMove: _onCameraMove),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: FloatingActionButton(
                      onPressed: _onAddMarkerButtonPressed,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: Colors.grey,
                      child: const Icon(Icons.map, size: 30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
