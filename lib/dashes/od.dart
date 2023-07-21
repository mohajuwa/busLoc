import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MyMap2 extends StatefulWidget {
  const MyMap2({super.key});

  @override
  _MyMap2State createState() => _MyMap2State();
}

class _MyMap2State extends State<MyMap2> {
  Set<LatLng> polylinePoints = {};
  Polyline polyline = const Polyline(
    polylineId: PolylineId('polyline'),
    points: [],
    color: Colors.red,
    width: 13,
  );
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen(_onLocationChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _positionStreamSubscription.cancel();
  }

  void _onLocationChanged(Position position) {
    setState(() {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      polylinePoints.add(currentLocation);
      polyline = Polyline(
        polylineId: const PolylineId('polyline'),
        points: polylinePoints.toList(),
        color: Colors.red,
        width: 5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Map Screen'),
      ),
      body: GoogleMap(
        polylines: {polyline},
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.9624, 44.1806),
          zoom: 16,
        ),
      ),
    );
  }
}
