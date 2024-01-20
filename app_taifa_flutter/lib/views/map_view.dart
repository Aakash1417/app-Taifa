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

  String? _selectedClient;
  List<Pins> _allPins = [];
  List<String> _selectedClients = [];
  List<Client> _clients = [];
  String _searchQuery = "";
  bool addPinState = false;
  List<String?> previousPinState = [];

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
      appBar: addPinState
          ? null
          : AppBar(
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
                      return {'AddClient', 'AddPin'}.map((String choice) {
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
      floatingActionButton: addPinState
          ? Row(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    updateAddState(false);
                  },
                  child: const Icon(Icons.add),
                ),
                SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () {
                    updateAddState(false);
                    print(previousPinState);
                    _showAddPinDialog(
                        "", "", false, const Text('Add Pin'), true);
                  },
                  child: const Icon(Icons.cancel),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void updateAddState(bool val) {
    setState(() {
      addPinState = val;
    });
  }

  void _showMarkerContextMenu(Pins temp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(temp.name),
          children: [
            ListTile(
              title: Text('Client: ${temp.client}'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showAddPinDialog(temp.name, temp.client, false,
                    const Text('Edit Pin'), false);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                // TODO: add confirmation
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
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
    } else if (choice == 'AddPin') {
      updateAddState(true);
      _showAddPinDialog("", "", true, const Text('Add Pin'), false);
    }
  }

  void _onMapTap(LatLng latLng) {
    if (addPinState) {
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
  }

  Future<void> _showAddPinDialog(String? existingName, String? existingClient,
      bool addingPin, Text titleText, bool restorePreviousState) async {
    TextEditingController _pinNameController = TextEditingController();
    TextEditingController _coordsController = TextEditingController();

    if (restorePreviousState) {
      _pinNameController.text = previousPinState[0] ?? '';
      _coordsController.text = previousPinState[2] ?? '';
      previousPinState.clear();
    } else {
      if (!addingPin) {
        _pinNameController.text = existingName as String;
        _selectedClient = existingClient as String;
      } else {
        _selectedClient = null;
        updateAddState(false);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: titleText,
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
                  decoration: InputDecoration(
                      labelText: 'Coordinates (Optional)',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          updateAddState(true);
                          previousPinState.add(_pinNameController.text.trim());
                          previousPinState.add(_selectedClient?.trim());
                          previousPinState.add(_coordsController.text.trim());
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.touch_app),
                      )),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Add Pin'),
              onPressed: () async {
                String pinName = _pinNameController.text.trim();
                if (!(await pinExistenceCheck(pinName)) || !addingPin) {
                  _updatePinFirestore(_pinNameController.text.trim(),
                      _coordsController.text.trim());
                  Navigator.of(context).pop();
                } else {
                  showAlreadyExistsAlert(context, pinName, "pin");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showAlreadyExistsAlert(BuildContext context, String name, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('$type: $name already exists.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
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
      for (Pins pinData in _allPins) {
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
                infoWindow: InfoWindow(
                  title: name,
                  snippet: 'Client: $client',
                  onTap: () => _showMarkerContextMenu(pinData),
                ),
              ),
            );
          }
        }
      }
    });
  }

  void _updatePinFirestore(String n, String coords) {
    final String pinNameText = n;
    final String coordsText = coords;
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
          _selectedClient?.trim(),
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
      } else if (_temporaryPinLocation != null) {
        addPinToFirestore(
          pinNameText,
          _selectedClient?.trim(),
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
      }
      _updateMarkers();
    }
  }

  double _colorToHue(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  @override
  void dispose() {
    // _pinNameController.dispose();
    super.dispose();
  }
}
