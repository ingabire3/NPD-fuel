import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/register_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/loading_overlay.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── Personal ──────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // ── Home location ─────────────────────────────────────────────────────────
  double? _homeLat;
  double? _homeLng;
  String? _homeAddress;
  bool _fetchingHome = false;
  String? _homeGpsError;
  // Manual fallback fields (always shown; auto-filled by GPS)
  final _homeLatCtrl = TextEditingController();
  final _homeLngCtrl = TextEditingController();

  // ── Work location ─────────────────────────────────────────────────────────
  double? _workLat;
  double? _workLng;
  String? _workAddress;
  final _workSearchCtrl = TextEditingController();
  bool _searchingWork = false;
  String? _workSearchError;
  // Manual fallback
  final _workLatCtrl = TextEditingController();
  final _workLngCtrl = TextEditingController();
  bool _showManualWork = false;

  // ── Calculated distance ───────────────────────────────────────────────────
  double? _distanceKm;

  // ── Vehicle ───────────────────────────────────────────────────────────────
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _tankCtrl = TextEditingController();
  final _efficiencyCtrl = TextEditingController();
  String _fuelType = 'PETROL';

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _homeLatCtrl.dispose();
    _homeLngCtrl.dispose();
    _workSearchCtrl.dispose();
    _workLatCtrl.dispose();
    _workLngCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _tankCtrl.dispose();
    _efficiencyCtrl.dispose();
    super.dispose();
  }

  // ── GPS home detection ────────────────────────────────────────────────────

  Future<void> _detectHomeLocation() async {
    setState(() {
      _fetchingHome = true;
      _homeGpsError = null;
    });
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _homeLat = result.lat;
        _homeLng = result.lng;
        _homeAddress = result.address;
        _homeLatCtrl.text = result.lat.toStringAsFixed(6);
        _homeLngCtrl.text = result.lng.toStringAsFixed(6);
        _fetchingHome = false;
      });
      _recalcDistance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _homeGpsError = e.toString();
        _fetchingHome = false;
      });
    }
  }

  // ── Work location search ──────────────────────────────────────────────────

  Future<void> _searchWorkLocation() async {
    final q = _workSearchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searchingWork = true;
      _workSearchError = null;
    });
    try {
      final result = await LocationService.searchAddress(q);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _workSearchError = 'Location not found. Try a more specific address or use manual input.';
          _searchingWork = false;
        });
        return;
      }
      setState(() {
        _workLat = result.lat;
        _workLng = result.lng;
        _workAddress = result.address;
        _workLatCtrl.text = result.lat.toStringAsFixed(6);
        _workLngCtrl.text = result.lng.toStringAsFixed(6);
        _searchingWork = false;
        _showManualWork = false;
      });
      _recalcDistance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _workSearchError = 'Search failed. Try again or use manual input.';
        _searchingWork = false;
      });
    }
  }

  // ── Parse manual coord fields into state ──────────────────────────────────

  void _applyManualHome() {
    final lat = double.tryParse(_homeLatCtrl.text.trim());
    final lng = double.tryParse(_homeLngCtrl.text.trim());
    if (lat != null && lng != null) {
      setState(() {
        _homeLat = lat;
        _homeLng = lng;
        _homeAddress = null;
      });
      _recalcDistance();
    }
  }

  void _applyManualWork() {
    final lat = double.tryParse(_workLatCtrl.text.trim());
    final lng = double.tryParse(_workLngCtrl.text.trim());
    if (lat != null && lng != null) {
      setState(() {
        _workLat = lat;
        _workLng = lng;
        _workAddress = null;
      });
      _recalcDistance();
    }
  }

  // ── Haversine distance preview ────────────────────────────────────────────

  void _recalcDistance() {
    if (_homeLat != null && _homeLng != null && _workLat != null && _workLng != null) {
      setState(() {
        _distanceKm = LocationService.haversineKm(
          _homeLat!,
          _homeLng!,
          _workLat!,
          _workLng!,
        );
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    // Parse manual coords into state before validating
    _applyManualHome();
    _applyManualWork();

    if (!_formKey.currentState!.validate()) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    // Location must be set (either via GPS/search or manual)
    if (_homeLat == null || _homeLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please set your home location (GPS or manual)'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (_workLat == null || _workLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please set your work location (search or manual)'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    ref.read(registerProvider.notifier).register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          homeLat: _homeLat!,
          homeLng: _homeLng!,
          homeAddress: _homeAddress,
          workLat: _workLat!,
          workLng: _workLng!,
          workAddress: _workAddress,
          plateNumber: _plateCtrl.text.trim().toUpperCase(),
          vehicleMake: _makeCtrl.text.trim(),
          vehicleModel: _modelCtrl.text.trim(),
          vehicleYear: int.parse(_yearCtrl.text.trim()),
          fuelType: _fuelType,
          tankCapacity: double.parse(_tankCtrl.text.trim()),
          averageKmPerL: _efficiencyCtrl.text.trim().isEmpty
              ? null
              : double.parse(_efficiencyCtrl.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registerProvider);

    ref.listen(registerProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      if (next.isSuccess) {
        _showSuccessDialog(next.successMessage ?? 'Registration submitted!');
      }
    });

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        goBack();
      },
      child: LoadingOverlay(
        isLoading: regState.isLoading,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            title: Row(
              children: [
                IconButton(
                  onPressed: goBack,
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(44, 44),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Sign Up',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('Create your account',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // ── Personal ─────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.person_outline,
                        title: 'Personal Information'),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'e.g. Jean Mutoni',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Full name is required';
                        if (v.trim().length < 3) return 'Name too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      hint: 'e.g. jean@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _phoneCtrl,
                      label: 'Phone Number (optional)',
                      hint: 'e.g. 0780000010',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: _inputDeco(
                        label: 'Password',
                        hint: 'Min 8 characters',
                        icon: Icons.lock_outlined,
                        suffix: _eyeBtn(
                          obscure: _obscurePass,
                          onTap: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      decoration: _inputDeco(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outlined,
                        suffix: _eyeBtn(
                          obscure: _obscureConfirm,
                          onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Locations ─────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.location_on_outlined,
                        title: 'Home & Work Locations'),
                    const SizedBox(height: 16),
                    _LocationSectionTitle(label: '🏠 Home Location'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fetchingHome ? null : _detectHomeLocation,
                        icon: _fetchingHome
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        label: Text(_fetchingHome
                            ? 'Detecting location…'
                            : _homeLat != null
                                ? 'Location detected — tap to refresh'
                                : 'Use My Current Location (GPS)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: _homeLat != null ? AppColors.success : AppColors.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (_homeGpsError != null) _ErrorTile(message: _homeGpsError!),
                    if (_homeLat != null) ...[
                      const SizedBox(height: 10),
                      _LocationCard(
                        address: _homeAddress ??
                            'Lat ${_homeLat!.toStringAsFixed(5)}, Lng ${_homeLng!.toStringAsFixed(5)}',
                        lat: _homeLat!,
                        lng: _homeLng!,
                        onClear: () => setState(() {
                          _homeLat = null;
                          _homeLng = null;
                          _homeAddress = null;
                          _homeLatCtrl.clear();
                          _homeLngCtrl.clear();
                          _distanceKm = null;
                        }),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _ManualCoordRow(
                      latCtrl: _homeLatCtrl,
                      lngCtrl: _homeLngCtrl,
                      latHint: 'e.g. -1.9325',
                      lngHint: 'e.g. 30.1065',
                      label: 'Or enter manually',
                      onChanged: (_) => _applyManualHome(),
                    ),
                    const SizedBox(height: 20),
                    _LocationSectionTitle(label: '🏢 Work Location'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _workSearchCtrl,
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchWorkLocation(),
                            decoration: _inputDeco(
                              label: 'Search work location',
                              hint: 'e.g. Kigali City Tower, Rwanda',
                              icon: Icons.search,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _searchingWork ? null : _searchWorkLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.zero,
                            ),
                            child: _searchingWork
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.search, size: 20),
                          ),
                        ),
                      ],
                    ),
                    if (_workSearchError != null) _ErrorTile(message: _workSearchError!),
                    if (_workLat != null) ...[
                      const SizedBox(height: 10),
                      _LocationCard(
                        address: _workAddress ??
                            'Lat ${_workLat!.toStringAsFixed(5)}, Lng ${_workLng!.toStringAsFixed(5)}',
                        lat: _workLat!,
                        lng: _workLng!,
                        onClear: () => setState(() {
                          _workLat = null;
                          _workLng = null;
                          _workAddress = null;
                          _workLatCtrl.clear();
                          _workLngCtrl.clear();
                          _distanceKm = null;
                        }),
                      ),
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showManualWork = !_showManualWork),
                      child: Row(
                        children: [
                          Icon(
                            _showManualWork
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showManualWork
                                ? 'Hide manual input'
                                : 'Enter coordinates manually instead',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (_showManualWork) ...[
                      const SizedBox(height: 8),
                      _ManualCoordRow(
                        latCtrl: _workLatCtrl,
                        lngCtrl: _workLngCtrl,
                        latHint: 'e.g. -1.9441',
                        lngHint: 'e.g. 30.0619',
                        label: 'Work coordinates',
                        onChanged: (_) => _applyManualWork(),
                      ),
                    ],
                    if (_distanceKm != null) ...[
                      const SizedBox(height: 16),
                      _DistancePreviewCard(distanceKm: _distanceKm!),
                    ],
                    const SizedBox(height: 28),

                    // ── Vehicle ───────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.directions_car_outlined,
                        title: 'Vehicle Details'),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _plateCtrl,
                      label: 'Plate Number',
                      hint: 'e.g. RAB 001 A',
                      icon: Icons.confirmation_number_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Plate number is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _makeCtrl,
                            label: 'Make',
                            hint: 'e.g. Toyota',
                            icon: Icons.business_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            controller: _modelCtrl,
                            label: 'Model',
                            hint: 'e.g. Hilux',
                            icon: Icons.directions_car_filled_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _yearCtrl,
                            label: 'Year',
                            hint: 'e.g. 2022',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final y = int.tryParse(v);
                              if (y == null || y < 1980 || y > DateTime.now().year + 1) {
                                return 'Invalid year';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            controller: _tankCtrl,
                            label: 'Tank (L)',
                            hint: 'e.g. 80',
                            icon: Icons.local_gas_station_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: _inputDeco(
                          label: 'Fuel Type', icon: Icons.oil_barrel_outlined),
                      items: const [
                        DropdownMenuItem(value: 'PETROL', child: Text('Petrol')),
                        DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                      ],
                      onChanged: (v) => setState(() => _fuelType = v!),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _efficiencyCtrl,
                      label: 'Fuel Efficiency (km/L) — optional',
                      hint: 'e.g. 8.5',
                      icon: Icons.speed_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Invalid efficiency';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Submit ────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: regState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: const Text('Submit Registration',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Already have an account? Sign In',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  // ── Success dialog ────────────────────────────────────────────────────────

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Registration Submitted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'An admin will review your request. You can log in once approved.',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Go to Login'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Decoration helpers ────────────────────────────────────────────────────

  InputDecoration _inputDeco({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  Widget _eyeBtn({required bool obscure, required VoidCallback onTap}) =>
      IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: onTap,
      );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        ],
      );
}

class _LocationSectionTitle extends StatelessWidget {
  final String label;
  const _LocationSectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );
}

class _LocationCard extends StatelessWidget {
  final String address;
  final double lat;
  final double lng;
  final VoidCallback onClear;

  const _LocationCard(
      {required this.address,
      required this.lat,
      required this.lng,
      required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(
                      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

class _DistancePreviewCard extends StatelessWidget {
  final double distanceKm;
  const _DistancePreviewCard({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final daily = distanceKm * 2;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated daily distance',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 2),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km one-way  ·  ${daily.toStringAsFixed(1)} km/day',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                Text('Used for monthly fuel estimation',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCoordRow extends StatelessWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final String latHint;
  final String lngHint;
  final String label;
  final ValueChanged<String>? onChanged;

  const _ManualCoordRow({
    required this.latCtrl,
    required this.lngCtrl,
    required this.latHint,
    required this.lngHint,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _CoordField(
                  controller: latCtrl,
                  label: 'Latitude',
                  hint: latHint,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoordField(
                  controller: lngCtrl,
                  label: 'Longitude',
                  hint: lngHint,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      );
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _CoordField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        style: const TextStyle(fontSize: 13),
      );
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error)),
              ),
            ],
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: validator,
      );
}
