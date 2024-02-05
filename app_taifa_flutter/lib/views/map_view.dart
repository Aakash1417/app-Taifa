import 'dart:async';

import 'package:app_taifa_flutter/views/signin.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../database_helper.dart';
import '../objects/Client.dart';
import '../objects/Colors.dart';
import '../objects/MapsOptions.dart';
import '../objects/Pins.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Set<Marker> _markers = {};
  LatLng? _temporaryPinLocation;
  List<Color> colorList = getAllColors();
  List<Pins> _allPins = [];
  List<String> _selectedClients = [];
  List<Client> _clients = [];
  String _searchQuery = "";
  bool _addPinState = false;
  List<String?> previousPinState = []; // name, client, coordinates
  late GoogleMapController _mapController;
  double _myLocationPadding = 0;
  FocusNode _searchFocusNode = FocusNode();

  MapType _currentMapType = MapType.normal;
  TextEditingController _searchFilterController = TextEditingController();
  List<String> suggestionList = [];
  List<String> filteredSuggestions = [];
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
    loadClients().then((List<Client>? castedClients) {
      _clients = castedClients ?? [];
      _updateMarkers();
    });
    loadPinsFromFirestore().then((List<dynamic>? things) {
      if (things?.length == 2) {
        _allPins = things?[0] ?? [];
        suggestionList = things?[1] ?? [];
      }
      _updateMarkers();
    });
    getCurrentLocation().then((value) => {}).catchError((e) => {});
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied!');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are denied forever, cannot request location!');
    }
    // Position temp = await Geolocator.getCurrentPosition();
    // _currLocation = LatLng(temp.latitude.toDouble(), temp.longitude.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _addPinState
          ? null
          : AppBar(
              title: TextField(
                controller: _searchFilterController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onTap: () {
                  setState(() {
                    isSearchActive = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Pins',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showClientFilterDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _updateMarkers();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                // if (SignInScreenState.perms != null &&
                //     SignInScreenState.perms!.contains("AddClient"))
                PopupMenuButton<String>(
                  onSelected: _handleMenuSelection,
                  itemBuilder: (BuildContext context) {
                    return Options.values.map((Options choice) {
                      return PopupMenuItem<String>(
                        value: choice.stringValue,
                        child: Text(choice.stringValue),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Dismiss search and suggestion list when clicking on the map
              setState(() {
                isSearchActive = false;
              });
              _searchFocusNode.unfocus(); // Unfocus the search field
            },
            child: GoogleMap(
              onTap: _onMapTap,
              onMapCreated: (GoogleMapController contr) {
                _mapController = contr;
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(53.492412, -113.496737),
                // Initial map position
                zoom: 8.0,
              ),
              markers: _markers,
              mapType: _currentMapType,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              padding: EdgeInsets.only(top: _myLocationPadding),
            ),
          ),
          Visibility(
            visible: isSearchActive && filteredSuggestions.isNotEmpty,
            child: Positioned(
              top: 0,
              left: 60,
              right: 60,
              child: Card(
                elevation: 4.0,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(filteredSuggestions[index]),
                      onDismissed: (direction) {
                        _onSuggestionSelected(filteredSuggestions[index]);
                      },
                      child: ListTile(
                        title: Text(filteredSuggestions[index]),
                        onTap: () {
                          _onSuggestionSelected(filteredSuggestions[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: _addPinState
          ? Row(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    final temp = _temporaryPinLocation;
                    if (temp != null) {
                      updateAddState(false);
                      previousPinState[2] =
                          "${temp.latitude}, ${temp.longitude}";
                      if (previousPinState[4] == '0') {
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
                    if (previousPinState[4] == '0') {
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

  void _onSuggestionSelected(String selectedSuggestion) {
    setState(() {
      _searchFilterController.text = selectedSuggestion;
      filteredSuggestions = [];
    });
    isSearchActive = false;
    _searchQuery = selectedSuggestion;
    _updateMarkers();
  }

  List<String> getAutofillSuggestions(String input) {
    final fuz = Fuzzy<String>(
      suggestionList,
      options: FuzzyOptions(threshold: 0.3),
    );

    final results = fuz.search(input);
    List<String> temp = results.map((result) => result.item).toList();

    return temp.sublist(0, temp.length > 4 ? 4 : temp.length);
  }

  void updateAddState(bool val) {
    setState(() {
      _addPinState = val;
      if (!_addPinState) {
        _temporaryPinLocation = null;
        _updateMarkers();
        _myLocationPadding = 0;
      } else {
        _myLocationPadding = 75;
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
                previousPinState.add(temp.description);

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
    isSearchActive = true;
    _searchQuery = query;
    setState(() {
      filteredSuggestions = getAutofillSuggestions(query);
    });
  }

  void _showClientFilterDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
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
              ),
            ));
  }

  void _handleMenuSelection(String choice) {
    if (choice == Options.addClient.stringValue) {
      _showAddClientDialog();
    } else if (choice == Options.addPin.stringValue) {
      previousPinState.clear();
      _showAddPinDialog(const Text('Add Pin'), false, false);
    } else if (choice == Options.switchView.stringValue) {
      switchMapViewMode();
    }
  }

  void setMapType(MapType x) {
    setState(() {
      _currentMapType = x;
    });
  }

  void switchMapViewMode() {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Map View Mode'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Select Map Type:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Normal'),
                    Switch(
                      value: _currentMapType != MapType.normal,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            setMapType(MapType.satellite);
                          } else {
                            setMapType(MapType.normal);
                          }
                        });
                      },
                    ),
                    const Text('Satellite'),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      isSearchActive = false;
    });
    if (_addPinState) {
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
    TextEditingController descriptionController = TextEditingController();
    String? asdfg;

    if (restorePreviousState) {
      pinNameController.text = previousPinState[0] ?? '';
      asdfg = previousPinState[1];
      coordsController.text = previousPinState[2] ?? '';
      descriptionController.text = previousPinState[3] ?? '';
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
                          Text(client.name.length > 15
                              ? '${client.name.substring(0, 15)}...'
                              : client.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: coordsController,
                  decoration: InputDecoration(
                      labelText: 'Coordinates',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          updateAddState(true);
                          previousPinState.add(pinNameController.text.trim());
                          previousPinState.add(asdfg?.trim());
                          previousPinState.add(coordsController.text.trim());
                          previousPinState
                              .add(descriptionController.text.trim());
                          previousPinState.add(editMode ? '1' : '0');
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.touch_app),
                      )),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description (Optional)'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: editMode ? const Text('Save') : const Text('Add Pin'),
              onPressed: () async {
                String pinName = pinNameController.text.trim();
                if (!(await pinExistenceCheck(pinName)) || editMode) {
                  if (pinName != "") {
                    if (asdfg != null && asdfg != "") {
                      if (validateRegex(coordsController.text.trim())) {
                        _updatePinFirestore(
                          pinNameController.text.trim(),
                          coordsController.text.trim(),
                          asdfg,
                          descriptionController.text.trim(),
                        );
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
      builder: (BuildContext context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                title: const Text('Add Client'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      TextField(
                        controller: clientNameController,
                        decoration:
                            const InputDecoration(labelText: 'Client Name'),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pick a color!'),
                                content: SizedBox(
                                  height: 300,
                                  // Adjust the height as needed
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: colorList.map((color) {
                                        return ListTile(
                                          title: Text(
                                              'Color ${colorList.indexOf(color) + 1}'),
                                          tileColor: color,
                                          onTap: () {
                                            setState(() {
                                              clientColor = color;
                                            });
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: clientColor,
                        ),
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
              )),
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

  void _updatePinFirestore(String pinNameText, String coordsText,
      String? selClient, String descriptionText) {
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
          descriptionText,
        );
        _allPins.add(Pins(
          name: pinNameText,
          client: selClient,
          latitude: double.parse(tempSplitString[0]),
          longitude: double.parse(tempSplitString[1]),
          lastUpdated: DateTime.now(),
          createdBy: SignInScreenState.currentUser!.email ?? '',
          description: descriptionText,
        ));
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
    _searchFocusNode.dispose();
    super.dispose();
  }
}
