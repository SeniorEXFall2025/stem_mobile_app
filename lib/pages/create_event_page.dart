import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic text fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController =
      TextEditingController(); // e.g. "MSU Denver – Science Building"
  final _cityController = TextEditingController(); // e.g. "Denver"

  // Date/time pickers
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Topics are now chips instead of free text
  final Set<String> _selectedTopics = {};

  // These should match or at least overlap with the interests used in onboarding.
  final List<String> _topicOptions = const [
    'AI',
    'Robotics',
    'Math',
    'Biology',
    'Space',
    'Coding',
  ];

  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final initial = _selectedTime ?? TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return 'Select date';
    return '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
  }

  String get _formattedTime {
    if (_selectedTime == null) return 'Select time';
    final h = _selectedTime!.hourOfPeriod.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    final suffix = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _error = 'Pick a date and time for the event.');
      return;
    }

    if (_selectedTopics.isEmpty) {
      setState(() => _error = 'Pick at least one topic for this event.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      // Combine date + time into a single DateTime
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final title = _titleController.text.trim();
      final description = _descController.text.trim();
      final location = _locationController.text.trim();
      final city = _cityController.text.trim();

      // For now, build a simple address string. Later we can add a dedicated
      // address field and geocoding to fill in lat/lng for the map.
      final address = '$location, $city';

      await FirebaseFirestore.instance.collection("events").add({
        "title": title,
        "description": description,
        // Store as ISO 8601 so DateTime.parse still works in EventsPage/EventDetailsPage
        "date": combinedDateTime.toIso8601String(),
        "location": location,
        "city": city,
        "address": address,

        // Topic tags used for filtering and matching interests later
        "topics": _selectedTopics.toList(),

        // Placeholders for future map pins (lat/lng will be filled by geocoding later)
        "lat": null,
        "lng": null,

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating event: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Event"),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput("Title", _titleController),
              _buildInput("Description", _descController, maxLines: 3),
              _buildInput("Location / Venue", _locationController),
              _buildInput("City", _cityController),
              const SizedBox(height: 16),
              Text(
                "Date and time",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickDate,
                      child: Text(_formattedDate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickTime,
                      child: Text(_formattedTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Topics",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topicOptions.map((topic) {
                  final selected = _selectedTopics.contains(topic);
                  return FilterChip(
                    label: Text(topic),
                    selected: selected,
                    selectedColor: scheme.primaryContainer.withOpacity(0.35),
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedTopics.remove(topic);
                        } else {
                          _selectedTopics.add(topic);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEvent,
                        icon: const Icon(Icons.check),
                        label: const Text("Save Event"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (val) =>
            val == null || val.trim().isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
