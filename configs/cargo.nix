{ ... }:
{
  xdg.configFile."cargo/config.toml".text = ''
    [target.aarch64-apple-darwin]
    rustflags = ["-L", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"]
  '';
}
