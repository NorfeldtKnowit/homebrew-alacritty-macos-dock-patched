class AlacrittyMacosDockPatched < Formula
  desc "GPU-accelerated terminal emulator (with macOS dock menu)"
  homepage "https://github.com/alacritty/alacritty"
  url "https://github.com/alacritty/alacritty/archive/refs/tags/v0.13.2.tar.gz"
  sha256 "e9a54aabc92bbdc25ab1659c2e5a1e9b76f27d101342c8219cc98a730fd46d90"
  license "Apache-2.0"

  depends_on "rust" => :build
  depends_on "scdoc" => :build

  def install
    # Apply patch before building
    patch_file = "#{tap.path}/alacritty-dock-menu.patch"
    ohai "Applying patch: #{patch_file}"
    system "patch", "-p1", "-i", patch_file

    system "make", "app"
    prefix.install "target/release/osx/Alacritty.app"
    bin.install_symlink prefix/"Alacritty.app/Contents/MacOS/alacritty"
  end

  def caveats
    <<~EOS
      To use as GUI app, create symlink:
        ln -s #{prefix}/Alacritty.app /Applications/Alacritty-Patched.app

      Or launch with:
        open #{prefix}/Alacritty.app
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/alacritty --version")
  end
end
