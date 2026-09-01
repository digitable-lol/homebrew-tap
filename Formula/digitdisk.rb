# Формула Homebrew для digitdisk.
#
# ЧТО ЭТО. Исходник формулы. Правится здесь; в хранилище формул
# (digitable-lol/homebrew-tap, файл Formula/digitdisk.rb) он выкладывается
# копией, и оттуда работает короткая строка
#
#     brew install digitable-lol/tap/digitdisk
#
# ЗАПОЛНЕНИЕ. В дереве лежит заготовка: версия и оба отпечатка помечены
# словами-заглушками. Их подставляет scripts/build-release.sh — с тех самых
# архивов, которые уезжают в выпуск, — и кладёт готовый файл в
# dist/homebrew/digitdisk.rb. Отпечаток руками не вписывается: тот, кто впишет
# его по памяти, узнает об ошибке от чужой машины, которая уже не поставилась.
# Незаполненное место останавливает сборку выпуска, а не уезжает в хранилище.
#
# СТАВИТСЯ ГОТОВЫЙ ДВОИЧНЫЙ ФАЙЛ, А НЕ СБОРКА ИЗ ИСХОДНИКОВ, и это выбор.
# Ядро digitdisk — спецификация на flang, напечатанная в Go; собрать её на
# машине поставившего можно, но тогда установка требует Go и молча зависит от
# версии компилятора. Выпуск собран один раз, повторимо и с признаком
# `flangcore`, а отпечаток архива проверяет сам brew до распаковки.
#
# ТОЛЬКО LINUX. Хозяин читает /proc и /sys и зовёт uname(2) и statfs(2) в том
# виде, в каком их даёт ядро Linux; под macOS он не собирается вовсе, а не
# «собирается, но врёт». Поэтому depends_on :linux, а не тихая установка,
# которая падает при первом запуске.
class Digitdisk < Formula
  desc "Read-only disk and system reporter: where the space went, how the machine feels"
  homepage "https://github.com/digitable-lol/digitdisk"
  version "0.1.1"
  license "BSD-2-Clause"

  # Адрес объявлен БЕЗУСЛОВНО, а не только внутри on_linux, и это не
  # небрежность. Формула обязана прочитаться на любой машине: без адреса
  # снаружи Homebrew падает ещё до проверки depends_on, и человек на маке
  # получает «formula requires at least a URL» со следом вызовов вместо
  # внятного «нужен Linux». Отказ должен объяснять, а не пугать.
  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.1.1/digitdisk-0.1.1-linux-amd64.tar.gz"
  sha256 "589c124cd70ce2d138d23331e64016fae70d07bc0b415ee1b621554db80e92e0"

  depends_on :linux

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.1.1/digitdisk-0.1.1-linux-arm64.tar.gz"
      sha256 "0e0a926cadabd8a351766f855dc2c6fbca3fe93e8c1caf696bff8269a123faa8"
    end
  end

  def install
    bin.install "digitdisk"
    doc.install "README.md", "README.ru.md", "NOTICE", "LICENSE"
  end

  def caveats
    <<~EOS
      Проверить установку:
        digitdisk --version
        digitdisk status
        digitdisk analyze ~

      digitdisk только читает. Режима очистки нет, ключа, который удаляет
      файл, нет: что убрать — решение читателя и команда кого-то другого.
    EOS
  end

  test do
    # 1. Двоичный файл называет себя и свою сборку. Проверяется не код
    #    возврата, а вывод: «всегда 0 и молчит» — самый частый способ
    #    выпустить битый архив и не заметить.
    version_output = shell_output("#{bin}/digitdisk --version")
    assert_match "digitdisk #{version}", version_output
    assert_match "решающий слой", version_output

    # 2. Внутри настоящее ядро на flang, а не заглушка. Заглушка считает, но
    #    не решает: разбор по разрядам вышел бы пустым, и заметил бы это
    #    только поставивший.
    assert_match "flang", version_output
    refute_match "заглушка", version_output

    # 3. Инструмент делает своё дело. Дерево известного состава: один файл
    #    ровно в 4096 байт, и обход обязан насчитать ровно его.
    (testpath/"дерево").mkpath
    (testpath/"дерево/крупный.bin").write("x" * 4096)
    отчёт = JSON.parse(shell_output("#{bin}/digitdisk analyze #{testpath}/дерево --json"))
    assert_equal 4096, отчёт["total_bytes"]
    assert_equal 1, отчёт["files"]
    assert_equal true, отчёт["decider_ready"]

    # 4. Снимок системы читается и разбирается как JSON: ядро названо.
    снимок = JSON.parse(shell_output("#{bin}/digitdisk status --json --sample 10"))
    refute_empty снимок["host"]["kernel_release"]

    # 5. Удаления нет ни в каком виде — это обещание страницы, и оно
    #    проверяется, а не подразумевается.
    справка = shell_output("#{bin}/digitdisk --help")
    refute_match(/--(delete|remove|clean|force)/, справка)
  end
end
