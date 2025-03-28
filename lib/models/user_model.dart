import 'package:firebase_database/firebase_database.dart';

class UserModel{
  String? phone;
  String? email;
  String? name;
  String? id;
  // String? address;

  UserModel({
    this.phone,
    this.email,
    this.name,
    this.id,
    // this.address
  });

  UserModel.fromSnapshot(DataSnapshot snap){
    phone=(snap.value as dynamic)["phone"];
    name=(snap.value as dynamic)["name"];
    email=(snap.value as dynamic)["email"];
    // address=(snap.value as dynamic)["address"];
    id=snap.key;
  }
}