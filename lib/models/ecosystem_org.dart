import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Model for one STEM ecosystem organization.
class EcosystemOrg {
  final String name;

  // Basic info
  final String? description;
  final String? orgType;       // "K-12 School", "Higher Ed", "Nonprofit", etc.
  final String? contactName;
  final String? email;
  final String? website;
  final String? zip;

  // Multi-select style fields
  final List<String> regions;           // regions served
  final List<String> offers;            // what they can offer
  final List<String> needs;             // what they need
  final List<String> programmingTypes;  // what their programming looks like

  EcosystemOrg({
    required this.name,
    this.description,
    this.orgType,
    this.contactName,
    this.email,
    this.website,
    this.zip,
    required this.regions,
    required this.offers,
    required this.needs,
    required this.programmingTypes,
  });

  factory EcosystemOrg.fromJson(Map<String, dynamic> json) {
    return EcosystemOrg(
      name: (json['name'] ?? 'Unknown Organization').toString(),
      description: _clean(json['description']),
      orgType: _clean(json['orgType']),
      contactName: _clean(json['contactName']),
      email: _clean(json['email']),
      website: _clean(json['website']),
      zip: _clean(json['zip']),
      regions: _stringList(json['regions']),
      offers: _stringList(json['offers']),
      needs: _stringList(json['needs']),
      programmingTypes: _stringList(json['programmingTypes']),
    );
  }

  /// Turn null/empty → null
  static String? _clean(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Normalize multi-select fields:
  /// - if JSON already has a List -> use it
  /// - if it's a single String like "A; B; C" -> split on ; or ,
  static List<String> _stringList(dynamic v) {
    if (v == null) return <String>[];

    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return <String>[];

      // split on ; or , and trim
      final parts = trimmed.split(RegExp(r'[;,]'));
      return parts
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  /// Load all orgs from the bundled JSON asset.
  static Future<List<EcosystemOrg>> loadFromAssets() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/ecosystem_orgs.json');
    final raw = json.decode(jsonStr);

    if (raw is List) {
      return raw
          .map((e) => EcosystemOrg.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
