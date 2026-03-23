using System.Diagnostics;
using System.IO.Compression;
using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SuperVPNSingle;

internal static partial class Program
{
    [STAThread]
    private static void Main()
    {
        LauncherConfig config = ReadLauncherConfig();

        string appDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            config.AppDirectoryName);

        string appExe = Path.Combine(appDir, config.AppExecutableName);

        if (!File.Exists(appExe))
        {
            Directory.CreateDirectory(appDir);
            ExtractEmbeddedPayload(appDir);
        }

        if (File.Exists(appExe))
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = appExe,
                WorkingDirectory = appDir,
                UseShellExecute = true
            });
        }
    }

    private static LauncherConfig ReadLauncherConfig()
    {
        using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("LauncherConfigJson");
        if (stream is null)
        {
            throw new InvalidOperationException("Embedded launcher config not found.");
        }

        LauncherConfig? config = JsonSerializer.Deserialize(stream, LauncherConfigJsonContext.Default.LauncherConfig);
        if (config is null || string.IsNullOrWhiteSpace(config.AppDirectoryName) || string.IsNullOrWhiteSpace(config.AppExecutableName))
        {
            throw new InvalidOperationException("Embedded launcher config is invalid.");
        }

        return config;
    }

    private static void ExtractEmbeddedPayload(string destinationDirectory)
    {
        using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("PayloadZip");
        if (stream is null)
        {
            throw new InvalidOperationException("Embedded payload not found.");
        }

        using var archive = new ZipArchive(stream, ZipArchiveMode.Read);

        foreach (ZipArchiveEntry entry in archive.Entries)
        {
            if (string.IsNullOrEmpty(entry.Name))
            {
                string dirPath = Path.Combine(destinationDirectory, entry.FullName);
                Directory.CreateDirectory(dirPath);
                continue;
            }

            string targetPath = Path.Combine(destinationDirectory, entry.FullName);
            string? targetDir = Path.GetDirectoryName(targetPath);
            if (!string.IsNullOrEmpty(targetDir))
            {
                Directory.CreateDirectory(targetDir);
            }

            entry.ExtractToFile(targetPath, overwrite: true);
        }
    }

    private sealed partial class LauncherConfig
    {
        public string AppDirectoryName { get; set; } = string.Empty;

        public string AppExecutableName { get; set; } = string.Empty;
    }

    [JsonSerializable(typeof(LauncherConfig))]
    private sealed partial class LauncherConfigJsonContext : JsonSerializerContext
    {
    }
}
