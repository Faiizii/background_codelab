import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:map_launcher/map_launcher.dart' as ml;
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_math/vector_math.dart';

class MapUtils {

  static double getRotation(LatLng start, LatLng end) {
    double latDiff = _abs(start.latitude - end.latitude);
    double lngDiff = _abs(start.longitude - end.longitude);

    double rotation = -1;
    if (start.latitude < end.latitude && start.longitude < end.longitude) {
      rotation = degrees(atan(lngDiff / latDiff)).toDouble();
    }
    if (start.latitude >= end.latitude && start.longitude < end.longitude) {
      rotation = (90 - degrees(atan(lngDiff / latDiff)) + 90).toDouble();
    }
    if (start.latitude >= end.latitude && start.longitude >= end.longitude) {
      rotation = (degrees(atan(lngDiff / latDiff)) + 180).toDouble();
    }
    if (start.latitude < end.latitude && start.longitude >= end.longitude) {
      rotation = (90 - degrees(atan(lngDiff / latDiff)) + 270).toDouble();
    }
    return rotation;
  }

  static double _abs(double value){
    if(value < 0) value = value * -1;
    return value;
  }


  static Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec =
    await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
  }


  static Future<void> launchTurnByTurnNavigationInGoogleMaps() async{

    double sLat = 31.589158;
    double sLng = 74.4642858;


    double dLat = 31.5904095;
    double dLng = 74.4559383;

    if(Platform.isAndroid) {
      AndroidIntent mapIntent = AndroidIntent(
          action:'action_view',
          package: 'com.google.android.apps.maps',
          data: 'google.navigation:q=$dLat,$dLng'
      );
      mapIntent.launch();
    } else if(Platform.isIOS){
      String url = "https://www.google.com/maps/dir/?api=1&origin=$sLat,$sLng&destination=$dLat,$dLng&travelmode=driving&dir_action=navigate";
      if (await ml.MapLauncher.isMapAvailable(ml.MapType.google) ?? false) {
        await ml.MapLauncher.showDirections(
            mapType: ml.MapType.google,
            origin: ml.Coords(sLat,sLng),
            destination: ml.Coords(dLat,dLng),
            directionsMode: ml.DirectionsMode.driving
        );
      } else if(await ml.MapLauncher.isMapAvailable(ml.MapType.apple) ?? false) {
        await ml.MapLauncher.showDirections(
            mapType: ml.MapType.apple,
            origin: ml.Coords(sLat,sLng),
            destination: ml.Coords(dLat,dLng),
            directionsMode: ml.DirectionsMode.driving
        );
      } else{
        await launchUrl(Uri.parse(url));
      }
    }
  }
}