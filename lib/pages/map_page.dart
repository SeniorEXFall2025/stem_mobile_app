import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stem_mobile_app/custom_colors.dart';
import 'event_details.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.radiusMi});

  //radius in miles (from app_shell)
  final ValueListenable<double> radiusMi;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _denver = LatLng(39.7392, -104.9903);
  LatLng _initialLatLng = _denver;
  bool _locationPermissionGranted = false;

  //radius (mirror of notifier)
  double _radiusMi = 10.0;

  //location
  Position? _currentPos;
  StreamSubscription<Position>? _posSub;

  //events
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _eventDocs = [];

  //map
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  //focus handling
  String? _focusEventId;
  bool _didFocus = false;

  @override
  void initState() {
    super.initState();
    _radiusMi = widget.radiusMi.value;
    widget.radiusMi.addListener(_onRadiusChanged);

    _determinePosition();
    _subscribeToEvents();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusMi != widget.radiusMi) {
      oldWidget.radiusMi.removeListener(_onRadiusChanged);
      _radiusMi = widget.radiusMi.value;
      widget.radiusMi.addListener(_onRadiusChanged);
      _recomputeMarkers();
    }
  }

  void _onRadiusChanged() {
    _radiusMi = widget.radiusMi.value;
    _recomputeMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //pick up route arguments here
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_focusEventId == null && args is Map && args['focusEventId'] is String) {
      _focusEventId = args['focusEventId'] as String;
    }
  }

  @override
  void dispose() {
    widget.radiusMi.removeListener(_onRadiusChanged);
    _sub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  //Location/Streams
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
      _locationPermissionGranted = true;

      final pos = await Geolocator.getCurrentPosition();
      _setCurrentPosition(pos, animateCamera: true);

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).listen((p) => _setCurrentPosition(p));
    } else {
      setState(() => _locationPermissionGranted = false);
    }
  }

  void _setCurrentPosition(Position pos, {bool animateCamera = false}) async {
    _currentPos = pos;
    _initialLatLng = LatLng(pos.latitude, pos.longitude);
    if (animateCamera && _controller.isCompleted) {
      final c = await _controller.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialLatLng, zoom: 13),
        ),
      );
    }
    _recomputeMarkers();
  }

  void _subscribeToEvents() {
    _sub = FirebaseFirestore.instance.collection('events').snapshots().listen(
      (snap) async {
        _eventDocs = snap.docs;
        _recomputeMarkers();
      },
    );
  }

  //Proximity/Markers
  double _distanceMilesBetween(
      double lat1, double lng1, double lat2, double lng2) {
    final meters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return meters / 1609.344; //meters -> miles
  }

  void _recomputeMarkers() async {
    if (!mounted) return;

    final nextMarkers = <Marker>{};
    final nextCircles = <Circle>{};

    final pos = _currentPos;

    //draw the radius circle if we know user location
    if (pos != null) {
      nextCircles.add(
        Circle(
          circleId: const CircleId('proximity'),
          center: LatLng(pos.latitude, pos.longitude),
          radius: _radiusMi * 1609.344, //miles -> meters
          strokeWidth: 2,
          strokeColor: curiousBlue.shade400.withOpacity(0.8),
          fillColor: curiousBlue.shade400.withOpacity(0.12),
        ),
      );
    }

    //build filtered markers
    for (final doc in _eventDocs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      bool withinRadius = true;
      double? dMi;

      if (pos != null) {
        dMi = _distanceMilesBetween(pos.latitude, pos.longitude, lat, lng);
        withinRadius = dMi <= _radiusMi;
      }

      //if the page was opened with a focus target then include that marker
      final isFocusTarget = (doc.id == _focusEventId);

      if (withinRadius || isFocusTarget) {
        final title = (data['title'] ?? '') as String;
        final address = (data['location'] ?? '') as String;

        nextMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            //default tap opens the info window
            infoWindow: InfoWindow(
              title: title.isEmpty ? 'Event' : title,
              snippet: () {
                final distLabel =
                    dMi == null ? null : '${dMi.toStringAsFixed(1)} mi';
                if (address.isEmpty && distLabel != null) return '$distLabel away';
                if (address.isEmpty) return null;
                return distLabel == null ? address : '$address • $distLabel';
              }(),
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
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(nextMarkers);
      _circles
        ..clear()
        ..addAll(nextCircles);
    });

    await _focusIfNeeded();

    if (!_didFocus && _markers.isNotEmpty) {
      await _fitToMarkers(padding: 80);
    }
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
        circles: _circles,
        onMapCreated: (c) => _controller.complete(c),
      ),
    );
  }
}
