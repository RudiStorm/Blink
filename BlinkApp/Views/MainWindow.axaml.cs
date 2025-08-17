using System;
using System.Diagnostics;
using System.Linq;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using BlinkApp.Models;
using BlinkApp.ViewModels;

namespace BlinkApp.Views
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            DataContext = new MainWindowViewModel();
        }

        private void OnWindowDeactivated(object? sender, EventArgs e)
        {
            this.WindowState = WindowState.Minimized;
            DataContext = new MainWindowViewModel();
        }

        private void Settings_Click(object? sender, RoutedEventArgs e)
        {
            var settings = new SettingsWindow();
            settings.ShowDialog(this);
        }

        private void SearchResults_DoubleTapped(object? sender, RoutedEventArgs e)
        {
            ExecuteAction();
        }

        private void SearchResults_KeyUp(object? sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
                ExecuteAction();
        }

        private void ExecuteAction()
        {
            if (SearchResults.SelectedItem is SearchResult sr && sr.Actions?.Any() == true)
            {
                var action = sr.Actions.First();
                var cmd = action.Command;
                if (!string.IsNullOrWhiteSpace(cmd))
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = cmd,
                        UseShellExecute = true
                    };
                    Process.Start(psi);
                }
            }
        }
    }
}