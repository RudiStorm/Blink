using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using Avalonia;

namespace BlinkApp.Plugins
{
    public class PluginLoader : IPluginLoader
    {
        public IEnumerable<IPlugin> LoadPlugins()
        {
            var pluginDir = Path.Combine(AppContext.BaseDirectory, "plugins");
            if (!Directory.Exists(pluginDir)) yield break;

            foreach (var dir in Directory.GetDirectories(pluginDir))
            {
                var manifestPath = Path.Combine(dir, "manifest.json");
                if (!File.Exists(manifestPath)) continue;

                Manifest manifest;
                try
                {
                    var json = File.ReadAllText(manifestPath);
                    manifest = JsonSerializer.Deserialize<Manifest>(json);
                }
                catch
                {
                    continue;
                }

                if (manifest.Type == "dll")
                {
                    var dllPath = Path.Combine(dir, manifest.Entry);
                    if (!File.Exists(dllPath)) continue;
                    var assembly = Assembly.LoadFrom(dllPath);
                    var pluginType = assembly.GetTypes()
                        .FirstOrDefault(t => typeof(IPlugin).IsAssignableFrom(t) && !t.IsInterface && !t.IsAbstract);
                    if (pluginType != null)
                    {
                        var plugin = (IPlugin)Activator.CreateInstance(pluginType);
                        plugin.Initialize();
                        yield return plugin;
                    }
                }
                else if (manifest.Type == "js")
                {
                    // JS plugin loading to be implemented
                }
                else if (manifest.Type == "json")
                {
                    var plugin = new JsonPlugin(manifest, dir);
                    plugin.Initialize();
                    yield return plugin;
                }
                {
                    // JS plugin loading to be implemented
                }
            }
        }
    }
}