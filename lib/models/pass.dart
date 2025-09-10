class Pass {
  final int PassId;
  final String PassTitle;
  final int VaultId;
  final int CreatedAt;

  Pass({
    required this.PassId,
    required this.PassTitle,
    required this.VaultId,
    required this.CreatedAt,
  });

  factory Pass.fromMap(Map<String, dynamic> map) {
    return Pass(
      PassId: map['PassId'],
      PassTitle: map['PassTitle'],
      VaultId: map['VaultId'],
      CreatedAt: map['CreatedAt']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'PassId': PassId,
      'PassTitle': PassTitle,
      'VaultId': VaultId,
      'CreatedAt': CreatedAt,
    };
  }
}