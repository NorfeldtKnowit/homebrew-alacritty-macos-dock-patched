class AlacrittyMacosDockPatched < Formula
  desc "GPU-accelerated terminal emulator (with macOS dock menu)"
  homepage "https://github.com/alacritty/alacritty"
  url "https://github.com/alacritty/alacritty/archive/refs/tags/v0.16.1.tar.gz"
  sha256 "ae11cfe89a86db9e7172f0ff03d83fb03f96e07e2c3c61e98de6ac85acba17bf"
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
