# dotfiles — Hyprland Lua rice

Компактный rice для Hyprland 0.55+ (проверено на 0.56.2): модульный Lua-конфиг,
видео-обои через mpvpaper, динамическая палитра из обоев через wallust
(kitty / zsh / Thunar / рамки Hyprland), cliphist, скриншоты grim+slurp, Thunar.

## Что внутри

- **Hyprland**: `hyprland.lua` + `modules/` — отступы/рамки, быстрые popin-анимации,
  автозапуск, правила окон. Никаких `.conf`.
- **Обои**: mpvpaper берёт самый свежий файл из `~/Pictures/Wallpapers`
  (mp4 / webm / mkv / mov / gif / png / jpg / webp; при равном mtime приоритет у видео).
- **wallust**: кадр из обоев → палитра →
  - kitty (`~/.config/kitty/wallust.conf`)
  - zsh (`~/.config/zsh/wallust-colors.zsh` + precmd-хук)
  - GTK/Thunar (`~/.config/gtk-3.0/gtk.css`)
  - рамки Hyprland (`~/.config/hypr/modules/colors.lua`)
- **Скриншоты**: `Print` — область, `SUPER+Print` — весь экран;
  файл в `~/Pictures/Screenshots/` + сразу в буфер.
- **Буфер обмена**: cliphist, watcher'ы текста и картинок в автозапуске.
- **Thunar**: тёмная Adwaita + цвета из обоев.

Скриншот для README положи в `assets/screenshot.png` и раскомментируй строку:

<!-- ![скриншот](assets/screenshot.png) -->

## Зависимости

Из репозиториев (Arch):

```
sudo pacman -S hyprland kitty mpv ffmpeg python wl-clipboard cliphist \
    thunar gvfs tumbler grim slurp
```

Из AUR: `mpvpaper`, `wallust`.

Опционально:

- `hyprshutdown` — меню завершения по `SUPER+M` (без него просто выходит из Hyprland)
- `hyprlauncher` — лаунчер по `SUPER+R`
- `brightnessctl` — клавиши яркости
- `playerctl` — мультимедиа-клавиши
- `xdg-desktop-portal-hyprland` — порталы (скриншоты в браузерах и т.п.)

## Установка

```bash
git clone <адрес-репы> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` делает по одному симлинку на файл в `$HOME`, живые файлы не затирает
(уводит в `*.bak.<дата>`), выдаёт `+x` скриптам и проверяет зависимости.
Генерируемые файлы (`colors.lua`, `gtk.css`, `wallust.conf`, `wallust-colors.zsh`)
не линкуются — их создаёт wallust.

Дополнительно:

```bash
# zsh: подключить цвета
echo '[[ -r "$HOME/.config/zsh/wallust.zsh" ]] && source "$HOME/.config/zsh/wallust.zsh"' >> ~/.zshrc

# Thunar как файловый менеджер по умолчанию для папок
xdg-mime default thunar.desktop inode/directory
```

## Обои и цвета

- Кидай файлы в `~/Pictures/Wallpapers` — перезапуск `wal-set.sh` подхватит самый свежий.
- Переопределения: `WALLPAPER_FILE=/путь/файл` (конкретный файл),
  `WALLPAPER_DIR=/путь/папка` (другая папка).
- Обновить вручную: `SUPER+SHIFT+W` (или `~/.local/bin/wal-set.sh`).
- Настройки палитры: `~/.config/wallust/wallust.toml`, шаблоны в `templates/`.
- Цвета рамок генерируются в `modules/colors.lua`; если файла нет —
  `settings.lua` использует дефолтный градиент.

## Клавиши

| Клавиши | Действие |
| --- | --- |
| `SUPER+Return`, `SUPER+Q` | kitty |
| `SUPER+E` | Thunar |
| `SUPER+R` | hyprlauncher (опционально) |
| `SUPER+M` | завершение сессии (hyprshutdown / hyprctl exit) |
| `SUPER+C` | закрыть окно |
| `SUPER+V` | плавающее окно |
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
| `SUPER+SHIFT+W` | обновить обои и палитру |
| `XF86Audio*` | громкость (wpctl), mic mute, playerctl |
| `XF86MonBrightness*` | яркость (brightnessctl) |

Раскладки: `us,ru`, переключение штатным `Alt+Shift` (`grp:alt_shift_toggle`).
Аудиовыход за раскладкой не следует — это убрано специально.

## Структура

```
hypr/.config/hypr/        конфиг Hyprland (hyprland.lua + modules/)
kitty/.config/kitty/      kitty.conf (include wallust-цветов)
wallust/.config/wallust/  wallust.toml + templates/ (kitty, zsh, gtk, hypr colors)
gtk/.config/gtk-3.0/      settings.ini (gtk.css генерируется)
zsh/.config/zsh/          wallust.zsh — подключение цветов + precmd
scripts/.local/bin/       wal-set.sh, screenshot.sh, clipboard-watch.sh
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
