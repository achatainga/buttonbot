#Requires AutoHotkey v2.0
#SingleInstance Force

; Rutas portables
global CONFIG_FILE := A_ScriptDir "\config\config.ini"
global IMAGES_DIR := A_ScriptDir "\images\"
global RESTART_FLAG := A_ScriptDir "\restart.flag"

; Configuración global
global defaults := {
    interval: 200,
    keyPressDelay: 4000,
    detectionCooldown: 2000,
    imageVariation: 50
}

global buttons := []
global lastKeyPress := 0

; Detectar cuando el usuario escribe
~*a::
~*b::
~*c::
~*d::
~*e::
~*f::
~*g::
~*h::
~*i::
~*j::
~*k::
~*l::
~*m::
~*n::
~*o::
~*p::
~*q::
~*r::
~*s::
~*t::
~*u::
~*v::
~*w::
~*x::
~*y::
~*z::
~Space::
~Enter::
~Backspace:: {
    global lastKeyPress
    lastKeyPress := A_TickCount
}

; Verificar si hay flag de restart
if FileExist(RESTART_FLAG) {
    FileDelete(RESTART_FLAG)
    Sleep(1000)
}

; Cargar configuración
LoadConfig()
SetupReloadHotkey()

LoadConfig() {
    global defaults, buttons, CONFIG_FILE, IMAGES_DIR
    
    if !FileExist(CONFIG_FILE)
        return
    
    ; Cargar defaults
    defaults.interval := IniRead(CONFIG_FILE, "Defaults", "Interval", 200)
    defaults.keyPressDelay := IniRead(CONFIG_FILE, "Defaults", "KeyPressDelay", 4000)
    defaults.detectionCooldown := IniRead(CONFIG_FILE, "Defaults", "DetectionCooldown", 2000)
    defaults.imageVariation := IniRead(CONFIG_FILE, "Defaults", "ImageVariation", 50)
    defaults.reloadHotkey := IniRead(CONFIG_FILE, "Defaults", "ReloadHotkey", "^!+r")
    defaults.configHotkey := IniRead(CONFIG_FILE, "Defaults", "ConfigHotkey", "^!+c")
    
    ; Cargar botones
    buttons := []
    index := 1
    Loop {
        section := "Button" index
        file := IniRead(CONFIG_FILE, section, "File", "")
        if file = ""
            break
        
        btn := {
            file: IMAGES_DIR file,
            action: IniRead(CONFIG_FILE, section, "Action", "click"),
            enabled: IniRead(CONFIG_FILE, section, "Enabled", "true") = "true",
            lastDetection: 0
        }
        
        hotkey := IniRead(CONFIG_FILE, section, "Hotkey", "")
        if hotkey != ""
            btn.hotkey := hotkey
        
        interval := IniRead(CONFIG_FILE, section, "Interval", "")
        btn.interval := (interval != "") ? Integer(interval) : defaults.interval
        
        keyDelay := IniRead(CONFIG_FILE, section, "KeyPressDelay", "")
        btn.keyPressDelay := (keyDelay != "") ? Integer(keyDelay) : defaults.keyPressDelay
        
        cooldown := IniRead(CONFIG_FILE, section, "DetectionCooldown", "")
        btn.detectionCooldown := (cooldown != "") ? Integer(cooldown) : defaults.detectionCooldown
        
        variation := IniRead(CONFIG_FILE, section, "ImageVariation", "")
        btn.imageVariation := (variation != "") ? Integer(variation) : defaults.imageVariation
        
        buttons.Push(btn)
        index++
    }
}

; Iniciar monitoreo con el intervalo más corto de todos los botones
minInterval := defaults.interval
for btn in buttons {
    if btn.enabled && btn.interval < minInterval
        minInterval := btn.interval
}
SetTimer(DetectAndApprove, minInterval)

TrayTip("ButtonBot", "✓ Activo | " defaults.reloadHotkey ": Reload | " defaults.configHotkey ": Config | Ctrl+Alt+P: Pausar", 4)

; Función principal de detección
DetectAndApprove() {
    global buttons, lastKeyPress
    
    if !WinActive("ahk_exe Code.exe")
        return
    
    WinGetPos(&winX, &winY, &winW, &winH, "A")
    
    ; Procesar cada botón configurado
    for btn in buttons {
        if !btn.enabled
            continue
        
        ; Verificar si el usuario está escribiendo (específico por botón)
        if (A_TickCount - lastKeyPress < btn.keyPressDelay)
            continue
        
        ; Verificar cooldown (específico por botón)
        if (A_TickCount - btn.lastDetection < btn.detectionCooldown)
            continue
        
        ; Buscar el botón
        if ImageSearch(&foundX, &foundY, winX, winY, winX + winW, winY + winH, "*" btn.imageVariation " " btn.file) {
            ; Ejecutar acción según configuración
            if btn.action = "click" {
                MouseGetPos(&originalX, &originalY)
                Click(foundX + 10, foundY + 10)
                MouseMove(originalX, originalY, 0)
            } else if btn.action = "hotkey" && btn.HasOwnProp("hotkey") {
                focusedControl := ControlGetFocus("A")
                SendInput(btn.hotkey)
                if focusedControl
                    ControlFocus(focusedControl, "A")
            }
            
            btn.lastDetection := A_TickCount
            return
        }
    }
}

; Capturar imagen del botón Run
^!i:: {
    global IMAGES_DIR
    MsgBox("
    (Join`n
    CAPTURAR BOTÓN:
    
    1. Presiona Win+Shift+S
    2. Selecciona SOLO el botón
    3. Guarda como: nombre.png
    4. Coloca el archivo en: " IMAGES_DIR "
    
    El script detectará el botón en cualquier posición.
    )", "Instrucciones de Captura")
}

; Configurar hotkeys dinámicos
SetupReloadHotkey() {
    global defaults
    
    try {
        Hotkey(defaults.reloadHotkey, ReloadScript)
    } catch {
        Hotkey("^!+r", ReloadScript)
    }
    
    try {
        Hotkey(defaults.configHotkey, OpenConfig)
    } catch {
        Hotkey("^!+c", OpenConfig)
    }
}

ReloadScript(*) {
    Reload()
}

OpenConfig(*) {
    Run(A_ScriptDir "\ButtonBotConfig.ahk")
}

; Pausar/Reanudar
^!p:: {
    global buttons
    allDisabled := true
    for btn in buttons {
        if btn.enabled {
            allDisabled := false
            break
        }
    }
    
    for btn in buttons
        btn.enabled := allDisabled
    
    TrayTip("ButtonBot", allDisabled ? "✓ Activado" : "⏸ Pausado", 1)
}

; Salir
^!q:: {
    TrayTip("ButtonBot", "Cerrando...", 1)
    Sleep(500)
    ExitApp()
}
