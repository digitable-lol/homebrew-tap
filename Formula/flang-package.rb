class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.32"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.32/flang-package-0.7.32-macos-arm64.tar.gz"
      sha256 "b1eea398db8e75b42f223bf8305aa6886bf1c62eafc6c48077cb43d083d0a066"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.32/flang-package-0.7.32-macos-x86_64.tar.gz"
      sha256 "affe86468ffdd04e5734a6204359147fb6605c6a0238e8571d67965208d26aee"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.32/flang-package-0.7.32-linux-aarch64.tar.gz"
      sha256 "d294b78de61710785fcc1bd146f8dbd9a4900b3775845ead85e974581c8af6fe"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.32/flang-package-0.7.32-linux-x86_64.tar.gz"
      sha256 "e2f2c93bc692015e717e58ac64ac549265f16a525ab6e9645e6694f04537c2e9"
    end
  end

  def install
    bin.install "bin/flang"
    bin.install "bin/flangtutor" if File.exist?("bin/flangtutor")
    # The independent proof checker: `flang check --proof` runs it from
    # ../libexec/flang/checker next to bin/flang. Every prebuilt build since
    # 0.7.30 carries it; without it every proved claim rests on the kernel alone.
    (libexec/"flang").install "libexec/flang/checker"
    lib.install Dir["lib/*"] if Dir.exist?("lib")
    include.install Dir["include/*"] if Dir.exist?("include")
    (share/"flang").install Dir["share/flang/*"]
    (share/"flang-tutor").install Dir["share/flang-tutor/*"] if Dir.exist?("share/flang-tutor")
    # The spec template `flang new` copies into a new package (0.7.31 and newer).
    (share/"flang-fspec").install Dir["share/flang-fspec/*"] if Dir.exist?("share/flang-fspec")
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

    (testpath/"larger.flang").write <<~FLANG
      модуль «Проба большего»

      тотальная функция «Большее»
        принимает а: неотрицательное, б: неотрицательное
        возвращает неотрицательное
        обеспечивает «не меньше первого» результат не меньше а
        если а больше б то а иначе б
    FLANG
    proved = shell_output("#{bin}/flang check larger.flang --proof 2>&1")
    refute_match "сверщика нет", proved
    assert_match "независимо, сверщиком", proved
  end
end
