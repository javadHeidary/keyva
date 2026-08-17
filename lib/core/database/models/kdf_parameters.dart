class KdfParameters {
  const KdfParameters({
    required this.algorithm,
    required this.memoryCost,
    required this.timeCost,
    required this.parallelism,
    required this.outputLength,
  });

  final String algorithm;
  final int memoryCost;
  final int timeCost;
  final int parallelism;
  final int outputLength;
}
