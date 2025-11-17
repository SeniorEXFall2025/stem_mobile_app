import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacePrediction {
  final String placeId;
  final String description;
  PlacePrediction({required this.placeId, required this.description});
}

class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final double lat;
  final double lng;

  PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

class PlacesService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  static Future<List<PlacePrediction>> autocomplete(String input,
      {String sessionToken = 'flutter-session'}) async {
    if (input.trim().isEmpty) return [];
    final uri = Uri.parse(
      '$_base/autocomplete/json?input=${Uri.encodeComponent(input)}'
      '&types=geocode&key=AIzaSyCf79RODA4K2SWZveZnraWI0pBA0CJ61yE&sessiontoken=$sessionToken',
      //Place this in a secure location once working!!!!^^^^
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final preds = (data['predictions'] as List?) ?? [];
    return preds
        .map((p) => PlacePrediction(
              placeId: p['place_id'],
              description: p['description'],
            ))
        .toList();
  }

  static Future<PlaceDetails?> details(String placeId,
      {String sessionToken = 'flutter-session'}) async {
    final uri = Uri.parse(
      '$_base/details/json?place_id=$placeId&key=AIzaSyCf79RODA4K2SWZveZnraWI0pBA0CJ61yE'
      '&sessiontoken=$sessionToken&fields=formatted_address,geometry',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result == null) return null;
    final loc = result['geometry']?['location'];
    if (loc == null) return null;
    return PlaceDetails(
      placeId: placeId,
      formattedAddress: result['formatted_address'] ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
    );
  }
}