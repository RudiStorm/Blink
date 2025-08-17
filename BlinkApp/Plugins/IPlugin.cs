namespace BlinkApp.Plugins;

public interface IPlugin
{
    void Initialize();
    PluginResult Execute(string input);
}