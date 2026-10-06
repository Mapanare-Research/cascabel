# Changelog

## 0.1.0 — 2026-10-05

First standalone Cascabel prototype, extracted from the Mapanare repository.

- Chess logic written entirely in Mapanare: legal moves, castling, en passant,
  four promotion choices, FEN, perft, and fixed-depth alpha–beta search.
- Independent builds using a checksum-pinned Mapanare 5.54.0 release bundle.
- 52 execution tests across the native and bootstrap compiler paths.
- Linux x86_64 / WSL and macOS arm64 CI and binary packaging.

This is a terminal prototype, not a UCI or tournament engine. Long sessions
can retain memory, native Windows compilation remains unresolved, and draw
adjudication is incomplete. See README.md for the supported commands and limits.
