import 'dart:io';

import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  final ApiServices api = ApiServices();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  final _focusNode = FocusScopeNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = XFile(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _focusNode.unfocus(); // dismiss keyboard
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await api.uploadFile(_selectedImage!);
      if (!mounted) return;
      if (imageUrl == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
        return;
      }
    }

    final response = await api.createOrganization({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'website': _websiteController.text.trim(),
      'logo': imageUrl ?? '',
    });

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
    }
  }

  Widget buildShadowButton({
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            "Create Organization",
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body: FocusScope(
          node: _focusNode,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(File(_selectedImage!.path))
                              : null,
                      child:
                          _selectedImage == null
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Organization Name",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? "Name is required"
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Description / Goal",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? "Description is required"
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: "Website",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: buildShadowButton(
                    label:
                        _isSubmitting ? "Creating..." : "Create Organization",
                    onTap: _submit,
                    textColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
