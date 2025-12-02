import 'package:flutter/material.dart';
import 'package:stem_mobile_app/models/ecosystem_org.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRegion; // null = All regions

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STEM Ecosystem Organizations'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.brightness == Brightness.dark ? Colors.white : scheme.primary,
      ),
      body: FutureBuilder<List<EcosystemOrg>>(
        future: EcosystemOrg.loadFromAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading organizations: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No organizations found.'),
            );
          }

          final allOrgs = snapshot.data!;

          // Build unique region list for chips.
          final regionSet = <String>{};
          for (final org in allOrgs) {
            for (final r in org.regions) {
              final trimmed = r.trim();
              if (trimmed.isNotEmpty) regionSet.add(trimmed);
            }
          }
          final regions = regionSet.toList()..sort();

          // Apply search + region filter.
          final filtered = allOrgs.where((org) {
            final q = _searchQuery.trim().toLowerCase();

            final matchesSearch = q.isEmpty ||
                org.name.toLowerCase().contains(q) ||
                (org.description ?? '').toLowerCase().contains(q) ||
                (org.orgType ?? '').toLowerCase().contains(q) ||
                org.regions.any((r) => r.toLowerCase().contains(q));

            final matchesRegion = _selectedRegion == null ||
                org.regions.contains(_selectedRegion);

            return matchesSearch && matchesRegion;
          }).toList();

          return Column(
            children: [
              // Search bar.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search organizations, regions, or topics...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // Region filter chips.
              if (regions.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All regions'),
                        selected: _selectedRegion == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedRegion = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...regions.map(
                        (region) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(region),
                            selected: _selectedRegion == region,
                            onSelected: (_) {
                              setState(() {
                                _selectedRegion = region;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // List of orgs (filtered).
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No organizations match your filters.\nTry clearing the search or region.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final org = filtered[index];

                          // Small subtitle under name: org type or first region.
                          String? subtitle;
                          if ((org.orgType ?? '').isNotEmpty) {
                            subtitle = org.orgType!;
                          } else if (org.regions.isNotEmpty) {
                            subtitle = org.regions.join(', ');
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: theme.colorScheme.surface.withOpacity(0.95),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                org.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: subtitle == null
                                  ? null
                                  : Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showOrgDetails(org),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- URL helpers ---------------------------------------------------------

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _launchMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  // --- Detail dialog -------------------------------------------------------

  void _showOrgDetails(EcosystemOrg org) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle =
        theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(org.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Org type
                if ((org.orgType ?? '').isNotEmpty) ...[
                  Text('Organization type:', style: labelStyle),
                  Text(org.orgType!),
                  const SizedBox(height: 12),
                ],

                // Description
                if ((org.description ?? '').isNotEmpty) ...[
                  Text(
                    org.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact Person
                if ((org.contactName ?? '').isNotEmpty) ...[
                  Text('Contact:', style: labelStyle),
                  Text(org.contactName!),
                  const SizedBox(height: 12),
                ],

                // Email (tappable)
                if ((org.email ?? '').isNotEmpty) ...[
                  Text('Email:', style: labelStyle),
                  InkWell(
                    onTap: () => _launchEmail(org.email!),
                    child: Text(
                      org.email!,
                      style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Website (tappable)
                if ((org.website ?? '').isNotEmpty) ...[
                  Text('Website:', style: labelStyle),
                  InkWell(
                    onTap: () {
                      final url = org.website!.startsWith('http')
                          ? org.website!
                          : 'https://${org.website!}';
                      _launchURL(url);
                    },
                    child: Text(
                      org.website!,
                      style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Regions served
                if (org.regions.isNotEmpty) ...[
                  Text('Regions served:', style: labelStyle),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.regions
                        .map(
                          (r) => Chip(
                            label: Text(r),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ZIP (tappable → maps)
                if ((org.zip ?? '').isNotEmpty) ...[
                  Text('ZIP Code:', style: labelStyle),
                  InkWell(
                    onTap: () {
                      // Use org name + zip for better search result.
                      final query = '${org.name} ${org.zip!}';
                      _launchMaps(query);
                    },
                    child: Text(
                      org.zip!,
                      style: TextStyle(
                        color: scheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Offers
                if (org.offers.isNotEmpty) ...[
                  Text('They can offer:', style: labelStyle),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.offers
                        .map(
                          (o) => Chip(
                            label: Text(o),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Needs
                if (org.needs.isNotEmpty) ...[
                  Text('They’re looking for:', style: labelStyle),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.needs
                        .map(
                          (n) => Chip(
                            label: Text(n),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Programming Types
                if (org.programmingTypes.isNotEmpty) ...[
                  Text('Programming looks like:', style: labelStyle),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.programmingTypes
                        .map(
                          (p) => Chip(
                            label: Text(p),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
