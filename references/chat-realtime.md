# Chat & Realtime (Socket.IO + E2E crypto)

Implement only the requested chat capabilities: transport and history first, then any
required encryption, UI and notifications. Reuse the app's existing protocol and infrastructure.

## 1. Transport service

`features/chat/data/services/chat_socket_service.dart` — `@lazySingleton`:

Constructor-inject the client configuration and the existing secure session boundary.
Read the current token there, not from SharedPreferences or a service locator inside connect.
Expose typed domain events with a defined parsing/error path. Keep the Socket.IO client and
its callback types inside the data service. Services never navigate or hold BuildContext.

One owner manages connection demand, lifecycle and retries. A retain count measures active
consumers, not reconnect attempts; don't increment it again on every resume. Single-flight
connect, dispose old sockets/listeners before replacement, reauthenticate safely after token
refresh, and reject late events from a previous user/session. Clear the active socket reference
when disposed so the next demand can create a usable client. Close owned stream controllers.

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
- Past ~500 lines, split the conversation cubit by concern (`runtime/`, `timeline/`,
  `socket_session/`, `message_mapper/`) instead of one giant cubit file.
- Optimistic send: add a local `pending` message with a temp id, replace on ack, mark
  `failed` with retry if the socket throws or times out.

## 3. Encryption when required

Use a reviewed protocol and maintained implementation that fits the product's identity,
multi-device, recovery and threat model. Do not invent a production messaging protocol from
an X25519/AES recipe. Key agreement alone does not authenticate a participant/device; nonce
management, identity verification, forward secrecy, replay handling and key rotation are
protocol concerns that need explicit design and tests.

Private keys belong in the existing secure key store; never logs, preferences or push payloads.
Define membership/device changes, lost-key behavior, backup/recovery and unreadable historical
messages before implementing UI. Verify known vectors and error/tamper paths using the chosen
protocol's specification. Do not claim E2E properties from a symmetric-encryption smoke test.
Read [Signal protocol specifications](https://signal.org/docs/) and the selected library's
[authenticated-encryption constraints](https://doc.libsodium.org/secret-key_cryptography/aead)
when evaluating these requirements. These sources are design references, not automatic
instructions to add a new crypto stack to ordinary chat.

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
