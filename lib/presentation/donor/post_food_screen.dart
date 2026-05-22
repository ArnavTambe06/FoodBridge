// lib/presentation/donor/post_food_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/food_repository.dart';
import '../../core/utils/cache_service.dart';
import '../../core/theme/app_theme.dart';
import 'my_donations_screen.dart';

class PostFoodScreen extends ConsumerStatefulWidget {
  const PostFoodScreen({super.key});

  @override
  ConsumerState<PostFoodScreen> createState() => _PostFoodScreenState();
}

class _PostFoodScreenState extends ConsumerState<PostFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _prepTime;
  DateTime? _expiryTime;
  String? _addressString;
  double? _lat;
  double? _lng;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  double _uploadProgress = 0;

  final _foodRepo = FoodRepository();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permission denied. Enable in settings.',
            isError: true);
        setState(() => _isFetchingLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _lat = position.latitude;
      _lng = position.longitude;
      final placemarks =
      await placemarkFromCoordinates(_lat!, _lng!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressString =
        '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
      }
    } catch (e) {
      _showSnackbar('Could not fetch location. Please retry.',
          isError: true);
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      _showSnackbar('Maximum 5 images allowed.');
      return;
    }
    if (source == ImageSource.gallery) {
      final remaining = 5 - _selectedImages.length;
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      final limited = picked.take(remaining).toList();
      setState(() {
        _selectedImages.addAll(limited.map((x) => File(x.path)));
      });
    } else {
      final picked =
      await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImages.add(File(picked.path)));
      }
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<void> _pickDateTime({required bool isExpiry}) async {
    final now = DateTime.now();
    final initialDate = isExpiry
        ? (_prepTime ?? now).add(const Duration(hours: 1))
        : now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    final result = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isExpiry) {
        _expiryTime = result;
      } else {
        _prepTime = result;
        if (_expiryTime != null && _expiryTime!.isBefore(result)) {
          _expiryTime = null;
        }
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Tap to select';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prepTime == null) {
      _showSnackbar('Please select preparation time.', isError: true);
      return;
    }
    if (_expiryTime == null) {
      _showSnackbar('Please select expiry time.', isError: true);
      return;
    }
    if (_lat == null || _lng == null) {
      _showSnackbar('Location not available. Please retry.',
          isError: true);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });
    try {
      await _foodRepo.postFood(
        foodName: _foodNameController.text.trim(),
        quantity: _quantityController.text.trim(),
        description: _descriptionController.text.trim(),
        expiryTime: _expiryTime!,
        lat: _lat!,
        lng: _lng!,
        images: _selectedImages,
        onUploadProgress: (progress) =>
            setState(() => _uploadProgress = progress),
      );
      if (mounted) {
        await CacheService.clearUserData();
        ref.invalidate(myDonationsProvider);
        _showSnackbar('Food posted successfully! 🎉');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackbar('Failed to post food: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface, size: 20),
              ),
            ),
            title: Text(
              'Post Food Donation',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Intro text
                    Text(
                      'Share your surplus food with\ncommunities that need it.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Food Details ──────────────────────────────
                    _sectionLabel('Food Details'),
                    const SizedBox(height: 12),

                    _buildField(
                      controller: _foodNameController,
                      label: 'Food Name',
                      hint: 'e.g. Biryani, Bread Loaves',
                      icon: Icons.fastfood_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Food name is required';
                        if (val.trim().length < 3)
                          return 'Minimum 3 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: 'e.g. 15 meals, 5 kg, 20 boxes',
                      icon: Icons.scale_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Quantity is required';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      hint:
                      'Ingredients, allergens, storage notes...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      maxLength: 300,
                      validator: null,
                    ),

                    const SizedBox(height: 28),

                    // ── Timing ────────────────────────────────────
                    _sectionLabel('Timing'),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.onSurface.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _timeTile(
                            label: 'Preparation Time',
                            icon: Icons.access_time_rounded,
                            value: _formatDateTime(_prepTime),
                            onTap: () =>
                                _pickDateTime(isExpiry: false),
                            isFirst: true,
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16),
                            color: AppColors.surfaceContainerHighest,
                          ),
                          _timeTile(
                            label: 'Expiry Time',
                            icon: Icons.timer_off_rounded,
                            value: _formatDateTime(_expiryTime),
                            onTap: _prepTime == null
                                ? () => _showSnackbar(
                                'Set preparation time first.')
                                : () =>
                                _pickDateTime(isExpiry: true),
                            error: (_prepTime != null &&
                                _expiryTime != null &&
                                _expiryTime!
                                    .isBefore(_prepTime!))
                                ? 'Expiry must be after prep time'
                                : null,
                            isFirst: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Location ──────────────────────────────────
                    _sectionLabel('Pickup Location'),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.onSurface.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed
                                  .withOpacity(0.5),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isFetchingLocation
                                ? Text(
                              'Detecting location...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color:
                                AppColors.onSurfaceVariant,
                              ),
                            )
                                : Text(
                              _addressString ??
                                  'Location not available',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _addressString != null
                                    ? AppColors.onSurface
                                    : Colors.red,
                                height: 1.4,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isFetchingLocation
                                ? null
                                : _fetchLocation,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                AppColors.surfaceContainerLow,
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: _isFetchingLocation
                                  ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                                  : const Icon(Icons.refresh_rounded,
                                  color: AppColors.primary,
                                  size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Photos ────────────────────────────────────
                    _sectionLabel('Food Photos (up to 5)'),
                    const SizedBox(height: 12),

                    // Image previews
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                          itemBuilder: (context, index) =>
                              _imageThumbnail(index),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Pick buttons
                    Row(
                      children: [
                        Expanded(
                          child: _imagePickerButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            onTap: () =>
                                _pickImages(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _imagePickerButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            onTap: () =>
                                _pickImages(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Upload progress
                    if (_isSubmitting &&
                        _selectedImages.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor:
                                AppColors.surfaceContainerHigh,
                                color: AppColors.primary,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    GestureDetector(
                      onTap: _isSubmitting ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: !_isSubmitting
                              ? const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: _isSubmitting
                              ? AppColors.surfaceContainerHighest
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: !_isSubmitting
                              ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                              : null,
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            'POST DONATION',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurface,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters:
        maxLines == 1 ? [LengthLimitingTextInputFormatter(100)] : [],
        style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(
              fontSize: 13, color: AppColors.onSurfaceVariant),
          hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          prefixIcon:
          Icon(icon, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: AppColors.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
        validator: validator,
      );

  Widget _timeTile({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    String? error,
    required bool isFirst,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value == 'Tap to select'
                            ? AppColors.onSurfaceVariant
                            .withOpacity(0.5)
                            : AppColors.onSurface,
                      ),
                    ),
                    if (error != null)
                      Text(error,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.red)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  size: 18),
            ],
          ),
        ),
      );

  Widget _imageThumbnail(int index) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          _selectedImages[index],
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: () => _removeImage(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.onSurface.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _imagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: _selectedImages.length >= 5 ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _selectedImages.length >= 5
                ? AppColors.surfaceContainerHighest
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: _selectedImages.length >= 5
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _selectedImages.length >= 5
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
}