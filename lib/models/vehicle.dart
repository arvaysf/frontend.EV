// lib/models/vehicle.dart
class Vehicle {
  final int id;
  final String name;
  final String? battery;
  final String? range;
  final String? dcChargeSpeed;
  final String? acChargingSpeed;
  final String? dcChargingTime;
  final String? acChargingTime;
  final String? sehirIciTuketim;
  final String? sehirDisiTuketim;
  final String? ortalamaTuketim;
  final String? acChargeSpeed;
  
  Vehicle({
    required this.id,
    required this.name,
    this.battery,
    this.range,
    this.dcChargeSpeed,
    this.acChargingSpeed,
    this.dcChargingTime,
    this.acChargingTime,
    this.sehirIciTuketim,
    this.sehirDisiTuketim,
    this.ortalamaTuketim,
    this.acChargeSpeed,
  });
  
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'] ?? '',
      battery: json['battery'],
      range: json['range'],
      dcChargeSpeed: json['dcChargeSpeed'],
      acChargingSpeed: json['acChargingSpeed'],
      dcChargingTime: json['dcChargingTime'],
      acChargingTime: json['acChargingTime'],
      sehirIciTuketim: json['sehirIciTuketim'],
      sehirDisiTuketim: json['sehirDisiTuketim'],
      ortalamaTuketim: json['ortalamaTuketim'],
      acChargeSpeed: json['acChargeSpeed'],
    );
  }
}