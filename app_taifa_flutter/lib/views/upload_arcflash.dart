import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:app_taifa_flutter/objects/ArcFlashData.dart';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

import '../database_helper.dart';

class UploadDataPage extends StatefulWidget {
  @override
  _UploadDataPageState createState() => _UploadDataPageState();
}

class _UploadDataPageState extends State<UploadDataPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ArcFlashData> _arcflashs = [];
  int _currentPage = 1;
  int _totalPages = 0;
  static const int pageSize = 12;

  @override
  void initState() {
    super.initState();
    fetchAllArcFlashs();
  }

  void _pickAndProcessCSV() async {
    // Use file_picker to let the user select a CSV file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String csvContent = '';
      if (kIsWeb) {
        Uint8List? fileBytes = result.files.single.bytes;
        if (fileBytes != null) {
          // For web, use the bytes directly
          csvContent = String.fromCharCodes(fileBytes);
        }
      } else {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          csvContent = await io.File(filePath).readAsString();
        }
      }
      List<List<dynamic>> csvData =
          const CsvToListConverter().convert(csvContent);
      _processCSVData(csvData);
    }
  }

  bool _validateArcFlash(ArcFlashData data) {
    return true;
  }

  void _processCSVData(List<List<dynamic>> csvData) async {
    final archive = Archive();
    List<dynamic> header = [];
    bool headerSet = false;
    for (var row in csvData) {
      if (!headerSet) {
        header = row;
        headerSet = true;
        continue;
      }
      ArcFlashData data = ArcFlashData(
        id: row[0].toString().toLowerCase(),
        dangerType: row[1].toString(),
        workingDistance: row[2].toString(),
        incidentEnergy: row[3].toString(),
        arcFlashBoundary: row[4].toString(),
        shockHazard: row[5].toString(),
        limitedApproach: row[6].toString(),
        restrictedApproach: row[7].toString(),
        gloveClass: row[8].toString(),
        equipment: row[9].toString(),
        date: row[10].toString(),
        standard: row[11].toString(),
        file: row[12].toString(),
      );
      if (!_validateArcFlash(data)) {
        continue;
      }

      final pdf = generatePdf(data);

      // Save the PDF to a byte array
      final pdfBytes = await pdf.save();
      final fileName = 'QR_Code_${data.id}.pdf';

      addArcFlashAnalysisToFirestore(data);

      // Add the PDF to the zip archive
      archive.addFile(ArchiveFile(fileName, pdfBytes.length, pdfBytes));
    }
    await _saveZipFile(archive, 'sdasd.zip');
  }

  pw.Document generatePdf(ArcFlashData data) {
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
    return pdf;
  }

  Future<void> _saveZipFile(Archive archiveDoc, String fileName) async {
    if (kIsWeb) {
      // For web
      final zipBytes = ZipEncoder().encode(archiveDoc);
      if (zipBytes != null) {
        final base64Zip = base64.encode(zipBytes);
        final href =
            'data:application/octet-stream;charset=utf-16le;base64,$base64Zip';
        final anchor = html.AnchorElement(href: href)
          ..setAttribute('download', 'archive.zip')
          ..click();
        html.Url.revokeObjectUrl(href);
        print('Zip archive downloaded');
      }
    }
    // if (kIsWeb) {
    //   // For web
    //   Uint8List bytes = await pdf.save();
    //   html.AnchorElement(
    //       href:
    //           "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}")
    //     ..setAttribute("download", fileName)
    //     ..click();
    //   print('PDF saved: $fileName web');
    // } else {
    //   // For mobile
    //   final directory = (await getExternalStorageDirectory())?.path ?? '';
    //   final filePath = '$directory/$fileName';
    //   final file = io.File(filePath);
    //   await file.writeAsBytes(await pdf.save(), flush: true);
    //   OpenFile.open(filePath);
    //   // Print the file path for debugging purposes
    //   print('PDF saved: $filePath');
    // }
  }

  Future<void> fetchAllArcFlashs() async {
    String? searchTerm =
        _searchController.text.isEmpty ? null : _searchController.text;
    var fetchedData = await getArcFlashStudies(_currentPage, pageSize);
    if (fetchedData != null && fetchedData.isNotEmpty) {
      setState(() {
        _arcflashs = fetchedData;
      });
    }
  }

  void _onSearch() {
    fetchAllArcFlashs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickAndProcessCSV,
            child: const Text('Upload CSV'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Search",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _arcflashs.length,
              itemBuilder: (context, index) {
                var arcflash = _arcflashs[index];
                return ListTile(
                  title: Text(arcflash.id ?? 'No equipment'),
                  subtitle: Text('Date: ${arcflash.date}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      final archive = Archive();
                      final pdf = generatePdf(arcflash);
                      final pdfBytes = await pdf.save();
                      final fileName = 'QR_Code_${arcflash.id}.pdf';
                      addArcFlashAnalysisToFirestore(arcflash);
                      archive.addFile(
                          ArchiveFile(fileName, pdfBytes.length, pdfBytes));
                      await _saveZipFile(archive, 'sdasd.zip');
                    },
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                          fetchAllArcFlashs();
                        });
                      }
                    : null,
              ),
              Text('Page $_currentPage'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    _currentPage++;
                    fetchAllArcFlashs();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
