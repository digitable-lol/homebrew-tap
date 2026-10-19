class FlangPackage < Formula
  desc "Verifiable programming language that prints programs into ten languages"
  homepage "https://github.com/digitable-lol/flang"
  version "0.7.30"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.30/flang-package-0.7.30-macos-arm64.tar.gz"
      sha256 "45e97979d507475ac27e398e9ad7b28a9715477b701116e52d3ffbeaaec5f32b"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.30/flang-package-0.7.30-macos-x86_64.tar.gz"
      sha256 "2b6b85fa3bb17fcae4da31b052de749cc3de4b01443d54eab957fff56ae64d3d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.30/flang-package-0.7.30-linux-aarch64.tar.gz"
      sha256 "294b33a57b059dc14dafe67a07ac2983655cc4e3e8764a6e29bc514189d4a1aa"
    end
    on_intel do
      url "https://github.com/digitable-lol/flang/releases/download/v0.7.30/flang-package-0.7.30-linux-x86_64.tar.gz"
      sha256 "fa3e8bd1eaa52b44c8f843544c21295acc13e80faa9c1dc281d0e2473009fd49"
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
