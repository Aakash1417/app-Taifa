import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsPage extends StatefulWidget {
  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Set<Marker> _markers = {};
  LatLng? _temporaryPinLocation;
  TextEditingController _pinNameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  String? _selectedCategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadPinsFromFirestore();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return {'Add Category'}.map((String choice) {
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
        onPressed: _temporaryPinLocation == null
            ? null
            : () {
                _showAddPinDialog();
              },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _handleMenuSelection(String choice) {
    if (choice == 'Add Category') {
      _showAddCategoryDialog();
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
    if (_temporaryPinLocation == null) return;

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
                  value: _selectedCategory,
                  hint: Text(_selectedCategory ?? "Select Category"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  onSaved: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  items: _categories
                      .map<DropdownMenuItem<String>>((Category category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: category.color,
                            radius: 10,
                          ),
                          SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
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

  Future<void> _showAddCategoryDialog() async {
    TextEditingController _categoryNameController = TextEditingController();
    Color _categoryColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
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
                              pickerColor: _categoryColor,
                              onColorChanged: (Color color) {
                                _categoryColor = color;
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
              child: const Text('Add Category'),
              onPressed: () {
                _categories.add(Category(
                    name: _categoryNameController.text,
                    color: Color(_categoryColor.value)));
                FirebaseFirestore.instance.collection('categories').add({
                  'name': _categoryNameController.text,
                  'color': _categoryColor.value,
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

  void _addPinToFirestore() {
    final String pinName = _pinNameController.text.trim();
    if (pinName.isNotEmpty &&
        _temporaryPinLocation != null &&
        _selectedCategory != null) {
      FirebaseFirestore.instance.collection('allPins').add({
        'name': pinName,
        'latitude': _temporaryPinLocation!.latitude,
        'longitude': _temporaryPinLocation!.longitude,
        'category': _selectedCategory,
      });
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(pinName),
            position: _temporaryPinLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                _colorToHue(_selectedColor)),
            infoWindow: InfoWindow(title: pinName),
          ),
        );
        _temporaryPinLocation = null;
        _pinNameController.clear();
      });
    }
  }

  double _colorToHue(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  void _loadPinsFromFirestore() {
    FirebaseFirestore.instance
        .collection('allPins')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _markers.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String name = data['name'] ?? '';
          final double latitude = data['latitude'] ?? 0.0;
          final double longitude = data['longitude'] ?? 0.0;
          final String category = data['category'] ?? '';
          int? temp;
          for (var item in _categories) {
            if (item.name == category) {
              temp = item.color.value;
            }
          }
          final int colorValue = temp ?? Colors.red.value;

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
      });
    });
  }

  void _loadCategories() {
    FirebaseFirestore.instance
        .collection('categories')
        .get()
        .then((querySnapshot) {
      List<Category> tempList = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String name = data['name'];
        int colorValue = data['color']; // Assuming color is stored as int
        tempList.add(Category(name: name, color: Color(colorValue)));
      }
      setState(() {
        _categories = tempList;
      });
    });
  }

  @override
  void dispose() {
    _pinNameController.dispose();
    super.dispose();
  }
}

class Category {
  String name;
  Color color;

  Category({required this.name, required this.color});
}
