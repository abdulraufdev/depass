class Pass {
  final int id;
  final String title;
  final int vaultId;
  final int createdAt;
  final int updatedAt;

  Pass({
    required this.id,
    required this.title,
    required this.vaultId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pass.fromMap(Map<String, dynamic> map) {
    return Pass(
      id: map['id'],
      title: map['Title'],
      vaultId: map['VaultID'],
      createdAt: map['CreatedAt'],
      updatedAt: map['UpdatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Title': title,
      'VaultID': vaultId,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
    };
  }
}