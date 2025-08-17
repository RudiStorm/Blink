using System.Collections.Generic;

namespace BlinkApp.Models
{
    public class SearchResult
    {
        public string Title { get; set; }
        public string Description { get; set; }

        // List of action items (text/icon) for UI
        public List<Actions> Actions { get; set; }
    }
}