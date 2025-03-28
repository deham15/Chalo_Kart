import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/screens/splash_screen.dart';
import 'package:untitled1/models/user_ride_request_information.dart';
import 'package:untitled1/screens/car_info_screen.dart';
import 'package:untitled1/screens/main_screen.dart';
import 'package:untitled1/screens/new_trip_screen.dart';
import 'package:untitled1/themeProvider/theme_provider.dart';
import 'package:untitled1/widgets/fare_amount_collection_debug.dart';

import 'infoHandler/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter Demo',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        // home: NewTripScreen(
        //   userRideRequestDetails: UserRideRequestInformation(
        //     rideRequestId: "test_ride_12345",
        //     originLatLng: LatLng(37.42796133580664, -122.085749655962),
        //     destinationLatLng: LatLng(37.43796133580664, -122.095749655962),
        //     originAddress: "Test Origin Address, Palo Alto, CA",
        //     destinationAddress: "Test Destination Address, Mountain View, CA",
        //     userName: "Test User",
        //     userPhone: "+1234567890",
        //   ),
        // ),
        home: MainScreen(),

      ),
    );
  }
}

