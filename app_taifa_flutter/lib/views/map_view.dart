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

  List<Pins> _allPins = [];
  List<String> _selectedClients = [];
  List<Client> _clients = [];
  String _searchQuery = "";
  bool addPinState = false;
  List<String?> previousPinState = []; // name, client, coordinates

  MapType _currentMapType = MapType.normal;

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
                // if (SignInScreenState.perms != null &&
                //     SignInScreenState.perms!.contains("AddClient"))
                PopupMenuButton<String>(
                  onSelected: _handleMenuSelection,
                  itemBuilder: (BuildContext context) {
                    return {'AddClient', 'AddPin', "SwitchView"}
                        .map((String choice) {
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
        mapType: _currentMapType,
      ),
      floatingActionButton: addPinState
          ? Row(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    final temp = _temporaryPinLocation;
                    if (temp != null) {
                      updateAddState(false);
                      previousPinState[2] =
                          "${temp.latitude}, ${temp.longitude}";
                      if (previousPinState[3] == '0') {
                        _showAddPinDialog(const Text('Add Pin'), true, false);
                      } else {
                        _showAddPinDialog(const Text('Edit Pin'), true, true);
                      }
                    }
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () {
                    updateAddState(false);
                    if (previousPinState[3] == '0') {
                      _showAddPinDialog(const Text('Add Pin'), true, false);
                    } else {
                      _showAddPinDialog(const Text('Edit Pin'), true, true);
                    }
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
      if (!addPinState) {
        _temporaryPinLocation = null;
        _updateMarkers();
      }
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                previousPinState.add(temp.name);
                previousPinState.add(temp.client);
                previousPinState.add("${temp.latitude}, ${temp.longitude}");

                _showAddPinDialog(const Text('Edit Pin'), true, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                removePinFirebase(temp.name);
                _allPins.removeWhere((pin) => pin.name == temp.name);
                _updateMarkers();
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
      previousPinState.clear();
      _showAddPinDialog(const Text('Add Pin'), false, false);
    } else if (choice == 'SwitchView') {
      switchMapViewMode();
    }
  }

  void switchMapViewMode() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Map View Mode'),
          content: Column(
            children: [
              const Text('Select Map Type:'),
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 4.0,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: _currentMapType == MapType.normal ? 0.0 : 1.0,
                  onChanged: (value) {
                    setState(() {
                      _currentMapType =
                          value == 0.0 ? MapType.normal : MapType.satellite;
                    });
                  },
                  min: 0.0,
                  max: 1.0,
                  divisions: 1,
                  label: _currentMapType == MapType.normal
                      ? 'Normal'
                      : 'Satellite',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  Future<void> _showAddPinDialog(
      Text titleText, bool restorePreviousState, bool editMode) async {
    TextEditingController pinNameController = TextEditingController();
    TextEditingController coordsController = TextEditingController();
    String? asdfg;

    if (restorePreviousState) {
      pinNameController.text = previousPinState[0] ?? '';
      asdfg = previousPinState[1];
      coordsController.text = previousPinState[2] ?? '';
      previousPinState.clear();
    }
    updateAddState(false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: titleText,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  readOnly: editMode,
                  controller: pinNameController,
                  decoration: const InputDecoration(labelText: 'Pin Name'),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: asdfg,
                  hint: Text(asdfg ?? "Select Client"),
                  onChanged: (String? newValue) {
                    setState(() {
                      asdfg = newValue;
                    });
                  },
                  onSaved: (String? newValue) {
                    setState(() {
                      asdfg = newValue;
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
                  controller: coordsController,
                  decoration: InputDecoration(
                      labelText: 'Coordinates (Optional)',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          updateAddState(true);
                          previousPinState.add(pinNameController.text.trim());
                          previousPinState.add(asdfg?.trim());
                          previousPinState.add(coordsController.text.trim());
                          previousPinState.add(editMode ? '1' : '0');
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.touch_app),
                      )),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Add Pin'),
              onPressed: () async {
                String pinName = pinNameController.text.trim();
                if (!(await pinExistenceCheck(pinName)) || editMode) {
                  if (pinName != "") {
                    if (asdfg != null && asdfg != "") {
                      if (validateRegex(coordsController.text.trim())) {
                        _updatePinFirestore(pinNameController.text.trim(),
                            coordsController.text.trim(), asdfg);
                        Navigator.of(context).pop();
                      } else {
                        showAlert(context,
                            "Invalid coordinates! must be of form: lat, long");
                      }
                    } else {
                      showAlert(context, "Invalid client selected");
                    }
                  } else {
                    showAlert(context, "Invalid pin Name");
                  }
                } else {
                  showAlert(context, '$pinName: pin already exists.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool validateRegex(String expression) {
    if (RegExp(r'^\s*-?\d+(\.\d+)?\s*[ ,]\s*-?\d+(\.\d+)?\s*$')
        .hasMatch(expression)) {
      final tempSplitString = expression
          .split(RegExp(r'\s*,\s*|\s+'))
          .map((s) => s.trim())
          .toList();
      try {
        double firstCoordinate = double.parse(tempSplitString[0]);
        double secondCoordinate = double.parse(tempSplitString[1]);
        if (firstCoordinate >= -90 &&
            firstCoordinate <= 90 &&
            secondCoordinate >= -180 &&
            secondCoordinate < 180) {
          return true;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  void showAlert(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: Text(text),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddClientDialog() async {
    TextEditingController clientNameController = TextEditingController();
    Color clientColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Client'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: clientNameController,
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
                              pickerColor: clientColor,
                              onColorChanged: (Color color) {
                                clientColor = color;
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
                    name: clientNameController.text,
                    color: Color(clientColor.value),
                    lastUpdated: DateTime.now()));
                addClientToFirestore(
                    clientNameController.text, clientColor.value);
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

  void _updatePinFirestore(
      String pinNameText, String coordsText, String? selClient) {
    final regex = RegExp(r'^\s*-?\d+(\.\d+)?\s*[ ,]\s*-?\d+(\.\d+)?\s*$');

    if (pinNameText.isNotEmpty && selClient != null) {
      if (regex.hasMatch(coordsText)) {
        final tempSplitString = coordsText
            .split(RegExp(r'\s*,\s*|\s+'))
            .map((s) => s.trim())
            .toList();

        addPinToFirestore(
          pinNameText,
          selClient.trim(),
          double.parse(tempSplitString[0]),
          double.parse(tempSplitString[1]),
        );
        _allPins.add(Pins(
            name: pinNameText,
            client: selClient,
            latitude: double.parse(tempSplitString[0]),
            longitude: double.parse(tempSplitString[1]),
            lastUpdated: DateTime.now(),
            createdBy: SignInScreenState.currentUser!.email ?? ''));
        _temporaryPinLocation = null;
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
    super.dispose();
  }
}
