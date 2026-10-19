import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/image_url.dart';
import '../../core/ui.dart';
import '../../data/media_repository.dart';
import '../../data/organization_repository.dart';
import '../../shared/widgets/shadow_button.dart';
import 'organization_providers.dart';

/// Create an organization, or edit one when [organizationId] is given.
class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.organizationId});

  final int? organizationId;

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState
    extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _website = TextEditingController();

  XFile? _newLogo;
  String? _existingLogoUrl;
  bool _loading = false;
  bool _submitting = false;

  bool get _isEditing => widget.organizationId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final org = await ref.read(
        organizationProvider(widget.organizationId!).future,
      );
      _name.text = org.name;
      _description.text = org.description ?? '';
      _location.text = org.location ?? '';
      _website.text = org.website ?? '';
      _existingLogoUrl = org.logo;
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _newLogo = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    try {
      var logo = _existingLogoUrl;
      if (_newLogo != null) {
        logo = await ref.read(mediaRepositoryProvider).uploadImage(_newLogo!);
      }

      final organizations = ref.read(organizationRepositoryProvider);
      if (_isEditing) {
        await organizations.update(
          widget.organizationId!,
          name: _name.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          website: _website.text.trim(),
          logo: logo,
        );
        ref.invalidate(organizationProvider(widget.organizationId!));
      } else {
        await organizations.create(
          name: _name.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          website: _website.text.trim(),
          logo: logo,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  ImageProvider? _logoImage(BuildContext context) {
    if (_newLogo != null) return FileImage(File(_newLogo!.path));
    if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(
        headers: imageHeaders,
        sizedImageUrl(
          _existingLogoUrl!,
          logicalWidth: 96,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            _isEditing ? 'Edit Organization' : 'Create Organization',
            style: const TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Center(
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _logoImage(context),
                            child:
                                _logoImage(context) == null
                                    ? const Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey,
                                      size: 30,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description / Goal',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Description is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _website,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ShadowButton(
                          label:
                              _submitting
                                  ? (_isEditing ? 'Saving...' : 'Creating...')
                                  : (_isEditing
                                      ? 'Save Changes'
                                      : 'Create Organization'),
                          onTap: _submitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
