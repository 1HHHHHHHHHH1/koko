// ============================================================
//  ⚙️  supabase_constants.dart
//  غيّر القيمتين التاليتين فقط ثم شغّل التطبيق
// ============================================================
class SupabaseConstants {
  // 🔑 استبدل بـ Project URL من Supabase → Settings → API
  static const String supabaseUrl = 'https://ufycrzqplhzdvsozlrvt.supabase.co';

  // 🔑 استبدل بـ anon public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmeWNyenFwbGh6ZHZzb3pscnZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MzU4NTQsImV4cCI6MjA4OTAxMTg1NH0._Wz3M63F5RFtXru2Pt1Oa7YU1a2aYFkZebn1Lyd0j3M';

  // ── أسماء الجداول ──────────────────────────────────────
  static const String profilesTable      = 'profiles';
  static const String projectsTable      = 'projects';
  static const String investorsTable     = 'investors';
  static const String matchesTable       = 'matches';
  static const String likesTable         = 'likes';
  static const String ratingsTable       = 'ratings';
  static const String messagesTable      = 'messages';
  static const String conversationsTable = 'conversations';
  static const String convParticipants   = 'conversation_participants';

  // ── Storage Buckets ────────────────────────────────────
  static const String avatarsBucket   = 'avatars';
  static const String pitchdeckBucket = 'pitch-decks';
}
