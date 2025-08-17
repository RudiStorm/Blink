using Avalonia.Controls;

namespace BlinkApp.Models
{
    public class Actions
    {
        public string Title { get; set; }

        public IconElement Icon { get; set; }

        // Command to execute
        public string Command { get; set; }
    }
}