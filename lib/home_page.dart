import 'dart:async';
import 'dart:isolate';
import 'package:background_codelab/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{

  String textMessage = "Start";
  ReceivePort? _port;
  final Completer<GoogleMapController> _mapController = Completer();
  late Marker _marker;
  LatLng? currentLatLng,previousLatLng;
  late AnimationController _animController;


  @override
  void initState() {
    super.initState();
    _marker = const Marker(
        markerId: MarkerId("id"),
        position: LatLng(31,74)
    );
    MapUtils.getBytesFromAsset('images/car.png', 100).then((value){
      if(value != null){
        _marker = _marker.copyWith(iconParam: BitmapDescriptor.fromBytes(value));
        if(mounted){
          setState(() {});
        }
      }
    });
    _animController = AnimationController(duration:const Duration(seconds: 4),vsync: this);
    _animController.addListener(() {
      if (currentLatLng != null && previousLatLng != null) {
        final multiplier = _animController.value;
        final nextLocation = LatLng(
            multiplier * currentLatLng!.latitude + (1 - multiplier) * previousLatLng!.latitude,
            multiplier * currentLatLng!.longitude + (1 - multiplier) * previousLatLng!.longitude
        );
        final rotation = MapUtils.getRotation(previousLatLng!, nextLocation);
        _updateMarker(nextLocation, rotation);
      }
    });
    _registerIfReceiverRunning();
  }
  void _updateMarker(LatLng latLng,double rotation){
    if(rotation < 0) rotation = 0;
    setState(() {
      _marker = _marker.copyWith(positionParam: latLng,rotationParam: rotation,anchorParam: const Offset(0.5,0.5));
    });
    _updateCameraPosition(latLng);
  }
  void _updateCameraPosition(LatLng latLng) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng,zoom: 18)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: GoogleMap(
              markers: {_marker},
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              myLocationEnabled: true,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              initialCameraPosition: const CameraPosition(target: LatLng(31,74),zoom: 19),
              onMapCreated: (controller) {
                _mapController.complete(controller);
              },
            )),
            TextButton(onPressed: (){
              MapUtils.launchTurnByTurnNavigationInGoogleMaps();
            }, child: const Text("Open Navigation Map"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchBackgroundService,
        tooltip: 'Launch',
        child: Text(textMessage)
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _launchBackgroundService() async {

    var permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
    }
    if(permission != LocationPermission.always){
      await ph.Permission.locationAlways.request();
    }

    if(await FlutterForegroundTask.isRunningService){
      _closePort();
      FlutterForegroundTask.stopService();
      setState(() {
        textMessage = "Start";
      });
    }else {
      bool isStarted = await FlutterForegroundTask.startService(notificationTitle: "Location",
          notificationText: "In Progress....",
          callback: startCallback);

      if(isStarted){
        setState(() {
          textMessage = "Stop";
        });
        _registerReceiverPort(await FlutterForegroundTask.receivePort);
      }
    }
  }
  void _closePort(){
    _port?.close();
    _port = null;
  }
  bool _registerReceiverPort(ReceivePort? port){
    _closePort();
    if(port != null){
      _port = port;
      _port!.listen((message) {
        if(previousLatLng == null){
          previousLatLng = LatLng(message['lat'], message['lng']);
          currentLatLng = LatLng(message['lat'], message['lng']);
        }else{
          previousLatLng = currentLatLng;
          currentLatLng = LatLng(message['lat'], message['lng']);
          _animController.reset();
          _animController.forward();
        }
      });
      return true;
    }else{
      return false;
    }
  }

  void _registerIfReceiverRunning() async {
    if(await FlutterForegroundTask.isRunningService){
      textMessage = "Stop";
      bool isRestarted = await FlutterForegroundTask.restartService();
      if(isRestarted){
        _registerReceiverPort(await FlutterForegroundTask.receivePort);
      }
    }
  }

  @override
  void dispose() {
    _closePort();
    super.dispose();
  }
}
