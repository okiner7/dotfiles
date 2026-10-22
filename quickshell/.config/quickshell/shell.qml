//@ pragma IconTheme Adwaita

import Quickshell
import Quickshell.Io
import "bar"
import "launcher"

// Корневой конфиг Quickshell: бар и лаунчер.
ShellRoot {
    Theme {
        id: theme
    }

    Bar {
        id: bar
        theme: theme
    }

    Launcher {
        id: launcher
        theme: theme
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcher.toggle()
        }

        function open(): void {
            launcher.open()
        }

        function close(): void {
            launcher.close()
        }
    }
}
