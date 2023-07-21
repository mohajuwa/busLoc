import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:loc/constants/constants.dart';
import 'package:intl/intl.dart' as intle;

class MyMap extends StatefulWidget {
  final String user_id;

  const MyMap(
    this.user_id, {
    super.key,
  });
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late GoogleMapController _controller;
  bool _added = false;

  static const LatLng sourceLocation = LatLng(13.9624, 44.1806);
  static const LatLng destination = LatLng(13.9559, 44.1816);
  List<LatLng> polylineCoordinates = [];

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void setCustomMarkerIcon() {
    getBytesFromAsset('assets/Pin_source.png', 70).then((onValue) {
      sourceIcon = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset('assets/Pin_destination.png', 70).then((onValue) {
      destinationIcon = BitmapDescriptor.fromBytes(onValue);
    });
    getBytesFromAsset('assets/Badge.png', 140).then((onValue) {
      currentLocationIcon = BitmapDescriptor.fromBytes(onValue);
    });
    setState(() {});
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      PointLatLng(currentLocation.latitude, currentLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );
    if (result.points.isNotEmpty) {
      // ignore: avoid_function_literals_in_foreach_calls
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );

      setState(() {});
    } // else {
    //   print("=====================${result.errorMessage}");
    //  }
  }

// databaseReference
//         .child("location")
//         .child(widget.user_id)
//         .onValue
//         .listen((event) {
//       if (event.snapshot.value != null) {
//         final Map<dynamic, dynamic>? locationList =
//             event.snapshot.value as Map<dynamic, dynamic>?;

//         final List<LatLng> newPolylinePoints = locationList!.values
//             .map((location) =>
//                 LatLng(location['latitude'], location['longitude']))
//             .toList();

//         setState(() {
//           _polylinePoints = newPolylinePoints;
//         });

//         _controller.animateCamera(CameraUpdate.newLatLng(LatLng(
//             locationList.values.last['latitude'],
//             locationList.values.last['longitude'])));
//       }
//     });

  bool getLocat = false;

  LatLng currentLocation =
      LatLng(sourceLocation.latitude, sourceLocation.longitude);
  _getTimeInHours() async {
    DateTime now = DateTime.now();
    DateTime localTime = now.toLocal();
    String formattedTime = intle.DateFormat('hh:mm a').format(localTime);
    print("----===---TIME---===--- IS [$formattedTime ]");
    int hours = now.hour;
    int menuts = now.minute;
    bool amORpm = false;
    if (formattedTime.contains('A') && formattedTime.contains('12')) {
      amORpm = true;
    } else {
      amORpm = false;
    }
    print("================$amORpm");

    if (amORpm == true) {
      getLocat = true;
      setState(() {
        getLocat = true;
      });
    } else {
      getLocat = false;
      setState(() {
        getLocat = false;
      });
    }
  }

  @override
  void initState() {
    print("===========CURENTLOCARION = $currentLocation");
    // _getTimeInHours();
    // if (getLocat == true) {
    //   getPolyPoints();

    //   print("-=-----------YES-----------==========You");
    // } else {
    //   print("-=-----------NO-----------==========You");
    // }

    // _stopListening();
    polylineCoordinates.clear();
    getPolyPoints();
    setCustomMarkerIcon();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Track order",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          toolbarHeight: 130,
          leadingWidth: 400,
          leading: Center(
            child: Column(
              children: [
                Expanded(
                  child: TextButton(
                      onPressed: () {
                        // getPolyPoints();
                      },
                      child: const Text('add my location')),
                ),
              ],
            ),
          ),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('location').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (_added) {
              mymap(snapshot);
              currentLocation = LatLng(
                snapshot.data!.docs.singleWhere(
                    (element) => element.id == widget.user_id)['latitude'],
                snapshot.data!.docs.singleWhere(
                    (element) => element.id == widget.user_id)['longitude'],
              );
              print(
                  "-------------------------MYMAP $currentLocation    MODWIR");
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return GoogleMap(
              mapType: MapType.normal,
              markers: {
                Marker(
                  position: LatLng(
                    snapshot.data!.docs.singleWhere(
                        (element) => element.id == widget.user_id)['latitude'],
                    snapshot.data!.docs.singleWhere(
                        (element) => element.id == widget.user_id)['longitude'],
                  ),
                  markerId: const MarkerId('id'),
                  icon: currentLocationIcon,
                ),
                Marker(
                  markerId: const MarkerId("sourceLocation"),
                  icon: sourceIcon,
                  position: sourceLocation,
                ),
                Marker(
                  markerId: const MarkerId("destination"),
                  icon: destinationIcon,
                  position: destination,
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: Colors.purple.shade200,
                  width: 16,
                ),
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  snapshot.data!.docs.singleWhere(
                      (element) => element.id == widget.user_id)['latitude'],
                  snapshot.data!.docs.singleWhere(
                      (element) => element.id == widget.user_id)['longitude'],
                ),
                zoom: 18.5,
                tilt: 70.20,
              ),
              onMapCreated: (GoogleMapController controller) async {
                setState(() {
                  _controller = controller;
                  _added = true;
                });
              },
            );
          },
        ));
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(
        snapshot.data!.docs
            .singleWhere((element) => element.id == widget.user_id)['latitude'],
        snapshot.data!.docs.singleWhere(
            (element) => element.id == widget.user_id)['longitude'],
      ),
      zoom: 18.5,
      tilt: 70.20,
    )));
  }
}
