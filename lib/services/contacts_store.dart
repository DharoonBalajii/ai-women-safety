import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trusted_contact.dart';

/// On-device persistence for trusted contacts. A hackathon-scope stand-in
/// for the real "Emergency Backend" contacts service.
class ContactsStore {
  static const _prefKey = 'trusted_contacts';

  Future<List<TrustedContact>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TrustedContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<TrustedContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }
}
