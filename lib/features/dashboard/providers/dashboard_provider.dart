import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/models/category_model.dart';
import 'package:flownote/services/category_service.dart';
// Re-export theme providers agar import lama tetap bekerja
export 'package:flownote/core/providers/theme_provider.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) => CategoryService());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final service = ref.read(categoryServiceProvider);
  return service.getCategories();
});
