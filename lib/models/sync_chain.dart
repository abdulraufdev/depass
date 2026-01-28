import 'dart:convert';

/// Represents a device connected to the sync chain
class SyncChainDevice {
  final String deviceId;
  final String deviceName;
  final DateTime connectedAt;
  final DateTime lastSyncedAt;

  SyncChainDevice({
    required this.deviceId,
    required this.deviceName,
    required this.connectedAt,
    required this.lastSyncedAt,
  });

  factory SyncChainDevice.fromMap(Map<String, dynamic> map) {
    return SyncChainDevice(
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      connectedAt: DateTime.fromMillisecondsSinceEpoch(map['connectedAt'] ?? 0),
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['lastSyncedAt'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'connectedAt': connectedAt.millisecondsSinceEpoch,
      'lastSyncedAt': lastSyncedAt.millisecondsSinceEpoch,
    };
  }

  SyncChainDevice copyWith({
    String? deviceId,
    String? deviceName,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
  }) {
    return SyncChainDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Represents a sync chain configuration
class SyncChain {
  final String chainId;
  final String seedPhrase;
  final DateTime createdAt;
  final List<SyncChainDevice> connectedDevices;
  final bool isActive;

  SyncChain({
    required this.chainId,
    required this.seedPhrase,
    required this.createdAt,
    required this.connectedDevices,
    this.isActive = true,
  });

  factory SyncChain.fromMap(Map<String, dynamic> map) {
    return SyncChain(
      chainId: map['chainId'] ?? '',
      seedPhrase: map['seedPhrase'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      connectedDevices:
          (map['connectedDevices'] as List?)
              ?.map((d) => SyncChainDevice.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chainId': chainId,
      'seedPhrase': seedPhrase,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'connectedDevices': connectedDevices.map((d) => d.toMap()).toList(),
      'isActive': isActive,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SyncChain.fromJson(String json) {
    return SyncChain.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  SyncChain copyWith({
    String? chainId,
    String? seedPhrase,
    DateTime? createdAt,
    List<SyncChainDevice>? connectedDevices,
    bool? isActive,
  }) {
    return SyncChain(
      chainId: chainId ?? this.chainId,
      seedPhrase: seedPhrase ?? this.seedPhrase,
      createdAt: createdAt ?? this.createdAt,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Types of sync messages
enum SyncMessageType {
  handshake,
  handshakeResponse,
  fullSync,
  fullSyncResponse,
  passwordAdded,
  passwordUpdated,
  passwordDeleted,
  noteAdded,
  noteUpdated,
  noteDeleted,
  vaultAdded,
  vaultUpdated,
  vaultDeleted,
  ping,
  pong,
  disconnect,
}

/// A message sent between devices in the sync chain
class SyncMessage {
  final SyncMessageType type;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  SyncMessage({
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.payload,
  });

  factory SyncMessage.fromMap(Map<String, dynamic> map) {
    return SyncMessage(
      type: SyncMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SyncMessageType.ping,
      ),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      payload: map['payload'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': payload,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SyncMessage.fromJson(String json) {
    return SyncMessage.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
}

/// Connection status for sync chain
enum SyncChainStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  syncing,
  error,
}

/// Represents a discovered device
class DiscoveredDevice {
  final String endpointId;
  final String deviceName;
  final String serviceId;

  DiscoveredDevice({
    required this.endpointId,
    required this.deviceName,
    required this.serviceId,
  });
}
