class Queen {
  bool hasQueen;
  bool marked;
  int year;
  int rating;

  Queen({
    required this.hasQueen,
    required this.marked,
    required this.year,
    required this.rating,
  });

  Map<String, dynamic> toMap() => {
        'hasQueen': hasQueen,
        'marked': marked,
        'year': year,
        'rating': rating,
      };

  factory Queen.fromMap(Map<String, dynamic> map) {
    return Queen(
      hasQueen: map['hasQueen'] ?? false,
      marked: map['marked'] ?? false,
      year: map['year'] ?? 0,
      rating: map['rating'] ?? 0,
    );
  }
}
