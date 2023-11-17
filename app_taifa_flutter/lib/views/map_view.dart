import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapsPage extends StatefulWidget {
  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Set<Marker> _markers = {};
  LatLng? _temporaryPinLocation;
  TextEditingController _pinNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPinsFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onMapTap,
        initialCameraPosition: const CameraPosition(
          target: LatLng(53.492412, -113.496737), // Initial map position
          zoom: 8.0,
        ),
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPinDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    // Initialize the GoogleMapController here if needed
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _temporaryPinLocation = latLng;
      if (_temporaryPinLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('temporary_pin'),
            position: _temporaryPinLocation!,
          ),
        );
      }
    });
  }

  Future<void> _showAddPinDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Pin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pinNameController,
                decoration: const InputDecoration(labelText: 'Pin Name'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _addPinToFirestore();
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPinToFirestore() {
    final String pinName = _pinNameController.text.trim();
    if (pinName.isNotEmpty && _temporaryPinLocation != null) {
      FirebaseFirestore.instance.collection('allPins').add({
        'name': pinName,
        'latitude': _temporaryPinLocation!.latitude,
        'longitude': _temporaryPinLocation!.longitude,
      });
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(pinName),
            position: _temporaryPinLocation!,
            infoWindow: InfoWindow(title: pinName),
          ),
        );
        _temporaryPinLocation = null;
        _pinNameController.clear();
      });
    }
  }

  void _loadPinsFromFirestore() {
    FirebaseFirestore.instance.collection('allPins').snapshots().listen((snapshot) {
      setState(() {
        _markers.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String name = data['name'] ?? '';
          final double latitude = data['latitude'] ?? 0.0;
          final double longitude = data['longitude'] ?? 0.0;

          _markers.add(
            Marker(
              markerId: MarkerId(name),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: name),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _pinNameController.dispose();
    super.dispose();
  }
}
