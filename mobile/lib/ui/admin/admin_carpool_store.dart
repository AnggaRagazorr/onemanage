import 'package:flutter/material.dart';
import '../../services/carpool_service.dart';

class AdminCar {
  AdminCar({this.id, required this.brand, required this.plate});

  final int? id;
  final String brand;
  final String plate;

  String get display => "$brand ($plate)";

  factory AdminCar.fromJson(Map<String, dynamic> json) {
    return AdminCar(
      id: json['id'] as int?,
      brand: json['brand'] as String,
      plate: json['plate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'plate': plate,
    };
  }
}

class AdminDriver {
  AdminDriver({this.id, required this.name, required this.nip});

  final int? id;
  final String name;
  final String nip;

  String get display => "$name ($nip)";

  factory AdminDriver.fromJson(Map<String, dynamic> json) {
    return AdminDriver(
      id: json['id'] as int?,
      name: json['name'] as String,
      nip: json['nip'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nip': nip,
    };
  }
}

class AdminCarpoolStore {
  final ValueNotifier<List<AdminCar>> cars;
  final ValueNotifier<List<AdminDriver>> drivers;

  AdminCarpoolStore({
    required List<AdminCar> initialCars,
    required List<AdminDriver> initialDrivers,
  })  : cars = ValueNotifier<List<AdminCar>>(List<AdminCar>.from(initialCars)),
        drivers = ValueNotifier<List<AdminDriver>>(List<AdminDriver>.from(initialDrivers));

  Future<void> load() async {
    final service = CarpoolService.instance;
    cars.value = await service.fetchVehicles();
    drivers.value = await service.fetchDrivers();
  }

  Future<void> addCar(AdminCar car) async {
    final service = CarpoolService.instance;
    final saved = await service.createVehicle(car);
    cars.value = [saved, ...cars.value];
  }

  Future<void> addDriver(AdminDriver driver) async {
    final service = CarpoolService.instance;
    final saved = await service.createDriver(driver);
    drivers.value = [saved, ...drivers.value];
  }

  Future<void> deleteCar(AdminCar car) async {
    if (car.id == null) {
      return;
    }
    final service = CarpoolService.instance;
    await service.deleteVehicle(car.id!);
    cars.value = cars.value.where((item) => item.id != car.id).toList(growable: false);
  }

  Future<void> deleteDriver(AdminDriver driver) async {
    if (driver.id == null) {
      return;
    }
    final service = CarpoolService.instance;
    await service.deleteDriver(driver.id!);
    drivers.value = drivers.value.where((item) => item.id != driver.id).toList(growable: false);
  }
}

final adminCarpoolStore = AdminCarpoolStore(
  initialCars: [],
  initialDrivers: [],
);
