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
  version "0.7.0"
  license "BSD-2-Clause"

  # Адрес объявлен безусловно, а не только внутри on_linux: без него Homebrew
  # падает ещё до проверок системы, и человек видит след вызовов вместо
  # объяснения. Проверено на живой машине владельца.
  url "https://github.com/digitable-lol/digitdisk/releases/download/v0.7.0/digitdisk-0.7.0-linux-amd64.tar.gz"
  sha256 "93174d06dd707fbf1bc53211515712b23f7b5d670efd54028c114eeb1e68380f"

  on_linux do
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.7.0/digitdisk-0.7.0-linux-arm64.tar.gz"
      sha256 "fe8f30121054c39ecdbf0ed97fcd766b3942e6ee8338a51068f23a6640be485c"
    end
  end

  on_macos do
    on_intel do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.7.0/digitdisk-0.7.0-darwin-amd64.tar.gz"
      sha256 "71f4a4a00f7a279a79b4f807a2d735e7072a83bc72a3ab43fa4a0c25a7fa7170"
    end
    on_arm do
      url "https://github.com/digitable-lol/digitdisk/releases/download/v0.7.0/digitdisk-0.7.0-darwin-arm64.tar.gz"
      sha256 "cadcdbda27da1b15d5b65e5da4a51806762f8886f9da6c06717eedef755a8351"
    end
  end

  def install
    bin.install "digitdisk"
    # СТРАНИЦ ДВЕ, И КЛАДУТСЯ ОНИ В РАЗНЫЕ МЕСТА. man ищет перевод по локали
    # сам: сперва <man>/<язык>/man1, потом <man>/man1. Поэтому английская
    # страница — базовая, в man1, а русская — в ru/man1, и тогда
    #
    #     man digitdisk                       → английская
    #     LANG=ru_RU.UTF-8 man digitdisk      → русская
    #
    # Отдельной настройки от поставившего это не требует: свой share/man
    # Homebrew кладёт в MANPATH сам. Проверяется ниже, в test do — обе.
    man1.install "digitdisk.en.1" => "digitdisk.1"
    (man/"ru/man1").install "digitdisk.1"
    doc.install "README.md", "README.ru.md", "NOTICE", "LICENSE"
  end

  def caveats
    <<~EOS
      Проверить установку:
        digitdisk --version
        digitdisk            # снимок системы: то же, что digitdisk status
        digitdisk analyze ~
        man digitdisk        # ключи, файлы, примеры (по-английски)
        LANG=ru_RU.UTF-8 man digitdisk   # та же страница по-русски

      Язык вывода digitdisk спросит один раз, при первом запуске в терминале, и
      запомнит ответ в ~/.digitable/digitdisk/settings.conf. Не терминал (труба,
      скрипт, CI) или --json — ничего не спрашивается и ничего не заводится:
      язык берётся из LC_ALL/LC_MESSAGES/LANG, а без них — английский. На один
      запуск: digitdisk --lang en. На живом экране язык переключает клавиша «l».
      Вывод --json от языка не зависит: его читают скрипты.

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

    # 6. Обе страницы руководства поставлены туда, где их ищет man, и это
    #    проверяется файлами, а не верой в install. Формула ставит двоичный
    #    файл; страницы едут с ним в том же архиве и без этих строк молча
    #    остались бы в нём.
    английская = man1/"digitdisk.1"
    русская = man/"ru/man1/digitdisk.1"
    assert_path_exists английская
    assert_path_exists русская
    assert_match "DIGITDISK 1", английская.read
    assert_match "DIGITDISK 1", русская.read
    # Та, что в man1, обязана быть английской, а та, что в ru/man1, — русской.
    # Перепутать их местами — это `man digitdisk` по-русски у того, кто
    # русского не знает, и наоборот; файл на месте, а толку нет.
    refute_match(/[А-Яа-яЁё]{4}/, английская.read.lines.grep(/^\.Nd /).join)
    assert_match(/[А-Яа-яЁё]{4}/, русская.read.lines.grep(/^\.Nd /).join)

    # 7. Инструмент говорит на двух языках, и это тоже обещание, а не
    #    намерение: две одинаковые справки — непереведённая справка.
    ru_help = shell_output("#{bin}/digitdisk --lang ru --help")
    en_help = shell_output("#{bin}/digitdisk --lang en --help")
    refute_equal ru_help, en_help
    assert_match "Подкоманды:", ru_help
    assert_match "Subcommands:", en_help

    # 8. А `--json` языка не знает: его читают скрипты, и байты в нём одни и
    #    те же, на каком бы языке ни говорил тот, кто запустил. Два прогона —
    #    это два разных момента времени, поэтому из сравнения снимаются те
    #    поля, которые меняются сами: длительность обхода и возраст файла.
    сам_по_себе = /duration_seconds|возраст_дней/
    ru_json = shell_output("#{bin}/digitdisk --lang ru analyze #{testpath}/дерево --json")
                .lines.grep_v(сам_по_себе)
    en_json = shell_output("#{bin}/digitdisk --lang en analyze #{testpath}/дерево --json")
                .lines.grep_v(сам_по_себе)
    assert_equal ru_json, en_json
    # И имена решающего слоя в нём остались собой: их читают скрипты, и
    # английский вывод на экране их не трогает.
    assert_match(/"разряд": "[А-ЯЁ]/, en_json.join)
    assert_match(/"приговор": "[А-ЯЁ]/, en_json.join)
  end
end
