# Cascabel

**A chess engine written in Mapanare.** Cascabel is Spanish for rattlesnake.

[![CI](https://github.com/Mapanare-Research/cascabel/actions/workflows/ci.yml/badge.svg)](https://github.com/Mapanare-Research/cascabel/actions/workflows/ci.yml)
[![Language: Mapanare](https://img.shields.io/badge/language-Mapanare-26734d)](https://github.com/Mapanare-Research/Mapanare)

The board, legal move generation, evaluation, search, and terminal protocol
are implemented in [`src/main.mn`](src/main.mn). This is an independent
project: you do not need a checkout of the Mapanare compiler to build it.

Cascabel 0.1.0 is a playable terminal prototype. It supports FEN positions,
castling, en passant, all four promotions, perft, and fixed-depth alpha–beta
search. It has no UCI interface yet.

## Build and play

Supported build platforms: Linux x86_64 (including Ubuntu under WSL) and
macOS on Apple Silicon. You need `clang`, `make`, `curl`, and `tar`.

On Ubuntu/WSL, install the build tools first:

```bash
sudo apt-get update
sudo apt-get install -y clang make curl
```

On macOS, install Apple's command-line developer tools with `xcode-select --install`,
then install LLVM 18 with [Homebrew](https://brew.sh). The bootstrap compiler
emits LLVM attributes that older Apple Clang versions cannot read.

```bash
brew install llvm@18
export PATH="$(brew --prefix llvm@18)/bin:$PATH"
```

```bash
git clone https://github.com/Mapanare-Research/cascabel.git
cd cascabel
make setup
make build
./build/cascabel
```

`make setup` installs the checksum-pinned Mapanare **5.54.0** compiler/runtime
bundle into the ignored `.toolchain/` directory. This version is the verified
build dependency, independent of the language project's newer development
versions. Clang links the Mapanare runtime supplied by that bundle; there is
no vendored C chess implementation or generated LLVM IR in this repository.

From PowerShell, after building under WSL, run from this repository directory:

```powershell
wsl -d Ubuntu -- ./build/cascabel
```

Try `d`, `play e2e4`, `go 2`, then `quit`. `go` searches and plays the engine's
reply. The executable reads standard input and exits on EOF or an empty line.

## Commands

| Command | Result |
|---|---|
| `help` | Show commands |
| `startpos` | Reset to the starting position |
| `fen <six FEN fields>` | Load a position |
| `d` | Display the board |
| `moves` | List legal coordinate moves |
| `play e2e4` | Play a legal move; promotions use a suffix, e.g. `a7a8n` |
| `go 2` | Search and play a move; depth 1–4 |
| `perft 3` | Count legal move paths; depth 0–4 |
| `quit` | Exit |

Use single spaces between command/FEN fields. Malformed input and illegal
moves leave the position unchanged. `bestmove 0000` means no legal move exists.
This is Cascabel's terminal protocol, not UCI.

## Design

- A 120-cell mailbox board, with explicit board copies between positions.
- Legal move filtering, king safety, castling rights and attacked-square checks.
- En passant, including discovered-check filtering, and all four promotions.
- Negamax with alpha–beta pruning, material values and pawn-advance bonuses.
- Checkmate and stalemate detection, including at the search horizon.
- A zero search score at the fifty-move threshold, after checking for mate.

All chess logic is Mapanare. Python is used only by the black-box test harness;
Make and Bash provide build tooling. GitHub does not yet recognize Mapanare
in its automatic language statistics. Test and build tooling is excluded from
those statistics; the README badge identifies the actual implementation language.

## Tests

The 52 tests compile and execute the engine through both compilers in the
released toolchain. Missing compilers or build tools fail the suite rather
than silently skipping it.

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
make setup
make test PYTHON=.venv/bin/python
```

To build with the bootstrap compiler explicitly:

```bash
make build BACKEND=bootstrap BUILD_DIR=build/bootstrap
```

The tests cover repeated searches, position isolation, malformed commands,
castling, promotion, en passant, mate/stalemate and standard perft positions
also used in [Stockfish's perft suite](https://github.com/official-stockfish/Stockfish/blob/master/tests/perft.sh).

| Position | Depth | Nodes |
|---|---:|---:|
| Initial position | 4 | 197,281 |
| Kiwipete | 3 | 97,862 |
| Rook/pawn endgame | 4 | 43,238 |
| Castling/promotion position | 3 | 9,467 |
| Promotion/check position | 3 | 62,379 |
| Middlegame | 3 | 89,890 |

CI runs both compiler paths on Linux and macOS and uploads native binary
archives. Pushing a matching `v<VERSION>` tag runs those checks again and
publishes a prototype prerelease with binaries and SHA-256 checksums.

## Current limits and next steps

There is no clock management, search interruption, repetition history,
insufficient-material adjudication, quiescence search, transposition table,
or measured playing strength. FEN validation checks representation and
required kings, not whether a position is reachable in a legal game.

Runtime stress testing found retained allocations in the compiler's generated
ownership/cleanup paths. Search depth is capped, but repeated commands can
still grow process memory. Restart between long experiments. An initial Linux
sanitizer probe reported approximately 1.7 MB retained after two depth-two
perft runs and a short play/search/reset session; this is an open issue, not
a clean leak-check result.

The Windows v5.54.0 native compiler rejected the engine's LLVM IR with
PHI/predecessor errors. Use WSL on Windows. The source also avoids chained
string method calls, `split()` results, and `trim()` on input lines because
initial probes exposed string-list indexing and aliased-string cleanup bugs.

The next milestones are bounded memory during long searches, native Windows
execution, complete draw handling, and interruptible UCI with timed search.

## Origin and license

Cascabel began as a Mapanare example and became a standalone project at
version 0.1.0. Its original implementation and tests are preserved from
[Mapanare commit e1447719](https://github.com/Mapanare-Research/Mapanare/tree/e14477192f8489f3a2030abb891a768cce966074/examples/mapanare-chess).
The engine source is unchanged by the extraction. Licensed under [MIT](LICENSE).
