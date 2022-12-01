import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class MyHandler extends TaskHandler{

  StreamSubscription<Position>? stream;
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print("destroyed at $timestamp");
    stream?.cancel();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    print("event called at $timestamp");
    FlutterForegroundTask.updateService(
        notificationText: "event called at $timestamp");
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("started at $timestamp");

    var stream;
    try {
      late LocationSettings settings;
      if(Platform.isIOS) {
        settings = AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
            distanceFilter: 15,
            activityType: ActivityType.automotiveNavigation
        );
      }else{
        settings = AndroidSettings(
          intervalDuration: const Duration(seconds: 10),
          accuracy: LocationAccuracy.bestForNavigation,
        );
      }
      stream = Geolocator.getPositionStream(
          locationSettings: settings);
    }catch (e){
      print("in init -> $e");
    }

    try {
      this.stream = stream.listen((position) {
        print("position stream called with -> $position");

        FlutterForegroundTask.updateService(
            notificationText: "Location $position");

        sendPort?.send({"lat":position.latitude,"lng":position.longitude});
      });
    }catch(e){
      print("in subscription -> $e");
    }
  }

}