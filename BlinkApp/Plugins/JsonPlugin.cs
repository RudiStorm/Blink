using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace BlinkApp.Plugins
{
    internal class JsonPlugin : IPlugin
    {
        private readonly List<Entry> _entries;

        public JsonPlugin(Manifest manifest, string pluginDir)
        {
            var path = Path.Combine(pluginDir, manifest.Entry);
            var json = File.ReadAllText(path);
            _entries = JsonSerializer.Deserialize<List<Entry>>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<Entry>();
        }

        public void Initialize() { }

        public PluginResult Execute(string input)
        {
            var entry = _entries.FirstOrDefault(e => e.Keyword.Equals(input, StringComparison.OrdinalIgnoreCase));
            if (entry == null) return null;
            return new PluginResult
            {
                Title = entry.Title,
                Description = entry.Description,
                UniversalCommand = entry.UniversalCommand,
                WindowsCommand = entry.WindowsCommand,
                MacCommand = entry.MacCommand
            };
        }

        private class Entry
        {
            public string Keyword { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public string UniversalCommand { get; set; }
            public string WindowsCommand { get; set; }
            public string MacCommand { get; set; }
        }
    }
}