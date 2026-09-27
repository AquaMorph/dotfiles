import Quickshell

ShellRoot {
    HardwareService {
        id: hardwareService
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            visible: !Quickshell.env("QUICKSHELL_BAR_SCREEN")
                || modelData.name === Quickshell.env("QUICKSHELL_BAR_SCREEN")
            hardware: hardwareService
        }
    }
}
