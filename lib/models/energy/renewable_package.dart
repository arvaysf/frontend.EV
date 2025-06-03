// lib/models/renewable_package.dart - DATA MODEL ONLY
// ignore: unused_import
import 'package:flutter/material.dart';

class RenewablePackage {
  final String power;
  final String panelPower;
  final int numberOfPanels;
  final String inverterPower;
  final String inverterModel;
  final String inverterBrand;
  final String chargerType;
  final String chargerModel;
  final int chargerPrice;
  final String batteryCapacity;
  final String batteryModel;
  final String batteryBrand;
  final String? batteryFeatures;
  final int totalCost;
  final String roi;
  final String energyPerDay;
  
  RenewablePackage({
    required this.power,
    required this.panelPower,
    required this.numberOfPanels,
    required this.inverterPower,
    required this.inverterModel,
    required this.inverterBrand,
    required this.chargerType,
    required this.chargerModel,
    required this.chargerPrice,
    required this.batteryCapacity,
    required this.batteryModel,
    required this.batteryBrand,
    this.batteryFeatures,
    required this.totalCost,
    required this.roi,
    required this.energyPerDay,
  });

  // Format numberOfPanels and panelPower as a display string
  String get panelsDisplay => '$numberOfPanels x $panelPower';
  

}

// Sample data provider for renewable packages
class RenewablePackageData {
  static List<RenewablePackage> getAllPackages() {
    return [
      RenewablePackage(
        power: '3 kW',
        panelPower: '675 Wp',
        numberOfPanels: 5,
        inverterPower: '3 kW',
        inverterModel: 'Huawei SUN2000-3KTL-L1',
        inverterBrand: 'Huawei',
        chargerType: '3 kW AC (single-phase)',
        chargerModel: 'Standard AC Wallbox',
        chargerPrice: 10000,
        batteryCapacity: '5 kWh',
        batteryModel: 'Pylontech US2000C',
        batteryBrand: 'Pylontech',
        batteryFeatures: 'LFP(LiFePO4), modular, wall-mounted',
        totalCost: 94500,
        roi: '21.5%-24.8%',
        energyPerDay: '10-12 kWh/day',
      ),
      RenewablePackage(
        power: '7.4 kW',
        panelPower: '675 Wp',
        numberOfPanels: 11,
        inverterPower: '8 kW',
        inverterModel: 'SMA Sunny Tripower 8.0',
        inverterBrand: 'SMA',
        chargerType: '7.4 kW AC (single-phase)',
        chargerModel: 'EVBox Elvi 7.4 kW',
        chargerPrice: 14000,
        batteryCapacity: '10 kWh',
        batteryModel: 'BYD Battery-Box Premium HVS',
        batteryBrand: 'BYD',
        batteryFeatures: null,
        totalCost: 164500,
        roi: '22.1%-25.7%',
        energyPerDay: '25-30 kWh/day',
      ),
      RenewablePackage(
        power: '11 kW',
        panelPower: '675 Wp',
        numberOfPanels: 17,
        inverterPower: '12 kW',
        inverterModel: 'GoodWe GW12K-ET',
        inverterBrand: 'GoodWe',
        chargerType: '11 kW AC (three-phase)',
        chargerModel: 'ABB Terra AC Wallbox 11 kW',
        chargerPrice: 18000,
        batteryCapacity: '15 kWh',
        batteryModel: 'Huawei Luna2000-15-S0',
        batteryBrand: 'Huawei',
        batteryFeatures: null,
        totalCost: 233500,
        roi: '24.3%-27.3%',
        energyPerDay: '35-70 kWh/day',
      ),
      RenewablePackage(
        power: '22 kW',
        panelPower: '675 Wp',
        numberOfPanels: 33,
        inverterPower: '22-25 kW',
        inverterModel: 'Fronius Symo 24.0-3-M',
        inverterBrand: 'Fronius',
        chargerType: '22 kW AC (three-phase)',
        chargerModel: 'KEBA KeContact P30 x-series 22 kW',
        chargerPrice: 28000,
        batteryCapacity: '30 kWh',
        batteryModel: 'LG Chem RESU16H Prime x2',
        batteryBrand: 'LG Chem',
        batteryFeatures: null,
        totalCost: 421500,
        roi: '24.2%-27.5%',
        energyPerDay: '65-70 kWh/day',
      ),
    ];
  }
}