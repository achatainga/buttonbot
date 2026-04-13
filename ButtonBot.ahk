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
global guardianCycles := 0 ; Contador de ciclos para optimización
global smartConfig := {
    enabled: false,
    stopFile: "",
    triggerFile: "",
    text: "",
    cooldown: 5000,
    variation: 30
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
        guardianConfig.recoveryFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "RecoveryFile", "context.png")
        guardianConfig.compactPromptFile := A_ScriptDir "\" IniRead(CONFIG_FILE, "ContextGuardian", "CompactPromptFile", "prompts\compaction.txt")
        guardianConfig.recoveryPromptFile := A_ScriptDir "\" IniRead(CONFIG_FILE, "ContextGuardian", "RecoveryPromptFile", "prompts\recovery.txt")
        guardianConfig.enterFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "EnterFile", "enter.png")
        guardianConfig.listoFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "ListoFile", "listo.png")
        guardianConfig.allowFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "AllowFile", "allow.png")
        guardianConfig.arrowFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "ArrowFile", "arrow.png")
        guardianConfig.finishedFile := IMAGES_DIR IniRead(CONFIG_FILE, "ContextGuardian", "FinishedFile", "compact_finished.png")
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
    
    ; Asegurar coordenadas relativas a la ventana INMEDIATAMENTE
    CoordMode("Pixel", "Window")
    CoordMode("Mouse", "Window")
    
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
    
    ; --- INICIO LÓGICA CONTEXT GUARDIAN (OPTIMIZADO: Escaneo cada 3 ciclos ~1s) ---
    global guardianCycles := guardianCycles + 1
    
    if guardianConfig.enabled && (Mod(guardianCycles, 3) == 0) && (currentTime - lastGuardianAction > guardianConfig.cooldown) {
        searchW_chat := Integer(winW * 0.45)
        searchY_msgs := 0
        searchY_btns := Integer(winH * 0.65)
        
        ; 1. ¿IA LISTA + BOTÓN ALLOW O ARROW? (Acción inmediata: click)
        if (guardianConfig.listoFile != "" && FileExist(guardianConfig.listoFile) && ImageSearch(&lX, &lY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.listoFile)) {
            ; Buscar Allow
            foundAllow := (guardianConfig.allowFile != "" && FileExist(guardianConfig.allowFile) && ImageSearch(&aX, &aY, 0, searchY_btns, searchW_chat, winH, "*70 " guardianConfig.allowFile))
            ; Buscar Arrow (Flecha abajo personalizada - Variación 100 para 4K)
            foundArrow := (guardianConfig.arrowFile != "" && FileExist(guardianConfig.arrowFile) && ImageSearch(&arX, &arY, 200, searchY_btns, 800, winH, "*100 " guardianConfig.arrowFile))
            
            if (foundAllow || foundArrow) {
                lastGuardianAction := currentTime
                targetX := foundAllow ? aX : arX
                targetY := foundAllow ? aY : arY
                Click(targetX + 20, targetY + 10)
                TrayTip("ButtonBot", "✅ Context Guardian: Botón de Avance clickeado", 1)
                return
            }
        }

        ; 2. ¿SOLO BOTÓN ARROW (Flecha abajo)?
        if (guardianConfig.arrowFile != "" && FileExist(guardianConfig.arrowFile) && ImageSearch(&arX, &arY, 200, searchY_btns, 800, winH, "*100 " guardianConfig.arrowFile)) {
            lastGuardianAction := currentTime
            Click(arX + 15, arY + 15)
            TrayTip("ButtonBot", "⬇️ Context Guardian: Click en Flecha Abajo", 1)
            return
        }

        ; 3. ¿COMPACTACIÓN TERMINADA O ERROR DE CONTEXTO? (Restaurar)
        isFinished := (guardianConfig.finishedFile != "" && FileExist(guardianConfig.finishedFile) && ImageSearch(&fX, &fY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.finishedFile))
        isError := (guardianConfig.recoveryFile != "" && FileExist(guardianConfig.recoveryFile) && ImageSearch(&rX, &rY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.recoveryFile))
        
        if (isFinished || isError) {
            if FileExist(guardianConfig.recoveryPromptFile) {
                lastGuardianAction := currentTime
                prompt := FileRead(guardianConfig.recoveryPromptFile)
                
                searchY_input_rel := winH - 600
                if searchY_input_rel < 0
                    searchY_input_rel := 0
                
                if ImageSearch(&tX, &tY, 0, searchY_input_rel, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.triggerFile) {
                    global isRoboTyping := true
                    Click(tX + 20, tY + 10)
                    Sleep(300)
                    A_Clipboard := prompt
                    Sleep(100) ; Dar tiempo al clipboard
                    SendEvent("^v")
                    Sleep(200) ; Pausa crucial
                    
                    ; Intentar hacer click en el botón de Enter si existe, si no, usar teclado
                    if (guardianConfig.enterFile != "" && FileExist(guardianConfig.enterFile) && ImageSearch(&eX, &eY, 0, searchY_btns, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.enterFile)) {
                        Click(eX + 10, eY + 10)
                    } else {
                        SendEvent("{Enter}")
                    }
                    global isRoboTyping := false
                    TrayTip("ButtonBot", isFinished ? "🔄 Context Guardian: Restaurando tras Compactación" : "🔄 Context Guardian: Restaurando tras Error", 1)
                    return
                }
            }
        }

        ; 3. ¿AVISO DE COMPACTACIÓN? (Si no estamos listos, enviar prompt)
        if (guardianConfig.compactFile != "" && FileExist(guardianConfig.compactFile) && ImageSearch(&cX, &cY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.compactFile)) {
            if FileExist(guardianConfig.compactPromptFile) {
                lastGuardianAction := currentTime
                prompt := FileRead(guardianConfig.compactPromptFile)
                
                searchY_input_rel := winH - 600
                if searchY_input_rel < 0
                    searchY_input_rel := 0
                
                if ImageSearch(&tX, &tY, 0, searchY_input_rel, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.triggerFile) {
                    global isRoboTyping := true
                    Click(tX + 20, tY + 10)
                    Sleep(300)
                    A_Clipboard := prompt
                    Sleep(100) ; Dar tiempo al clipboard
                    SendEvent("^v")
                    Sleep(200) ; Pausa crucial
                    
                    ; Intentar hacer click en el botón de Enter si existe, si no, usar teclado
                    if (guardianConfig.enterFile != "" && FileExist(guardianConfig.enterFile) && ImageSearch(&eX, &eY, 0, searchY_btns, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.enterFile)) {
                        Click(eX + 10, eY + 10)
                    } else {
                        SendEvent("{Enter}")
                    }
                    global isRoboTyping := false
                    TrayTip("ButtonBot", "💾 Context Guardian: Enviando Volcado de Memoria", 1)
                    return
                }
            }
        }

        ; --- LÓGICA SMART RESPONSE (Dentro del mismo ciclo para respetar prioridad) ---
        if smartConfig.enabled && (currentTime - lastSmartResponse > smartConfig.cooldown) {
            try {
                ; 1. ¿Está la IA trabajando?
                if (smartConfig.stopFile != "" && FileExist(smartConfig.stopFile) && !ImageSearch(&sX, &sY, 0, searchY_btns, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.stopFile)) {
                    
                    ; 2. ¿Está el campo listo para escribir?
                    searchY_input_rel := winH - 600
                    if searchY_input_rel < 0
                        searchY_input_rel := 0
                        
                    if (smartConfig.triggerFile != "" && FileExist(smartConfig.triggerFile) && ImageSearch(&tX, &tY, 0, searchY_input_rel, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.triggerFile)) {
                        lastSmartResponse := currentTime
                        global isRoboTyping := true
                        Click(tX + 20, tY + 10)
                        Sleep(300)
                        SendEvent(smartConfig.text)
                        Sleep(200)
                        
                        ; Usar botón físico si existe, si no, Enter
                        if (guardianConfig.enterFile != "" && FileExist(guardianConfig.enterFile) && ImageSearch(&eX, &eY, 0, searchY_btns, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.enterFile)) {
                            Click(eX + 10, eY + 10)
                        } else {
                            SendEvent("{Enter}")
                        }
                        global isRoboTyping := false
                        
                        TrayTip("ButtonBot", "⚡ SmartResponse: " smartConfig.text, 1)
                        return
                    }
                }
            } catch {
                ; Error en búsqueda
            }
        }
    }
    
        ; Procesar cada botón configurado (OPTIMIZADO: Escaneo cada 10 ciclos ~2s)
        if (Mod(guardianCycles, 10) != 0)
            return

        searchW_chat := (winW > 600) ? 600 : winW
        searchY_msgs := (winH > 1000) ? winH - 1000 : 0
        searchY_btns := (winH > 500) ? winH - 500 : 0
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
                
                ; Buscar el botón en la zona del chat (ahora ultra-rápido)
                if ImageSearch(&foundX, &foundY, 0, 0, searchW_chat, winH, "*" btn.imageVariation " " btn.file) {
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
    global smartConfig, buttons, guardianConfig, defaults
    
    ; Asegurar coherencia de coordenadas desde el inicio
    CoordMode("Pixel", "Window")
    CoordMode("Mouse", "Window")
    
    hwnd := WinExist("A")
    if !hwnd {
        TrayTip("ButtonBot", "Error: No hay una ventana activa", 1)
        return
    }

    try {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
        
        startTime := A_TickCount
        searchW_chat := Integer(winW * 0.45)
        searchY_msgs := 0
        searchY_btns := Integer(winH * 0.65)
        searchY_input_rel := winH - 600
        if searchY_input_rel < 0
            searchY_input_rel := 0
        
        ; 1. SmartResponse Results
        fileStop := StrSplit(smartConfig.stopFile, ["/", "\"]).Pop()
        fileTrig := StrSplit(smartConfig.triggerFile, ["/", "\"]).Pop()
        eStop := (smartConfig.stopFile != "" && FileExist(smartConfig.stopFile))
        eTrig := (smartConfig.triggerFile != "" && FileExist(smartConfig.triggerFile))
        fStop := eStop ? ImageSearch(&sX, &sY, 0, 0, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.stopFile) : 0
        fTrigger := eTrig ? ImageSearch(&tX, &tY, 0, searchY_input_rel, searchW_chat, winH, "*" smartConfig.variation " " smartConfig.triggerFile) : 0
        
        ; 2. Context Guardian Results
        fileComp := StrSplit(guardianConfig.compactFile, ["/", "\"]).Pop()
        fileRec := StrSplit(guardianConfig.recoveryFile, ["/", "\"]).Pop()
        fileListo := StrSplit(guardianConfig.listoFile, ["/", "\"]).Pop()
        fileAllow := StrSplit(guardianConfig.allowFile, ["/", "\"]).Pop()
        fileFin := StrSplit(guardianConfig.finishedFile, ["/", "\"]).Pop()
        fileArrow := StrSplit(guardianConfig.arrowFile, ["/", "\"]).Pop()
        fileEnter := StrSplit(guardianConfig.enterFile, ["/", "\"]).Pop()
        
        eCompact := (guardianConfig.compactFile != "" && FileExist(guardianConfig.compactFile))
        eRecovery := (guardianConfig.recoveryFile != "" && FileExist(guardianConfig.recoveryFile))
        eListo := (guardianConfig.listoFile != "" && FileExist(guardianConfig.listoFile))
        eAllow := (guardianConfig.allowFile != "" && FileExist(guardianConfig.allowFile))
        eFinished := (guardianConfig.finishedFile != "" && FileExist(guardianConfig.finishedFile))
        eArrow := (guardianConfig.arrowFile != "" && FileExist(guardianConfig.arrowFile))
        eEnter := (guardianConfig.enterFile != "" && FileExist(guardianConfig.enterFile))
        
        CoordMode("Pixel", "Window")
        fCompact := eCompact ? ImageSearch(&cX, &cY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.compactFile) : 0
        fRecovery := eRecovery ? ImageSearch(&rX, &rY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.recoveryFile) : 0
        fListo := eListo ? ImageSearch(&lX, &lY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.listoFile) : 0
        fAllow := eAllow ? ImageSearch(&aX, &aY, 0, searchY_btns, searchW_chat, winH, "*70 " guardianConfig.allowFile) : 0
        fArrow := eArrow ? ImageSearch(&arX, &arY, 200, searchY_btns, 800, winH, "*100 " guardianConfig.arrowFile) : 0
        fFinished := eFinished ? ImageSearch(&fX, &fY, 0, searchY_msgs, searchW_chat, winH, "*" defaults.imageVariation " " guardianConfig.finishedFile) : 0
        fEnter := eEnter ? ImageSearch(&enX, &enY, 0, searchY_btns, searchW_chat, winH, "*70 " guardianConfig.enterFile) : 0

        capsStatus := GetKeyState("CapsLock", "T") ? "🔴 ACTIVADO (Kill-switch)" : "🟢 DESACTIVADO"
        softStatus := smartConfig.enabled ? "🟢 ACTIVO" : "⏸ PAUSADO (Manual)"
        
        msg := "ESTADO DEL BOT:`n"
             . "Kill-switch (CapsLock): " capsStatus "`n"
             . "Estado Software (^!+P): " softStatus "`n`n"
             . "--- SMART RESPONSE ---`n"
             . "Stop (IA Trabajando) [" fileStop "]: " (eStop ? "📁 " : "📁❌ ") (fStop ? "🔍✅" : "🔍❌") "`n"
             . "Ask (Listo) [" fileTrig "]: " (eTrig ? "📁 " : "📁❌ ") (fTrigger ? "🔍✅" : "🔍❌") "`n`n"
             . "--- CONTEXT GUARDIAN ---`n"
             . "Compact Warning [" fileComp "]: " (eCompact ? "📁 " : "📁❌ ") (fCompact ? "🔍✅" : "🔍❌") "`n"
             . "IA Confirm (Listo) [" fileListo "]: " (eListo ? "📁 " : "📁❌ ") (fListo ? "🔍✅" : "🔍❌") "`n"
             . "Allow Button [" fileAllow "]: " (eAllow ? "📁 " : "📁❌ ") (fAllow ? "🔍✅" : "🔍❌") "`n"
             . "Arrow Button [" fileArrow "]: " (eArrow ? "📁 " : "📁❌ ") (fArrow ? "🔍✅" : "🔍❌") "`n"
             . "Enter Button [" fileEnter "]: " (eEnter ? "📁 " : "📁❌ ") (fEnter ? "🔍✅" : "🔍❌") "`n`n"
             . "--- BOTONES ACTIVOS ---`n"
        
        ; Calcular Próxima Acción (Siguiendo la nueva prioridad)
        nextAction := "Ninguna (Esperando)"
        if (fArrow) {
            nextAction := "⬇️ CLICK ARROW (Avanzar Chat)"
        } else if (fListo && fAllow) {
            nextAction := "✅ CLICK ALLOW (Permitir Compactación)"
        } else if (fFinished || fRecovery) {
            if (fTrigger)
                nextAction := "🔄 ENVIAR RECOVERY (Restaurar Contexto)"
            else
                nextAction := "⏳ ESPERANDO INPUT PARA RECOVERY"
        } else if (fCompact) {
            if (fTrigger)
                nextAction := "💾 ENVIAR COMPACTION (Volcado de Memoria)"
            else
                nextAction := "⏳ ESPERANDO INPUT PARA COMPACTION"
        } else if (!fStop && fTrigger) {
            nextAction := "⚡ SMART RESPONSE (Continuar)"
        }
        
        ; 2. Botones del Config (También en el 40% izquierdo)
        for btn in buttons {
            if !btn.enabled
                continue
            
            name := StrSplit(btn.file, ["\", "/"]).Pop()
            found := ImageSearch(&fX, &fY, 0, 0, searchW_chat, winH, "*" btn.imageVariation " " btn.file)
            msg .= name ": " (found ? "✅" : "❌") "`n"
        }
        
        elapsed := A_TickCount - startTime
        msg .= "`nPROXIMA ACCION: " nextAction
        msg .= "`nTiempo: " elapsed " ms | Var: " smartConfig.variation
             
        ToolTip(msg)
        SetTimer(() => ToolTip(), -6000) ; Quitar en 6 segundos
    } catch Error as err {
        TrayTip("ButtonBot", "Error: " err.Message, 1)
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

; Pausar/Reanudar Ctrl+Alt+Shift+P (Pausa de Software)
^!+p:: {
    global buttons, smartConfig, guardianConfig
    
    ; Determinar el nuevo estado basado en si SmartResponse está encendido
    newState := !smartConfig.enabled
    
    smartConfig.enabled := newState
    guardianConfig.enabled := newState
    
    for btn in buttons
        btn.enabled := newState
    
    TrayTip("ButtonBot", newState ? "✓ Bot Totalmente Activado" : "⏸ Bot Totalmente Pausado", 1)
}

; Salir
^!q:: {
    TrayTip("ButtonBot", "Cerrando...", 1)
    Sleep(500)
    ExitApp()
}
