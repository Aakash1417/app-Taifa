import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class UploadDataPage extends StatefulWidget {
  @override
  _UploadDataPageState createState() => _UploadDataPageState();
}

class _UploadDataPageState extends State<UploadDataPage> {
  void _pickAndProcessCSV() async {
    // Use file_picker to let the user select a CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      // Get the file path from the result
      String? filePath = result.files.single.path;

      if (filePath != null) {
        // Read the file as a string using the File class
        String csvContent = await File(filePath).readAsString();

        // Use the csv package to parse the CSV file
        List<List<dynamic>> csvData =
            const CsvToListConverter().convert(csvContent);

        // Process the CSV data
        _processCSVData(csvData);
      }
    }
  }

  void _processCSVData(List<List<dynamic>> csvData) {
    // Implement your logic to process the CSV data
    print(csvData);

    // For example, print each row of the CSV file
    for (var row in csvData) {
      print(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _pickAndProcessCSV,
        child: Text('Upload CSV'),
      ),
    );
  }
}
