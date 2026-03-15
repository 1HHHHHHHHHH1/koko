import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ hide Provider لتجنب التعارض مع gotrue
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
