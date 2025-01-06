import 'package:equatable/equatable.dart';

class Patient extends Equatable {
  final int id;
  final String firstName;
  final String lastName;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Patient.fromJson(var json) {
    return Patient(
      id: json["id"],
      firstName: json["first_name"],
      lastName: json["last_name"],
    );
  }

  @override
  List<Object?> get props => [id];
}
