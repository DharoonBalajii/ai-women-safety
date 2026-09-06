import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trusted_contact.dart';
import '../providers/contacts_provider.dart';
import '../theme/home_theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ContactsProvider>().load());
  }

  InputDecoration _lightInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: HomeText.body(),
        filled: true,
        fillColor: HomeColors.appBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HomeColors.brandIndigo, width: 1.5),
        ),
      );

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController(text: 'Family');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Add trusted contact', style: HomeText.title()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: _lightInput('Name')),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: _lightInput('Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              decoration: _lightInput('Relationship'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: HomeText.body(color: HomeColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HomeColors.brandIndigo),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty) {
      if (context.mounted) {
        await context.read<ContactsProvider>().addContact(
              name: nameController.text.trim(),
              phone: phoneController.text.trim(),
              relationship: relationshipController.text.trim().isEmpty
                  ? 'Contact'
                  : relationshipController.text.trim(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>().contacts;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text('Safety Circle', style: HomeText.title()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: HomeColors.brandIndigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No trusted contacts yet.\nAdd the people who should be alerted during an emergency.',
                  textAlign: TextAlign.center,
                  style: HomeText.body(),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: contacts.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ContactTile(contact: contacts[index]),
            ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final TrustedContact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: HomeColors.brandIndigo.withValues(alpha: 0.1),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: HomeText.cardTitle(color: HomeColors.brandIndigo).copyWith(fontSize: 17),
          ),
        ),
        title: Text(contact.name, style: HomeText.cardTitle()),
        subtitle: Text('${contact.relationship} · ${contact.phone}', style: HomeText.caption()),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: HomeColors.textSecondary),
          onPressed: () => context.read<ContactsProvider>().removeContact(contact.id),
        ),
      ),
    );
  }
}
