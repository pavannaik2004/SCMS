class GrammarCorrectionModel {
  final bool hasCorrections;
  final String correctedText;
  final List<GrammarDiff> diffs;

  const GrammarCorrectionModel({
    required this.hasCorrections,
    required this.correctedText,
    this.diffs = const [],
  });

  factory GrammarCorrectionModel.fromJson(Map<String, dynamic> json) {
    return GrammarCorrectionModel(
      hasCorrections: json['hasCorrections'] as bool? ?? false,
      correctedText: json['correctedText'] as String? ?? '',
      diffs: (json['diffs'] as List<dynamic>?)
              ?.map((d) => GrammarDiff.fromJson(d as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'hasCorrections': hasCorrections,
    'correctedText': correctedText,
    'diffs': diffs.map((d) => d.toJson()).toList(),
  };

  /// Safe default when AI service is unavailable
  factory GrammarCorrectionModel.noCorrections(String originalText) {
    return GrammarCorrectionModel(
      hasCorrections: false,
      correctedText: originalText,
      diffs: [],
    );
  }
}

class GrammarDiff {
  final String type; // EQUAL | DELETE | INSERT
  final String text;

  const GrammarDiff({required this.type, required this.text});

  factory GrammarDiff.fromJson(Map<String, dynamic> json) {
    return GrammarDiff(
      type: json['type'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'text': text};

  bool get isEqual => type == 'EQUAL';
  bool get isDelete => type == 'DELETE';
  bool get isInsert => type == 'INSERT';
}
