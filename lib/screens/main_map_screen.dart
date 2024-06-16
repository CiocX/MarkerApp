import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marker_app/components/app_text_form_field.dart';
import 'package:marker_app/resources/appMarker.dart';
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
  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  late BuildContext auxContext;

  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  User user = FirebaseAuth.instance.currentUser!;

  String email = '';
  String name = '';

  late dynamic latitude;
  late dynamic longitude;

  var uuid = const Uuid();

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

  String markerId = '';
  String markerTitle = '';
  String markerAuthor = '';
  String markerCategory = '';
  String markerDescription = '';
  String markerDuration = '';

  bool currentEventFilter = true;
  bool upcomingEventFilter = true;
  bool endedEventFilter = true;

  bool isMarkerAuthor = false;

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
      //Position currentLocation = await Geolocator.getCurrentPosition();
      LatLng currentLocation = const LatLng(45.7494, 21.2272);
      setState(() {
        _userLocation =
            LatLng(currentLocation.latitude, currentLocation.longitude);
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  double markerColorSelector(AppMarker appMarker) {
    if (DateTime.now().isAfter(appMarker.endDate)) {
      return BitmapDescriptor.hueRed;
    }

    if (DateTime.now().isBefore(appMarker.startDate)) {
      return BitmapDescriptor.hueOrange;
    }

    return BitmapDescriptor.hueGreen;
  }

  Future setAuthorNameFromFirebase(String userID) async {
    await db
        .collection('userData')
        .doc(userID)
        .get()
        .then((DocumentSnapshot snapshot) {
      markerAuthor = snapshot.get('name');
    });
  }

  void updateDrawerInfo(int markerNumber) {
    setState(() {
      setAuthorNameFromFirebase(appMarkers[markerNumber].author);
      markerId = appMarkers[markerNumber].id;

      markerTitle = appMarkers[markerNumber].title;
      markerCategory = appMarkers[markerNumber].category;
      markerDescription = appMarkers[markerNumber].description;
      markerDuration = appMarkers[markerNumber].startDate.toString();
      markerDuration = '$markerDuration ${appMarkers[markerNumber].endDate}';

      if (FirebaseAuth.instance.currentUser!.uid ==
          appMarkers[markerNumber].author) {
        isMarkerAuthor = true;
      } else {
        isMarkerAuthor = false;
      }
    });
  }

  void updateMarkers() {
    CollectionReference reference = db.collection('markerData');
    reference.snapshots().listen((querySnapshot) {
      for (var change in querySnapshot.docChanges) {
        var markerUid = currentMarker;

        appMarkers = <AppMarker>[
          ...appMarkers,
          AppMarker(
              change.doc.id,
              change.doc.get('title'),
              change.doc.get('author'),
              change.doc.get('category'),
              change.doc.get('description'),
              (change.doc.get('startDate') as Timestamp).toDate(),
              (change.doc.get('endDate') as Timestamp).toDate(),
              change.doc.get('latitude'),
              change.doc.get('longitude'))
        ];
        MarkerId markerId = MarkerId(appMarkers[currentMarker].id);

        final Marker marker = (Marker(
          markerId: markerId,
          position: LatLng(appMarkers[currentMarker].latitude,
              appMarkers[currentMarker].longitude),
          infoWindow: InfoWindow(
            title: appMarkers[currentMarker].title,
            snippet: appMarkers[currentMarker].category,
            onTap: () {
              updateDrawerInfo(markerUid);
              Scaffold.of(auxContext).openEndDrawer();
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              markerColorSelector(appMarkers[currentMarker])),
        ));

        setState(() {
          _markers[markerId] = marker;
        });

        currentMarker = currentMarker + 1;
      }
    });
  }

  void _onCameraMove(CameraPosition position) {}

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

        AppMarker newMarker = AppMarker(
            markerUid,
            titleController.text,
            user.uid,
            categoryController.text,
            descriptionController.text,
            startDate,
            endDate,
            latitude,
            longitude);

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
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.black87,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Text(
                          'Add new marker',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24.0, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => onAddMarkerToDatabasePress(),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          onChanged: (value) => setState(() {
                            startDate = value!;
                            endDateKey.currentState!.build(context);
                          }),
                        ),
                        const SizedBox(height: 20),
                        DateTimeFormField(
                          key: endDateKey,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                          ),
                          firstDate: (DateTime.now().isBefore(startDate))
                              ? startDate
                              : DateTime.now(),
                          initialPickerDateTime:
                              (DateTime.now().isBefore(startDate))
                                  ? startDate
                                  : DateTime.now(),
                          onChanged: (value) => setState(() {
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

  late BitmapDescriptor transparentIcon;

  Future _createTransparentIcon() async {
    transparentIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(0.001, 0.001)),
        'assets/vectors/invisible_marker.png');
  }

  void updateMarkerVisibility(
      MarkerId markerId, bool isVisible, int markerType) {
    var marker = _markers[markerId];

    setState(() {
      _markers[markerId] = marker!.copyWith(
        iconParam: isVisible
            ? BitmapDescriptor.defaultMarkerWithHue(markerType == 0
                ? BitmapDescriptor.hueGreen
                : markerType == 1
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueRed)
            : transparentIcon,
      );
    });
  }

  void visibilityHandler(int markerType) {
    switch (markerType) {
      case 0: //current
        for (AppMarker appMarker in appMarkers) {
          if (DateTime.now().isAfter(appMarker.startDate) &&
              DateTime.now().isBefore(appMarker.endDate)) {
            updateMarkerVisibility(
                MarkerId(appMarker.id), currentEventFilter, 0);
          }
        }
      case 1: //upcoming
        for (AppMarker appMarker in appMarkers) {
          if (DateTime.now().isBefore(appMarker.startDate)) {
            updateMarkerVisibility(
                MarkerId(appMarker.id), upcomingEventFilter, 1);
          }
        }
      case 2: //ended
        for (AppMarker appMarker in appMarkers) {
          if (DateTime.now().isAfter(appMarker.endDate)) {
            updateMarkerVisibility(MarkerId(appMarker.id), endedEventFilter, 2);
          }
        }
    }
  }

  Future deleteEventAndCloseDrawer() async {
    await db.collection('markerData').doc(markerId).delete();
    setState(() {
      _markers.remove(MarkerId(markerId));
    });

    Scaffold.of(auxContext).closeEndDrawer();
  }

  @override
  void initState() {
    currentMarker = 0;

    _createTransparentIcon();
    initializeControllers();
    getCurrentLocation();
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
    final Future<String> calculation = Future<String>.delayed(
      const Duration(seconds: 2),
      () => 'Data Loaded',
    );

    return FutureBuilder<String>(
        future: calculation,
        builder: (context, AsyncSnapshot<String> snapshot) {
          return MaterialApp(
            home: Scaffold(
              drawerEdgeDragWidth: 0.0,
              appBar: AppBar(
                actions: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.access_alarm,
                        color: Color.fromARGB(221, 36, 36, 36),
                      ))
                ],
                title: const Text(
                  'Marker Mapper',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                automaticallyImplyLeading: false,
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
                          backgroundImage: AssetImage(
                              'assets/vectors/negative_profile_picture.png')),
                      accountEmail: Text(email),
                      accountName: Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24.0,
                          ),
                        ),
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                      ),
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.filter_list),
                      title: const Text(
                        'Filter Marker',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Current'),
                          trailing: Switch(
                            value: currentEventFilter,
                            onChanged: (value) {
                              setState(() {
                                currentEventFilter = value;
                                visibilityHandler(0);
                              });
                            },
                            activeTrackColor:
                                const Color.fromARGB(255, 128, 128, 128),
                            activeColor: const Color.fromARGB(255, 90, 90, 90),
                          ),
                        ),
                        ListTile(
                          title: const Text('Upcoming'),
                          trailing: Switch(
                            value: upcomingEventFilter,
                            onChanged: (value) {
                              setState(() {
                                upcomingEventFilter = value;
                                visibilityHandler(1);
                              });
                            },
                            activeTrackColor:
                                const Color.fromARGB(255, 128, 128, 128),
                            activeColor: const Color.fromARGB(255, 90, 90, 90),
                          ),
                        ),
                        ListTile(
                          title: const Text('Ended'),
                          trailing: Switch(
                            value: endedEventFilter,
                            onChanged: (value) {
                              setState(() {
                                endedEventFilter = value;
                                visibilityHandler(2);
                              });
                            },
                            activeTrackColor:
                                const Color.fromARGB(255, 128, 128, 128),
                            activeColor: const Color.fromARGB(255, 90, 90, 90),
                          ),
                        ),
                      ],
                    ),
                    const ExpansionTile(
                      leading: Icon(Icons.info_outline),
                      title: Text(
                        'About Us',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        ListTile(
                          title: AutoSizeText(
                            'This application\'s purpose is to provide it\'s users with the ability to better organise as a community. The functionality it provides consists in the ability to create markers and to have them readily available to all users of the app, in order for them to know about all important upcoming, current, and past events.',
                            minFontSize: 14,
                            maxLines: 10,
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text(
                        'Sign out',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => signOutOfAccount(),
                    ),
                  ],
                ),
              ),
              endDrawer: Drawer(
                child: Stack(children: <Widget>[
                  ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      DrawerHeader(
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                        ),
                        child: Text(
                          markerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Author',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: const Icon(Icons.person),
                        children: <Widget>[
                          ListTile(
                            title: Text(markerAuthor),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: const Icon(Icons.category_sharp),
                        children: <Widget>[
                          ListTile(
                            title: Text(markerCategory),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: const Icon(Icons.description_rounded),
                        children: <Widget>[
                          ListTile(
                            title: Text(markerDescription),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: const Icon(Icons.hourglass_full_rounded),
                        children: <Widget>[
                          ListTile(
                            title: Text(markerDuration),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 10.0,
                    bottom: 10.0,
                    child: isMarkerAuthor
                        ? FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: () {
                              deleteEventAndCloseDrawer();
                            },
                            child: const Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 202, 45, 33),
                            ),
                          )
                        : Container(),
                  ),
                ]),
              ),
              body: Stack(
                children: <Widget>[
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _userLocation,
                      zoom: 15.0,
                    ),
                    markers: Set<Marker>.of(_markers.values),
                    onCameraMove: _onCameraMove,
                    onTap: (position) => onMapTap(position),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
