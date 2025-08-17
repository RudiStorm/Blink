using System.Collections.Generic;

namespace BlinkApp.Plugins
{
    public interface IPluginLoader
    {
        IEnumerable<IPlugin> LoadPlugins();
    }
}