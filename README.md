# Silex — Secure Messaging App

> A privacy-first mobile messaging application built with Flutter, featuring end-to-end encryption inspired by the Signal Protocol.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NestJS](https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## Overview

Cross-platform mobile messaging application designed around a security-first philosophy.

The cryptographic model is inspired by the app "Signal". Authentication relies on phone number verification via OTP, keeping user identity data minimal.

> The server acts exclusively as a relay for encrypted data. It cannot read your messages — by design.

---

## Features

### MVP Scope

| Feature | Status |
|---|---|
| Phone number authentication (OTP) | Included |
| Local cryptographic key generation | Included |
| End-to-end encrypted 1-to-1 chats | Included |
| Secure public key exchange | Included |
| Message encryption with key ratcheting | Included |
| Identity verification (PIN) | Included |
| Local decrypted message history | Included |
| Group chats | Out of scope |
| Voice / video calls | Out of scope |
| Cloud backups | Out of scope |
| Server-side key storage | Out of scope |

---

## Architecture

### Security Model

The architecture follows a **zero-trust server** approach:

- Private keys are generated and stored locally on the device and never transmitted.
- The server only stores ciphertext and public keys.
- Message routing uses WebSockets; offline messages are queued and delivered on reconnect.
- Sessions use Double Ratchet key derivation for forward secrecy.

```
+-------------------------------------+
|           Flutter Client            |
|  Identity Key (Ed25519) · Pre-Keys  |
|  Session Keys · Double Ratchet      |
|  Encrypt / Decrypt (local only)     |
+----------------+--------------------+
                 | Encrypted messages only
                 v
+-------------------------------------+
|           NestJS Backend            |
|  WebSockets · OTP · JWT             |
|                                     |
|  No access to private keys          |
|  Cannot decrypt messages            |
|  No plaintext storage               |
+----------------+--------------------+
                 |
                 v
+-------------------------------------+
|           PostgreSQL                |
|  users · public_keys · sessions     |
|  messages (ciphertext) · otp_reqs   |
+-------------------------------------+
```

### Authentication Flow

```
User enters phone number
        |
        v
POST /auth/request-otp  -->  Backend generates 6-digit OTP
                                    |
                                    v
                           SMS Provider sends OTP
        |
        v
POST /auth/verify-otp   -->  Backend validates & issues JWT
        |
        v
App generates key pair locally --> sends ONLY public key to server
```

---

## Tech Stack

### Frontend
- **Flutter** — Cross-platform mobile framework (Android & iOS)
- **Dart** — Application language
- Cryptographic libraries for E2EE (Ed25519, X25519, AES-GCM)

---

## Project Structure

```
flutter_app/          # Mobile client
 ├── lib/
 │   ├── screens/      # UI screens (Chats, Conversation, Contacts)
 │   ├── services/     # Crypto, WebSocket, Auth services
 │   ├── models/       # User, Chat, Message, Contact
 │   └── widgets/      # Reusable components
 └── ...

```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.x
- [Node.js](https://nodejs.org/) >= 18.x
- [PostgreSQL](https://www.postgresql.org/) >= 14
- An SMS provider (e.g., Twilio) for OTP delivery


### Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutter run
```

---


## Security Principles

1. **E2EE by default**
2. **Zero server trust**
3. **Local key custody**
4. **Independent cryptographic sessions**
5. **Frequent key rotation**

---

## License

This project is licensed under the MIT License.

---

## Author

**Yeisen Kenneth López Reyes**  
Academic project — Secure Mobile Messaging Systems