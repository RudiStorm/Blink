namespace BlinkApp.Plugins
{
    public class PluginResult
    {
        public string Title { get; set; }
        public string Description { get; set; }

        // Universal command for any OS
        public string UniversalCommand { get; set; }

        // Fallback platform-specific commands
        public string WindowsCommand { get; set; }
        public string MacCommand { get; set; }
    }
}