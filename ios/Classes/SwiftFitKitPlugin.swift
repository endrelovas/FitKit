import Flutter
import UIKit
import HealthKit

public class SwiftFitKitPlugin: NSObject, FlutterPlugin {

    private let TAG = "FitKit";

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fit_kit", binaryMessenger: registrar.messenger())
        let instance = SwiftFitKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private var healthStore: HKHealthStore? = nil;

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: TAG, message: "Not supported", details: nil))
            return
        }

        if (call.method == "requestPermissions") {
            do {
                let request = try PermissionsRequest.fromCall(call: call)
                requestPermissions(request: request, result: result)
            } catch {
                result(FlutterError(code: TAG, message: "Error \(error)", details: nil))
            }
        } else if (call.method == "read") {
            do {
                let request = try ReadRequest.fromCall(call: call)
                read(request: request, result: result)
            } catch {
                result(FlutterError(code: TAG, message: "Error \(error)", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestPermissions(request: PermissionsRequest, result: @escaping FlutterResult) {
        requestAuthorization(sampleTypes: request.sampleTypes) { success, error in
            guard success else {
                result(false)
                return
            }

            result(true)
        }
    }

    private func read(request: ReadRequest, result: @escaping FlutterResult) {
        let permissions = try! HKSampleType.permissionRequestTypes(type: request.type)
        requestAuthorization(sampleTypes: permissions["permissionRequests"] as! [HKSampleType] ) { success, error in
            guard success else {
                result(error)
                return
            }
            self.readSample(request: request, result: result)
        }
    }

    private func requestAuthorization(sampleTypes: Array<HKSampleType>, completion: @escaping (Bool, FlutterError?) -> Void) {
        if (healthStore == nil) {
            healthStore = HKHealthStore();
        }

        healthStore!.requestAuthorization(toShare: nil, read: Set(sampleTypes)) { (success, error) in
            guard success else {
                completion(false, FlutterError(code: self.TAG, message: "Error \(error?.localizedDescription ?? "empty")", details: nil))
                return
            }
            completion(true, nil)
        }
    }

    private func readBloodPressureSample(request: ReadRequest, result: @escaping FlutterResult) {

        let predicate = HKQuery.predicateForSamples(withStart: request.dateFrom, end: request.dateTo, options: .strictStartDate)
        //let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKCorrelationQuery(type: request.sampleType as! HKCorrelationType, predicate: predicate, samplePredicates: nil ) { _, samplesOrNil, error in
            guard let samples = samplesOrNil else {
                result(FlutterError(code: self.TAG, message: "Results are null", details: error))
                return
            }

            let results = samples.map { sample  -> NSDictionary in
                guard let systolicSample = sample.objects(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!).first! as? HKQuantitySample else {
                    return [:]
                }
                guard let diastolicSample = sample.objects(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!).first! as? HKQuantitySample else {
                    return [:]
                }

                let systolicValue = systolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                let diastolicValue = diastolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())

                return [
                    "systolic" : systolicValue,
                    "diastolic" : diastolicValue,
                    "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),
                    "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),
                ]
            }
            result (results)
        }
        healthStore!.execute(query)
    }

    private func readSample(request: ReadRequest, result: @escaping FlutterResult) {
        print("readSample: \(request.type)")

    // Quick and dirty: bloood pressure requires different readout
        if request.type == "blood_pressure" {
            readBloodPressureSample(request: request, result: result);
            return;
        }

        let predicate = HKQuery.predicateForSamples(withStart: request.dateFrom, end: request.dateTo, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: request.sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
            _, samplesOrNil, error in

            // TODO: Change this to support all HKCategorySample instead of only sleepAnalysis
            if request.type == "sleep" {
                guard let samples = samplesOrNil as? [HKCategorySample] else {
                    result(FlutterError(code: self.TAG, message: "Results are null", details: error))	
                    return	
                }	

                result(samples.map { sample -> NSDictionary in
                    return [	
                        "value": sample.value, // inBed = 0, asleep = 1, awake = 2	
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),	
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),	
                    ]	
                })

            } else {
                guard let samples = samplesOrNil as? [HKQuantitySample] else {	
                    result(FlutterError(code: self.TAG, message: "Results are null", details: error))	
                    return	
                }	

                result(samples.map { sample -> NSDictionary in
                    return [	
                        "value": sample.quantity.doubleValue(for: request.unit),	
                        "date_from": Int(sample.startDate.timeIntervalSince1970 * 1000),	
                        "date_to": Int(sample.endDate.timeIntervalSince1970 * 1000),	
                    ]	
                })
        }
    }
        healthStore!.execute(query)
}
}
