import 'package:flutter/material.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  bool _isArabic = true;

  final TextEditingController _amountCtrl = TextEditingController();

  String _from = 'SAR';

  String _to = 'OMR';

  String _resultText = '-';

  // أسعار تقريبية بالنسبة للريال العماني (OMR)

  final Map<String, double> _toOmrRate = {
    'OMR': 1.0,

    'USD': 0.384, // 1 USD = 0.384 OMR تقريباً

    'EUR': 0.41,

    'SAR': 0.1026,

    'AED': 0.1047,
  };

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  void dispose() {
    _amountCtrl.dispose();

    super.dispose();
  }

  void _toggleLang() {
    setState(() => _isArabic = !_isArabic);
  }

  void _reset() {
    setState(() {
      _amountCtrl.clear();

      _from = 'SAR';

      _to = 'OMR';

      _resultText = '-';
    });
  }

  void _convert() {
    final raw = _amountCtrl.text.trim();

    if (raw.isEmpty) {
      setState(() => _resultText = '-');

      return;
    }

    final value = double.tryParse(raw.replaceAll(',', '.'));

    if (value == null) {
      setState(() => _resultText = _tr('القيمة غير صحيحة', 'Invalid amount'));

      return;
    }

    final fromRate = _toOmrRate[_from] ?? 1.0;

    final toRate = _toOmrRate[_to] ?? 1.0;

    // أولاً نحول من العملة الأصلية إلى OMR ثم من OMR إلى العملة الهدف

    final omrAmount = value * fromRate;

    final targetAmount = omrAmount / toRate;

    setState(() {
      _resultText = '${targetAmount.toStringAsFixed(2)} $_to';
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _tr('محوّل العملات', 'Currency Converter');

    final subtitle = _tr(
      'حوّلي ميزانيتك بين العملات بسهولة.',
      'Easily convert your travel budget between currencies.',
    );

    final heroTitle = _tr(
      'ميزانيتك بالريال العُماني',
      'Your budget in Omani Rial',
    );

    final heroSub = _tr(
      'اعملي حسابك قبل الرحلة، وبدلي بين عملات السفر براحة.',
      'Plan your budget before the trip and convert between currencies comfortably.',
    );

    final fromLabel = _tr('من', 'From');

    final toLabel = _tr('إلى', 'To');

    final amountLabel = _tr('المبلغ', 'Amount');

    final convertNow = _tr('تحويل الآن', 'Convert now');

    final resetLabel = _tr('استرجاع', 'Reset');

    final resultLabel = _tr('النتيجة:', 'Result:');

    final currencies = ['OMR', 'USD', 'EUR', 'SAR', 'AED'];

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,

          elevation: 0,

          centerTitle: true,

          // زر الرجوع

          leading: IconButton(
            icon: Icon(
              _isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // العنوان

          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),

          // زر تغيير اللغة يمين

          actions: [
            TextButton(
              onPressed: _toggleLang,
              child: Text(
                _isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // الخلفية المزخرفة

            Image.asset(
              'assets/images/currency_bg.png', // غيّري الاسم حسب ملفك

              fit: BoxFit.cover,
            ),

            // طبقة بيضاء خفيفة فوق الخلفية

            Container(
              color: Colors.white.withOpacity(0.85),
            ),

            // المحتوى

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // كرت العملة العمانية

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/omr_notes.jpg', // صورة العملات

                            height: 120,

                            width: double.infinity,

                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          heroTitle,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          heroSub,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // حقل المبلغ

                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: amountLabel,
                      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // من / إلى

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromLabel,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _from,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val == null) return;

                                    setState(() => _from = val);
                                  },
                                  items: currencies
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                                fontFamily: 'Tajawal'),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final temp = _from;

                            _from = _to;

                            _to = temp;
                          });
                        },
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toLabel,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _to,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val == null) return;

                                    setState(() => _to = val);
                                  },
                                  items: currencies
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                                fontFamily: 'Tajawal'),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // أزرار تحويل + استرجاع

                  Row(
                    children: [
                      // استرجاع

                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            resetLabel,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // تحويل الآن

                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _convert,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              convertNow,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // النتيجة

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          resultLabel,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          _resultText,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
