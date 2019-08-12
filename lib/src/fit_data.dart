part of fit_kit;

class FitData {
  num value;
  Map<String, num> complexValue = Map<String, num>() ;

  final DateTime dateFrom;
  final DateTime dateTo;

  FitData(this.value, this.dateFrom, this.dateTo);

  FitData.fromJson(Map<dynamic, dynamic> json)
      :
        dateFrom = DateTime.fromMillisecondsSinceEpoch(json['date_from']),
        dateTo = DateTime.fromMillisecondsSinceEpoch(json['date_to']) {
    if (json.containsKey('value')) {
      this.value = json['value']; //held for backward compatibility
      this.complexValue['value'] = this.value;
    } else {
      if (json.containsKey('systolic')) {
        this.complexValue['systolic'] = json['systolic'];
      }
      if (json.containsKey('diastolic')) {
        this.complexValue['diastolic'] = json['diastolic'];
      }
    }
  }

  @override
  String toString() =>
      'FitData(value: $value, complexValue: $complexValue, dateFrom: $dateFrom, dateTo: $dateTo)';
}
