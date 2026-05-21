import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_keys.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      anonKey: ApiKeys.supabaseAnonKey,
    );
  }

  // ──────────────────────────────────────────────────────
  // AUTH
  // ──────────────────────────────────────────────────────

  static Future<AuthResponse> signUpWithEmail(
      String email, String password, String name) async {
    // Sign up user
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );

    // Create profile row manually (no trigger needed)
    if (res.user != null) {
      try {
        await client.from('profiles').upsert({
          'id':    res.user!.id,
          'name':  name,
          'email': email,
        });
      } catch (_) {
        // Non-critical — profile is created/updated on first login too
      }
    }

    return res;
  }

  static Future<AuthResponse> signInWithEmail(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signInWithGoogle(
      String idToken, String accessToken) {
    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStream => client.auth.onAuthStateChange;

  // ──────────────────────────────────────────────────────
  // PROFILE  — ensure row exists then return it
  // ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    // Try to fetch
    var row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // If no row exists yet, create one from auth metadata
    if (row == null) {
      final user = currentUser;
      final name  = user?.userMetadata?['full_name']
                     ?? user?.email?.split('@').first
                     ?? 'User';
      final email = user?.email ?? '';
      await client.from('profiles').upsert({
        'id':    userId,
        'name':  name,
        'email': email,
      });
      row = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    }
    return row;
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    await client.from('profiles').upsert({'id': userId, ...data});
  }

  // ──────────────────────────────────────────────────────
  // EMERGENCY CONTACTS
  // ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final res = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>> addContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    final res = await client
        .from('emergency_contacts')
        .insert({
          'user_id':  userId,
          'name':     name,
          'phone':    phone,
          'relation': relation,
        })
        .select()
        .single();
    return res;
  }

  static Future<void> deleteContact(String contactId) async {
    await client.from('emergency_contacts').delete().eq('id', contactId);
  }

  // ──────────────────────────────────────────────────────
  // EVENT HISTORY
  // ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEventHistory(
      String userId) async {
    final res = await client
        .from('event_history')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> addEvent({
    required String userId,
    required String title,
    required String type,
    required String location,
    String severity = 'MODERATE',
  }) async {
    await client.from('event_history').insert({
      'user_id':  userId,
      'title':    title,
      'type':     type,
      'location': location,
      'severity': severity,
    });
  }
}
