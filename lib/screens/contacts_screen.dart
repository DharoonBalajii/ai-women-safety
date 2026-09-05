import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trusted_contact.dart';
import '../providers/contacts_provider.dart';
import '../theme/app_theme.dart';

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

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController(text: 'Family');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.inkSurfaceRaised,
        title: const Text('Add trusted contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add')),
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
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.beaconAmber,
        foregroundColor: AppColors.inkBase,
        child: const Icon(Icons.add),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No trusted contacts yet.\nAdd the people who should be alerted during an emergency.',
                  textAlign: TextAlign.center,
                  style: AppText.textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.inkSurfaceRaised,
          child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: AppText.textTheme.titleLarge),
        ),
        title: Text(contact.name, style: AppText.textTheme.bodyLarge),
        subtitle: Text('${contact.relationship} · ${contact.phone}', style: AppText.textTheme.bodyMedium),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.paperMuted),
          onPressed: () => context.read<ContactsProvider>().removeContact(contact.id),
        ),
      ),
    );
  }
}
