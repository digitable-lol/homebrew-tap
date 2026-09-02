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
# macOS из sysctl, getfsstat, маршрутного сокета и документированных функций
# libSystem — всё по справочным страницам системы. Решающее ядро (спецификация
# на flang, напечатанная в Go) одно на обе. Обе маковские цели собираются
# кросс-сборкой с Linux, с выключенным CGO и повторимым отпечатком: маковская
# половина хозяина написана без cgo.
#
# ЧТО ПРОВЕРЕНО НА МАКЕ. Раскладку каждой структуры сверяет с машиной сам
# двоичный файл — при каждом снимке, а не однажды при сборке: свой номер
# процесса, свой пользователь, своя командная строка, свой объём памяти. Не
# сошлось — поле пустое и названо в «НЕ ИЗМЕРЕНО», а не напечатано наугад.
# Сверх того, на каждый толчок в дерево эти же проверки прогоняются на живых
# маковских бегунках GitHub, на Apple Silicon и на Intel.
#
# ЧТО НА МАКЕ ВСЁ ЕЩЁ ПУСТО. Температура: показания снимает SMC через IOKit, а
# документированного интерфейса к нему Apple не публикует. Память, потоки и
# командные строки процессов ДРУГИХ пользователей: ядро отказывает всем, кто не
# администратор, — под sudo они появляются.
class Digitdisk < Formula
  desc "Read-only disk and system reporter: where the space went, how the machine feels"
  homepage "https://github.com/digitable-lol/digitdisk"
  version "0.4.0"
  license "BSD-2-Clause"

  # Адрес объявлен безусловно, а не только внутри on_linux: без него Homebrew
  # падает ещё до проверок системы, и человек видит след вызовов вместо
  # объяснения. Проверено на живой машине владельца.
  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.4.0/digitdisk-0.4.0-linux-amd64.tar.gz"
  sha256 "f741bdbbc790080ae22b9c8a53092cd61b5407e2c0541d8e62c9e1f9ec98f4cb"

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.4.0/digitdisk-0.4.0-linux-arm64.tar.gz"
      sha256 "a1f1dfd2a92231957ef07d22141ea89252ac18aa9c2503a6452eb774e93a88f4"
    end
  end

  on_macos do
    on_intel do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.4.0/digitdisk-0.4.0-darwin-amd64.tar.gz"
      sha256 "973d81e466375d747230adabc8845b20d0093cb44a99b0398edf99e8eb82f65d"
    end
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.4.0/digitdisk-0.4.0-darwin-arm64.tar.gz"
      sha256 "a2e7cf33f8b96307cd0dafdcdcd1e25af8ba565712b123edffb46447da1f5906"
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

      status и analyze только читают. Уборка — отдельная команда и три шага:
        digitdisk clean <путь>                 план, ничего не тронуто
        digitdisk clean <путь> --apply         перенос в корзину, обратимо
        digitdisk restore <корзина>            вернуть обратно
        digitdisk purge <корзина> --confirm N  стереть, необратимо

      Убирается ровно то, чему решающий слой вынес приговор «МожноУбрать», —
      не похожее на него и не совпавшее с маской. Перенос в корзину места не
      освобождает: файлы остаются на диске под другим именем до `purge`.
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
