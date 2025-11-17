import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'event_details.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _denver = LatLng(39.7392, -104.9903);
  LatLng _initialLatLng = _denver;
  bool _locationPermissionGranted = false;

  final Set<Marker> _markers = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // focus handling
  String? _focusEventId;
  bool _didFocus = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _subscribeToEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick up route arguments here (ModalRoute not available in initState).
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_focusEventId == null && args is Map && args['focusEventId'] is String) {
      _focusEventId = args['focusEventId'] as String;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationPermissionGranted = false);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _initialLatLng = LatLng(pos.latitude, pos.longitude);
        _locationPermissionGranted = true;
      });
      final c = await _controller.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialLatLng, zoom: 13),
        ),
      );
    }
  }

  void _subscribeToEvents() {
    _sub = FirebaseFirestore.instance.collection('events').snapshots().listen(
      (snap) async {
        final next = <Marker>{};
        for (final doc in snap.docs) {
          final data = doc.data();

          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final title = (data['title'] ?? '') as String;
          final address = (data['location'] ?? '') as String;

          next.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              // default tap opens the info window
              infoWindow: InfoWindow(
                title: title.isEmpty ? 'Event' : title,
                snippet: address,
                onTap: () {
                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailsPage(
                        eventId: doc.id,
                        eventData: data,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (!mounted) return;
        setState(() {
          _markers
            ..clear()
            ..addAll(next);
        });

        // Focus target if provided
        await _focusIfNeeded();

        // If no specific focus and first load, fit to markers
        if (!_didFocus && _markers.isNotEmpty) {
          await _fitToMarkers(padding: 80);
        }
      },
    );
  }

  Future<void> _focusIfNeeded() async {
    if (_didFocus || _focusEventId == null) return;
    final id = _focusEventId!;
    final marker = _markers.firstWhere(
      (m) => m.markerId.value == id,
      orElse: () => const Marker(markerId: MarkerId('__none__')),
    );
    if (marker.markerId.value == '__none__') return;

    _didFocus = true;
    final c = await _controller.future;
    await c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: marker.position, zoom: 16),
      ),
    );
    // open the info window after camera settles
    await Future.delayed(const Duration(milliseconds: 200));
    c.showMarkerInfoWindow(MarkerId(id));
  }

  Future<void> _fitToMarkers({double padding = 60}) async {
    if (_markers.isEmpty) return;
    final c = await _controller.future;

    LatLngBounds? bounds;
    for (final m in _markers) {
      final p = m.position;
      if (bounds == null) {
        bounds = LatLngBounds(southwest: p, northeast: p);
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            p.latitude < bounds.southwest.latitude ? p.latitude : bounds.southwest.latitude,
            p.longitude < bounds.southwest.longitude ? p.longitude : bounds.southwest.longitude,
          ),
          northeast: LatLng(
            p.latitude > bounds.northeast.latitude ? p.latitude : bounds.northeast.latitude,
            p.longitude > bounds.northeast.longitude ? p.longitude : bounds.northeast.longitude,
          ),
        );
      }
    }

    if (bounds!.northeast == bounds.southwest) {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: bounds.northeast, zoom: 15),
        ),
      );
    } else {
      await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    }
  }

  Future<void> _recenterToMe() async {
    final granted = _locationPermissionGranted;
    if (!granted) return _determinePosition();
    final pos = await Geolocator.getCurrentPosition();
    final c = await _controller.future;
    await c.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color appBarForegroundColor =
        theme.brightness == Brightness.dark ? Colors.white : curiousBlue.shade900;
    final Color appBarBackgroundColor = theme.scaffoldBackgroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEM Events Map'),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        actions: [
          IconButton(
            tooltip: 'My Location',
            onPressed: _recenterToMe,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialLatLng, zoom: 12),
        myLocationEnabled: _locationPermissionGranted,
        myLocationButtonEnabled: false,
        markers: _markers,
        onMapCreated: (c) => _controller.complete(c),
      ),
    );
  }
}
