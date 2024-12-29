import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Patient extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final DateTime dateOfBirth;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.dateOfBirth,
  });

  factory Patient.fromJson(var json) {
    return Patient(
      id: json["id"],
      username: json["username"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      dateOfBirth: DateFormat("yyyy-MM-dd").parse(json["date_of_birth"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "username": username,
      "date_of_birth": DateFormat("yyyy-MM-dd").format(dateOfBirth),
    };
  }

  @override
  List<Object?> get props => [id];
}
