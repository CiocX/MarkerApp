import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Markercallback extends StatefulWidget {
  final Function(MarkerId) onMarkersChanged;

  final Widget? child;
  final MarkerId markerId;

  Markercallback({required this.onMarkersChanged, this.child, required this.markerId});

  @override
  _MarkercallbackState createState() => _MarkercallbackState();
}

class _MarkercallbackState extends State<Markercallback> {

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => widget.onMarkersChanged(widget.markerId),
      child: Container(
        padding: EdgeInsets.all(20.0),
        color: Colors.blue,
        child: Text(
          'Tap Me!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}