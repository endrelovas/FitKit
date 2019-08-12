//
// Created by Martin Anderson on 2019-03-10.
//

import HealthKit

extension String: LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

extension HKSampleType {
    public static func permissionRequestTypes(type: String) throws -> [String:Any] {
        if (type == "blood_pressure") {
            guard let systolicSampleType = HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic),
                let diastolicSampleType = HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
                throw "type \"\(type)\" is not supported"
             }
            return [
                "permissionRequests" : [systolicSampleType, diastolicSampleType],
                "types" : ["systolicSampleType", "diastolicSampleType"]]
        } else {
            let sampleType = try HKSampleType.fromDartType(type: type)
            return [
                "permissionRequests" : [sampleType],
                "types" : [type]
                ]
        }
    }

    public static func fromDartType(type: String) throws -> HKSampleType {
        guard let sampleType: HKSampleType = {
            switch type {
            case "heart_rate":
                return HKSampleType.quantityType(forIdentifier: .heartRate)
            case "step_count":
                return HKSampleType.quantityType(forIdentifier: .stepCount)
            case "height":
                return HKSampleType.quantityType(forIdentifier: .height)
            case "weight":
                return HKSampleType.quantityType(forIdentifier: .bodyMass)
            case "distance":
                return HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)
            case "energy":
                return HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)
            case "sleep":	
                return HKSampleType.categoryType(forIdentifier: .sleepAnalysis)
            case "water":
                if #available(iOS 9, *) {
                    return HKSampleType.quantityType(forIdentifier: .dietaryWater)
                } else {
                    return nil
                }
            case "blood_pressure":
                return HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)
            case "blood_glucose":
                return HKSampleType.quantityType(forIdentifier: .bloodGlucose)
            default:
                return nil
            }
        }() else {
            throw "type \"\(type)\" is not supported";
        }
        return sampleType
    }
}

extension HKUnit {
    public static func fromDartType(type: String) throws -> HKUnit {
        guard let unit: HKUnit = {
            switch (type) {
            case "heart_rate":
                return HKUnit.init(from: "count/min")
            case "step_count":
                return HKUnit.count()
            case "height":
                return HKUnit.meter()
            case "weight":
                return HKUnit.gramUnit(with: .kilo)
            case "distance":
                return HKUnit.meter()
            case "energy":
                return HKUnit.kilocalorie()
            case "sleep":	
                return HKUnit.minute()
            case "water":
                return HKUnit.liter()
            case "blood_pressure":
                return HKUnit.millimeterOfMercury()
            case "blood_glucose":
                return HKUnit.moleUnit(with: HKMetricPrefix.milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
            default:
                return nil
            }
        }() else {
            throw "type \"\(type)\" is not supported";
        }
        return unit
    }
}