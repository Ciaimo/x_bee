class Frames {
  int honeyFrames;
  int broodFrames;
  int pollenFrames;
  int emptyFrames;

  Frames({
    required this.honeyFrames,
    required this.broodFrames,
    required this.pollenFrames,
    required this.emptyFrames,
  });

  Map<String, dynamic> toMap() => {
        'honeyFrames': honeyFrames,
        'broodFrames': broodFrames,
        'pollenFrames': pollenFrames,
        'emptyFrames': emptyFrames,
      };

  factory Frames.fromMap(Map<String, dynamic> map) {
    return Frames(
      honeyFrames: map['honeyFrames'] ?? 0,
      broodFrames: map['broodFrames'] ?? 0,
      pollenFrames: map['pollenFrames'] ?? 0,
      emptyFrames: map['emptyFrames'] ?? 0,
    );
  }
}
