# Universal single EXE build

Этот каталог содержит универсальный пайплайн для сборки одного EXE-лаунчера
для любых desktop-проектов на Windows.

Лаунчер при первом запуске:

1. Распаковывает payload в `%LOCALAPPDATA%\\<AppDirectoryName>`.
2. Запускает `<AppExecutableName>` из распакованной папки.

## Что находится в папке

- `build-single-exe.ps1` — конфигурируемый скрипт сборки.
- `build-config.json` — параметры конкретного проекта (что паковать, как назвать EXE).
- `single_launcher/` — .NET launcher, в который встраиваются `payload.zip` и `launcher-config.json`.
- `launcher.cmd` и `single_exe.sed` — legacy-вариант через IExpress.

## Требования

- Windows.
- Установленный .NET SDK.
- Доступный в PATH `tar` (bsdtar в Windows 10/11).
- Корень проекта содержит все пути, перечисленные в `PayloadItems`.

## Быстрый старт

1. Отредактируйте `build/build-config.json` под ваш проект.
2. Из корня репозитория выполните:

```powershell
powershell -ExecutionPolicy Bypass -File .\build\build-single-exe.ps1
```

3. Готовый файл появится в папке, заданной `DistDir`, с именем `OutputFileName`.

## Запуск с другим конфигом

```powershell
powershell -ExecutionPolicy Bypass -File .\build\build-single-exe.ps1 -ConfigPath build\my-project-config.json
```

## Параметры build-config.json

- `AppDirectoryName` — имя папки в `%LOCALAPPDATA%` для распаковки.
- `AppExecutableName` — exe, который нужно запустить после распаковки.
- `OutputFileName` — итоговое имя single EXE в `DistDir`.
- `AssemblyName` — имя публикуемого launcher exe (внутреннее имя сборки).
- `RuntimeIdentifier` — RID для `dotnet publish` (например, `win-x64`).
- `DistDir` — папка с итоговым артефактом относительно корня репозитория.
- `PayloadItems` — массив файлов/папок (относительные пути от корня), которые попадут в payload.

## Что делает скрипт

1. Читает `build-config.json` и валидирует обязательные поля.
2. Создаёт `build/payload.zip` из `PayloadItems`.
3. Генерирует `build/single_launcher/launcher-config.json` с параметрами запуска.
4. Запускает `dotnet publish` для launcher (single-file, self-contained, trimmed).
5. Копирует результат в `DistDir/OutputFileName`.
6. Чистит временные артефакты (`payload.zip`, `publish`, `bin`, `obj`, `launcher-config.json`).

## Troubleshooting

- Если не найден путь из `PayloadItems`, проверьте относительный путь от корня проекта.
- Если `tar` недоступен, убедитесь, что bsdtar есть в PATH.
- Если блокирует политика PowerShell, используйте `-ExecutionPolicy Bypass`.
- Если путь проекта содержит не-ASCII символы и сборка ведёт себя нестабильно,
  временно соберите из ASCII-пути и перенесите готовый артефакт обратно.

## Legacy IExpress (шаблон)

Файлы `launcher.cmd` и `single_exe.sed` переведены в универсальный шаблон с
плейсхолдерами.

Плейсхолдеры в `launcher.cmd`:

- `__APP_DIRECTORY_NAME__` — имя папки в `%LOCALAPPDATA%`.
- `__APP_EXECUTABLE_NAME__` — имя запускаемого EXE внутри распакованной папки.

Плейсхолдеры в `single_exe.sed`:

- `__TARGET_NAME__` — полный путь к итоговому EXE, который создаст IExpress.
- `__FRIENDLY_NAME__` — отображаемое имя пакета.
- `__SOURCE_FILES_DIR__` — папка, где лежат `launcher.cmd` и `payload.zip` для упаковки.

Перед запуском IExpress замените плейсхолдеры на конкретные значения проекта.
