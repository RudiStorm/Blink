# Plugin System Implementation To-Do List

1. **Define Plugin Folder Structure** ✅
   - Create a `plugins/` directory at app root
   - Inside `plugins/`, allow subfolders per plugin (e.g. `plugins/MyPlugin/`)

2. **Design Plugin Manifest Schema** ✅
   - Draft a `manifest.json` spec (ID, version, entry file, type: dll/js/json)
   - Create JSON Schema for validation

3. **Define Plugin Interfaces** ✅
   - C# interface `IPlugin` with `Initialize()`, `Execute(string input) => PluginResult`
   - JS contract: export a function `execute(input: string): PluginResult`

4. **Implement Plugin Loader Service** ✅ (Basic JSON/DLL loading)
   - On app startup, scan `plugins/` folder
   - For each subfolder, load and validate `manifest.json`
   - Depending on `type`:
     - **DLL**: load assembly via `Assembly.LoadFrom`, find `IPlugin` implementer
     - **JS**: host in Jint (or ClearScript), compile script, bind `execute` function

5. **Sandbox JS Execution**
   - Limit global objects and memory/time
   - Expose only `execute(input)` and a minimal API
   - Catch and log script errors

6. **Implement Manifest Validation**
   - Use `Newtonsoft.Json.Schema` or similar to validate `manifest.json`
   - Reject or disable invalid plugins

7. **Integrate Plugin Execution in ViewModel**
   - Inject `IPluginLoader` into `MainWindowViewModel`
   - On `SearchTerm` change, call loader to run all or specific plugin(s)
   - Aggregate and display `PluginResult` in `SearchResults`

8. **Implement `reset` Command**
   - Add a command (e.g. menu or key binding) named **Reset**
   - On invocation: close main window, re-launch app process
   - On new startup, plugin loader re-scans `plugins/`

9. **UI/UX for Plugin Management**
   - Add Settings page to list installed plugins
   - Allow enable/disable per-plugin
   - Show plugin version and author from manifest

10. **Logging & Error Handling**
    - Centralize logs for plugin load failures and execution errors
    - Surface errors in UI or log window

11. **Testing & Validation**
    - Unit tests for manifest validation
    - Integration tests for DLL and JS plugins
    - Simulate malformed JSON and failing scripts

12. **Documentation & Templates**
    - Write a plugin template project (C# DLL)
    - Provide example JS plugin and manifest
    - Document folder layout, manifest fields, and API in `README.md`
