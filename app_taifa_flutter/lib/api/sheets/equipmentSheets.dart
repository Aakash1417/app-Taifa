import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gsheets/gsheets.dart';

class EquipmentSheetsApi {
  static final _spreadSheetId = dotenv.env['EQUIPMENT_SHEETS_ID'];
  static final _credentials = '''{
                       "type": "service_account",
                       "project_id": "${dotenv.env['project_id']}",
                       "private_key_id": "${dotenv.env['private_key_id']}",
                       "private_key": "${dotenv.env['private_key']}",
                       "client_email": "${dotenv.env['client_email']}",
                       "client_id": "${dotenv.env['client_id']}",
                       "auth_uri": "${dotenv.env['auth_uri']}",
                       "token_uri": "${dotenv.env['token_uri']}",
                       "auth_provider_x509_cert_url": "${dotenv.env['auth_provider_x509_cert_url']}",
                       "client_x509_cert_url": "${dotenv.env['client_x509_cert_url']}",
                       "universe_domain": "googleapis.com"
                     }''';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _equipmentSheet;

  static Future init() async {
    final spreadsheet = await _gsheets.spreadsheet(_spreadSheetId!);
    _equipmentSheet = await _getWorkSheet(spreadsheet, title: 'Sheet1');
    get_data();
  }

  static Future<Worksheet> _getWorkSheet(Spreadsheet spreadsheet,
      {required String title}) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return spreadsheet.worksheetByTitle(title)!;
    }
  }

  static Future<void> get_data() async {
    final json = _equipmentSheet!.values.row(2);
    json.then((value) {
      print(value);
    });
  }
}
