import 'dart:async';
import 'dart:io';

import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marker_app/components/app_text_form_field.dart';
import 'package:marker_app/resources/appMarker.dart';
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
  LatLng _userLocation = const LatLng(45.7494, 21.2272);
  final Set<Marker> _markers = {};
  late LatLng _currentMapPosition = _userLocation;
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

  //Geolocator geolocator = Geolocator(); 

  late final TextEditingController titleController;
  late final TextEditingController categoryController;
  late final TextEditingController descriptionController;
  late final TextEditingController durationController;

  late DateTime startDate = DateTime.now();
  late DateTime endDate;

  final endDateKey = GlobalKey<State>();

  List<AppMarker> appMarkers = List.empty();
  int currentMarker = 0;

  String markerTitle = '';
  String markerAuthor = '';
  String markerCategory = '';
  String markerDescription = '';
  String markerDuration = '';

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



  Future<void> getCurrentLocation() async {
    try {
      //Position _currentLocation = await Geolocator.getCurrentPosition();
      LatLng _currentLocation = LatLng(45.7494, 21.2272);
      setState(() {
        _userLocation = LatLng(_currentLocation.latitude, _currentLocation.longitude);
      });
    } catch (e) {
      print(e);
      rethrow;

    }
  }

  double markerColorSelector (AppMarker appMarker){
    if(DateTime.now().isAfter(appMarker.endDate)) {
      return BitmapDescriptor.hueRed;
    }

    if(DateTime.now().isBefore(appMarker.startDate)) {
      return BitmapDescriptor.hueYellow;
    }

    return BitmapDescriptor.hueGreen;
  }

  void updateDrawerInfo(int markerNumber) {
    setState(() {
      markerTitle = appMarkers[markerNumber].title;
      markerAuthor = appMarkers[markerNumber].author;
      markerCategory = appMarkers[markerNumber].category;
      markerDescription = appMarkers[markerNumber].description;
      markerDuration = appMarkers[markerNumber].startDate.toString();
      markerDuration = markerDuration + appMarkers[markerNumber].description.toString();
    });
  }

  void updateMarkers() {
    CollectionReference reference = db.collection('markerData');
    reference.snapshots().listen((querySnapshot) {
            for (var change in querySnapshot.docChanges) {
              //appMarkers.add(AppMarker(change.doc.id, change.doc.get('title'), change.doc.get('author'), change.doc.get('category'), change.doc.get('description'), (change.doc.get('startDate') as Timestamp).toDate(), (change.doc.get('endDate') as Timestamp).toDate(), change.doc.get('latitude'), change.doc.get('longitude')));
              appMarkers = <AppMarker>[...appMarkers, AppMarker(change.doc.id, change.doc.get('title'), change.doc.get('author'), change.doc.get('category'), change.doc.get('description'), (change.doc.get('startDate') as Timestamp).toDate(), (change.doc.get('endDate') as Timestamp).toDate(), change.doc.get('latitude'), change.doc.get('longitude'))];

              setState(() {
                _markers.add(Marker(
                  markerId: MarkerId(appMarkers[currentMarker].id),
                  position: LatLng(appMarkers[currentMarker].latitude, appMarkers[currentMarker].longitude),
                  infoWindow: InfoWindow(
                    title: appMarkers[currentMarker].title,
                    snippet: appMarkers[currentMarker].category,
                    onTap: () {
                      int markerNumber = currentMarker;
                      updateDrawerInfo(markerNumber); //TODO: markerNumber is always 4, regardless of the marker pressed... Fix it
                      Scaffold.of(auxContext).openEndDrawer();
                    },
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(markerColorSelector(appMarkers[currentMarker])),
                ));
              });
              currentMarker = currentMarker + 1;
            }
      }
    );

    
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

        AppMarker newMarker = AppMarker(markerUid, titleController.text, user.uid, categoryController.text, descriptionController.text, startDate, endDate, latitude, longitude);

        await db.collection("markerData").doc(markerUid).set({
          "author": newMarker.author,
          "title": newMarker.title,
          "category": newMarker.category,
          "description": newMarker.description,
          "startDate": newMarker.startDate,
          "endDate": newMarker.endDate,
          "latitude": newMarker.latitude,
          "longitude": newMarker.longitude,
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
                        DateTimeFormField(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                          ),
                          firstDate: DateTime.now(),
                          initialPickerDateTime: DateTime.now(),
                          onChanged: (value) =>
                            setState(() {
                              startDate = value!;
                              endDateKey.currentState!.build(context);
                            }),
                        ),
                        DateTimeFormField(
                          key: endDateKey,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                          ),
                          firstDate: (DateTime.now().isBefore(startDate))? startDate : DateTime.now(),
                          initialPickerDateTime: (DateTime.now().isBefore(startDate))? startDate : DateTime.now(),
                          onChanged: (value) =>
                            setState(() {
                              endDate = value!;
                            }),
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
    getCurrentLocation();

    //Timer.periodic(Duration(seconds: 3), (Timer t) => updateMarkers());
    updateMarkers();

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
                          Expanded(
                            child: Text(
                              markerTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 24.0, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
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
                                label: markerAuthor,
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
                                value: Text('Name of Category'),
                                label: markerCategory,
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
                                value: Text('Name of Description'),
                                label: markerDescription,
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
                                value: Text('Name of Duration'),
                                label: markerDuration,
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
                    initialCameraPosition: CameraPosition(
                      target: _userLocation,
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
