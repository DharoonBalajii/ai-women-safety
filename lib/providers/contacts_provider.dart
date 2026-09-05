import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/trusted_contact.dart';
import '../services/contacts_store.dart';

class ContactsProvider extends ChangeNotifier {
  final ContactsStore _store = ContactsStore();
  final _uuid = const Uuid();

  List<TrustedContact> _contacts = [];
  bool _loaded = false;

  List<TrustedContact> get contacts => List.unmodifiable(_contacts);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _contacts = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addContact({
    required String name,
    required String phone,
    String relationship = 'Contact',
  }) async {
    _contacts.add(TrustedContact(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      relationship: relationship,
    ));
    await _store.save(_contacts);
    notifyListeners();
  }

  Future<void> updateContact(TrustedContact updated) async {
    final index = _contacts.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _contacts[index] = updated;
    await _store.save(_contacts);
    notifyListeners();
  }

  Future<void> removeContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _store.save(_contacts);
    notifyListeners();
  }
}
