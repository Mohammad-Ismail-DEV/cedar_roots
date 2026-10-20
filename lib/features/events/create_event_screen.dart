import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/ui.dart';
import '../../data/event_repository.dart';
import '../../shared/widgets/shadow_button.dart';
import '../feed/feed_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  DateTime? _dateTime;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) {
      return showSnack(context, 'Pick the event date and time.');
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(eventRepositoryProvider)
          .create(
            title: _title.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            dateTime: _dateTime!,
            organizationId: widget.organizationId,
          );
      ref.invalidate(feedProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
    ),
  );

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: _decoration('Title'),
                validator: (v) => _required(v, 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: _decoration('Description'),
                validator: (v) => _required(v, 'Description'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                decoration: _decoration('Location'),
                validator: (v) => _required(v, 'Location'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dateTime == null
                      ? 'Pick event date and time'
                      : DateFormat('MMM d, yyyy • h:mm a').format(_dateTime!),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.grey),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              _submitting
                  ? const CircularProgressIndicator()
                  : ShadowButton(
                    icon: Icons.check_circle_outline,
                    label: 'Create Event',
                    color: Colors.green.shade700,
                    onTap: _submit,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
