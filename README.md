# dotfiles — Hyprland Lua rice

Компактный rice для Hyprland 0.55+ (проверено на 0.56.2): модульный Lua-конфиг,
видео-обои через mpvpaper, динамическая палитра из обоев через wallust
(kitty / zsh / Thunar / рамки Hyprland), cliphist, скриншоты grim+slurp, Thunar.

## Что внутри

- **Hyprland**: `hyprland.lua` + `modules/` — стеклянный декор (blur, прозрачность,
  мягкие popin-анимации), отступы/рамки из палитры, автозапуск, правила окон.
  Никаких `.conf`.
- **Обои**: mpvpaper + wallust; `SUPER+SHIFT+W` переключает файлы по кругу,
  (mp4 / webm / mkv / mov / gif / png / jpg / jpeg / webp), выбор запоминается
  между запусками.
- **wallust**: кадр из обоев → палитра →
  - kitty (`~/.config/kitty/wallust.conf`)
  - zsh (цвета в `~/.config/zsh/wallust-colors.zsh`, промпт в `prompt.zsh`)
  - GTK/Thunar (`~/.config/gtk-3.0/gtk.css`)
  - рамки Hyprland (`~/.config/hypr/modules/colors.lua`)
- **Quickshell**: бар и лаунчер на QML, цвета из палитры wallust, `SUPER+R`.
  Дальше на нём же планируются OSD, уведомления и power menu.
- **Скриншоты**: `Print` — область, `SUPER+Print` — весь экран;
  файл в `~/Pictures/Screenshots/` + сразу в буфер.
- **Буфер обмена**: cliphist, watcher'ы текста и картинок в автозапуске.
- **zsh**: промпт на палитре обоев, автоподсказки из истории, подсветка
  синтаксиса и расширенные Tab-дополнения.
- **Thunar**: тёмная Adwaita + цвета из обоев.

Скриншот для README положи в `assets/screenshot.png` и раскомментируй строку:

<!-- ![скриншот](assets/screenshot.png) -->

## Зависимости

Из репозиториев (Arch):

```
sudo pacman -S hyprland kitty mpv ffmpeg python wl-clipboard cliphist \
    thunar gvfs tumbler grim slurp quickshell
```

Из AUR: `mpvpaper`, `wallust`.

Опционально:

- `brightnessctl` — клавиши яркости
- `playerctl` — мультимедиа-клавиши
- `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` — порталы
  (файловые диалоги, шаринг экрана, скриншоты в браузерах)

## Установка

```bash
git clone <адрес-репы> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` делает по одному симлинку на файл в `$HOME`, живые файлы не затирает
(уводит в `*.bak.<дата>`), выдаёт `+x` скриптам, ставит zsh-плагины
автодополнения и проверяет зависимости.
Генерируемые файлы (`colors.lua`, `gtk.css`, `wallust.conf`, `wallust-colors.zsh`)
не линкуются — их создаёт wallust.

Дополнительно:

```bash
# zsh: подключить цвета и промпт
echo '[[ -r "$HOME/.config/zsh/wallust.zsh" ]] && source "$HOME/.config/zsh/wallust.zsh"' >> ~/.zshrc

# zsh: плагины автодополнения (install.sh клонирует их сам)
# в ~/.zshrc: plugins=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting)

# Thunar как файловый менеджер по умолчанию для папок
xdg-mime default thunar.desktop inode/directory
```

## Обои и цвета

- Кидай файлы в `~/Pictures/Wallpapers` (или `~/Videos`).
- `SUPER+SHIFT+W` — следующий файл по имени, по кругу; выбранный файл
  запоминается в `~/.cache/wal-set/last`, после перезагрузки остаются те же обои.
- Режимы вручную: `wal-set.sh --next` (по очереди), `--random` (случайный),
  `--last` (последний, по умолчанию), `--newest` (самый свежий).
- Промпт zsh собирается из палитры перед каждой командой: путь, git-ветка
  и код ошибки последней команды.
- Переопределения: `WALLPAPER_FILE=/путь/файл` (конкретный файл),
  `WALLPAPER_DIR=/путь/папка` (другая папка).
- Настройки палитры: `~/.config/wallust/wallust.toml`, шаблоны в `templates/`.
- Цвета рамок генерируются в `modules/colors.lua`; если файла нет —
  `settings.lua` использует дефолтный градиент.

## Стекло

Внешний вид стеклянных панелей Quickshell (лаунчер и бар; дальше — OSD,
уведомления, power menu) настраивается в одном файле:
`quickshell/.config/quickshell/GlassConfig.qml`.

- `radius`, `borderWidth` — скругление и толщина рамки;
- `glassAlpha`, `topAlpha`, `bodyAlpha`, `baseAlpha` — прозрачность заливки;
- `specular`, `borderAlpha`, `accentAlpha` — блик, рамка и подмес цвета обоев;
- `shadowOpacity`, `shadowBlur`, `shadowOffset` — тень под плитой;
- `blurEnabled`, `blurRadius` — размытие фона под плитой;
- `barHeight`, `barMargin`, `barRadius`, `barAlpha` — размеры и заливка бара.

Размытие рисует Hyprland по протоколу `ext-background-effect-v1`: QML отдаёт
композитору точный `Region`, поэтому размытие обрезано по силуэту плиты и не
выходит за края. Сила размытия — на стороне композитора, в
`modules/settings.lua`: `decoration:blur:size`, `passes`, `vibrancy`.

Применение: QML — `qs kill && qs -n -d`, Hyprland — `hyprctl reload`.

## Бар

Верхний бар — одна стеклянная полоса на всю ширину: `PanelWindow` в слое
`Top` с namespace `quickshell-bar`. Отступ сверху 8 px, по бокам 10 px,
высота 40 px; сверху резервируется 48 px, поэтому окна не заезжают под бар.

Слева воркспейсы 1–10, в центре часы с датой, справа раскладка us/ru,
громкость, сеть, трей, загрузка CPU и памяти.

- воркспейсы: клик — переход, колесо — соседний воркспейс;
- раскладка: клик — следующая (`hyprctl switchxkblayout active next`);
- громкость: клик — mute, колесо — ±2%;
- трей: ЛКМ — активация, СКМ — вторичное действие, ПКМ — меню приложения.

## Клавиши

| Клавиши | Действие |
| --- | --- |
| `SUPER+Return`, `SUPER+Q` | kitty |
| `SUPER+E` | Thunar |
| `SUPER+R` | лаунчер Quickshell |
| `SUPER+M` | выход из Hyprland (позже — power menu Quickshell) |
| `SUPER+C` | закрыть окно |
| `SUPER+V` | плавающее окно |
| `SUPER+SPACE` | все окна воркспейса: плавающий режим / тайлинг |
| `SUPER+P` | pseudo-tile |
| `SUPER+J` | togglesplit |
| `SUPER+F` | fullscreen |
| `SUPER+стрелки` | фокус |
| `SUPER+1..0`, `SUPER+SHIFT+1..0` | workspace / перенести окно |
| `SUPER+S`, `SUPER+SHIFT+S` | scratchpad `magic` |
| `SUPER+ЛКМ` / `SUPER+ПКМ` | тащить / ресайзить окно |
| `SUPER+колесо` | соседний workspace |
| `Print` | скриншот области (в файл и буфер) |
| `SUPER+Print` | скриншот всего экрана |
| `SUPER+SHIFT+W` | следующие обои по очереди (и палитра) |
| `XF86Audio*` | громкость (wpctl), mic mute, playerctl |
| `XF86MonBrightness*` | яркость (brightnessctl) |

Раскладки: `us,ru`, переключение штатным `Alt+Shift` (`grp:alt_shift_toggle`).
Аудиовыход за раскладкой не следует — это убрано специально.

## Структура

```
hypr/.config/hypr/        конфиг Hyprland (hyprland.lua + modules/)
kitty/.config/kitty/      kitty.conf (include wallust-цветов)
wallust/.config/wallust/  wallust.toml + templates/ (kitty, zsh, gtk, hypr, quickshell)
gtk/.config/gtk-3.0/      settings.ini (gtk.css генерируется)
zsh/.config/zsh/          wallust.zsh — подключение цветов + precmd
quickshell/.config/quickshell/  shell.qml, GlassConfig.qml + launcher/, bar/ (QML)
scripts/.local/bin/       wal-set.sh, layout-toggle.sh, screenshot.sh, clipboard-watch.sh
assets/                   скриншоты для README
```

## Заметки

- В Hyprland 0.56 `ecosystem.enforce_permissions` ломает grim: запрос screencopy
  ждёт диалог подтверждения, и grim виснет (даже с `allow`-правилом в конфиге).
  Поэтому система прав в `modules/permissions.lua` выключена. Если включишь —
  проверь, что скриншоты живы.
- Права/`hl.permission` применяются только при рестарте Hyprland, не на `hyprctl reload`.
- Мониторы: пустое правило `output = ""` (preferred/auto) — подойдёт большинству;
  для мультимонитора правь `modules/monitors.lua`.
- Конфиг Hyprland пишется только на Lua (Hyprland 0.55+). Для старых версий не подойдёт.

## Лицензия

MIT — см. [LICENSE](LICENSE).
