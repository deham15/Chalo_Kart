import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled1/Assistance/assistance_methods.dart';
import 'package:untitled1/global/global.dart';
import 'package:untitled1/models/user_ride_request_information.dart';
import 'package:untitled1/screens/new_trip_screen.dart';

class NotificationDialogBox extends StatefulWidget {
  final UserRideRequestInformation userRideRequestDetails;

  const NotificationDialogBox({
    Key? key,
    required this.userRideRequestDetails,
  }) : super(key: key);

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[800],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Image.asset(
              "images/car_logo.png",
              width: 160,
            ),
            const SizedBox(height: 10),
            const Text(
              "New Ride Request",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(
              height: 3,
              thickness: 3,
              color: Colors.grey,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "images/origin.png",
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestDetails.originAddress!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Image.asset(
                        "images/destination.png",
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          child: Text(
                            widget.userRideRequestDetails.destinationAddress!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: 3,
              thickness: 3,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      // Cancel the ride request
                      FirebaseDatabase.instance
                          .ref()
                          .child("All Ride Requests")
                          .child(widget.userRideRequestDetails.rideRequestId!)
                          .remove()
                          .then((value) {
                        FirebaseDatabase.instance
                            .ref()
                            .child("drivers")
                            .child(firebaseAuth.currentUser!.uid)
                            .child("newRideStatus")
                            .set("idle");
                      }).then((value) {
                        FirebaseDatabase.instance
                            .ref()
                            .child("drivers")
                            .child(firebaseAuth.currentUser!.uid)
                            .child("tripsHistory")
                            .child(widget.userRideRequestDetails.rideRequestId!)
                            .remove();
                      }).then((value) {
                        Fluttertoast.showToast(msg: "Ride Request has been Cancelled.");
                      });

                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancel".toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      // Accept the ride request
                      acceptRideRequest(context);
                    },
                    child: Text(
                      "Accept".toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  acceptRideRequest(BuildContext context) {
    String getRideRequestId = "";
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("newRideStatus")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        getRideRequestId = snap.snapshot.value.toString();
      } else {
        Fluttertoast.showToast(msg: "This ride request do not exists.");
      }

      if (getRideRequestId == widget.userRideRequestDetails.rideRequestId) {
        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(firebaseAuth.currentUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        AssistantMethods.pauseLiveLocationUpdates();
        
        // Navigate to new trip screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => NewTripScreen(
              userRideRequestDetails: widget.userRideRequestDetails,
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "This ride request do not exists.");
      }
    });
  }
}
