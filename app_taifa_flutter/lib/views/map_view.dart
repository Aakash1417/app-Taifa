import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../objects/Client.dart';
import '../objects/Pins.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Set<Marker> _markers = {};
  LatLng? _temporaryPinLocation;
  TextEditingController _pinNameController = TextEditingController();
  TextEditingController _coordsController = TextEditingController();

  String? _selectedClient;
  List<Pins> _allPins = [];
  List<String> _selectedClients = [];
  List<Client> _clients = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadPinsFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search Pins',
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showClientFilterDialog,
            ),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return {'Add Client'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: GoogleMap(
        onTap: _onMapTap,
        initialCameraPosition: const CameraPosition(
          target: LatLng(53.492412, -113.496737), // Initial map position
          zoom: 8.0,
        ),
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPinDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _updateMarkers();
  }

  void _showClientFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Clients'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _clients.map((client) {
                return CheckboxListTile(
                  title: Text(client.name),
                  value: _selectedClients.contains(client.name),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedClients.add(client.name);
                      } else {
                        _selectedClients.remove(client.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateMarkers(); // Update markers based on selected clients
              },
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(String choice) {
    if (choice == 'Add Client') {
      _showAddClientDialog();
    }
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
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _pinNameController,
                  decoration: const InputDecoration(labelText: 'Pin Name'),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _selectedClient,
                  hint: Text(_selectedClient ?? "Select Client"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedClient = newValue;
                    });
                  },
                  onSaved: (String? newValue) {
                    setState(() {
                      _selectedClient = newValue;
                    });
                  },
                  items:
                      _clients.map<DropdownMenuItem<String>>((Client client) {
                    return DropdownMenuItem<String>(
                      value: client.name,
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: client.color,
                            radius: 10,
                          ),
                          const SizedBox(width: 8),
                          Text(client.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _coordsController,
                  decoration: const InputDecoration(
                      labelText: 'Coordinates (Optional)'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Add Pin'),
              onPressed: () {
                _addPinToFirestore();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddClientDialog() async {
    TextEditingController _clientNameController = TextEditingController();
    Color _clientColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Client'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(labelText: 'Client Name'),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Pick a color!'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: _clientColor,
                              onColorChanged: (Color color) {
                                _clientColor = color;
                              },
                            ),
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text('Got it'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Pick Color'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Add Client'),
              onPressed: () {
                _clients.add(Client(
                    name: _clientNameController.text,
                    color: Color(_clientColor.value)));
                FirebaseFirestore.instance.collection('clients').add({
                  'name': _clientNameController.text,
                  'color': _clientColor.value,
                }).then((_) {
                  // Handle successful addition
                  Navigator.of(context).pop();
                }).catchError((error) {
                  // Handle errors
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      for (var pinData in _allPins) {
        final String name = pinData.name;
        final double latitude = pinData.latitude;
        final double longitude = pinData.longitude;
        final String client = pinData.client;

        if (_selectedClients.isEmpty || _selectedClients.contains(client)) {
          if (_searchQuery == "" ||
              name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            int? tempColor;
            for (var i in _clients) {
              if (i.name == client) {
                tempColor = i.color.value;
                break;
              }
            }
            final int colorValue = tempColor ?? Colors.red.value;

            _markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(latitude, longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    _colorToHue(Color(colorValue))),
                infoWindow: InfoWindow(title: name),
              ),
            );
          }
        }
      }
    });
  }

  void _addPinToFirestore() {
    final String pinNameText = _pinNameController.text.trim();
    final String coordsText = _coordsController.text.trim();
    final regex = RegExp(r'^\s*-?\d+(\.\d+)?\s*[ ,]\s*-?\d+(\.\d+)?\s*$');

    if (pinNameText.isNotEmpty && _selectedClient != null) {
      if (regex.hasMatch(coordsText)) {
        final tempSplitString = coordsText
            .split(RegExp(r'\s*,\s*|\s+'))
            .map((s) => s.trim())
            .toList();
        log(tempSplitString[0].toString());
        log(tempSplitString[1].toString());

        FirebaseFirestore.instance.collection('allPins').add({
          'name': pinNameText,
          'latitude': double.parse(tempSplitString[0]),
          'longitude': double.parse(tempSplitString[1]),
          'client': _selectedClient,
        });
        _allPins.add(Pins(
            name: pinNameText,
            client: _selectedClient ?? '',
            latitude: double.parse(tempSplitString[0]),
            longitude: double.parse(tempSplitString[1])));
        _temporaryPinLocation = null;
        _pinNameController.clear();
        _coordsController.clear();
        _updateMarkers();
      } else if (_temporaryPinLocation != null) {
        FirebaseFirestore.instance.collection('allPins').add({
          'name': pinNameText,
          'latitude': _temporaryPinLocation!.latitude,
          'longitude': _temporaryPinLocation!.longitude,
          'client': _selectedClient,
        });
        _allPins.add(Pins(
            name: pinNameText,
            client: _selectedClient ?? '',
            latitude: _temporaryPinLocation!.latitude,
            longitude: _temporaryPinLocation!.longitude));
        _temporaryPinLocation = null;
        _pinNameController.clear();
        _coordsController.clear();
        _updateMarkers();
      }
    }
  }

  void _loadPinsFromFirestore() {
    FirebaseFirestore.instance
        .collection('allPins')
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String name = data['name'] ?? '';
        final double latitude = data['latitude'] ?? 0.0;
        final double longitude = data['longitude'] ?? 0.0;
        final String client = data['client'] ?? '';

        _allPins.add(Pins(
            name: name,
            client: client,
            latitude: latitude,
            longitude: longitude));
      }
      _updateMarkers();
    });
  }

  void _loadClients() {
    FirebaseFirestore.instance
        .collection('clients')
        .get()
        .then((querySnapshot) {
      List<Client> tempList = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String name = data['name'];
        int colorValue = data['color']; // Assuming color is stored as int
        tempList.add(Client(name: name, color: Color(colorValue)));
      }
      setState(() {
        _clients = tempList;
      });
    });
  }

  double _colorToHue(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  @override
  void dispose() {
    _pinNameController.dispose();
    super.dispose();
  }
}
