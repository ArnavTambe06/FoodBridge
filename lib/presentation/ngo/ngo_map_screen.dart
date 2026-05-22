// lib/presentation/ngo/ngo_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/food.dart';
import 'ngo_food_detail_screen.dart';

class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  State<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  final _supabase = Supabase.instance.client;
  final _mapController = MapController();

  LatLng? _currentLocation;
  List<Food> _nearbyFoods = [];
  bool _isLoadingLocation = true;
  bool _isLoadingFoods = false;
  Food? _selectedFood;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Please enable location services.',
            isError: true);
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLocation =
            LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      await _loadNearbyFoods();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackbar('Could not get location. Please retry.',
          isError: true);
    }
  }

  Future<void> _loadNearbyFoods() async {
    if (_currentLocation == null) return;
    setState(() => _isLoadingFoods = true);
    try {
      final data =
      await _supabase.rpc('get_nearby_foods', params: {
        'lat': _currentLocation!.latitude,
        'lng': _currentLocation!.longitude,
        'radius_metres': 5000,
      });
      setState(() {
        _nearbyFoods =
            (data as List).map((e) => Food.fromJson(e)).toList();
      });
    } catch (e) {
      _showSnackbar('Failed to load nearby foods.',
          isError: true);
    } finally {
      setState(() => _isLoadingFoods = false);
    }
  }

  LatLng? _parseLocation(String location) {
    try {
      final clean = location
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .trim();
      final parts = clean.split(' ');
      return LatLng(
          double.parse(parts[1]), double.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  void _centerOnMe() {
    if (_currentLocation == null) return;
    _mapController.move(_currentLocation!, 15);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Location Required',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
        content: Text(
          'FoodBridge needs your location to show nearby food donations.',
          style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryContainer
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Open Settings',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter()),
      backgroundColor:
      isError ? Colors.red[700] : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────
          _isLoadingLocation
              ? _buildLocationLoading()
              : _currentLocation == null
              ? _buildLocationError()
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 15,
              onTap: (_, __) =>
                  setState(() => _selectedFood = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.arnav.foodbridge',
              ),
              MarkerLayer(
                markers: [
                  // Current location
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset:
                              const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 16),
                        ),
                      ),
                    ),

                  // Food markers
                  ..._nearbyFoods.map((food) {
                    final coords =
                    _parseLocation(food.location);
                    if (coords == null) {
                      return Marker(
                        point: _currentLocation!,
                        child: const SizedBox.shrink(),
                      );
                    }
                    final isSelected =
                        _selectedFood?.id == food.id;
                    return Marker(
                      point: coords,
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 52 : 44,
                      child: GestureDetector(
                        onTap: () => setState(
                                () => _selectedFood = food),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [
                                AppColors.secondary,
                                const Color(
                                    0xFFB05A3A),
                              ]
                                  : [
                                AppColors.primary,
                                AppColors
                                    .primaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end:
                              Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                    ? AppColors
                                    .secondary
                                    : AppColors
                                    .primary)
                                    .withOpacity(0.35),
                                blurRadius: 12,
                                offset:
                                const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: Colors.white,
                            size: isSelected ? 24 : 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── Top Bar ───────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryContainer
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingFoods
                              ? 'Finding nearby food...'
                              : '${_nearbyFoods.length} donations nearby',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Within 5km radius',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingFoods)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // ── FABs ──────────────────────────────────────────
          Positioned(
            bottom: _selectedFood != null ? 260 : 100,
            right: 16,
            child: Column(
              children: [
                _mapFab(
                  icon: Icons.refresh_rounded,
                  onTap: _loadNearbyFoods,
                ),
                const SizedBox(height: 10),
                _mapFab(
                  icon: Icons.my_location_rounded,
                  onTap: _centerOnMe,
                  isPrimary: true,
                ),
              ],
            ),
          ),

          // ── Food Bottom Sheet ─────────────────────────────
          if (_selectedFood != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child:
              _buildFoodBottomSheet(_selectedFood!),
            ),
        ],
      ),
    );
  }

  Widget _mapFab({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryContainer
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isPrimary
                ? null
                : AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPrimary
                ? Colors.white
                : AppColors.primary,
            size: 20,
          ),
        ),
      );

  Widget _buildFoodBottomSheet(Food food) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: food.imageUrls.isNotEmpty
                      ? Image.network(
                    food.imageUrls.first,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imgPlaceholder(),
                  )
                      : _imgPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.foodName,
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.quantity,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed
                                  .withOpacity(0.5),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.timer_outlined,
                                    size: 11,
                                    color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatExpiry(
                                      food.expiryTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (food.distanceM != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors
                                    .surfaceContainerLow,
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(food.distanceM! / 1000).toStringAsFixed(1)} km',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                  AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFood = null),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 16),
                  ),
                ),
              ],
            ),
          ),

          // CTA Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFood = null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NgoFoodDetailScreen(food: food),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'VIEW DETAILS & REQUEST',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(Icons.fastfood_outlined,
        color:
        AppColors.onSurfaceVariant.withOpacity(0.4),
        size: 30),
  );

  Widget _buildLocationLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Getting your location...',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Finding food donations near you',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _buildLocationError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.location_off_rounded,
                color: Colors.red[400], size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Location unavailable',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need your location to show\nnearby food donations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _initLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryContainer
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return '${diff.inMinutes}m left';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}