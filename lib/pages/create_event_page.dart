import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _topicsController = TextEditingController();

  bool _saving = false;

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection("events").add({
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "date": _dateController.text.trim(),
        "location": _locationController.text.trim(),
        "city": _cityController.text.trim(),
        "topics": _topicsController.text
            .split(",")
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🔥 Error creating event: $e")),
      );
    } finally {
      setState(() => _saving = false);
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
            children: [
              _buildInput("Title", _titleController),
              _buildInput("Description", _descController, maxLines: 3),
              _buildInput("Date (YYYY-MM-DD)", _dateController),
              _buildInput("Location", _locationController),
              _buildInput("City", _cityController),
              _buildInput("Topics (comma-separated)", _topicsController),
              const SizedBox(height: 20),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (val) =>
            val == null || val.trim().isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
