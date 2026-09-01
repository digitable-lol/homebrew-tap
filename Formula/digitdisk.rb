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
# LINUX И macOS. Факты собираются по-разному: под Linux из /proc и /sys, под
# macOS из sysctl, getfsstat и маршрутного сокета — всё по справочным страницам
# системы. Решающее ядро (спецификация на flang, напечатанная в Go) одно на обе.
#
# ⚠ МАКОВСКИЙ АРХИВ НИ РАЗУ НЕ ЗАПУСКАЛСЯ НА МАКЕ. Он собирается и проходит
# статическую проверку, а разбор ответов системы написан самопроверяющимся:
# раскладка структуры принимается, только если сошлась с заведомо известным —
# свой номер процесса, свой пользователь, размер пакета от стандартной
# библиотеки. Не сошлось — поле пустое и названо в «не измерено», а не
# напечатано наугад. Часть полей на macOS пуста и так: разбивка памяти, доля
# процессора и температура требуют cgo, а он ломает повторимую сборку выпуска.
class Digitdisk < Formula
  desc "Read-only disk and system reporter: where the space went, how the machine feels"
  homepage "https://github.com/digitable-lol/digitdisk"
  version "0.2.0"
  license "BSD-2-Clause"

  # Адрес объявлен безусловно, а не только внутри on_linux: без него Homebrew
  # падает ещё до проверок системы, и человек видит след вызовов вместо
  # объяснения. Проверено на живой машине владельца.
  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.2.0/digitdisk-0.2.0-linux-amd64.tar.gz"
  sha256 "2ee0662cff9d2bccbf43f9f51f175dae63941127c83fb89a338ab18a4f41bbbf"

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.2.0/digitdisk-0.2.0-linux-arm64.tar.gz"
      sha256 "38c964f0f78edf77ec8306a2d7ae2096aefb655a69cefdacf14ad50f788ed681"
    end
  end

  on_macos do
    on_intel do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.2.0/digitdisk-0.2.0-darwin-amd64.tar.gz"
      sha256 "f3c2aed5f7803e3740bd0cab6e81daeb9070ad809af2ae027b47b47f7a3582c1"
    end
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.2.0/digitdisk-0.2.0-darwin-arm64.tar.gz"
      sha256 "4064c42e180940bdce801ff90a83ad120dd1c5a655b7feac6c18f76c8bd3eb82"
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
