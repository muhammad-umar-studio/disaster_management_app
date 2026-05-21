import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/places_service.dart';
import '../../home/providers/home_provider.dart';

class SafeZoneMapScreen extends StatefulWidget {
  const SafeZoneMapScreen({super.key});
  @override
  State<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
}

class _SafeZoneMapScreenState extends State<SafeZoneMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  GoogleMapController? _mapController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Hospitals', 'Shelters', 'Rescue'];

  LatLng _userLocation = const LatLng(24.8607, 67.0011);
  bool _locationLoaded = false;
  bool _placesLoading  = true;

  final Set<Marker>  _markers = {};
  final Set<Circle>  _circles = {};
  List<PlaceResult>  _places  = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadEverything();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    // 1) Location
    final loc = LocationService.cached ?? await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _userLocation = LatLng(loc.latitude, loc.longitude);
        _locationLoaded = true;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation, 14));
    }

    // 2) Places
    await _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    if (!mounted) return;
    setState(() => _placesLoading = true);
    _places = await PlacesService.getNearbyPlaces(
      lat: _userLocation.latitude,
      lng: _userLocation.longitude,
      filter: _selectedFilter,
    );
    _buildMarkers();
    if (mounted) setState(() => _placesLoading = false);
  }

  void _buildMarkers() {
    final newMarkers = <Marker>{};
    final newCircles  = <Circle>{};

    // User location
    newMarkers.add(Marker(
      markerId: const MarkerId('user'),
      position: _userLocation,
      infoWindow: const InfoWindow(title: '📍 Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      zIndex: 99,
    ));
    newCircles.add(Circle(
      circleId: const CircleId('user_radius'),
      center: _userLocation,
      radius: 500,
      fillColor: const Color(0xFF00E5FF).withOpacity(0.07),
      strokeColor: const Color(0xFF00E5FF).withOpacity(0.3),
      strokeWidth: 1,
    ));

    // Real place markers
    for (int i = 0; i < _places.length; i++) {
      final p = _places[i];
      final pos = LatLng(p.lat, p.lng);
      final hue = _markerHue(p.type);

      newMarkers.add(Marker(
        markerId: MarkerId('place_$i'),
        position: pos,
        infoWindow: InfoWindow(
          title: p.name,
          snippet: '${p.isOpen ? "OPEN" : "CLOSED"} · ${p.rating.toStringAsFixed(1)}★ · ${p.address}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _mapController?.showMarkerInfoWindow(MarkerId('place_$i')),
      ));

      newCircles.add(Circle(
        circleId: CircleId('circle_$i'),
        center: pos,
        radius: 100,
        fillColor: _typeColor(p.type).withOpacity(0.08),
        strokeColor: _typeColor(p.type).withOpacity(0.35),
        strokeWidth: 1,
      ));
    }

    setState(() {
      _markers..clear()..addAll(newMarkers);
      _circles..clear()..addAll(newCircles);
    });
  }

  double _markerHue(String type) {
    switch (type) {
      case 'hospital': return BitmapDescriptor.hueBlue;
      case 'shelter':  return BitmapDescriptor.hueGreen;
      case 'rescue':   return BitmapDescriptor.hueOrange;
      default:         return BitmapDescriptor.hueRed;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'hospital': return AppColors.cyanPrimary;
      case 'shelter':  return AppColors.safeGreen;
      case 'rescue':   return AppColors.warningOrange;
      default:         return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'hospital': return Icons.local_hospital_rounded;
      case 'shelter':  return Icons.home_rounded;
      case 'rescue':   return Icons.local_fire_department_rounded;
      default:         return Icons.location_on_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'hospital': return 'HOSPITAL';
      case 'shelter':  return 'SHELTER';
      case 'rescue':   return 'RESCUE';
      default:         return type.toUpperCase();
    }
  }

  Future<void> _dialPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(PlaceResult place) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}&query_place_id=${place.placeId}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(home),
          _buildGoogleMap(),
          _buildFilters(),
          Expanded(child: _buildPlacesList()),
        ]),
      ),
    );
  }

  Widget _buildHeader(HomeProvider home) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Safe Zone Map', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(home.locationName, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const Spacer(),
        // Refresh button
        GestureDetector(
          onTap: _loadPlaces,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderPrimary)),
            child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (ctx, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.safeGreen.withOpacity(0.1 + 0.05 * _pulseCtrl.value),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.gps_fixed_rounded, color: AppColors.safeGreen, size: 14),
              const SizedBox(width: 4),
              Text(_locationLoaded ? 'GPS LIVE' : 'LOCATING...',
                  style: const TextStyle(color: AppColors.safeGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }

  Widget _buildGoogleMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _userLocation, zoom: 14),
            onMapCreated: (ctrl) async {
              _mapController = ctrl;
              await ctrl.setMapStyle(_darkMapStyle);
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final sel = _selectedFilter == _filters[i];
            return GestureDetector(
              onTap: () async {
                setState(() => _selectedFilter = _filters[i]);
                await _loadPlaces();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.cyanPrimary : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? AppColors.cyanPrimary : AppColors.borderPrimary),
                ),
                child: Center(child: Text(_filters[i],
                    style: TextStyle(color: sel ? Colors.black : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_placesLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyanPrimary, strokeWidth: 2));
    }
    if (_places.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_off_rounded, color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text('No places found nearby', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          SizedBox(height: 4),
          Text('Try expanding your search or changing filter', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _places.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _PlaceCard(
        place: _places[i],
        color: _typeColor(_places[i].type),
        icon: _typeIcon(_places[i].type),
        label: _typeLabel(_places[i].type),
        onNavigate: () {
          _openMaps(_places[i]);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(_places[i].lat, _places[i].lng), 16));
        },
        onCall: () async {
          final phone = _places[i].phone ?? await PlacesService.getPhoneNumber(_places[i].placeId);
          if (phone != null) {
            _dialPhone(phone);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No phone number available for this location'), backgroundColor: Colors.orange));
          }
        },
      ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PlaceResult place;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  const _PlaceCard({required this.place, required this.color, required this.icon, required this.label, required this.onNavigate, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final statusColor = place.isOpen ? AppColors.safeGreen : AppColors.dangerRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(place.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(place.address, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(place.isOpen ? 'OPEN' : 'CLOSED', style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: AppColors.warningOrange, size: 12),
              const SizedBox(width: 2),
              Text(place.rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.warningOrange, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ]),
        const SizedBox(height: 10),
        // Capacity bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ),
          Text('~${(place.occupancy * 100).toInt()}% capacity', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: place.occupancy, backgroundColor: AppColors.bgSurface, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onNavigate,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(12)),
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.navigation_rounded, color: Colors.black, size: 16),
                  SizedBox(width: 6),
                  Text('Navigate', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onCall,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.safeGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.safeGreen.withOpacity(0.3))),
              child: const Icon(Icons.phone_rounded, color: AppColors.safeGreen, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sharePlace(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.aiPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.aiPurple.withOpacity(0.3))),
              child: const Icon(Icons.share_rounded, color: AppColors.aiPurple, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }

  void _sharePlace(BuildContext context) {
    final text = '🚨 *AEGIS Emergency Safe Zone* 🚨\n\n'
        '🏠 *Name:* ${place.name}\n'
        '📍 *Address:* ${place.address}\n'
        '📞 *Emergency Contact:* ${place.phone ?? "1122"}\n'
        '🏷️ *Type:* ${place.type.toUpperCase()}\n'
        '⭐ *Rating:* ${place.rating.toStringAsFixed(1)}\n\n'
        'Map Link: https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}\n\n'
        'Shared via AEGIS Crisis Intelligence.';
    Share.share(text, subject: 'Emergency Safe Zone Location');
  }
}

const String _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0a0e1a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0e1a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7a99"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#1a2040"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2040"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e3a5f"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#00e5ff"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1a2040"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#0d1520"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6b7a99"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0a1a10"}]},
  {"featureType":"poi.medical","elementType":"geometry","stylers":[{"color":"#0a1a2a"}]},
  {"featureType":"poi.medical","elementType":"labels.text.fill","stylers":[{"color":"#00e5ff"}]}
]''';
