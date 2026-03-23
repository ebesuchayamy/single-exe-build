using System.Diagnostics;
using System.IO.Compression;
using System.Reflection;

namespace SuperVPNSingle;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        string appDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "SuperVPN");

        string appExe = Path.Combine(appDir, "super_vpn.exe");

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
}
