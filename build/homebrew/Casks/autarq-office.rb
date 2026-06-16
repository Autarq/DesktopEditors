cask "autarq-office" do
  version "9.3.1-beta.1"
  sha256 "ca57a309e72202f3b443a172c7b240d2a8b3482d3586e3def9c3104f3e4da235"

  url "https://github.com/Autarq/DesktopEditors/releases/download/beta-1/AUTARQ-Office-macOS-arm64.zip"
  name "AUTARQ Office"
  desc "AUTARQ desktop office suite"
  homepage "https://github.com/Autarq/DesktopEditors"

  depends_on arch: :arm64

  app "AUTARQ Office.app"

  zap trash: [
    "~/Library/Application Support/AUTARQ Office",
    "~/Library/Caches/com.autarq.office",
    "~/Library/Preferences/com.autarq.office.plist",
    "~/Library/Saved Application State/com.autarq.office.savedState",
  ]
end
