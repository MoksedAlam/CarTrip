import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/avatar_helper.dart';
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
  late final TextEditingController _photoUrlController;
  bool _showPhoneOnBoard = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserDocProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _areaController = TextEditingController(text: user?.area ?? '');
    _upiController = TextEditingController(text: user?.upiId ?? '');
    _photoUrlController = TextEditingController(text: user?.photoUrl ?? '');
    _showPhoneOnBoard = user?.showPhoneOnBoard ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _upiController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      setState(() {
        _photoUrlController.text = dataUri;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selected! Tap "Save Changes" to apply.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.green),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Capture using device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo from device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.link_rounded, color: Colors.deepPurple),
                ),
                title: const Text('Image URL or Preset Avatar'),
                subtitle: const Text('Paste web link or pick ready avatar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPhotoDialog();
                },
              ),
              if (_photoUrlController.text.trim().isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoUrlController.clear());
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoDialog() async {
    final tempController = TextEditingController(text: _photoUrlController.text.startsWith('data:') ? '' : _photoUrlController.text);
    final presets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile Photo URL / Presets'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Image URL:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: tempController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/photo.jpg',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or Choose an Avatar:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: presets.map((url) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      tempController.text = url;
                      setState(() => _photoUrlController.text = url);
                      Navigator.pop(ctx);
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(url),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _photoUrlController.clear());
              Navigator.pop(ctx);
            },
            child: const Text('Remove Photo'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _photoUrlController.text = tempController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Set Photo'),
          ),
        ],
      ),
    );
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
        photoUrl: _photoUrlController.text.trim().isNotEmpty ? _photoUrlController.text.trim() : null,
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
    final theme = Theme.of(context);
    final photo = _photoUrlController.text.trim();

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
                // Profile Avatar with Change Button
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: photo.isNotEmpty ? AvatarHelper.getImageProvider(photo) : null,
                        child: photo.isEmpty
                            ? Text(
                                _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      InkWell(
                        onTap: _showPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showPhotoOptions,
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: const Text('Change Photo'),
                ),
                const SizedBox(height: 16),

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
                      'Allows other owners to see your number and call you from the board (Enabled by default)',
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
