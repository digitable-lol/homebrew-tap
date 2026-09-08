# Homebrew Tap for Digitable

Официальный Homebrew tap проектов Digitable.

## Digit

Установка:

```bash
brew install digitable-lol/tap/digit
```

Запуск и первичная настройка:

```bash
digit setup
digit
```

Обновление:

```bash
brew upgrade digitable-lol/tap/digit
```

Формула устанавливает CLI, ACP-команду и встроенные skills Digit в отдельное
окружение Homebrew. Пользовательские настройки, ключи, память и сессии остаются
в `~/.digit` и не удаляются при обновлении пакета.

Исходный код: [digitable-lol/digit](https://github.com/digitable-lol/digit).

## flang

Проверяемый язык: исполняемая спецификация, которая исполняется, тестируется и
печатается в восемь языков. Компилятор написан на самом языке и приезжает
напечатанным в C, поэтому **Node не нужен** — хватает `cc`.

```bash
brew install digitable-lol/tap/flang
flang    # JSON на входе, JSON на выходе
```

Полный инструментарий — восемь бэкендов, интерпретатор, языковой сервер —
ставится через npm и требует Node:

```bash
npm install -g @digitable-lol/fts
```

## Уроборос

Показывает, как код исполнялся на самом деле: какие функции звались, с какими
доводами, что вернули и что бросили. Языков восемь: Python, JavaScript/TypeScript,
C, C++, Elixir, Go, Java, C#.

```bash
brew install digitable-lol/tap/ouroboros
ouroboros languages     # список языков — им же проверяется, что инструмент встал
```

Формула ставит пакет в собственное окружение Python и выносит наружу две
команды — `ouroboros` (командная строка) и `ouroboros-mcp` (сервер MCP для
ИИ-агентов). Нужен Python 3.12 или новее; Homebrew доставит его сам.

Чтобы обмазывать не Python, доставьте отдельно:

```bash
brew install llvm      # clang-tidy и clangd — команды lint, symbols, refs, callers, describe
brew install node      # запустить обмазанный JavaScript и TypeScript
brew install elixir    # запустить обмазанный Elixir
brew install go        # обмазать, собрать и запустить Go
brew install openjdk   # обмазать и собрать Java
brew install dotnet    # обмазать и собрать C#
```

Компилятор C и C++ берётся системный. Тот же список печатает `caveats` формулы, и
там же сказано, почему эти шесть не записаны в зависимости: они нужны только тем,
кто обмазывает соответствующий язык, а тянуть их каждому, кто ставит инструмент
ради Python, неправильно.

Обновление и удаление:

```bash
brew upgrade ouroboros
brew uninstall ouroboros
```

Исходный код: [digitable-lol/ouroboros](https://github.com/digitable-lol/ouroboros).
Страницы: <https://digitable-lol.github.io/ouroboros/>.
