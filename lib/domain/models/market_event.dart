class MarketEvent {
  final String id;
  final String title;
  final String description;
  final String? scenarioType;
  final String? historicalTag;
  final bool isSynthetic;
  final double impactMin;
  final double impactMax;
  final List<String> appliesTo;
  final int duration;
  final String rarity;

  const MarketEvent({
    required this.id,
    required this.title,
    required this.description,
    this.scenarioType,
    this.historicalTag,
    this.isSynthetic = false,
    required this.impactMin,
    required this.impactMax,
    required this.appliesTo,
    required this.duration,
    required this.rarity,
  });

  double sampleImpact(double ratio) {
    if (ratio <= 0) return impactMin;
    if (ratio >= 1) return impactMax;
    return impactMin + (impactMax - impactMin) * ratio;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scenarioType': scenarioType,
      'historicalTag': historicalTag,
      'isSynthetic': isSynthetic,
      'impactMin': impactMin,
      'impactMax': impactMax,
      'appliesTo': appliesTo,
      'duration': duration,
      'rarity': rarity,
    };
  }

  factory MarketEvent.fromMap(Map<String, dynamic> map) {
    return MarketEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      scenarioType: map['scenarioType'] as String?,
      historicalTag: map['historicalTag'] as String?,
      isSynthetic: map['isSynthetic'] as bool? ?? false,
      impactMin: (map['impactMin'] as num).toDouble(),
      impactMax: (map['impactMax'] as num).toDouble(),
      appliesTo: List<String>.from(map['appliesTo'] as List),
      duration: map['duration'] as int,
      rarity: map['rarity'] as String,
    );
  }
}
