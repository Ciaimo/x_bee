import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/data/entities_repository.dart';

final entitiesProvider = Provider<EntitiesRepository>((ref) {
  return EntitiesRepository();
});
