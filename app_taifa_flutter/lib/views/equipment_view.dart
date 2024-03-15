// import 'package:flutter/material.dart';
//
// import '../api/sheets/equipmentSheets.dart';
//
// class CalibratorPage extends StatefulWidget {
//   const CalibratorPage({Key? key}) : super(key: key);
//
//   @override
//   _CalibratorPageState createState() => _CalibratorPageState();
// }
//
// class _CalibratorPageState extends State<CalibratorPage> {
//   final TextEditingController _input1Controller = TextEditingController();
//   final TextEditingController _input2Controller = TextEditingController();
//   final TextEditingController _input3Controller = TextEditingController();
//   List<Map<String, String>> _results = [];
//
//   void fetchData(
//       String serialNumber, String make, String equipmentNumber) async {
//     var allRows = await EquipmentSheetsApi.fetchAllRows();
//     var data;
//     print(allRows?[4]);
//   }
//
//   void _showDetails(String detail) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Details'),
//           content: Text(detail),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Close'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Calibration Check'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: <Widget>[
//             TextField(
//               controller: _input1Controller,
//               decoration: const InputDecoration(labelText: 'Equipment #'),
//             ),
//             TextField(
//               controller: _input2Controller,
//               decoration: const InputDecoration(labelText: 'Serial Number'),
//             ),
//             TextField(
//               controller: _input3Controller,
//               decoration: const InputDecoration(labelText: 'Make/Model'),
//             ),
//             ElevatedButton(
//               onPressed: () => {fetchData('', '', 'EQ103')},
//               child: const Text('Search'),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _results.length,
//                 itemBuilder: (context, index) {
//                   final result = _results[index];
//                   return ListTile(
//                     title:
//                         Text('${result['name']} (${result['age']} years old)'),
//                     onTap: () => _showDetails(result['detail']!),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
