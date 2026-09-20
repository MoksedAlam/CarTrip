import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _areaController;
  late final TextEditingController _upiController;
  bool _showPhoneOnBoard = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserDocProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _areaController = TextEditingController(text: user?.area ?? '');
    _upiController = TextEditingController(text: user?.upiId ?? '');
    _showPhoneOnBoard = user?.showPhoneOnBoard ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        area: _areaController.text.trim(),
        upiId: _upiController.text.trim().isNotEmpty ? _upiController.text.trim() : null,
        showPhoneOnBoard: _showPhoneOnBoard,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  validator: (v) => Validators.requiredField(v, 'Name is required'),
                  prefix: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  label: 'Mobile Number *',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  prefix: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _areaController,
                  label: 'Area / City *',
                  validator: (v) => Validators.requiredField(v, 'Area is required'),
                  prefix: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _upiController,
                  label: 'UPI ID (For Trip Payment QR)',
                  hint: 'e.g. name@okhdfcbank',
                  validator: (v) => Validators.upiId(v, required: false),
                  prefix: const Icon(Icons.qr_code_rounded),
                ),
                const SizedBox(height: 20),
                Card(
                  child: SwitchListTile(
                    title: const Text('Show Phone on Fleet Board'),
                    subtitle: const Text(
                      'Allows other owners to see your number and call you from the board',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _showPhoneOnBoard,
                    onChanged: (val) => setState(() => _showPhoneOnBoard = val),
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
