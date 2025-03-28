import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:untitled1/global/global.dart';
import 'package:untitled1/models/user_ride_request_information.dart';
import 'package:untitled1/screens/splash_screen.dart';

import '../Assistance/assistance_methods.dart';
import '../widgets/progress_dialog.dart';
 
class NewTripScreen extends StatefulWidget {
  final UserRideRequestInformation userRideRequestDetails;
  
  const NewTripScreen({
    Key? key,
    required this.userRideRequestDetails,
  }) : super(key: key);

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {

  GoogleMapController? newTripGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  static const CameraPosition_kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String buttonTitle = "Accepted";
  Color ? buttonColor =Colors.green;

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircles = Set<Circle>();
  Set<Polyline> SetOfPolylines = Set<Polyline>();
  List<LatLng> polylinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDriverCurrentPosition;
  StreamSubscription<Position>? streamSubscriptionDriverLivePosition;

  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestDirectionDetails = false;

  Future<void> drawPolylineFromOriginToDestination(LatLng originLatLng, LatLng destinationLatLng, bool darkTheme) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait.....",),
    );
    
    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    Navigator.pop(context);
    
    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.$1.e_points!);
    polylinePositionCoordinates.clear();

    if(decodedPolylinePointsResultList.isNotEmpty) {
      decodedPolylinePointsResultList.forEach((PointLatLng pointLatLng){
        polylinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    
    SetOfPolylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polylinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );
      SetOfPolylines.add(polyline);
    });
    
    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    
    newTripGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
    
    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    
    Marker destinationMarker = Marker(
      markerId: MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
    });
    
    Circle originCircle = Circle(
      circleId: CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );
    
    Circle destinationCircle = Circle(
      circleId: CircleId("destinationID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      setOfCircles.add(originCircle);
      setOfCircles.add(destinationCircle);
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      saveAssignedDriverDetailsToUserRideRequest();
    } catch (e) {
      print("Error in initialization: $e");
    }
  }
  
  @override
  void dispose() {
    // Cancel the position stream subscription when widget is disposed
    if(streamSubscriptionDriverLivePosition != null) {
      streamSubscriptionDriverLivePosition!.cancel();
    }
    super.dispose();
  }
  
  void getDriverLocationUpdatesAtRealTime() {
    LatLng oldLatLng = LatLng(0, 0);
    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream().listen((Position position) {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;
      
      LatLng latLngLiveDriverPosition = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);
      
      Marker animatingMarker = Marker(
        markerId: MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: InfoWindow(title: "This is your position"),
      );
      
      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDriverPosition, zoom: 18);
        newTripGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        
        setOfMarkers.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        setOfMarkers.add(animatingMarker);
      });

      oldLatLng = latLngLiveDriverPosition;
      updateDurationTimeAtRealTime();

      // updating driver location at real time in database
      Map<String, String> driverLatLngDataMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };
      
      FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails.rideRequestId!)
          .child("driverLocation")
          .set(driverLatLngDataMap);
    });
  }
  
  void updateDurationTimeAtRealTime() async {
    if(isRequestDirectionDetails == false) {
      isRequestDirectionDetails = true;
      if(onlineDriverCurrentPosition == null) {
        return;
      }

      var originLatLng = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);
      var destinationLatLng;
      
      if(rideRequestStatus == "accepted") {
        destinationLatLng = widget.userRideRequestDetails.originLatLng!; // user pickup location
      }
      else {
        destinationLatLng = widget.userRideRequestDetails.destinationLatLng!;
      }

      var directionInformation = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
      
      if(directionInformation != null) {
        setState(() {
          durationFromOriginToDestination = directionInformation.$1.duration_text_in_s!;
        });
      }
      
      isRequestDirectionDetails = false;
    }
  }
  
  void stopDriverLocationUpdatesAtRealTime() {
    if(streamSubscriptionDriverLivePosition != null) {
      streamSubscriptionDriverLivePosition!.cancel();
    }
  }
  
  void createDriverIconMarker() {
    if(iconAnimatedMarker == null && mounted) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value) {
        if(mounted) {
          setState(() {
            iconAnimatedMarker = value;
          });
        }
      });
    }
  }
  
  void saveAssignedDriverDetailsToUserRideRequest() {
    DatabaseReference databaseReference = FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails.rideRequestId!);
    
    Map<String, String> driverLocationDataMap = {
      "Latitude": driverCurrentPosition.latitude.toString(),
      "longitude": driverCurrentPosition.longitude.toString(),
    };
    
    try {
      databaseReference.child("driverLocation").set(driverLocationDataMap);
      databaseReference.child("status").set("accepted");
      databaseReference.child("driverId").set(onlineDriverData.id);
      databaseReference.child("driverName").set(onlineDriverData.name);
      databaseReference.child("driverPhone").set(onlineDriverData.phone);
      databaseReference.child("ratings").set(onlineDriverData.ratings);
      databaseReference.child("car_details").set(
          "${onlineDriverData.carModel} ${onlineDriverData.carNumber} (${onlineDriverData.carColor})");
      
      saveRideRequestIdToDriverHistory();
    } catch (e) {
      print("Error saving driver details: $e");
    }
  }
  
  void saveRideRequestIdToDriverHistory() {
    try {
      if (firebaseAuth.currentUser != null) {
        DatabaseReference tripsHistoryRef = FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(firebaseAuth.currentUser!.uid)
            .child("tripsHistory");
        
        tripsHistoryRef.child(widget.userRideRequestDetails.rideRequestId!).set(true);
      }
    } catch (e) {
      DatabaseReference tripsHistoryRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseAuth.currentUser!.uid)
          .child("tripsHistory");
      
      tripsHistoryRef.child(widget.userRideRequestDetails.rideRequestId!).set(true);
    }
  }
  
  void endTripNow() async {
    // Stop location updates when trip ends
    stopDriverLocationUpdatesAtRealTime();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
    );
    
    // Make sure we have the current position
    if (onlineDriverCurrentPosition == null) {
      // Use driver's last known position if the current position is null
      onlineDriverCurrentPosition = driverCurrentPosition;
    }
    
    try {
      var currentDriverPositionLatLng = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);
      var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
          currentDriverPositionLatLng, 
          widget.userRideRequestDetails.destinationLatLng ?? widget.userRideRequestDetails.originLatLng!
      );
      
      // Make sure to dismiss the progress dialog
      Navigator.pop(context);
      
      double totalFareAmount = AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetails);
      
      // Update the ride status and fare amount in the database
      await FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails.rideRequestId!)
          .update({
            "status": "ended",
            "fareAmount": totalFareAmount.toString(),
          });

      // Show fare amount dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Trip Completed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Total Fare Amount:",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                "\$${totalFareAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate back to home screen after trip completion
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (c) => SplashScreen())
                );
              },
              child: Text(
                "COLLECT CASH",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
      );
      
      // Save fare amount to driver's earnings
      saveFareAmountToDriverEarnings(totalFareAmount);
      
    } catch (e) {
      // Make sure to dismiss the progress dialog if there's an error
      Navigator.pop(context);
      
      print("Error ending trip: $e");
      Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
    }
  }

  void saveFareAmountToDriverEarnings(double totalFareAmount){
    FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("earnings").once().then((snap){
      if(snap.snapshot.value != null){
        double oldEarnings= double.parse(snap.snapshot.value.toString());
        double driverTotalEarnings= totalFareAmount + oldEarnings;
        FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("earnings").set(driverTotalEarnings.toString());
      }
      else{
        FirebaseDatabase.instance.ref().child("drivers").child(firebaseAuth.currentUser!.uid).child("earnings").set(totalFareAmount.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    // Create the driver icon marker here instead of in initState
    if (iconAnimatedMarker == null) {
      createDriverIconMarker();
    }
    
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            initialCameraPosition: CameraPosition_kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircles,
            polylines: SetOfPolylines,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 280; // Reduced for better map visibility
              });

              // Delay map initialization slightly to ensure everything is properly set up
              Future.delayed(Duration(milliseconds: 200), () {
                if (!mounted) return;
                
                // Check if driverCurrentPosition is not null before using it
                if (driverCurrentPosition != null) {
                  var driverLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
                  
                  // Check if userRideRequestDetails originLatLng is not null
                  if (widget.userRideRequestDetails.originLatLng != null) {
                    var userPickupLatLng = widget.userRideRequestDetails.originLatLng!;
                    drawPolylineFromOriginToDestination(driverLatLng, userPickupLatLng, darkTheme);
                  }
                }

                getDriverLocationUpdatesAtRealTime();
              });
            },
          ),
          
          // Status bar at the top
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.6, 0.6),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: darkTheme ? Colors.amber.shade400 : Colors.black87,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      durationFromOriginToDestination.isEmpty ? "Calculating..." : durationFromOriginToDestination,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: darkTheme ? Colors.amber.shade400 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom ride details panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: darkTheme ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  )
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passenger info and call button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: darkTheme ? Colors.amber.shade400.withOpacity(0.2) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: darkTheme ? Colors.amber.shade400 : Colors.black87,
                                  size: 30,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userRideRequestDetails.userName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: darkTheme ? Colors.amber.shade400 : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rate,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    Text(
                                      "4.9",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: darkTheme ? Colors.white70 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.amber.shade400.withOpacity(0.2) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Call passenger functionality
                            },
                            icon: Icon(
                              Icons.phone,
                              color: darkTheme ? Colors.amber.shade400 : Colors.green,
                              size: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    Divider(
                      thickness: 1,
                      color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                    SizedBox(height: 20),
                    
                    // Pickup location
                    Row(
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.userRideRequestDetails.originAddress!,
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.white70 : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    // Dotted line between origin and destination
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        height: 20,
                        width: 2,
                        color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Destination
                    Row(
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.userRideRequestDetails.destinationAddress ?? "Destination",
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.white70 : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if(rideRequestStatus == "accepted"){
                            rideRequestStatus = "arrived";
                            FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails.rideRequestId!).child("status").set(rideRequestStatus);

                            setState((){
                              buttonTitle = "Let's Go";
                              buttonColor = Colors.green;
                            });
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context ) => ProgressDialog(message: "Loading....",),
                            );
                            await drawPolylineFromOriginToDestination(
                                widget.userRideRequestDetails.originLatLng!,
                                widget.userRideRequestDetails.destinationLatLng!,
                                darkTheme
                            );
                            Navigator.pop(context);
                          }
                          else if(rideRequestStatus == "arrived"){
                            rideRequestStatus = "ontrip";
                            FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails.rideRequestId!).child("status").set(rideRequestStatus);

                            setState((){
                              buttonTitle = "End Trip";
                              buttonColor = Colors.red;
                            });
                          }
                          else if(rideRequestStatus == "ontrip"){
                            endTripNow();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          buttonTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

