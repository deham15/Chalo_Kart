import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:untitled1/Assistance/request_assistant.dart';
import '../global/global.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/direction.dart';
import '../models/direction_details_with_polyline.dart';
import '../models/user_model.dart';

class AssistantMethods {
  static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentUser!.uid);
    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeoCoordinates(Position position,
      context) async {
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position
        .latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if (requestResponse != "Error occurred, no response") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickupAddress = Directions();
      userPickupAddress.locationLatitude = position.latitude;
      userPickupAddress.locationLongitude = position.longitude;
      userPickupAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false).updatePickupLocationAddress(
          userPickupAddress);
    }
    return humanReadableAddress;
  }

  static Future<
      (DirectionDetailsWithPolyline, dynamic)> obtainOriginToDestinationDirectionDetails(
      LatLng originPosition, LatLng destinationPosition) async {
    // String urlOriginToDestinationDirection="https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    // var responseDirectionApi=await RequestAssistant.receiveRequest(urlOriginToDestinationDirection);
    //
    // // if(responseDirectionApi=="Error occurred, no response"){
    // //   return null;
    // // }
    //
    // DirectionDetailsInfo directionDetailsInfo=DirectionDetailsInfo();
    // directionDetailsInfo.e_points=responseDirectionApi["routes"][0]["overview_polyline"]["points"];
    //
    // directionDetailsInfo.distance_text=responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    // directionDetailsInfo.distance_value=responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
    // directionDetailsInfo.duration_text=responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    // directionDetailsInfo.duration_value=responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
    //
    // return directionDetailsInfo;
    // String url = "https://routes.googleapis.com/directions/v2:computeRoutes";
    // Map<String, dynamic> requestBody = {
    //   "origin": {
    //     "location": {
    //       "latLng": {
    //         "latitude": originPosition.latitude,
    //         "longitude": originPosition.longitude
    //       }
    //     }
    //   },
    //   "destination": {
    //     "location": {
    //       "latLng": {
    //         "latitude": destinationPosition.latitude,
    //         "longitude": destinationPosition.longitude
    //       }
    //     }
    //   },
    //   "travelMode": "DRIVE"
    // };
    //
    // var responseDirectionApi = await RequestAssistant.receiveRequestForDirectionDetails(url, body: requestBody);
    //
    // // Ensure response is valid
    // if (responseDirectionApi == "Error occurred, no response" || responseDirectionApi["routes"] == null || responseDirectionApi["routes"].isEmpty) {
    //   throw Exception("Failed to fetch direction details.");
    // }
    //
    // var route = responseDirectionApi["routes"][0];
    //
    // if (route["polyline"] == null || route["polyline"]["encodedPolyline"] == null) {
    //   throw Exception("Polyline points missing in the response.");
    // }
    //
    // var leg = route["legs"]?.isNotEmpty == true ? route["legs"][0] : null;
    //
    // if (leg == null || leg["distance"] == null || leg["duration"] == null) {
    //   throw Exception("Missing distance or duration data.");
    // }
    //
    // DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo(
    //   e_points: route["polyline"]["encodedPolyline"],
    //   distance_text: leg["distance"]["text"],
    //   distance_value: leg["distance"]["value"],
    //   duration_text: leg["duration"]["text"],
    //   duration_value: leg["duration"]["value"],
    // );
    //
    // return directionDetailsInfo;

    // final url=Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes");
    //
    // final headers = {
    //   'Content-Type': 'application/json',
    //   'X-Goog-Api-Key': mapKey,
    //   'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
    //  };
    //
    // final body = jsonEncode({
    //   'origin': {
    //     'location': {
    //       'latLng': {
    //         'latitude': originPosition.latitude,
    //         'longitude': originPosition.longitude,
    //       },
    //     },
    //   },
    //   'destination': {
    //     'location': {
    //       'latLng': {
    //         'latitude': destinationPosition.latitude,
    //         'longitude': destinationPosition.longitude,
    //       },
    //     },
    //   },
    //   'travelMode': 'DRIVE',
    // });
    //
    // final response = await http.post(url, headers: headers, body: body);
    // try {
    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     print(data);
    //     return data;
    //     // Process the response data
    //   } else {
    //     print('Request failed with status: ${response.statusCode}');
    //     print(response.body);
    //     return null;
    //     // Handle errors
    //   }
    // } catch (e) {
    //   print('Error: $e');
    //   return null;
    //   // Handle exceptions
    // }
    DirectionDetailsWithPolyline directionDetailsWithPolyline = DirectionDetailsWithPolyline();
    // print("Function called");
    var responseDirectionApi = await RequestAssistant
        .receiveRequestForDirectionDetails(originPosition, destinationPosition);
    DirectionDetailsWithPolyline nullInstance = DirectionDetailsWithPolyline(
      e_points: null,
      distance_value_in_meters: null,
      duration_text_in_s: null,
    );
    // print(responseDirectionApi);
    if (responseDirectionApi == "Error occurred, no response") {
      return (nullInstance, "");
    }
    directionDetailsWithPolyline.e_points =
    responseDirectionApi["routes"][0]["polyline"]["encodedPolyline"];
    directionDetailsWithPolyline.distance_value_in_meters =
    responseDirectionApi["routes"][0]["distanceMeters"];
    directionDetailsWithPolyline.duration_text_in_s =
    responseDirectionApi["routes"][0]["duration"];
    // print("asdf");
    // print(responseDirectionApi["routes"][0]["polyline"]["encodedPolyline"]);
    return (directionDetailsWithPolyline, responseDirectionApi["routes"][0]["polyline"]["encodedPolyline"]);
  }
  static Future<void> pauseLiveLocationUpdates() async {
    if (streamSubscriptionPosition != null) {
      streamSubscriptionPosition!.pause();
    }
    if (currentUser != null) {
      Geofire.removeLocation(currentUser!.uid);
    }
  }
  static double calculateFareAmountFromOriginToDestination((DirectionDetailsWithPolyline, dynamic) directionDetails) {
    double timeTravelledFareAmountPerMinute = (double.parse(directionDetails.$1.duration_text_in_s!) / 60) * 0.1;
    double distanceTravelledFareAmountPerKilometer = (directionDetails.$1.distance_value_in_meters! / 1000) * 0.1;
    double totalFareAmount = timeTravelledFareAmountPerMinute + distanceTravelledFareAmountPerKilometer;
    double localCurrencyTotalFare = totalFareAmount * 107;
    
    // Default value if no car type data available
    String carType = onlineDriverData.carType ?? "standard";
    
    if(carType == "Cart1"){
      double resultFareAmount = (localCurrencyTotalFare.truncate()) * 2;
      return resultFareAmount;
    }
    else if(carType == "Cart2"){
      double resultFareAmount = (localCurrencyTotalFare.truncate()) * 2;
      return resultFareAmount;
    }
    else if(carType == "Cart3"){
      double resultFareAmount = (localCurrencyTotalFare.truncate()) * 2;
      return resultFareAmount;
    }
    
    return localCurrencyTotalFare.truncate().toDouble();
  }

}
