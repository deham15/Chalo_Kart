import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:untitled1/global/global.dart';
import 'package:untitled1/models/user_ride_request_information.dart';
import 'package:untitled1/pushNotification/notification_dialog_box.dart';

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async {
    // 1. Terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        // display ride request information - user information who request a ride
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });

    // 2. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      // display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });

    // 3. Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
      // display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });
  }

  Future generateAndGetToken() async {
    String? registrationToken = await messaging.getToken();
    print("FCM Registration Token: $registrationToken");

    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }

  readUserRideRequestInformation(String userRideRequestId, BuildContext context) {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(userRideRequestId)
        .once()
        .then((snapData) {
      if (snapData.snapshot.value != null) {
        double originLat = double.parse((snapData.snapshot.value as Map)["origin"]["latitude"]);
        double originLng = double.parse((snapData.snapshot.value as Map)["origin"]["longitude"]);
        String originAddress = (snapData.snapshot.value as Map)["originAddress"];

        double destinationLat = double.parse((snapData.snapshot.value as Map)["destination"]["latitude"]);
        double destinationLng = double.parse((snapData.snapshot.value as Map)["destination"]["longitude"]);
        String destinationAddress = (snapData.snapshot.value as Map)["destinationAddress"];

        String userName = (snapData.snapshot.value as Map)["userName"];
        String userPhone = (snapData.snapshot.value as Map)["userPhone"];

        UserRideRequestInformation userRideRequestDetails = UserRideRequestInformation(
          originLatLng: LatLng(originLat, originLng),
          originAddress: originAddress,
          destinationLatLng: LatLng(destinationLat, destinationLng),
          destinationAddress: destinationAddress,
          userName: userName,
          userPhone: userPhone,
          rideRequestId: userRideRequestId,
        );

        showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialogBox(
            userRideRequestDetails: userRideRequestDetails,
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "This Ride Request ID do not exists.");
      }
    });
  }
}