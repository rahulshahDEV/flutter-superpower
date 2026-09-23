# Chat & Realtime (Socket.IO + E2E crypto)

Hardest cross-cutting feature to rebuild — build it in this order: transport → REST
history → crypto → UI → notifications.

## 1. Transport service

`features/chat/data/services/chat_socket_service.dart` — `@lazySingleton`:

```dart
@lazySingleton
class ChatSocketService {
  IO.Socket? _socket;
  int _retainCount = 0;                     // connect/disconnect by demand
  final _events = StreamController<ChatSocketEvent>.broadcast();
  Stream<ChatSocketEvent> get events => _events.stream;

  Future<void> connect() async {
    _retainCount++;
    if (_socket?.connected ?? false) return;
    final token = getIt<LocalStorageService>().getString(StorageKeys.accessToken);
    _socket = IO.io(AppConfig.instance.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build());
    _socket!
      ..onConnect((_) => _debug('connected'))
      ..on('message:new', (data) => _emit(ChatMessageReceived.fromJson(data)))
      ..on('message:read', (data) => _emit(ChatReadUpdated.fromJson(data)))
      ..onDisconnect((_) => _debug('disconnected'));
    _socket!.connect();
  }

  void disconnect() {
    _retainCount = (_retainCount - 1).clamp(0, 1 << 31);
    if (_retainCount == 0) _socket?.dispose();
  }

  void sendMessage(String conversationId, Map<String, dynamic> payload) =>
      _socket?.emit('message:send', {'conversationId': conversationId, ...payload});
}
```

Rules:
- **Retain-count** connect/disconnect — multiple screens (list + thread) hold the socket.
- **Foreground gating**: app lifecycle observer connects on `resumed`, disconnects on
  `paused`/`hidden` (shared with the video/audio pause hook).
- Reconnect with exponential backoff; re-join conversation rooms after `onConnect`.
- A debug logger that redacts tokens/payload bodies (dev only).
- Expose a broadcast `Stream<ChatSocketEvent>`; cubits subscribe, service never touches UI.

## 2. REST history

- `GET /conversations` (paginated), `GET /conversations/:id/messages?cursor=`
  (reverse-paginated: newest first, `hasMore` flag), `POST /conversations/:id/read`,
  `POST /messages` fallback when the socket is down.
- Repo returns entities; cubit merges socket events into the loaded list (dedupe by
  message id, keep ordering by `createdAt`).
- Optimistic send: add a local `pending` message with a temp id, replace on ack, mark
  `failed` with retry if the socket throws or times out.

## 3. E2E crypto (device identity + conversation keys)

- **Device identity**: generate an X25519 keypair on first login, store the private key
  in `flutter_secure_storage` (`DeviceKeyStore`), register the public key with the backend
  (`PATCH /notifications/devices/:deviceUid/public-key`).
- **Conversation key**: AES-256 key generated per conversation; wrapped for every
  participant device with their X25519 public key (sealed box); stored via
  `ConversationKeyStore` (secure storage). New device → backend appends its wrapped key;
  clients re-fetch on key-version change.
- **Message payload**: AES-256-GCM — `{ciphertext, nonce, mac, keyVersion}`; the server
  stores ciphertext only.
- Never log keys, plaintext, or wrapped keys. Crypto code lives in `core/crypto/`, pure
  Dart, unit-tested with known vectors (see `testing.md`).

## 4. UI

- Conversation list: avatar + last message preview + relative time (`timeAgo` extension)
  + unread badge cubit (`@Singleton` + `BlocProvider.value` at app root).
- Thread: reversed `ListView`, date separators, typing indicator (socket `typing` events),
  optimistic bubbles with `sending/sent/failed` status, image messages via presigned upload
  then send the key.
- Enter to send on desktop/web; `TextInputAction.send` + `onSubmitted` on mobile.
- Empty/error/loading via the shared design-system widgets; no custom loaders.

## 5. Notifications

- FCM data message `{type: 'chat', conversationId, messageId}` → tap handler routes to the
  thread (cold-start payload consumed after router ready).
- Suppress notification for the currently open conversation (check active thread id).
- Badge count refresh on `message:new` and on app resume.

## Failure modes

| Symptom | Cause |
|---|---|
| Messages duplicated | socket event + REST fetch both appended; dedupe by id |
| Socket dies after background | missing lifecycle reconnect |
| Old messages unreadable after reinstall | private key lost — design for key re-registration, not recovery |
| Send hangs | socket down and no REST fallback |
| Unread badge wrong | badge cubit not refreshed on read event |
