import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Location _location = Location();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndFetchLocation();
  }

  Future<void> _checkPermissionsAndFetchLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locData = await _location.getLocation();
      _currentPosition = LatLng(locData.latitude!, locData.longitude!);
      setState(() {
        _loading = false;
      });

      await _loadDisasterMarkers();
    } catch (e) {
      debugPrint("Konum alınırken hata oluştu: $e");
    }
  }

  Future<void> _loadDisasterMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('disasters').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        _markers.add(Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(
            title: data['type'] ?? 'Afet',
            snippet: data['description'] ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Harita")),
      body: _loading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
