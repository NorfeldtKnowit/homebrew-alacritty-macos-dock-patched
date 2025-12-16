class AlacrittyMacosDockPatched < Formula
  desc "GPU-accelerated terminal emulator (with macOS dock menu)"
  homepage "https://github.com/alacritty/alacritty"

  # Source: Alacritty v0.16.1 (https://github.com/alacritty/alacritty/releases/tag/v0.16.1)
  # Mirrored as GitHub release asset for stable SHA256 distribution
  url "https://github.com/NorfeldtKnowit/homebrew-alacritty-macos-dock-patched/releases/download/v0.16.1/alacritty-v0.16.1.tar.gz"
  sha256 "b7240df4a52c004470977237a276185fc97395d59319480d67cad3c4347f395e"
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
