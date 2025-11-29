import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _items = <String>[];
  bool _loading = true;
  bool _isArabic = true;

  static const Color _primary = Color(0xFF5E2BFF);
  static const Color _background = Color(0xFFF3EED9);
  static const Color _cardColor = Color(0xFFE5D7B8);

  String t(String ar, String en) => _isArabic ? ar : en;

  static const _prefsKey = 'favorites_list_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _items
      ..clear()
      ..addAll(p.getStringList(_prefsKey) ?? const []);
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_prefsKey, _items);
  }

  Future<void> _addItemDialog() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          t('إضافة إلى المفضلة', 'Add to Favorites'),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        content: TextField(
          controller: c,
          decoration: InputDecoration(
            hintText: t('اسم المكان', 'Place name'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('إلغاء', 'Cancel'),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(
              t('إضافة', 'Add'),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _items.add(result));
      await _save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('تمت الإضافة', 'Added'),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }

  void _removeAt(int index) async {
    final removed = _items.removeAt(index);
    setState(() {});
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t('تم حذف "$removed"', 'Deleted "$removed"'),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            t('المفضلة', 'My Favorites'),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _isArabic = !_isArabic),
              child: Text(
                _isArabic ? 'English' : 'العربية',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        t(
                          'لا توجد أماكن في المفضلة بعد.\nابدأي بإضافة الأماكن التي تحبينها 🌟',
                          'No favorite places yet.\nStart adding the places you love 🌟',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final title = _items[i];
                      return Dismissible(
                        key: ValueKey(title),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeAt(i),
                        child: Card(
                          color: _cardColor,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: const Icon(
                              Icons.place_outlined,
                              size: 30,
                              color: Colors.black87,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              t(
                                'مكان مفضل من اختيارك',
                                'A favorite place you saved',
                              ),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black87,
                            ),
                            onTap: () {
                              // لاحقاً: افتحي تفاصيل المكان / الخريطة
                            },
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          onPressed: _addItemDialog,
          icon: const Icon(Icons.add),
          label: Text(
            t('إضافة', 'Add'),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      ),
    );
  }
}
