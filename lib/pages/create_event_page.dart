import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'places_service.dart'; // uses your existing Places API helper

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Text fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();

  // TypeAhead visible controller (builder pattern)
  final _locationController = TextEditingController();

  // Date/time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Topics (chips)
  final Set<String> _selectedTopics = {};
  final List<String> _topicOptions = const ['AI', 'Robotics', 'Math', 'Biology', 'Space', 'Coding'];

  // Places selection
  String? _selectedPlaceId;
  String? _selectedFormattedAddress;
  double? _selectedLat;
  double? _selectedLng;

  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
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

    // Require a picked suggestion so latitude/longitude are present (needed by MapPage)
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a location from suggestions to set coordinates.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final title = _titleController.text.trim();
      final description = _descController.text.trim();
      final city = _cityController.text.trim();

      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': description,
        'date': combinedDateTime.toIso8601String(),
        'location': _selectedFormattedAddress ?? _locationController.text.trim(),
        'city': city,
        'topics': _selectedTopics.toList(),
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'placeId': _selectedPlaceId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
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
              _buildInput('Title', _titleController, context),
              _buildInput('Description', _descController, context, maxLines: 3),

              const SizedBox(height: 8),
              Text('Location (type to search)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),

              // flutter_typeahead v5 builder pattern
              TypeAheadField<PlacePrediction>(
                suggestionsCallback: (pattern) => PlacesService.autocomplete(pattern),
                itemBuilder: (context, s) => ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(s.description),
                ),
                onSelected: (s) async {
                  _locationController.text = s.description;
                  final det = await PlacesService.details(s.placeId);
                  if (det != null) {
                    setState(() {
                      _selectedPlaceId = det.placeId;
                      _selectedFormattedAddress = det.formattedAddress;
                      _selectedLat = det.lat;
                      _selectedLng = det.lng;
                    });
                  }
                },
                builder: (context, textController, focusNode) {
                  // keep the visible controller in sync with our backing controller
                  if (textController.text != _locationController.text) {
                    textController.value = TextEditingValue(
                      text: _locationController.text,
                      selection: TextSelection.collapsed(offset: _locationController.text.length),
                    );
                  }
                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: scheme.primary),
                      floatingLabelStyle: TextStyle(color: scheme.primary),
                      hintText: 'Start typing an address…',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter Location' : null,
                    onChanged: (v) {
                      _locationController.text = v;
                      // user is typing something new, clear previous selection coords
                      setState(() {
                        _selectedPlaceId = null;
                        _selectedFormattedAddress = null;
                        _selectedLat = null;
                        _selectedLng = null;
                      });
                    },
                  );
                },
                emptyBuilder: (context) => const SizedBox(
                  height: 48,
                  child: Center(child: Text('No addresses found')),
                ),
              ),

              _buildInput('City', _cityController, context),

              const SizedBox(height: 16),
              Text('Date and time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _pickDate, child: Text(_formattedDate)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(onPressed: _pickTime, child: Text(_formattedTime)),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text('Topics', style: Theme.of(context).textTheme.titleMedium),
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
              if (_selectedLat != null && _selectedLng != null)
                Text(
                  'Selected coords: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                  style: TextStyle(color: scheme.secondary),
                ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: TextStyle(color: scheme.error)),
              ],

              const SizedBox(height: 12),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEvent,
                        icon: const Icon(Icons.check),
                        label: const Text('Save Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, BuildContext context, {int maxLines = 1}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.black,
        validator: (val) => val == null || val.trim().isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: scheme.primary),
          floatingLabelStyle: TextStyle(color: scheme.primary),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
