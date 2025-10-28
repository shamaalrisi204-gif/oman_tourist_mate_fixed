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
        title: Text(t('إضافة إلى المفضلة', 'Add to Favorites')),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: t('اسم المكان', 'Place name')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(t('إضافة', 'Add')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _items.add(result));
      await _save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('تمت الإضافة', 'Added'))),
      );
    }
  }

  void _removeAt(int index) async {
    final removed = _items.removeAt(index);
    setState(() {});
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('تم حذف "$removed"', 'Deleted "$removed"'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('المفضلة', 'My Favorites')),
          actions: [
            TextButton(
              onPressed: () => setState(() => _isArabic = !_isArabic),
              child: Text(_isArabic ? 'English' : 'العربية'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Text(
                      t('لا توجد عناصر بعد — أضيفي أماكنك المفضلة',
                          'No items yet — add your favorite places'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) => Dismissible(
                      key: ValueKey(_items[i]),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _removeAt(i),
                      child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(_items[i]),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // لاحقًا: افتحي تفاصيل المكان
                        },
                      ),
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addItemDialog,
          icon: const Icon(Icons.add),
          label: Text(t('إضافة', 'Add')),
        ),
      ),
    );
  }
}
