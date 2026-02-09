Secure Messaging App (Flutter)

This repository contains a privacy-focused mobile messaging application developed with Flutter for Android and iOS. The project is designed around security-first principles, with end-to-end encryption (E2EE) enabled by default.

The cryptographic model is inspired by the Signal protocol, ensuring that message content is encrypted on the client device and can only be decrypted by the intended recipient. The backend operates under a zero-trust model, acting exclusively as a transport and storage layer for encrypted data, without access to private keys or plaintext messages.

User authentication is performed via phone number verification using one-time passwords (OTP). Cryptographic identities are generated locally on the device and are strictly separated from authentication mechanisms.

Core Features

Cross-platform mobile app built with Flutter

End-to-end encrypted one-to-one messaging

Signal-inspired key management and session establishment

Client-side encryption and decryption

Phone number authentication via OTP

Real-time communication using WebSockets

Server-side storage of encrypted messages only

Project Scope

This project serves as an educational and research-oriented implementation of secure messaging concepts and provides a solid foundation for further development, such as group messaging, multi-device support, and encrypted backups.
