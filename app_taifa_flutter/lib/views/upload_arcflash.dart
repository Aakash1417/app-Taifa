import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
      String? filePath = result.files.single.path;

      if (filePath != null) {
        String csvContent = await File(filePath).readAsString();
        List<List<dynamic>> csvData =
            const CsvToListConverter().convert(csvContent);
        _processCSVData(csvData);
      }
    }
  }

  void _processCSVData(List<List<dynamic>> csvData) {
    for (var row in csvData) {
      // Assume the first column contains the ID
      String id = row[0].toString();

      final pdf = pw.Document();

      // Add a page with the QR code in the middle
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 200,
                height: 200,
                child: pw.BarcodeWidget(
                    data: "www.google.com",
                    barcode: pw.Barcode.qrCode(),
                    width: 100,
                    height: 100),
              ),
            );
          },
        ),
      );
      _savePdfFile(pdf, 'QR_Code_$id');
    }
  }

  // for android, and ios maybe?
  Future<void> _savePdfFile(pw.Document pdf, String fileName) async {
    final directory = (await getExternalStorageDirectory())?.path ?? '';

    // Create the Downloads folder if it doesn't exist
    final downloadsDirectory = Directory('$directory/Downloads');
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync();
    }
    final filePath = '${downloadsDirectory.path}/$fileName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save(), flush: true);
    OpenFile.open(filePath);

    // Print the file path for debugging purposes
    print('PDF saved: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _pickAndProcessCSV,
        child: const Text('Upload CSV'),
      ),
    );
  }
}
