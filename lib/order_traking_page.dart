import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_mao/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  late final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation = LatLng(34.1198, 72.6859);
  static const LatLng destination = LatLng(34.1226, 72.6844);

  List<LatLng> polylineCoordinates = [];

  LocationData? _currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  void getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then((currentLocation) {
      _currentLocation = currentLocation;
    });

    location.onLocationChanged.listen((newLoc) async {
      _currentLocation = newLoc;
      GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              newLoc.latitude!,
              newLoc.longitude!,
            ),
            zoom: 16.0,
          ),
        ),
      );
      setState(() {});
    });
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(
            point.latitude,
            point.longitude,
          ),
        );
      }
      setState(() {});
    }
  }

  void setCustomMarkerIcon() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/Pin_source.png')
        .then(
      (icon) => sourceIcon = icon,
    );
    destinationIcon = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(devicePixelRatio: 2.5),
            'assets/Pin_destination.png')
        .then(
      (icon) => destinationIcon = icon,
    );
    currentLocationIcon = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(devicePixelRatio: 2.5), 'assets/Badge.png')
        .then(
      (icon) => currentLocationIcon = icon,
    );
  }

  @override
  void initState() {
    getPolyPoints();
    setCustomMarkerIcon();
    getCurrentLocation();
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
      ),
      body: _currentLocation == null
          ? const Center(
              child: Text(
                "Loading",
              ),
            )
          : Center(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentLocation!.latitude!,
                    _currentLocation!.longitude!,
                  ),
                  zoom: 16,
                ),
                onMapCreated: (mapController) {
                  _controller.complete(mapController);
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('poly'),
                    color: Colors.red,
                    points: polylineCoordinates,
                    width: 4,
                  ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    icon: currentLocationIcon,
                    position: LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                  ),
                  Marker(
                    icon: sourceIcon,
                    markerId: const MarkerId("source"),
                    position: sourceLocation,
                  ),
                  Marker(
                    icon: destinationIcon,
                    markerId: const MarkerId("destination"),
                    position: destination,
                  )
                },
              ),
            ),
    );
  }
}
