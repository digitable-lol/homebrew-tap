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
