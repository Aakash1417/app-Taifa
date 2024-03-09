import 'package:flutter/material.dart';
import 'add_admin_page.dart';
import 'upload_arcflash.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _selectedTask = 'Add Admin';

  Widget _getTaskPage() {
    switch (_selectedTask) {
      case 'Add Admin':
        return AddAdminPage();
      case 'Upload Data':
        return UploadDataPage();
      default:
        return AddAdminPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedTask,
            onChanged: (String? newValue) {
              setState(() {
                _selectedTask = newValue!;
              });
            },
            items: <String>['Add Admin', 'Upload Data']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(child: _getTaskPage()),
        ],
      ),
    );
  }
}
