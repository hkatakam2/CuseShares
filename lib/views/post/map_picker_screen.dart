import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding; // Use prefix to avoid conflicts
import 'package:location/location.dart'; // For user's current location
import 'dart:io'; // For Platform check

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerScreen({Key? key, required this.initialPosition}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  // Marker? _marker; // Using center pin instead of draggable marker
  String _pickedAddress = "Fetching address...";
  bool _isLoading = false;
  bool _isGettingUserLocation = false;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition; // Start with initial position
    _updateAddress(widget.initialPosition); // Fetch initial address
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
     // Apply dark mode styling if needed when map is created
     _setMapStyle();
  }

  // Apply map style based on theme
  void _setMapStyle() async {
    if (_mapController == null || !mounted) return;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      // TODO: Load dark map style JSON from assets if you have one
      // String darkStyle = await DefaultAssetBundle.of(context).loadString('assets/map_styles/dark_mode.json');
      // _mapController!.setMapStyle(darkStyle);
       _mapController!.setMapStyle(null); // Reset to default for now
    } else {
      _mapController!.setMapStyle(null); // Reset to default light style
    }
  }


  void _onCameraMove(CameraPosition position) {
    // Could potentially show a "loading" state on the address while moving
     if (!mounted) return;
     setState(() {
        _isLoading = true; // Show loading indicator while moving
        _pickedAddress = "Moving map...";
     });
  }

  void _onCameraIdle() async {
    if (_mapController != null && mounted) {
        LatLng center = await _getCenter();
         _pickedLocation = center;
        _updateAddress(center); // Fetch address for the final center position
    }
  }

  Future<LatLng> _getCenter() async {
    if (_mapController == null) return widget.initialPosition;
    // Use screen coordinates to calculate center to be more robust
    if (!mounted) return widget.initialPosition; // Check mounted before accessing context
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height; // Be careful with context access
    ScreenCoordinate centerPoint = ScreenCoordinate(x: (screenWidth / 2).round(), y: (screenHeight / 2).round());
    LatLng centerLatLng = await _mapController!.getLatLng(centerPoint);
    return centerLatLng;
    // Fallback using visibleRegion (less accurate if map tilted/rotated)
    // LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();
    // LatLng center = LatLng(
    //   (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
    //   (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
    // );
    // return center;
  }


  Future<void> _updateAddress(LatLng position) async {
    if (!mounted) return;
    setState(() { _isLoading = true; }); // Ensure loading state is set

    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        // Optionally set localeIdentifier: 'en_US'
      );
      if (mounted && placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        _pickedAddress = "${place.street ?? ''}${place.street != null && place.locality != null ? ', ' : ''}${place.locality ?? ''}${place.locality != null && place.administrativeArea != null ? ', ' : ''}${place.administrativeArea ?? ''} ${place.postalCode ?? ''}".trim();
         if (_pickedAddress.startsWith(',')) _pickedAddress = _pickedAddress.substring(1).trim();
         if (_pickedAddress.isEmpty) _pickedAddress = "Address not found at this location";
      } else if (mounted) {
        _pickedAddress = "Address not found";
      }
    } catch (e) {
      print("Error fetching address: $e");
       if (mounted) _pickedAddress = "Could not fetch address";
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _goToUserLocation() async {
      if (!mounted) return;
      setState(() { _isGettingUserLocation = true; });
      try {
          var serviceEnabled = await _locationService.serviceEnabled();
          if (!serviceEnabled) {
              serviceEnabled = await _locationService.requestService();
              if (!serviceEnabled) throw Exception("Location service disabled");
          }

          var permissionGranted = await _locationService.hasPermission();
          if (permissionGranted == PermissionStatus.denied) {
              permissionGranted = await _locationService.requestPermission();
              if (permissionGranted != PermissionStatus.granted) throw Exception("Location permission denied");
          }

          final LocationData currentLocation = await _locationService.getLocation();
          if (mounted && currentLocation.latitude != null && currentLocation.longitude != null) {
              final userLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15.0));
              // Address will update via _onCameraIdle after animation
          }
      } catch (e) {
          print("Error getting user location: $e");
           if (mounted) _showPlatformDialog("Location Error", "Could not get current location: ${e.toString()}");
      } finally {
           if (mounted) setState(() { _isGettingUserLocation = false; });
      }
  }


  void _confirmSelection() {
    if (_pickedLocation != null) {
      Navigator.pop(context, {
        'latlng': _pickedLocation!,
        'address': _pickedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
     // Update map style if theme changes
     _setMapStyle();

    final Widget mapWidget = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 15.0,
      ),
      // markers: _marker != null ? {_marker!} : {}, // Don't show marker, use center pin
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: Platform.isAndroid, // Only show zoom controls on Android
      compassEnabled: false, // Hide compass
      mapToolbarEnabled: false, // Hide toolbar
      mapType: MapType.normal,
    );

    final Widget body = Stack(
      children: [
        mapWidget,
        // Center Marker Pin
         Center(
           child: Padding(
             padding: const EdgeInsets.only(bottom: 40.0), // Adjust so pin bottom is at center
             child: Icon(Platform.isIOS ? CupertinoIcons.map_pin_ellipse : Icons.location_pin, size: 40.0, color: Colors.orange[700]),
           ),
         ),
        // Address Display Card at Bottom
        Positioned(
          bottom: 80,
          left: 10,
          right: 10,
          child: Card(
             elevation: 4.0,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                  children: [
                      Icon(Platform.isIOS ? CupertinoIcons.location_solid : Icons.location_on, color: Theme.of(context).primaryColor),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              _isLoading ? "Fetching address..." : _pickedAddress,
                              style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ),
                      if (_isLoading) SizedBox(width: 20, height: 20, child: Platform.isIOS ? CupertinoActivityIndicator(radius: 10) : CircularProgressIndicator(strokeWidth: 2)),
                  ],
              ),
            ),
          ),
        ),
         // My Location Button
         Positioned(
            top: MediaQuery.of(context).padding.top + (Platform.isIOS ? 60 : 15), // Adjust based on AppBar/StatusBar
            right: 15,
            child: Platform.isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: CircleAvatar( // Wrap in CircleAvatar for background
                     radius: 22, // Slightly larger tap target
                     backgroundColor: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.8),
                     child: _isGettingUserLocation
                       ? CupertinoActivityIndicator()
                       : Icon(CupertinoIcons.location_fill, color: CupertinoTheme.of(context).primaryColor),
                  ),
                  onPressed: _isGettingUserLocation ? null : _goToUserLocation,
                )
              : FloatingActionButton(
                  mini: true,
                  onPressed: _isGettingUserLocation ? null : _goToUserLocation,
                  child: _isGettingUserLocation
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location),
                  heroTag: 'myLocationBtn',
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
          ),
      ],
    );

     final PreferredSizeWidget appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: Text('Pick Location'),
            previousPageTitle: 'Create Post', // Provide back button context
            trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isLoading ? null : _confirmSelection,
            ),
          )
        : AppBar(
            title: Text('Pick Location'),
            actions: [
                IconButton(
                    icon: Icon(Icons.check),
                    tooltip: 'Confirm Location',
                    onPressed: _isLoading ? null : _confirmSelection,
                )
            ],
          );

      // Confirm Button
      final Widget confirmButton = Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 15, // Adjust for safe area + padding
              left: 20,
              right: 20,
              top: 15
          ),
          child: SizedBox(
            width: double.infinity,
            child: Platform.isIOS
              ? CupertinoButton.filled(
                  child: Text('Confirm This Location'),
                  onPressed: _isLoading ? null : _confirmSelection,
                )
              : ElevatedButton( // Use ElevatedButton for Material consistency
                  child: Text('Confirm This Location'),
                  onPressed: _isLoading ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
          ),
        );


    return Platform.isIOS
      ? CupertinoPageScaffold(
          navigationBar: appBar as ObstructingPreferredSizeWidget,
          child: Stack(children: [body, Positioned(bottom: 0, left: 0, right: 0, child: Material( // Material needed for elevation/shadow on button background
             color: CupertinoTheme.of(context).scaffoldBackgroundColor.withOpacity(0.9), // Slightly transparent background
             child: confirmButton))]),
        )
      : Scaffold(
          appBar: appBar,
          body: body,
          // Use bottomNavigationBar for Material button placement
          bottomNavigationBar: Material( // Material needed for elevation/shadow
             elevation: 8.0,
             child: confirmButton
          ),
        );
  }

   // --- Helper for Platform Dialog ---
  void _showPlatformDialog(String title, String content) {
      if (!mounted) return; // Check if mounted before showing dialog
      if (Platform.isIOS) {
          showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                  title: Text(title),
                  content: Text(content),
                  actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('OK'), onPressed: () => Navigator.pop(context))],
              ),
          );
      } else {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                  title: Text(title),
                  content: Text(content),
                  actions: [TextButton(child: Text('OK'), onPressed: () => Navigator.pop(context))],
              ),
          );
      }
  }
}