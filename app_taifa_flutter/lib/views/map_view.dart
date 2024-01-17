import 'dart:async';
import 'dart:developer';

import 'package:app_taifa_flutter/views/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../database_helper.dart';
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
    loadClients().then((List<Client>? castedClients) {
      _clients = castedClients ?? [];
      _updateMarkers();
    });
    loadPinsFromFirestore().then((List<Pins>? castedPins) {
      _allPins = castedPins ?? [];
      _updateMarkers();
    });
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
          if (SignInScreenState.perms != null &&
              SignInScreenState.perms!.contains("AddClient"))
            PopupMenuButton<String>(
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) {
                return {'AddClient'}.map((String choice) {
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
    if (choice == 'AddClient') {
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
                _updatePinFirestore();
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
                    color: Color(_clientColor.value),
                    lastUpdated: DateTime.now()));
                addClientToFirestore(
                    _clientNameController.text, _clientColor.value);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateMarkers() {
    _markers.clear();
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

  void _updatePinFirestore() {
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

        addPinToFirestore(
          pinNameText,
          _selectedClient,
          double.parse(tempSplitString[0]),
          double.parse(tempSplitString[1]),
        );
        _allPins.add(Pins(
            name: pinNameText,
            client: _selectedClient ?? '',
            latitude: double.parse(tempSplitString[0]),
            longitude: double.parse(tempSplitString[1]),
            lastUpdated: DateTime.now(),
            createdBy: SignInScreenState.currentUser!.email ?? ''));
        _temporaryPinLocation = null;
        _pinNameController.clear();
        _coordsController.clear();
        _updateMarkers();
      } else if (_temporaryPinLocation != null) {
        addPinToFirestore(
          pinNameText,
          _selectedClient,
          _temporaryPinLocation!.latitude,
          _temporaryPinLocation!.longitude,
        );
        _allPins.add(
          Pins(
              name: pinNameText,
              client: _selectedClient ?? '',
              latitude: _temporaryPinLocation!.latitude,
              longitude: _temporaryPinLocation!.longitude,
              lastUpdated: DateTime.now(),
              createdBy: SignInScreenState.currentUser!.email ?? ''),
        );
        _temporaryPinLocation = null;
        _pinNameController.clear();
        _coordsController.clear();
        _updateMarkers();
      }
    }
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
