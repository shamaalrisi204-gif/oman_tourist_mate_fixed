import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import '../services/trip_storage.dart';

class TripPlanScreen extends StatelessWidget {
  final MapTripPlan plan;
  final bool isArabic;
  const TripPlanScreen({super.key, required this.plan, required this.isArabic});
  @override
  Widget build(BuildContext context) {
    final t = (String k) => isArabic ? _ar[k]! : _en[k]!;
    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'تفاصيل الخطة' : 'Trip plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(t('category'), _catName(plan.category, isArabic)),
            const SizedBox(height: 8),
            _row(t('place'), '${plan.placeName} (${plan.placeCity})'),
            const SizedBox(height: 8),
            _row(t('stay_city'), plan.stayCity),
            const SizedBox(height: 8),
            _row(t('will_book'), plan.willBookHere ? t('yes') : t('no')),
            const SizedBox(height: 8),
            _row(t('hours'), '${plan.hours}'),
            const SizedBox(height: 8),
            _row(t('eta'), '${plan.etaMinutes} ${t('minutes')}'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bookmark_added_outlined),
                    label: Text(t('save')),
                    onPressed: () async {
                      await TripStorage.savePlan(plan);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('saved_ok'))),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: Text(t('back')),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) => Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: Text(value)),
        ],
      );
  String _catName(String c, bool ar) {
    if (c == 'sea') return ar ? 'البحر' : 'Sea';
    if (c == 'desert') return ar ? 'البر/الصحاري' : 'Desert';
    return ar ? 'تاريخي' : 'Historic';
  }
}

const _ar = {
  'category': 'التصنيف',
  'place': 'المكان',
  'stay_city': 'مدينة السكن',
  'will_book': 'حجز في نفس المكان؟',
  'hours': 'عدد الساعات',
  'eta': 'مدة القيادة',
  'minutes': 'دقيقة',
  'save': 'حفظ الخطة',
  'saved_ok': 'تم حفظ الخطة ✅',
  'back': 'رجوع',
  'yes': 'نعم',
  'no': 'لا',
};
const _en = {
  'category': 'Category',
  'place': 'Place',
  'stay_city': 'Stay city',
  'will_book': 'Book at same place?',
  'hours': 'Hours',
  'eta': 'Drive time',
  'minutes': 'min',
  'save': 'Save plan',
  'saved_ok': 'Plan saved ✅',
  'back': 'Back',
  'yes': 'Yes',
  'no': 'No',
};
