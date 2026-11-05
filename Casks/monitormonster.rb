cask "monitormonster" do
  version "1.0.0"
  sha256 "b5192280aff8005bf69545620edeca9a261d30d01b0e20b4155ee52007be5fec"

  url "https://github.com/YOUR_GITHUB_USERNAME/MonitorMonster/releases/download/v#{version}/MonitorMonster-#{version}.dmg"
  name "MonitorMonster"
  desc "Lightweight native macOS menu bar app for Wi-Fi and battery diagnostics"
  homepage "https://github.com/YOUR_GITHUB_USERNAME/MonitorMonster"

  depends_on macos: ">= :sonoma"

  app "MonitorMonster.app"

  zap trash: [
    "~/Library/Caches/com.monitormonster.mac",
    "~/Library/Preferences/com.monitormonster.mac.plist",
  ]
end
