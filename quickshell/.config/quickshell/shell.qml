import Quickshell
import Quickshell.Io
import "launcher"

// Корневой конфиг Quickshell: пока только лаунчер.
ShellRoot {
    Theme {
        id: theme
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
