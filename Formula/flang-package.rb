class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.29"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.29/flang-package-0.7.29-macos-arm64.tar.gz"
      sha256 "74409f5801ac9ee930da2fbca749344b5d260d16db36b11e0422a79727eb0ea2"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.29/flang-package-0.7.29-macos-x86_64.tar.gz"
      sha256 "de1814d912f676669b98126239bed61c4e11dea560944b6b57638535e9df4cde"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.29/flang-package-0.7.29-linux-aarch64.tar.gz"
      sha256 "a7c2cfd500b871297f8e4954aaca17fa7419fe3378e543debdbd58babdbc5c44"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.29/flang-package-0.7.29-linux-x86_64.tar.gz"
      sha256 "5b3e111af88923d4448f9de0002e389d4f64376f0c87e9c9b8171b7e0464931e"
    end
  end

  def install
    bin.install "bin/flang"
    bin.install "bin/flangtutor" if File.exist?("bin/flangtutor")
    lib.install Dir["lib/*"] if Dir.exist?("lib")
    include.install Dir["include/*"] if Dir.exist?("include")
    (share/"flang").install Dir["share/flang/*"]
    (share/"flang-tutor").install Dir["share/flang-tutor/*"] if Dir.exist?("share/flang-tutor")
    man1.install "share/man/man1/flang.1"
  end

  def caveats
    <<~EOS
      The command is `flang`. LLVM Flang (the Fortran compiler, formula `flang`
      in homebrew/core) has the same name; if both are installed, the one
      earlier on PATH wins. Check with: flang --version
    EOS
  end

  test do
    assert_match "flang #{version}", shell_output("#{bin}/flang --version")
    (testpath/"probe.flang").write <<~FLANG
      модуль «Проба»
        использует «Lists» только «Соединить списки»

      тотальная функция «Два»
        возвращает список строки
        «Соединить списки» от ["а"] и ["б"]
    FLANG
    system bin/"flang", "check", "probe.flang"
    system bin/"flang", "emit", "probe.flang", "--target", "c", "--out", "out"
    assert_path_exists testpath/"out/flang_runtime.c"
  end
end
