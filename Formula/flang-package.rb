class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.31"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.31/flang-package-0.7.31-macos-arm64.tar.gz"
      sha256 "1b6e850495f90f8c26093180a125d9b4780fb054a76ef9cb95daed62b1963eb0"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.31/flang-package-0.7.31-macos-x86_64.tar.gz"
      sha256 "f3f78751b4ea5dc5c74db2bf1dc4912fb444b27390720bc17579f026b81e55cb"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.31/flang-package-0.7.31-linux-aarch64.tar.gz"
      sha256 "55a45ff2e601725b06f0e2bcda6d3ba16773a211b952da83cec43939a815fe4c"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.31/flang-package-0.7.31-linux-x86_64.tar.gz"
      sha256 "c92536aafeb200a4a2811b87bb53fb7b3cf4d568a180b1d3d8d3c12bd993994e"
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
