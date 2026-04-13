#Requires AutoHotkey v2.0
#SingleInstance Force
A_MaxHotkeysPerInterval := 200 ; Evitar error de "71 hotkeys"

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
global lastSmartResponse := 0
global isRoboTyping := false
global lastGuardianAction := 0
global smartConfig := {
    enabled: false,
    stopFile: "",
    triggerFile: "",
    text: "",
    cooldown: 5000,
    variation: 70
}

global guardianConfig := {
    enabled: false,
    compactFile: "",
    recoveryFile: "",
    compactPromptFile: "",
    recoveryPromptFile: "",
    listoFile: "",
    allowFile: "",
    cooldown: 30000
}

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
    global lastKeyPress, isRoboTyping
    if isRoboTyping
        return
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
    
    ; Cargar SmartResponse
    smartConfig.enabled := IniRead(CONFIG_FILE, "SmartResponse", "Enabled", "false") = "true"
    if smartConfig.enabled {
        smartConfig.stopFile := IMAGES_DIR IniRead(CONFIG_FILE, "SmartResponse", "StopFile", "stop.png")
        smartConfig.triggerFile := IMAGES_DIR IniRead(CONFIG_FILE, "SmartResponse", "TriggerFile", "ask_question.png")
        smartConfig.text := IniRead(CONFIG_FILE, "SmartResponse", "Text", "Si, continua")
        smartConfig.cooldown := Integer(IniRead(CONFIG_FILE, "SmartResponse", "Cooldown", "5000"))
        smartConfig.variation := Integer(IniRead(CONFIG_FILE, "SmartResponse", "ImageVariation", "70"))
    }
    
    ; Cargar ContextGuardian
    guardianConfig.enabled := IniRead(CONFIG_FILE, "ContextGuardian", "Enabled", "false") = "true"
    if guardianConfig.enabled {
        guardianConfig.compactFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "CompactFile", "compact.png")
        guardianConfig.recoveryFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "RecoveryFile", "too_much_content.png")
        guardianConfig.compactPromptFile := A_ScriptDir "\" IniRead(CONFIG_FILE, "ContextGuardian", "CompactPromptFile", "prompts\compaction.txt")
        guardianConfig.recoveryPromptFile := A_ScriptDir "\" IniRead(CONFIG_FILE, "ContextGuardian", "RecoveryPromptFile", "prompts\recovery.txt")
        guardianConfig.listoFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "ListoFile", "listo.png")
        guardianConfig.allowFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "AllowFile", "allow.png")
        guardianConfig.cooldown := Integer(IniRead(CONFIG_FILE, "ContextGuardian", "Cooldown", "30000"))
    }
}

; Iniciar monitoreo con intervalo optimizado
; Usar el intervalo más corto de botones activos, mínimo 50ms para evitar sobrecarga
minInterval := defaults.interval
for btn in buttons {
    if btn.enabled && btn.interval < minInterval
        minInterval := btn.interval
}
; Limitar a mínimo 50ms para evitar uso excesivo de CPU
if minInterval < 50
    minInterval := 50
SetTimer(DetectAndApprove, minInterval)

TrayTip("ButtonBot", "✓ Activo | " defaults.reloadHotkey ": Reload | " defaults.configHotkey ": Config | Ctrl+Alt+Shift+P: Pausar", 4)

; Función principal de detección (OPTIMIZADA + HANDLE VALIDATION)
DetectAndApprove() {
    global buttons, lastKeyPress, lastSmartResponse, lastGuardianAction, smartConfig, guardianConfig
    
    if !WinActive("ahk_exe Code.exe") && !WinActive("ahk_exe antigravity.exe")
        return
    
    currentTime := A_TickCount
    
    ; Capturar handle y validar existencia
    try {
        hwnd := WinGetID("A")
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
    } catch {
        return  ; Ventana no válida
    }
    
    ; --- KILL-SWITCH GLOBAL (CAPSLOCK) ---
    if GetKeyState("CapsLock", "T") == 1
        return
    
    ; --- INICIO LÓGICA SMART RESPONSE ---
    if smartConfig.enabled {
        if (currentTime - lastSmartResponse > smartConfig.cooldown) {
            try {
                ; 1. ¿Está la IA trabajando? (Buscamos solo en los últimos 250px para máxima velocidad)
                searchY := (winY + winH) - 250
                if searchY < winY
                    searchY := winY
                
                if !ImageSearch(&sX, &sY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.stopFile) {
                    
                    ; 2. ¿Está el campo listo para escribir?
                    if ImageSearch(&tX, &tY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.triggerFile) {
                        lastSmartResponse := currentTime
                        global isRoboTyping := true
                        Click(tX + 20, tY + 10)
                        Sleep(300)
                        Send(smartConfig.text "{Enter}")
                        global isRoboTyping := false
                        
                        TrayTip("ButtonBot", "⚡ SmartResponse: " smartConfig.text, 1)
                        return
                    } else {
                        ; Opcional: Descomentar para ver si llega aquí pero no encuentra el placeholder
                        ; TrayTip("ButtonBot", "Esperando placeholder...", 1)
                    }
                }
            } catch {
                ; Error en búsqueda
            }
        }
    }
    ; --- INICIO LÓGICA CONTEXT GUARDIAN ---
    if guardianConfig.enabled && (currentTime - lastGuardianAction > guardianConfig.cooldown) {
        ; 1. ¿Aviso de compactación? (Buscamos en ventana completa porque puede salir en cualquier lado)
        if ImageSearch(&cX, &cY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.compactFile) {
            if FileExist(guardianConfig.compactPromptFile) {
                lastGuardianAction := currentTime
                prompt := FileRead(guardianConfig.compactPromptFile)
                
                ; Enfocar campo y enviar
                searchY := (winY + winH) - 250
                if searchY < winY
                    searchY := winY
                
                if ImageSearch(&tX, &tY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.triggerFile) {
                    global isRoboTyping := true
                    Click(tX + 20, tY + 10)
                    Sleep(300)
                    A_Clipboard := prompt
                    Send("^v{Enter}")
                    global isRoboTyping := false
                    TrayTip("ButtonBot", "💾 Context Guardian: Enviando Volcado de Memoria", 1)
                    return
                }
            }
        }
        
        ; 2. ¿Error de contexto lleno?
        if ImageSearch(&rX, &rY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.recoveryFile) {
            if FileExist(guardianConfig.recoveryPromptFile) {
                lastGuardianAction := currentTime
                prompt := FileRead(guardianConfig.recoveryPromptFile)
                
                ; Enfocar campo y enviar
                searchY := (winY + winH) - 250
                if searchY < winY
                    searchY := winY
                
                if ImageSearch(&tX, &tY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.triggerFile) {
                    global isRoboTyping := true
                    Click(tX + 20, tY + 10)
                    Sleep(300)
                    A_Clipboard := prompt
                    Send("^v{Enter}")
                    global isRoboTyping := false
                    TrayTip("ButtonBot", "🔄 Context Guardian: Restaurando Contexto", 1)
                    return
                }
            }
        }

        ; 3. ¿La IA dijo 'LISTO' y se ve el botón 'ALLOW'? (Auto-compactación)
        if ImageSearch(&lX, &lY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.listoFile) {
            if ImageSearch(&aX, &aY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.allowFile) {
                lastGuardianAction := currentTime
                Click(aX + 20, aY + 10)
                TrayTip("ButtonBot", "✅ Context Guardian: Compactación Permitida automáticamente", 1)
                return
            }
        }
    }
    ; --- FIN LÓGICA CONTEXT GUARDIAN ---
    
    ; Procesar cada botón configurado
    for btn in buttons {
        if !btn.enabled
            continue
        
        ; Verificar cooldown primero (más rápido que ImageSearch)
        if (currentTime - btn.lastDetection < btn.detectionCooldown)
            continue
        
        ; Verificar si el usuario está escribiendo
        if (currentTime - lastKeyPress < btn.keyPressDelay)
            continue
        
        ; Validar handle antes de ImageSearch
        try {
            if !WinExist("ahk_id " hwnd)
                return
            
            ; Buscar el botón (operación costosa)
            if ImageSearch(&foundX, &foundY, winX, winY, winX + winW, winY + winH, "*" btn.imageVariation " " btn.file) {
                ; Ejecutar acción según configuración (OPTIMIZADO)
                if btn.action = "click" {
                    Click(foundX + 10, foundY + 10)
                } else if btn.action = "hotkey" && btn.HasOwnProp("hotkey") {
                    Send(btn.hotkey)
                }
                
                btn.lastDetection := currentTime
                return  ; CRITICAL: Early-exit al encontrar botón
            }
        } catch {
            return  ; Handle inválido durante ImageSearch
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
    2. Selecciona SOLO el botón o un trozo de texto único
    3. Guarda como: nombre.png
    4. Coloca el archivo en: " IMAGES_DIR "
    
    El script detectará la imagen en cualquier posición.
    )", "Instrucciones de Captura")
}

; Prueba de detección Ctrl+Alt+Shift+T (COMPLETA - Compatible con Bloq Mayús)
*^!+t:: {
    global smartConfig, buttons, guardianConfig
    
    hwnd := WinExist("A")
    if !hwnd {
        TrayTip("ButtonBot", "Error: No hay una ventana activa", 1)
        return
    }

    try {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
        
        startTime := A_TickCount
        searchY := (winY + winH) - 250
        if searchY < winY
            searchY := winY
        
        ; 1. SmartResponse Results
        foundStop := ImageSearch(&sX, &sY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.stopFile)
        foundTrigger := ImageSearch(&tX, &tY, winX, searchY, winX + winW, winY + winH, "*" smartConfig.variation " " smartConfig.triggerFile)
        
        foundCompact := ImageSearch(&cX, &cY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.compactFile)
        foundRecovery := ImageSearch(&rX, &rY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.recoveryFile)
        foundListo := ImageSearch(&lX, &lY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.listoFile)
        foundAllow := ImageSearch(&aX, &aY, winX, winY, winX + winW, winY + winH, "*" defaults.imageVariation " " guardianConfig.allowFile)

        capsStatus := GetKeyState("CapsLock", "T") ? "🔴 ACTIVADO (Bot Pausado)" : "🟢 DESACTIVADO (Bot Operativo)"
        
        msg := "ESTADO GLOBAL:`n"
             . "CapsLock: " capsStatus "`n`n"
             . "--- SMART RESPONSE ---`n"
             . "Stop (Trabajando): " (foundStop ? "❌" : "✅") "`n"
             . "Ask (Listo): " (foundTrigger ? "✅" : "❌") "`n`n"
             . "--- CONTEXT GUARDIAN ---`n"
             . "Compact Warning: " (foundCompact ? "✅" : "❌") "`n"
             . "Recovery Error: " (foundRecovery ? "✅" : "❌") "`n"
             . "IA Confirm (Listo): " (foundListo ? "✅" : "❌") "`n"
             . "Allow Button: " (foundAllow ? "✅" : "❌") "`n`n"
             . "--- BOTONES ACTIVOS ---`n"
        
        ; 2. Botones del Config
        for btn in buttons {
            if !btn.enabled
                continue
            
            ; Intentar buscar en ventana completa para botones generales
            name := StrSplit(btn.file, ["\", "/"]).Pop()
            found := ImageSearch(&fX, &fY, winX, winY, winX + winW, winY + winH, "*" btn.imageVariation " " btn.file)
            msg .= name ": " (found ? "✅" : "❌") "`n"
        }
        
        elapsed := A_TickCount - startTime
        msg .= "`nTiempo: " elapsed " ms | Var: " smartConfig.variation
             
        TrayTip(msg, "ButtonBot Diagnóstico Extra", 4)
    } catch {
        TrayTip("ButtonBot", "Error: Asegúrate de que la ventana esté activa", 1)
    }
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

; Pausar/Reanudar Ctrl+Alt+Shift+P
^!+p:: {
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
