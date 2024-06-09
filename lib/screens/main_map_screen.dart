import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marker_app/components/app_text_form_field.dart';
import 'package:marker_app/values/app_strings.dart';
import '../values/app_routes.dart';
import '../utils/helpers/navigation_helper.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MainMapPage extends StatefulWidget {
  const MainMapPage({super.key});

  @override
  State<MainMapPage> createState() => _MainMapPageState();
}

class _MainMapPageState extends State<MainMapPage> {
  late GoogleMapController mapController;
  static const LatLng _center = LatLng(45.7494, 21.2272);
  final Set<Marker> _markers = {};
  LatLng _currentMapPosition = _center;
  late BuildContext auxContext;

  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  User user = FirebaseAuth.instance.currentUser!;

  String email = '';
  String name = '';

  late dynamic latitude;
  late dynamic longitude;

  var uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController categoryController;
  late final TextEditingController descriptionController;
  late final TextEditingController durationController;

  void initializeControllers() {
    titleController = TextEditingController()..addListener(controllerListener);
    categoryController = TextEditingController()
      ..addListener(controllerListener);
    descriptionController = TextEditingController()
      ..addListener(controllerListener);
    durationController = TextEditingController()
      ..addListener(controllerListener);
  }

  void disposeControllers() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    durationController.dispose();
  }

  void controllerListener() {
    final title = titleController.text;
    final category = categoryController.text;
    final decription = descriptionController.text;
    final duration = durationController.text;

    if (title.isEmpty &&
        category.isEmpty &&
        decription.isEmpty &&
        duration.isEmpty) return;
  }

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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<dynamic> getUserDetails() async {
    await FirebaseFirestore.instance
        .collection("userData")
        .doc(user.uid)
        .get()
        .then((DocumentSnapshot snapshot) {
      email = snapshot.get('email');
      name = snapshot.get('name');
    });
  }

  void signOutOfAccount() async {
    await FirebaseAuth.instance.signOut();

    NavigationHelper.pushReplacementNamed(
      AppRoutes.login,
    );
  }

  void onMapTap(LatLng position) {
    latitude = position.latitude;
    longitude = position.longitude;

    showMenu();
  }

  void onAddMarkerToDatabasePress() async {
    try {
      if (auth.currentUser != null) {
        user = auth.currentUser!;
        var markerUid = uuid.v4();

        await db.collection("markerData").doc(markerUid).set({
          "author": user.uid,
          "title": titleController.text,
          "category": categoryController.text,
          "description": descriptionController.text,
          "duration": durationController.text,
          "latitude": latitude,
          "longitude": longitude,
        }).onError((e, _) => print("Error writing document: $e"));

        titleController.clear();
        categoryController.clear();
        descriptionController.clear();
        durationController.clear();

        NavigationHelper.pushReplacementNamed(
          AppRoutes.login,
        );
      } else {
        print("No user logged in");
      }
    } catch (e) {
      print(e);
    }

    Navigator.of(context).pop();
  }

  void showMenu() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Drawer(
            width: MediaQuery.of(context).size.width,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Add new marker',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24.0, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => onAddMarkerToDatabasePress(),
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextFormField(
                          labelText: 'Title',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) =>
                              _formKey.currentState?.validate(),
                          controller: titleController,
                        ),
                        AppTextFormField(
                          labelText: 'Category',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) =>
                              _formKey.currentState?.validate(),
                          controller: categoryController,
                        ),
                        AppTextFormField(
                          labelText: 'Description',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) =>
                              _formKey.currentState?.validate(),
                          controller: descriptionController,
                        ),
                        AppTextFormField(
                          labelText: 'Duration',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) =>
                              _formKey.currentState?.validate(),
                          controller: durationController,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  void initState() {
    initializeControllers();
    super.initState();
  }

  @override
  void dispose() {
    disposeControllers();
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
                title: const Text(
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
                      currentAccountPicture: const CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/vectors/default_profile.png')),
                      accountEmail: Text(email),
                      accountName: Text(
                        name,
                        style: TextStyle(fontSize: 24.0),
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.add),
                      title: Text(
                        'Add Marker',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.filter_list),
                      title: Text(
                        'Filter Marker',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.account_box),
                      title: Text(
                        'Account Details',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text(
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
                      onTap: () => signOutOfAccount(),
                    ),
                  ],
                ),
              ),
              endDrawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                      ),
                      child: Row(
                        children: [
                          Image.asset('assets/vectors/default_profile.png'),
                          const Expanded(
                            child: Text(
                              'Marker Title',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 24.0, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    const Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownMenu(
                          enableFilter: false,
                          enableSearch: false,
                          leadingIcon: Icon(Icons.person),
                          label: Text(
                            'Author',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry<Text>(
                                value: Text('Name of Author'),
                                label: 'Name of Author2',
                                enabled: false)
                          ],
                        ),
                        DropdownMenu(
                          enableFilter: false,
                          enableSearch: false,
                          leadingIcon: Icon(Icons.category_sharp),
                          label: Text(
                            'Category',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry<Text>(
                                value: Text('Name of Author'),
                                label: 'Name of Author2',
                                enabled: false)
                          ],
                        ),
                        DropdownMenu(
                          enableFilter: false,
                          enableSearch: false,
                          leadingIcon: Icon(Icons.description_rounded),
                          label: Text(
                            'Description',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry<Text>(
                                value: Text('Name of Author'),
                                label: 'Name of Author2',
                                enabled: false)
                          ],
                        ),
                        DropdownMenu(
                          enableFilter: false,
                          enableSearch: false,
                          leadingIcon: Icon(Icons.hourglass_full_rounded),
                          label: Text(
                            'Duration',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry<Text>(
                                value: Text('Name of Author'),
                                label: 'Name of Author2',
                                enabled: false)
                          ],
                        ),
                      ],
                    ))
                  ],
                ),
              ),
              body: Stack(
                children: <Widget>[
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: const CameraPosition(
                      target: _center,
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    onCameraMove: _onCameraMove,
                    onTap: (position) => onMapTap(position),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FloatingActionButton(
                        onPressed: showMenu,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.grey,
                        child: const Icon(Icons.add, size: 30.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
