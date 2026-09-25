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
            hardware: hardwareService
        }
    }
}
