import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/home_theme.dart';

enum _Step { phone, otp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();

  _Step _step = _Step.phone;
  UserRole _role = UserRole.protected;
  bool _loading = false;
  bool _otpIsMock = false;
  String? _error;

  static final _phonePattern = RegExp(r'^\+[1-9]\d{7,14}$');

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!_phonePattern.hasMatch(phone)) {
      setState(() => _error = 'Enter a phone number in international format, e.g. +919876543210');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<AuthProvider>().sendOtp(phoneNumber: phone, role: _role);
      setState(() {
        _step = _Step.otp;
        _otpIsMock = result.mock;
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = "Couldn't reach the server. Check your connection and try again.";
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the code you received.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().verifyOtp(
            phoneNumber: _phoneController.text.trim(),
            role: _role,
            code: code,
          );
      // AuthGate in main.dart swaps screens once AuthProvider reports signed-in.
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = "Couldn't reach the server. Check your connection and try again.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.appBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon/app_icon.png', width: 76, height: 76, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                Text('Raksha Thunai', style: HomeText.greeting().copyWith(fontSize: 26), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  _step == _Step.phone
                      ? 'Sign in with your phone number to get started.'
                      : 'Enter the code sent to ${_phoneController.text.trim()}',
                  style: HomeText.body(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_step == _Step.phone) ..._buildPhoneStep() else ..._buildOtpStep(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: HomeText.body(color: HomeColors.sosCrimson), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPhoneStep() {
    return [
      Row(
        children: [
          Expanded(child: _RoleChip(label: 'I need protection', selected: _role == UserRole.protected, onTap: () => setState(() => _role = UserRole.protected))),
          const SizedBox(width: 10),
          Expanded(child: _RoleChip(label: "I'm a Guardian", selected: _role == UserRole.guardian, onTap: () => setState(() => _role = UserRole.guardian))),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: HomeText.body(color: HomeColors.textPrimary),
        decoration: _decoration('Phone number'),
      ),
      const SizedBox(height: 18),
      _PrimaryButton(label: 'Send code', loading: _loading, onPressed: _sendOtp),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      if (_otpIsMock)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HomeColors.brandTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Demo mode: SMS isn\'t configured on the server yet, so no real code was sent. Enter 000000 to continue.',
            style: HomeText.caption(color: HomeColors.brandTeal),
            textAlign: TextAlign.center,
          ),
        ),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        style: HomeText.body(color: HomeColors.textPrimary),
        decoration: _decoration('6-digit code'),
      ),
      const SizedBox(height: 18),
      _PrimaryButton(label: 'Verify & continue', loading: _loading, onPressed: _verifyOtp),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _loading ? null : () => setState(() => _step = _Step.phone),
        child: Text('Change phone number', style: HomeText.body(color: HomeColors.textSecondary)),
      ),
    ];
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: HomeText.body(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeColors.brandIndigo, width: 1.5)),
      );
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? HomeColors.brandIndigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? HomeColors.brandIndigo : HomeColors.cardBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: HomeText.cardTitle(color: selected ? Colors.white : HomeColors.textPrimary).copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: HomeColors.brandIndigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}
