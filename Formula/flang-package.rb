class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.40"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.40/flang-package-0.7.40-macos-arm64.tar.gz"
      sha256 "8120d13fbade92729ffad8902a91d635e6000a85b8ee1ab3f2326493987c0ac5"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.40/flang-package-0.7.40-macos-x86_64.tar.gz"
      sha256 "c1e57c1de39816354e5924c2b775933e2c83a89b576e6559c601614b56d5db2b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.40/flang-package-0.7.40-linux-aarch64.tar.gz"
      sha256 "55f17e3c792d3a608baaa4621afce4775ba75ce79e8b55e93a9f3e41fded916b"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.40/flang-package-0.7.40-linux-x86_64.tar.gz"
      sha256 "31f166099c885a3e62c49e0736230d8dfe1e845acab5fde81d9fd7232b314551"
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
