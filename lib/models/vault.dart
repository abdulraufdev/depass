class Vault {
  final int VaultId;
  final String VaultTitle;
  final String VaultIcon;
  final String VaultColor;
  final int CreatedAt;
  final int UpdatedAt;

  Vault({
    required this.VaultId,
    required this.VaultTitle,
    required this.VaultIcon,
    required this.VaultColor,
    required this.CreatedAt,
    required this.UpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'VaultId': VaultId,
      'VaultTitle': VaultTitle,
      'VaultIcon': VaultIcon,
      'VaultColor': VaultColor,
      'CreatedAt': CreatedAt,
      'UpdatedAt': UpdatedAt,
    };
  }

  // Create Vault from Map (database result)
  factory Vault.fromMap(Map<String, dynamic> map) {
    return Vault(
      VaultId: map['VaultId'],
      VaultTitle: map['VaultTitle'] ?? '',
      VaultIcon: map['VaultIcon'] ?? '',
      VaultColor: map['VaultColor'] ?? '',
      CreatedAt: map['CreatedAt'],
      UpdatedAt: map['UpdatedAt'],
    );
  }

  // Create a copy of Vault with updated fields
  Vault copyWith({
    int? VaultId,
    String? VaultTitle,
    String? VaultIcon,
    String? VaultColor,
    int? CreatedAt,
    int? UpdatedAt,
  }) {
    return Vault(
      VaultId: VaultId ?? this.VaultId,
      VaultTitle: VaultTitle ?? this.VaultTitle,
      VaultIcon: VaultIcon ?? this.VaultIcon,
      VaultColor: VaultColor ?? this.VaultColor,
      CreatedAt: CreatedAt ?? this.CreatedAt,
      UpdatedAt: UpdatedAt ?? this.UpdatedAt,
    );
  }

  @override
  String toString() {
    return 'Vault{VaultId: $VaultId, VaultTitle: $VaultTitle, CreatedAt: $CreatedAt, UpdatedAt: $UpdatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vault &&
        other.VaultId == VaultId &&
        other.VaultTitle == VaultTitle &&
        other.CreatedAt == CreatedAt &&
        other.UpdatedAt == UpdatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(VaultId, VaultTitle, CreatedAt, UpdatedAt);
  }
}
