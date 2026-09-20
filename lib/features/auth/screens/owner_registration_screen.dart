import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  ConsumerState<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends ConsumerState<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _areaController;
  late final TextEditingController _upiController;

  bool _declarationAccepted = false;
  bool _declarationError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    _nameController = TextEditingController(text: firebaseUser?.displayName ?? '');
    _phoneController = TextEditingController();
    _areaController = TextEditingController();
    _upiController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!_declarationAccepted) {
      setState(() => _declarationError = true);
      return;
    } else {
      setState(() => _declarationError = false);
    }

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).submitRegistration(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        area: _areaController.text.trim(),
        upiId: _upiController.text.trim().isNotEmpty ? _upiController.text.trim() : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving registration: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Registration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provide your contact and operating details to request approval.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Enter your full name',
                  validator: (v) => Validators.requiredField(v, 'Name is required'),
                  textCapitalization: TextCapitalization.words,
                  prefix: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  label: 'Mobile Number (10 digits) *',
                  hint: '9876543210',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  prefix: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _areaController,
                  label: 'Area / City *',
                  hint: 'e.g. South Delhi, New Delhi',
                  validator: (v) => Validators.requiredField(v, 'Area/City is required'),
                  textCapitalization: TextCapitalization.words,
                  prefix: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _upiController,
                  label: 'UPI ID (Optional)',
                  hint: 'e.g. yourname@okhdfcbank',
                  validator: (v) => Validators.upiId(v, required: false),
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.qr_code_rounded),
                ),
                const SizedBox(height: 20),
                // Legal declaration card
                Card(
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Compliance Declaration',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.declarationText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _declarationAccepted = !_declarationAccepted;
                              if (_declarationAccepted) _declarationError = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _declarationAccepted,
                                onChanged: (val) {
                                  setState(() {
                                    _declarationAccepted = val ?? false;
                                    if (_declarationAccepted) _declarationError = false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'I read and accept this declaration *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_declarationError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              'You must accept the declaration to continue',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Submit Registration',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
