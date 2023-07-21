import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loc/constants/constants.dart';
import 'package:loc/dashes/mymap.dart';
import 'package:loc/tests/tochange_icon.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart' as intle;

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng destination = LatLng(13.9559, 44.1816);
  List<LatLng> polylineCoordinates = [];
  static const LatLng sourceLocation = LatLng(13.9624, 44.1806);

  LatLng currentLocation =
      LatLng(sourceLocation.latitude, sourceLocation.longitude);

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  GlobalKey<FormState> orderTrakPageKey = GlobalKey();

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<Uint8List> getBytesFromCanvas(int width, int height) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue;
    const Radius radius = Radius.circular(20.0);
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        ),
        paint);
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = const TextSpan(
      text: 'Hello world',
      style: TextStyle(fontSize: 25.0, color: Colors.white),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));
    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    Position position = await Geolocator.getCurrentPosition();
    currentLocation = LatLng(position.latitude, position.longitude);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      PointLatLng(currentLocation.latitude, currentLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );
    print("-=-----------FinalLocat$currentLocation -----------==========You");

    if (result.points.isNotEmpty) {
      // ignore: avoid_function_literals_in_foreach_calls
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {
        polylineCoordinates;
        currentLocation;
      });
    } // else {
    //   print("=====================${result.errorMessage}");
    //  }
  }

  void setCustomMarkerIcon() {
    getBytesFromAsset('assets/Pin_source.png', 70).then((onValue) {
      sourceIcon = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset('assets/Pin_destination.png', 70).then((onValue) {
      destinationIcon = BitmapDescriptor.fromBytes(onValue);
    });
    getBytesFromAsset('assets/bus.png', 180).then((onValue) {
      currentLocationIcon = BitmapDescriptor.fromBytes(onValue);
    });
    setState(() {});
  }

  bool getLocat = false;

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
    _getLiveLocation();

    getPolyPoints();
    _listenLocation();
    setCustomMarkerIcon();
    // _getTimeInHours();
    if (getLocat == false) {
      print("-=-----------YES-----------==========You");
    } else {
      print("-=-----------NO-----------==========You");
    }
    // _stopListening();

    // location.changeSettings(interval: 300, accuracy: loc.LocationAccuracy.high);
    // location.enableBackgroundMode(enable: false);

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
                  child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('location')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                              snapshot.data!.docs[index]['name'].toString()),
                          subtitle: Row(
                            children: [
                              Text(snapshot.data!.docs[index]['latitude']
                                  .toString()),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(snapshot.data!.docs[index]['longitude']
                                  .toString()),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => MyMap(
                                          snapshot.data!.docs[index].id,
                                        )),
                              );
                            },
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.local_attraction),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const MyHomePage(
                                    title: 'ModWir-Tracker',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      });
                },
              )),
            ],
          ),
        ),
      ),
      body: currentLocation == null
          ? const Center(
              child: Text("Loading ..."),
            )
          : GoogleMap(
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target:
                    LatLng(currentLocation.latitude, currentLocation.longitude),
                zoom: 18.5,
                tilt: 20.70,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: Colors.purple.shade200,
                  width: 16,
                ),
              },
              markers: {
                Marker(
                    markerId: const MarkerId("id"),
                    icon: currentLocationIcon,
                    position: LatLng(
                        currentLocation.latitude, currentLocation.longitude)),
                Marker(
                  icon: sourceIcon,
                  markerId: const MarkerId("source"),
                  position: sourceLocation,
                ),
                Marker(
                  markerId: const MarkerId("destination"),
                  icon: destinationIcon,
                  position: destination,
                ),
              },
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              },
            ),
    );
  }
// To add Location Info

  _getLocation() async {
    try {
      final loc.LocationData locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc('user3').set({
        'latitude': locationResult.latitude,
        'longitude': locationResult.longitude,
        'name': 'Hani'
      }, SetOptions(merge: true));
      double? latitude = locationResult.latitude;
      double? longitude = locationResult.longitude;
      setState(() {
        currentLocation = LatLng(latitude!, longitude!);
        print("------------=================MODWIRALI $currentLocation");
      });
    } catch (e) {
      print(e);
    }
  }

  // To Enable Location in live

  Future<void> _listenLocation() async {
    // FirebaseFirestore firestore = FirebaseFirestore.instance;
    // Stream<DocumentSnapshot> stream =
    //     firestore.collection('location').doc('user1').snapshots();
    // stream.listen((DocumentSnapshot snapshot) {
    //   double latitude = snapshot['latitude'];
    //   double longitude = snapshot['longitude'];

    //   setState(() {
    //     currentLocation = LatLng(latitude, longitude);
    //   });

    // });

    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen(
      (loc.LocationData currentlocation) async {
        await FirebaseFirestore.instance
            .collection('location')
            .doc('user1')
            .set({
          'latitude': currentlocation.latitude,
          'longitude': currentlocation.longitude,
          'name': 'john',
        }, SetOptions(merge: true));
        double? latitude = currentlocation.latitude;
        double? longitude = currentlocation.longitude;
        setState(() {
          currentLocation = LatLng(latitude!, longitude!);
          print("------------=================MODWIRALI $currentLocation");
        });

        // setState(() {
        //   currentLocation ==
        //       LatLng(currentlocation.altitude!, currentlocation.longitude!);
        //   print("===========1 1 1 1===============$currentLocation");
        // });

        GoogleMapController googleMapController = await _controller.future;

        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 18.5,
              tilt: 70.20,
              target: LatLng(
                currentLocation.latitude,
                currentLocation.longitude,
              ),
            ),
          ),
        );

        // print("---------------------------------CurrentLLLL$currentLocation");
      },
    );
  }

// To get live location

  _getLiveLocation() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Stream<DocumentSnapshot> stream =
        firestore.collection('location').doc('user2').snapshots();
    stream.listen((DocumentSnapshot snapshot) {
      double latitude = snapshot['latitude'];
      double longitude = snapshot['longitude'];
      SetOptions(merge: true);

      setState(() {
        currentLocation = LatLng(latitude, longitude);
        currentLocation;
      });

      print("------------=================Curr$currentLocation");
    });
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 15.5,
          tilt: 20.70,
          target: LatLng(
            currentLocation.latitude,
            currentLocation.longitude,
          ),
        ),
      ),
    );
  }

// To Clear Listing

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }
}
