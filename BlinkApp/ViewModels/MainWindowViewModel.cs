using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using BlinkApp.Models;
using BlinkApp.Plugins;
using CommunityToolkit.Mvvm.ComponentModel;

namespace BlinkApp.ViewModels
{
    public partial class MainWindowViewModel : ViewModelBase
    {
        private readonly IPluginLoader _pluginLoader = new PluginLoader();

        [ObservableProperty]
        private string searchTerm;

        private CancellationTokenSource _debounceCts;

        partial void OnSearchTermChanged(string value)
        {
            _debounceCts?.Cancel();
            _debounceCts = new CancellationTokenSource();
            var token = _debounceCts.Token;
            _ = Task.Delay(500, token).ContinueWith(t =>
            {
                if (!t.IsCanceled)
                    Search(value);
            }, TaskScheduler.FromCurrentSynchronizationContext());
        }

        public ObservableCollection<SearchResult> SearchResults { get; } = new();

        public MainWindowViewModel()
        {
            LoadDefaultItems();
        }

        private void LoadDefaultItems()
        {
            SearchResults.Clear();
            for (int i = 1; i <= 20; i++)
                SearchResults.Add(new SearchResult { Title = $"Item {i}", Description = $"Description for item {i}", Actions = new List<Actions>() });
        }

        public void Search(string term)
        {
            if (string.IsNullOrWhiteSpace(term))
            {
                LoadDefaultItems();
            }
            else
            {
                var pluginResults = _pluginLoader.LoadPlugins()
                    .Select(p => p.Execute(term))
                    .Where(r => r != null)
                    .ToList();

                SearchResults.Clear();

                if (pluginResults.Any())
                {
                    foreach (var pr in pluginResults)
                    {
                        var actions = new List<Actions>();
                        if (!string.IsNullOrWhiteSpace(pr.UniversalCommand))
                            actions.Add(new Actions { Title = "Run (All)", Icon = null, Command = pr.UniversalCommand });
                        if (!string.IsNullOrWhiteSpace(pr.WindowsCommand))
                            actions.Add(new Actions { Title = "Run (Windows)", Icon = null, Command = pr.WindowsCommand });
                        if (!string.IsNullOrWhiteSpace(pr.MacCommand))
                            actions.Add(new Actions { Title = "Run (Mac)", Icon = null, Command = pr.MacCommand });

                        SearchResults.Add(new SearchResult
                        {
                            Title = pr.Title,
                            Description = pr.Description,
                            Actions = actions
                        });
                    }
                }
                else
                {
                    SearchResults.Add(new SearchResult
                    {
                        Title = term,
                        Description = $"Description for {term}",
                        Actions = new List<Actions>()
                    });
                }
            }
        }
    }
}