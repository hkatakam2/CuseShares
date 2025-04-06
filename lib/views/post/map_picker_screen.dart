
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
  Marker? _marker;
  String _pickedAddress = "Fetching address...";
  bool _isLoading = false;
  bool _isGettingUserLocation = false;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition; // Start with initial position
    _updateMarkerAndAddress(widget.initialPosition);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    // Update picked location as camera moves, but maybe only update marker on idle?
    // _pickedLocation = position.target;
  }

  void _onCameraIdle() async {
    // Update marker and address when camera stops moving
    if (_mapController != null) {
        // This gets the center of the screen
        LatLng center = await _getCenter();
         _pickedLocation = center;
        _updateMarkerAndAddress(center);
    }
  }

  // Helper to get map center reliably
  Future<LatLng> _getCenter() async {
    if (_mapController == null) return widget.initialPosition; // Fallback
    LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();
    LatLng center = LatLng(
      (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
      (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
    );
    return center;
  }


  Future<void> _updateMarkerAndAddress(LatLng position) async {
    setState(() {
      _isLoading = true;
      _pickedLocation = position;
      _marker = Marker(
        markerId: MarkerId('pickedLocation'),
        position: position,
        infoWindow: InfoWindow(title: 'Selected Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    });

    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Construct a readable address
        _pickedAddress = "${place.street ?? ''}${place.street != null && place.locality != null ? ', ' : ''}${place.locality ?? ''}${place.locality != null && place.administrativeArea != null ? ', ' : ''}${place.administrativeArea ?? ''} ${place.postalCode ?? ''}".trim();
         if (_pickedAddress.startsWith(',')) _pickedAddress = _pickedAddress.substring(1).trim();
         if (_pickedAddress.isEmpty) _pickedAddress = "Address not found";

      } else {
        _pickedAddress = "Address not found";
      }
    } catch (e) {
      print("Error fetching address: $e");
      _pickedAddress = "Could not fetch address";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

   // --- Get User's Current Location ---
  Future<void> _goToUserLocation() async {
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
          if (currentLocation.latitude != null && currentLocation.longitude != null) {
              final userLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15.0));
              // Update marker and address after animation (optional, _onCameraIdle will handle it)
              // _updateMarkerAndAddress(userLatLng);
          }
      } catch (e) {
          print("Error getting user location: $e");
          // Show error to user
           _showPlatformDialog("Location Error", "Could not get current location: ${e.toString()}");
      } finally {
           setState(() { _isGettingUserLocation = false; });
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
    final Widget mapWidget = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 15.0,
      ),
      markers: _marker != null ? {_marker!} : {},
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      myLocationEnabled: true, // Show blue dot for user location
      myLocationButtonEnabled: false, // Disable default button, we use our own
      zoomControlsEnabled: true, // Show zoom controls
       mapType: MapType.normal,
    );

    final Widget body = Stack(
      children: [
        mapWidget,
        // Center Marker Pin (doesn't move with map) - visual guide
         Center(
           child: Padding(
             padding: const EdgeInsets.only(bottom: 40.0), // Adjust so pin bottom is at center
             child: Icon(Platform.isIOS ? CupertinoIcons.map_pin_ellipse : Icons.location_pin, size: 40.0, color: Colors.orange[700]),
           ),
         ),
        // Address Display Card at Bottom
        Positioned(
          bottom: 80, // Position above the confirm button
          left: 10,
          right: 10,
          child: Card(
             elevation: 4.0,
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
            top: Platform.isIOS ? 100 : 80, // Adjust based on AppBar/StatusBar
            right: 15,
            child: FloatingActionButton(
              mini: true,
              onPressed: _isGettingUserLocation ? null : _goToUserLocation,
              child: _isGettingUserLocation
                  ? (Platform.isIOS ? CupertinoActivityIndicator() : SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)))
                  : Icon(Platform.isIOS ? CupertinoIcons.location_fill : Icons.my_location),
              heroTag: 'myLocationBtn', // Avoid Hero tag conflicts if multiple FABs
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
      ],
    );

     final PreferredSizeWidget appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: Text('Pick Location'),
            trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Done'),
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

      // Confirm Button (Floating Action Button style)
      final Widget confirmButton = Padding(
          padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20), // Add padding
          child: SizedBox( // Ensure button takes full width
            width: double.infinity,
            child: Platform.isIOS
              ? CupertinoButton.filled(
                  child: Text('Confirm Location'),
                  onPressed: _isLoading ? null : _confirmSelection,
                )
              : FloatingActionButton.extended(
                  onPressed: _isLoading ? null : _confirmSelection,
                  label: Text('Confirm Location'),
                  icon: Icon(Icons.check),
                  // heroTag: 'confirmLocationBtn', // Avoid Hero tag conflicts
                ),
          ),
        );


    return Platform.isIOS
      ? CupertinoPageScaffold(
          navigationBar: appBar as ObstructingPreferredSizeWidget,
          child: Stack(children: [body, Positioned(bottom: 0, left: 0, right: 0, child: confirmButton)]), // Place button at bottom
        )
      : Scaffold(
          appBar: appBar,
          body: body,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Position FAB
          floatingActionButton: confirmButton,
        );
  }

   // --- Helper for Platform Dialog ---
  void _showPlatformDialog(String title, String content) {
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
