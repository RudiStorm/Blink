using System.Text.Json.Serialization;

namespace BlinkApp.Plugins
{
    public class Manifest
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }

        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("version")]
        public string Version { get; set; }

        [JsonPropertyName("entry")]
        public string Entry { get; set; }

        [JsonPropertyName("type")]
        public string Type { get; set; }
    }
}