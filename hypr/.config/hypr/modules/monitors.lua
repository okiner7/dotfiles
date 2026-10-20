-- Мониторы.
-- Пустой output = правило для всех найденных мониторов.
-- Режим preferred и position auto подходят для одного HDMI-A-2.
-- Если добавишь второй монитор, задай для него отдельный hl.monitor(...).

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
