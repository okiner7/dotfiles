#!/usr/bin/env bash
# SUPER+SPACE: все окна активного воркспейса — плавающие / обратно в тайлинг.
# JSON парсим через python3, чтобы не зависеть от jq.
set -u

notify() {
    hyprctl notify -1 1500 "rgb(5E6F83)" "$1" >/dev/null 2>&1 || true
}

# togglefloating для окна по адресу (hyprctl dispatch в 0.56 ждёт Lua-выражение).
toggle_float() {
    hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\", window = \"address:$1\" })" \
        >/dev/null 2>&1 || true
}

active=$(hyprctl -j activeworkspace 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' 2>/dev/null) || exit 1
[[ -n "${active:-}" ]] || exit 1

# Строки "floating address" для окон активного воркспейса.
mapfile -t clients < <(hyprctl -j clients 2>/dev/null | python3 -c '
import json, sys
ws = int(sys.argv[1])
for c in json.load(sys.stdin):
    if c.get("workspace", {}).get("id") == ws:
        print(("1" if c.get("floating") else "0") + " " + c["address"])
' "$active" 2>/dev/null)

if ((${#clients[@]} == 0)); then
    notify "Нет окон на воркспейсе"
    exit 0
fi

# Если есть хоть одно тайловое окно — включаем плавающий режим,
# иначе (все уже плавают) — возвращаем в тайлинг.
tiled=0
for c in "${clients[@]}"; do
    [[ "${c%% *}" == "0" ]] && tiled=1
done

if ((tiled)); then
    for c in "${clients[@]}"; do
        [[ "${c%% *}" == "0" ]] || continue
        toggle_float "${c#* }"
    done
    notify "Плавающий режим"
else
    for c in "${clients[@]}"; do
        toggle_float "${c#* }"
    done
    notify "Тайлинг"
fi
