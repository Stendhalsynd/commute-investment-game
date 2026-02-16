class InvestmentOption {
  final String id;
  final String name;
  final String category;
  final double expectedReturn;
  final double volatility;
  final double cost;
  final int cooldownSec;
  final int riskLevel;

  const InvestmentOption({
    required this.id,
    required this.name,
    required this.category,
    required this.expectedReturn,
    required this.volatility,
    required this.cost,
    required this.cooldownSec,
    required this.riskLevel,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'expectedReturn': expectedReturn,
      'volatility': volatility,
      'cost': cost,
      'cooldownSec': cooldownSec,
      'riskLevel': riskLevel,
    };
  }

  factory InvestmentOption.fromMap(Map<String, dynamic> map) {
    return InvestmentOption(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      expectedReturn: (map['expectedReturn'] as num).toDouble(),
      volatility: (map['volatility'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      cooldownSec: map['cooldownSec'] as int,
      riskLevel: map['riskLevel'] as int,
    );
  }
}
