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
  version "0.5.0"
  license "BSD-2-Clause"

  # Адрес объявлен безусловно, а не только внутри on_linux: без него Homebrew
  # падает ещё до проверок системы, и человек видит след вызовов вместо
  # объяснения. Проверено на живой машине владельца.
  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.5.0/digitdisk-0.5.0-linux-amd64.tar.gz"
  sha256 "be2aa649978e103066d79f080b59e761e15a72d33faa8e25c8ff2af712881539"

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.5.0/digitdisk-0.5.0-linux-arm64.tar.gz"
      sha256 "4f610ed9657ee9fe483513c301133e62f88613402d54c509fa81026be3738b54"
    end
  end

  on_macos do
    on_intel do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.5.0/digitdisk-0.5.0-darwin-amd64.tar.gz"
      sha256 "e30aa56457325485ad0ff9f4a6d1df5e4cfd4e97768a7305a7ed3dc6e5e39cf7"
    end
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.5.0/digitdisk-0.5.0-darwin-arm64.tar.gz"
      sha256 "272f270b748f047f0b83f6729c56d7e68cabd988ba8f0bc4f558df6954eebdec"
    end
  end

  def install
    bin.install "digitdisk"
    # man1 — то место, где `man digitdisk` страницу и ищет: Homebrew кладёт
    # свой share/man в MANPATH сам. Отдельной настройки от поставившего это
    # не требует, и проверяется ниже, в test do.
    man1.install "digitdisk.1"
    doc.install "README.md", "README.ru.md", "NOTICE", "LICENSE"
  end

  def caveats
    <<~EOS
      Проверить установку:
        digitdisk --version
        digitdisk            # снимок системы: то же, что digitdisk status
        digitdisk analyze ~
        man digitdisk        # ключи, файлы, примеры

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

    # 6. Страница руководства поставлена туда, где её ищет man, и это
    #    проверяется файлом, а не верой в install. Формула ставит двоичный
    #    файл; страница едет с ним в том же архиве и без этой строки молча
    #    осталась бы в нём.
    страница = man1/"digitdisk.1"
    assert_path_exists страница
    assert_match "DIGITDISK 1", страница.read
  end
end
