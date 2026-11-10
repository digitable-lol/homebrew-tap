class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.33"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.33/flang-package-0.7.33-macos-arm64.tar.gz"
      sha256 "b934201bf14afca0bca9e18e6958a33ac9a018febb0f71fd5c14db8bcb5e9467"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.33/flang-package-0.7.33-macos-x86_64.tar.gz"
      sha256 "fdbbf353628d5d19fb7a1aac239654455066bc80e950a9731cdca500916d4160"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.33/flang-package-0.7.33-linux-aarch64.tar.gz"
      sha256 "47e73c143059f84082aa8a1c15a58a360591a00d4decc0c06aa6e4a5680ce27d"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.33/flang-package-0.7.33-linux-x86_64.tar.gz"
      sha256 "f64425b1e1dfc0dab39550b3b20a15529617326c9a3395e701f19dabd64f20c2"
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
