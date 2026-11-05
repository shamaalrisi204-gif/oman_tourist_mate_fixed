import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;

  final String titleAr;

  final String titleEn;

  final String descriptionAr;

  final String descriptionEn;

  final String locationName;

  final String imageUrl;

  final String sourceUrl;

  final DateTime? startAt;

  final bool isFeatured;

  const EventModel({
    required this.id,
    this.titleAr = '',
    this.titleEn = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.locationName = '',
    this.imageUrl = '',
    this.sourceUrl = '',
    this.startAt,
    this.isFeatured = false,
  });

  factory EventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    DateTime? date;

    final value = data['startAt'];

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    return EventModel(
      id: doc.id,
      titleAr: data['titleAr']?.toString() ?? '',
      titleEn: data['titleEn']?.toString() ?? '',
      descriptionAr: data['descriptionAr']?.toString() ?? '',
      descriptionEn: data['descriptionEn']?.toString() ?? '',
      locationName: data['locationName']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      sourceUrl: data['sourceUrl']?.toString() ?? '',
      startAt: date,
      isFeatured: data['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titleAr': titleAr,
      'titleEn': titleEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'locationName': locationName,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
      'isFeatured': isFeatured,
    };
  }
}
