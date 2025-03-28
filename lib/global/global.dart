import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/ui/utils/stream_subscriber_mixin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


import '../models/direction_details_with_polyline.dart';
import '../models/user_model.dart';
import '../models/driver_data.dart';


final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
User? currentUser;

StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;
//AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
UserModel? userModelCurrentInfo;

// Initialize with a default position to prevent null errors
Position driverCurrentPosition = Position(
  longitude: -122.085749655962,
  latitude: 37.42796133580664,
  timestamp: DateTime.now(),
  accuracy: 0.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
  altitudeAccuracy: 0.0,
  headingAccuracy: 0.0
);

DriverData onlineDriverData = DriverData(
  id: "test_driver_id",
  name: "Test Driver",
  email: "driver@test.com",
  phone: "+1234567890",
  ratings: "4.9",
  carType: "Cart1",
  carModel: "Toyota Camry",
  carNumber: "ABC123",
  carColor: "Blue",
);
