import '../common.dart';

class ECGReport {
  int id;
  String dataInfo;
  String label;
  String name;
  int age;
  int pediatrics;

  ECGReport({required this.id, required this.dataInfo, required this.label, required this.name, required this.age, required this.pediatrics,
  });

  void init() {
    id = DateTime.now().millisecondsSinceEpoch;
    dataInfo = '';
    label = '';
    name = '';
    age = -1;
    pediatrics = -1;
  }

  @override
  bool operator == (Object other) {
    return other is ECGReport && id == other.id;
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'ECGReport{id: $id, value: $dataInfo, label: $label, name: $name, age: $age, pediatrics: $pediatrics}';
  }

  factory ECGReport.fromJson(Map<String, dynamic> json) {
    return ECGReport(
      id: json['id'],
      dataInfo: json['dataInfo'],
      label: json['label'],
      name: json['name'],
      age: json['age'],
      pediatrics: json['pediatrics'],
    );
  }

  Map toJson() => {
    'time': id,
    'dataInfo': dataInfo,
    'label': label,
    'name': name,
    'age': age,
    'pediatrics': pediatrics,
  };

  @override
  int get hashCode => id.hashCode;
}