# vlckit-macos-patched

VLCKit for macOS, built from the official VLCKit sources with one extra patch that fixes a deadlock in libVLC's configuration lock. It is distributed as a Swift package.

This is not an official VideoLAN release.

## The problem

An app that creates and stops several `VLCMediaPlayer` instances can hang forever. The main thread waits for a read lock in `config_GetInt` while creating a player:

```
-[VLCMediaPlayer(Private) initWithDrawable:options:]
-[VLCLibrary initWithOptions:]
-[VLCLibrary prepareInstanceWithOptions:]
config_GetInt (core.c:108)
__psynch_rw_rdlock
```

VLCKit issue [#631](https://code.videolan.org/videolan/VLCKit/-/work_items/631) shows the same stack.

## The cause

- VLCKit's patches `0015-lib-save-configuration-after-playback-parse.patch` and `0024-lib-media_player-add-stop-set_media-async-support.patch` call `config_AutoSaveConfigFile()` whenever an input is closed (`release_input_thread`, `worker_thread`) and whenever a parsed media is released. These calls do not check `ignore-config`.
- `config_AutoSaveConfigFile()` takes the read lock of the process-wide `config_lock` and then calls `config_SaveConfigFile()`, which takes the read lock again (`src/config/file.c`).
- `config_PutPsz()` takes the write lock. The auhal audio output calls it whenever it is closed, and libVLC opens an audio output for every media player.
- On macOS, a pending writer blocks new readers. If a writer starts waiting between the two read locks, the second read lock never succeeds, and every thread that uses the configuration hangs.

## The patch

[`patches/9001-lib-do-not-auto-save-the-configuration-after-playback.patch`](patches/9001-lib-do-not-auto-save-the-configuration-after-playback.patch) removes these three `config_AutoSaveConfigFile()` calls. libVLC's own save in `libvlc_InternalCleanup()` remains. It only runs when `ignore-config` is disabled, which is not the default, so vlcrc is no longer written.

## Usage

Add the package with an exact version:

```swift
.package(url: "https://github.com/cathandnya/vlckit-macos-patched.git", exact: "3.7.3-patched.1")
```

The product is `VLCKit`. Use it with `import VLCKit` as with the official framework.

## How the binary is built

The release `3.7.3-patched.1` was built by `build.sh` with:

- VLCKit tag `3.7.3` from https://code.videolan.org/videolan/VLCKit
- libVLC (vlc.git) commit `79128878ddb2c280bbb6c89c76a46b31a80ade1c`, the `TESTEDHASH` of VLCKit 3.7.3
- VLCKit's patches `0001`-`0047`, then the patch in `patches/`
- macOS deployment target 12.0. VLCKit's project targets 10.9, which current Xcode no longer accepts.
- Xcode 27.2 on macOS 27.2 (Apple silicon), architectures arm64 and x86_64

To build it yourself, run `./build.sh`. It prints the checksum of the resulting `build/VLCKit.xcframework.zip`.

## License

VLCKit and libVLC are licensed under the GNU Lesser General Public License, version 2.1 or later. See [LICENSE](LICENSE). The sources are available from VideoLAN at the tag and commit above. The changes made here are the patch in `patches/` and the deployment target change in `build.sh`.
