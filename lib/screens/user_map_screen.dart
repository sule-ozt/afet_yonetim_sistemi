import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(39.9208, 32.8541); // Varsayılan: Ankara
  bool _loading = true;

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      _initialPosition = LatLng(locData.latitude!, locData.longitude!);
      _loading = false;
    });
  }

  Future<void> _loadUserMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Gönüllü')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        _markers.add(Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(
            title: data['name'] ?? data['email'] ?? 'Gönüllü',
            snippet: 'Bu gönüllünün konumu',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) => _loadUserMarkers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gönüllü Haritası")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
