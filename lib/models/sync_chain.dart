enum SyncChainStatus {
  disconnected,
  creating,
  waiting,
  connecting,
  connected,
  error,
}

enum SyncMessageType {
  handshake,
  passwordSync,
  passwordUpdate,
  passwordDelete,
  verification,
  verificationResponse,
  heartbeat,
}

class SyncChain {
  final String id;
  final String seedPhrase;
  final DateTime createdAt;
  final List<String> connectedPeers;
  final SyncChainStatus status;
  final bool isOwner;

  SyncChain({
    required this.id,
    required this.seedPhrase,
    required this.createdAt,
    required this.connectedPeers,
    required this.status,
    required this.isOwner,
  });

  factory SyncChain.fromMap(Map<String, dynamic> map) {
    return SyncChain(
      id: map['id'] ?? '',
      seedPhrase: map['seedPhrase'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      connectedPeers: List<String>.from(map['connectedPeers'] ?? []),
      status: SyncChainStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SyncChainStatus.disconnected,
      ),
      isOwner: map['isOwner'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seedPhrase': seedPhrase,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'connectedPeers': connectedPeers,
      'status': status.toString(),
      'isOwner': isOwner,
    };
  }

  SyncChain copyWith({
    String? id,
    String? seedPhrase,
    DateTime? createdAt,
    List<String>? connectedPeers,
    SyncChainStatus? status,
    bool? isOwner,
  }) {
    return SyncChain(
      id: id ?? this.id,
      seedPhrase: seedPhrase ?? this.seedPhrase,
      createdAt: createdAt ?? this.createdAt,
      connectedPeers: connectedPeers ?? this.connectedPeers,
      status: status ?? this.status,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

class SyncMessage {
  final SyncMessageType type;
  final Map<String, dynamic> data;
  final String senderId;
  final DateTime timestamp;

  SyncMessage({
    required this.type,
    required this.data,
    required this.senderId,
    required this.timestamp,
  });

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      type: SyncMessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SyncMessageType.handshake,
      ),
      data: json['data'] ?? {},
      senderId: json['senderId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'data': data,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class PeerConnection {
  final String peerId;
  final String deviceName;
  final bool isConnected;
  final DateTime lastSeen;
  final bool isPendingVerification;

  PeerConnection({
    required this.peerId,
    required this.deviceName,
    required this.isConnected,
    required this.lastSeen,
    this.isPendingVerification = false,
  });

  factory PeerConnection.fromMap(Map<String, dynamic> map) {
    return PeerConnection(
      peerId: map['peerId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      isConnected: map['isConnected'] ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
      isPendingVerification: map['isPendingVerification'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'peerId': peerId,
      'deviceName': deviceName,
      'isConnected': isConnected,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isPendingVerification': isPendingVerification,
    };
  }

  PeerConnection copyWith({
    String? peerId,
    String? deviceName,
    bool? isConnected,
    DateTime? lastSeen,
    bool? isPendingVerification,
  }) {
    return PeerConnection(
      peerId: peerId ?? this.peerId,
      deviceName: deviceName ?? this.deviceName,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
      isPendingVerification: isPendingVerification ?? this.isPendingVerification,
    );
  }
}

class SyncedPassword {
  final int passId;
  final String passTitle;
  final int vaultId;
  final int createdAt;
  final int updatedAt;
  final List<SyncedNote> notes;
  final String lastModifiedBy;

  SyncedPassword({
    required this.passId,
    required this.passTitle,
    required this.vaultId,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.lastModifiedBy,
  });

  factory SyncedPassword.fromMap(Map<String, dynamic> map) {
    return SyncedPassword(
      passId: map['passId'] ?? 0,
      passTitle: map['passTitle'] ?? '',
      vaultId: map['vaultId'] ?? 0,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      notes: (map['notes'] as List<dynamic>?)
              ?.map((note) => SyncedNote.fromMap(note))
              .toList() ??
          [],
      lastModifiedBy: map['lastModifiedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passId': passId,
      'passTitle': passTitle,
      'vaultId': vaultId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes.map((note) => note.toMap()).toList(),
      'lastModifiedBy': lastModifiedBy,
    };
  }
}

class SyncedNote {
  final int noteId;
  final String description;
  final String type;
  final int passId;
  final int createdAt;
  final int updatedAt;

  SyncedNote({
    required this.noteId,
    required this.description,
    required this.type,
    required this.passId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SyncedNote.fromMap(Map<String, dynamic> map) {
    return SyncedNote(
      noteId: map['noteId'] ?? 0,
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      passId: map['passId'] ?? 0,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'description': description,
      'type': type,
      'passId': passId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}