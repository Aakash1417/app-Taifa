import 'package:cloud_firestore/cloud_firestore.dart';

class ArcFlashData {
  String id;
  String dangerType;
  String workingDistance;
  String incidentEnergy;
  String arcFlashBoundary;
  String shockHazard;
  String limitedApproach;
  String restrictedApproach;
  String gloveClass;
  String equipment;
  String date;
  String standard;
  String file;

  ArcFlashData({
    required this.id,
    required this.dangerType,
    required this.workingDistance,
    required this.incidentEnergy,
    required this.arcFlashBoundary,
    required this.shockHazard,
    required this.limitedApproach,
    required this.restrictedApproach,
    required this.gloveClass,
    required this.equipment,
    required this.date,
    required this.standard,
    required this.file,
  });

  factory ArcFlashData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ArcFlashData(
      id: doc.id,
      dangerType: data['dangerType'],
      workingDistance: data['workingDistance'],
      incidentEnergy: data['incidentEnergy'],
      arcFlashBoundary: data['arcFlashBoundary'],
      shockHazard: data['shockHazard'],
      limitedApproach: data['limitedApproach'],
      restrictedApproach: data['restrictedApproach'],
      gloveClass: data['gloveClass'],
      equipment: data['equipment'],
      date: data['date'],
      standard: data['standard'],
      file: data['file'],
    );
  }
}
