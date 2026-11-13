class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.35"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.35/flang-package-0.7.35-macos-arm64.tar.gz"
      sha256 "218b378eb2cbece1acc64f0b25cd2419003e71ff0690fc4070a7a313d4b12d52"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.35/flang-package-0.7.35-macos-x86_64.tar.gz"
      sha256 "3816956812a10875189909e705afcf23f9492631a3a9609522694bcd602d4bfd"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.35/flang-package-0.7.35-linux-aarch64.tar.gz"
      sha256 "4ba8f0917d44f9c1705e2425271117d8a643739e2e7cbc1a7198f27a35457114"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.35/flang-package-0.7.35-linux-x86_64.tar.gz"
      sha256 "aaae90b1e69b567f90ad82cb6ec6d00f384d81fc5cc360be097e6fa6b319c605"
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
