import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import '../utils/logger.dart';
import '../utils/utils.dart';

/// Resolves a [regionLabel] and optional TheMealDB `strArea` from device location.
class LocationContext {
  final String? areaForMealDb;
  final String? countryName;
  final bool permissionDenied;
  final bool serviceDisabled;
  final String? error;

  const LocationContext({
    this.areaForMealDb,
    this.countryName,
    this.permissionDenied = false,
    this.serviceDisabled = false,
    this.error,
  });
}

class LocationContextService {
  LocationContextService._();
  static final LocationContextService instance = LocationContextService._();

  static const Map<String, String> _countryToMealArea = {
    'united states': 'American',
    'united states of america': 'American',
    'united kingdom': 'British',
    'united kingdom of great britain and northern ireland': 'British',
    'france': 'French',
    'germany': 'Unknown',
    'italy': 'Italian',
    'spain': 'Spanish',
    'portugal': 'Portuguese',
    'mexico': 'Mexican',
    'japan': 'Japanese',
    'india': 'Indian',
    'china': 'Chinese',
    'thailand': 'Thai',
    'russia': 'Russian',
    'australia': 'Unknown',
    'canada': 'Canadian',
    'türkiye': 'Turkish',
    'greece': 'Greek',
    'poland': 'Polish',
    'morocco': 'Moroccan',
    'jamaica': 'Jamaican',
    'kenya': 'Kenyan',
    'malaysia': 'Malaysian',
    'tunisia': 'Tunisian',
    'egypt': 'Egyptian',
    'vietnam': 'Vietnamese',
    'netherlands': 'Dutch',
    'croatia': 'Croatian',
    'ireland': 'Irish',
  };

  /// Best-effort [LocationContext] from GPS. Never throws; permission denied is surfaced in state.
  Future<LocationContext> resolve() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        AppLogger.info('[LocationContextService] location services disabled');
        return const LocationContext(serviceDisabled: true);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        AppLogger.info('[LocationContextService] location permission denied');
        return const LocationContext(permissionDenied: true);
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await geocoding.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) {
        return const LocationContext(error: 'no_placemark');
      }
      final p = placemarks.first;
      final country = (p.country ?? '').toLowerCase().trim();
      final area = _countryToMealArea[country];
      debugPrint('[LocationContextService] country=$country area=$area');
      AppLogger.info('[LocationContextService] country=$country area=$area');
      return LocationContext(
        areaForMealDb: area,
        countryName: p.country,
      );
    } catch (e, st) {
      AppLogger.error('[LocationContextService] $e', [e, st]);
      return LocationContext(error: e.toString());
    }
  }
}
