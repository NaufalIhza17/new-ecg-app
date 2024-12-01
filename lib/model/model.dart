class Model {
  final int id;
  final String fileName;
  final String name;
  final String task;
  final double mean;
  final double std;
  final double threshold;
  final List<String> labels;

  const Model({
    required this.id,
    required this.fileName, required this.name, required this.task,
    required this.mean, required this.std, required this.threshold,
    required this.labels
  });
}