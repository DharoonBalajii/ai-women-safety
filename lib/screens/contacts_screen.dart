import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/guardian_invite.dart';
import '../models/trusted_contact.dart';
import '../providers/contacts_provider.dart';
import '../services/api_client.dart';
import '../services/guardian_service.dart';
import '../theme/home_theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<GuardianRelationshipSummary> _guardians = [];
  bool _loadingGuardians = true;
  String? _guardianError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ContactsProvider>().load());
    _loadGuardians();
  }

  Future<void> _loadGuardians() async {
    try {
      final relationships = await guardianService.fetchMyRelationships();
      if (!mounted) return;
      setState(() {
        _guardians = relationships;
        _loadingGuardians = false;
        _guardianError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGuardians = false;
        _guardianError = e is ApiException ? e.message : 'Could not reach the server.';
      });
    }
  }

  Future<void> _showInviteGuardianDialog(BuildContext context) async {
    final phoneController = TextEditingController(text: '+91');
    final labelController = TextEditingController();
    String? errorText;

    final invited = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Invite a Guardian', style: HomeText.title()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'They need an existing Guardian account on Raksha Thunai to receive this invite.',
                style: HomeText.caption(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: HomeText.body(color: HomeColors.textPrimary),
                decoration: _lightInput('Guardian phone number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                style: HomeText.body(color: HomeColors.textPrimary),
                decoration: _lightInput('Label (e.g. Mother) — optional'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: HomeText.caption(color: HomeColors.sosCrimson)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: HomeText.body(color: HomeColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: HomeColors.brandIndigo),
              onPressed: () async {
                final phone = phoneController.text.trim();
                if (phone.isEmpty) return;
                try {
                  await guardianService.inviteGuardian(
                    guardianPhoneNumber: phone,
                    label: labelController.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  setDialogState(() {
                    errorText = e is ApiException ? e.message : 'Could not reach the server.';
                  });
                }
              },
              child: const Text('Send invite'),
            ),
          ],
        ),
      ),
    );

    if (invited == true) await _loadGuardians();
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
            TextField(
              controller: nameController,
              style: HomeText.body(color: HomeColors.textPrimary),
              decoration: _lightInput('Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: HomeText.body(color: HomeColors.textPrimary),
              decoration: _lightInput('Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              style: HomeText.body(color: HomeColors.textPrimary),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              Text('APP GUARDIANS', style: HomeText.eyebrow()),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showInviteGuardianDialog(context),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: const Text('Invite'),
                style: TextButton.styleFrom(foregroundColor: HomeColors.brandIndigo, padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingGuardians)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(color: HomeColors.brandIndigo)),
            )
          else if (_guardianError != null)
            Text(_guardianError!, style: HomeText.caption(color: HomeColors.sosCrimson))
          else if (_guardians.isEmpty)
            Text(
              'No guardians linked yet. Invite someone with a Guardian account to see your SOS alerts live.',
              style: HomeText.body(),
            )
          else
            for (final guardian in _guardians) ...[
              _GuardianTile(guardian: guardian),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 24),
          Text('TRUSTED CONTACTS', style: HomeText.eyebrow()),
          const SizedBox(height: 10),
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No trusted contacts yet. Add the people who should be alerted during an emergency.',
                style: HomeText.body(),
              ),
            )
          else
            for (final contact in contacts) ...[
              _ContactTile(contact: contact),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _GuardianTile extends StatelessWidget {
  final GuardianRelationshipSummary guardian;
  const _GuardianTile({required this.guardian});

  Color _statusColor() {
    switch (guardian.status) {
      case 'ACTIVE':
        return HomeColors.statusGreen;
      case 'REVOKED':
        return HomeColors.textSecondary;
      default:
        return HomeColors.caution;
    }
  }

  String _statusLabel() {
    switch (guardian.status) {
      case 'ACTIVE':
        return 'Connected';
      case 'REVOKED':
        return 'Declined';
      default:
        return 'Invite sent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: HomeColors.brandTeal.withValues(alpha: 0.12),
            child: const Icon(Icons.shield_outlined, color: HomeColors.brandTeal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardian.label?.isNotEmpty == true ? guardian.label! : guardian.guardianPhoneNumber,
                  style: HomeText.cardTitle(),
                ),
                if (guardian.label?.isNotEmpty == true)
                  Text(guardian.guardianPhoneNumber, style: HomeText.caption()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(),
              style: HomeText.caption(color: _statusColor()).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
