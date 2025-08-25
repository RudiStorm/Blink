# Blink

Lightweight cross-platform launcher built with Avalonia and .NET 9.0.

## Features

- Debounced search UI with real-time plugin results
- JSON and DLL-based plugins loaded from `plugins/` folder
- Plugin manifest validation against JSON schema
- Self-contained Windows and macOS builds via `release.sh`
- Simple settings dialog
- Auto-version bump and GitHub release script

## Getting Started

### Prerequisites

- .NET 9.0 SDK
- [GitHub CLI (`gh`)](https://cli.github.com/) for release automation

### Build & Run

```bash
# Restore and build
dotnet build BlinkApp/BlinkApp.csproj

# Run the app
dotnet run --project BlinkApp/BlinkApp.csproj
```

### Release Automation

`release.sh` will:

1. Bump patch version in `BlinkApp.csproj`
2. Commit, tag (`vX.Y.Z`), and push
3. Publish self-contained builds for `win-x64` and `osx-x64`
4. Create or update GitHub release and upload zipped artifacts

```bash
chmod +x release.sh
./release.sh
```

## Plugin System

1. Create `plugins/` at app root.
2. Add subfolder per plugin, e.g. `plugins/MyPlugin/`.
3. Include `manifest.json` (ID, name, version, entry, type).
4. Add `plugin.json` or compiled DLL matching `entry`.
   - JSON plugins: array of `{ keyword, title, description, universalCommand, windowsCommand, macCommand }` entries
5. On search, matching plugins execute and return results.

See `plugins/manifest.schema.json` for manifest spec.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make changes and ensure build/tests pass
4. Submit a pull request

## License

MIT © Your Name
