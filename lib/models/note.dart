class Note {
  final int NoteId;
  final String Description;
  final String Type;
  final int CreatedAt;
  final int UpdatedAt;
  final int PassId;

  Note({
    required this.NoteId,
    required this.Description,
    required this.Type,
    required this.CreatedAt,
    required this.UpdatedAt,
    required this.PassId,
  });

  Map<String, dynamic> toMap() {
    return {
      'NoteId': NoteId,
      'Description': Description,
      'Type': Type,
      'CreatedAt': CreatedAt,
      'UpdatedAt': UpdatedAt,
      'PassId': PassId,
    };
  }

  // Create Note from Map (database result)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      NoteId: map['NoteId'],
      Description: map['Description'] ?? '',
      Type: map['Type'] ?? '',
      CreatedAt: map['CreatedAt'],
      UpdatedAt: map['UpdatedAt'],
      PassId: map['PassId'],
    );
  }

  // Create a copy of Note with updated fields
  Note copyWith({
    int? NoteId,
    String? Description,
    String? Type,
    int? CreatedAt,
    int? UpdatedAt,
    int? PassId,
  }) {
    return Note(
      NoteId: NoteId ?? this.NoteId,
      Description: Description ?? this.Description,
      Type: Type ?? this.Type,
      CreatedAt: CreatedAt ?? this.CreatedAt,
      UpdatedAt: UpdatedAt ?? this.UpdatedAt,
      PassId: PassId ?? this.PassId,
    );
  }

  @override
  String toString() {
    return 'Note{NoteId: $NoteId, Description: $Description, Type: $Type, CreatedAt: $CreatedAt, UpdatedAt: $UpdatedAt, PassId: $PassId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.NoteId == NoteId &&
        other.Description == Description &&
        other.Type == Type &&
        other.CreatedAt == CreatedAt &&
        other.UpdatedAt == UpdatedAt &&
        other.PassId == PassId;
  }

  @override
  int get hashCode {
    return Object.hash(
      NoteId,
      Description,
      Type,
      CreatedAt,
      UpdatedAt,
      PassId,
    );
  }

}