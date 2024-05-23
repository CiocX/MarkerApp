import 'package:flutter/material.dart';  
import 'package:google_maps_flutter/google_maps_flutter.dart';  
  
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
  
  void _onAddMarkerButtonPressed() {  
    setState(() {  
      _markers.add(Marker(  
        markerId: MarkerId(_currentMapPosition.toString()),  
        position: _currentMapPosition, 
        infoWindow: InfoWindow(  
          title: 'Nice Place',  
          snippet: 'Welcome to Poland',  
          onTap:  () {
                  Scaffold.of(auxContext).openDrawer();
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
    return MaterialApp(  
      home: Scaffold(  
        appBar: AppBar(  
          title: Text('Flutter Maps Demo'),  
          backgroundColor: Colors.green,  
          leading: Builder(
            builder: (context) {
              auxContext = context;
              return IconButton(
                icon: const Icon(Icons.menu),
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
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Drawer Header'),
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
              onCameraMove: _onCameraMove  
            ),  
            Padding(  
              padding: const EdgeInsets.all(14.0),  
              child: Align(  
                alignment: Alignment.topRight, 
                child: FloatingActionButton(  
                  onPressed: _onAddMarkerButtonPressed, 
                  materialTapTargetSize: MaterialTapTargetSize.padded,  
                  backgroundColor: Colors.green,  
                  child: const Icon(Icons.map, size: 30.0),  
                ),  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  