import 'package:flutter/material.dart';

class TripSummaryCard extends StatelessWidget {
  final String title;

  final int daysCount;

  final int placesCount;

  final String headerImageAsset;

  final VoidCallback? onTap;

  const TripSummaryCard({
    super.key,
    required this.title,
    required this.daysCount,
    required this.placesCount,
    required this.headerImageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------- صورة الهيدر -------

            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.asset(
                headerImageAsset,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // ------- النصوص -------

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        "$placesCount موقع",
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.calendar_month,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        "$daysCount أيام",
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
