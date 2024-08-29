import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapExample extends StatefulWidget {
  @override
  State<MapExample> createState() => _MapExampleState();
}

class _MapExampleState extends State<MapExample> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _center = LatLng(37.7749, -122.4194);
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _originAddress = '';
  String _destinationAddress = '';
  LatLng? _origin;
  LatLng? _destination;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.whileInUse) {
      setState(() {
        _isLoading = true;
      });

      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Change the icon
            infoWindow: InfoWindow(title: 'Mi ubicación actual'),
          ));

          if (_mapController != null) {
            _mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 15.0,
              ),
            ));
          }
          _isLoading = false;
        });
      } catch (e) {
        print('Error al obtener la ubicación actual: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _getPositionStream() async {
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: LocationSettings()).listen((Position position) {
      setState(() {
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Change the icon
          infoWindow: InfoWindow(title: 'Mi ubicación actual'),
        ));

        if (_mapController != null) {
          _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ));
        }
      });
    });
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Origen',
                ),
                onChanged: (value) {
                  setState(() {
                    _originAddress = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Destino',
                ),
                onChanged: (value) {
                  setState(() {
                    _destinationAddress = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await _getCoordinates();
                  await _getDirections();
                  Navigator.pop(context);
                },
                child: Text('Crear ruta'),
              ),
              FloatingActionButton(
                onPressed: () {
                  _getCurrentLocation();
                },
                child: Icon(Icons.location_on),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCoordinates() async {
    final geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
    final originResponse = await http.post(Uri.parse(geocodingUrl), headers: {
      'Content-Type': 'application/json',
    }, body: jsonEncode({
      'address': _originAddress,
      'key': 'AIzaSyBOTkCGPbkizppjUFhPDWOWQCCRxZ4Wjxo',
    }));

    final destinationResponse = await http.post(Uri.parse(geocodingUrl), headers: {
      'Content-Type': 'application/json',
    },
            body: jsonEncode({
          'address': _destinationAddress,
          'key': 'AIzaSyBOTkCGPbkizppjUFhPDWOWQCCRxZ4Wjxo',
        }));

    if (originResponse.statusCode == 200 && destinationResponse.statusCode == 200) {
      final originJson = jsonDecode(originResponse.body);
      final destinationJson = jsonDecode(destinationResponse.body);

      setState(() {
        _origin = LatLng(
          originJson['results'][0]['geometry']['location']['lat'],
          originJson['results'][0]['geometry']['location']['lng'],
        );
        _destination = LatLng(
          destinationJson['results'][0]['geometry']['location']['lat'],
          destinationJson['results'][0]['geometry']['location']['lng'],
        );
      });
    } else {
      print('Failed to get coordinates');
    }
  }

  Future<void> _getDirections() async {
    final directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    final response = await http.post(Uri.parse(directionsUrl), headers: {
      'Content-Type': 'application/json',
    }, body: jsonEncode({
      'origin': '$_originAddress',
      'destination': '$_destinationAddress',
      'mode': 'driving',
      'key': 'AIzaSyBOTkCGPbkizppjUFhPDWOWQCCRxZ4Wjxo',
    }));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final route = json['routes'][0]['overview_polyline']['points'];

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _decodePolyline(route),
          color: Colors.blue,
          width: 10,
        ));
      });
    } else {
      print('Failed to get directions');
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> polylineCoordinates = [];
    List<int> indexList = <int>[];
    int len = polyline.length;

    for (int x = 0; x < len; x++) {
      if (x < len - 2) {
        int res = (polyline.codeUnitAt(x) - 63);
        res = res << 5;
        res += (polyline.codeUnitAt(x + 1) - 65);
        res = res << 4;
        indexList.add(res);
        x += 2;
      }
    }

    int lastX = 0;
    int lastY = 0;
    int currentX = 0;
    int currentY = 0;

    for (int pointItem = 0; pointItem < indexList.length; pointItem++) {
      if (pointItem == 0) {
        currentX = indexList[pointItem];
        currentY = indexList[pointItem];
      } else {
        currentX += indexList[pointItem];
        currentY += indexList[pointItem + 1];
      }

      polylineCoordinates.add(LatLng(
        lastX + (currentX / 1E5),
        lastY + (currentY / 1E5),
      ));
      lastX = (currentX % 1E5) as int;
      lastY = (currentY % 1E5) as int;
    }
    return polylineCoordinates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _showMenu(context);
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12.0,
        ),
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}