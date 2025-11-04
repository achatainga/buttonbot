#Requires AutoHotkey v2.0
#SingleInstance Force

; Rutas portables
global CONFIG_FILE := A_ScriptDir "\config\config.ini"
global IMAGES_DIR := A_ScriptDir "\images\"
global RESTART_FLAG := A_ScriptDir "\restart.flag"

; Configuración por defecto
global defaults := {
    interval: 200,
    keyPressDelay: 4000,
    detectionCooldown: 2000,
    imageVariation: 50,
    enabled: true,
    action: "click"
}

global buttons := []

; Crear GUI con estilo Material Design
myGui := Gui("+Resize", "ButtonBot - Configuration Editor")
myGui.BackColor := "0xF5F5F5"
myGui.SetFont("s10", "Segoe UI")

; Cargar configuración antes de crear GUI
LoadConfig()

; Sección de configuración global
myGui.SetFont("s11 Bold", "Segoe UI")
myGui.Add("Text", "x10 y10 w760 h30 +0x200 +Center BackgroundTrans", "Global Settings").SetFont("s12 Bold", "Segoe UI")
myGui.SetFont("s10 Norm", "Segoe UI")
myGui.Add("Progress", "x10 y42 w760 h2 Background0x2196F3 c0x2196F3", 100)

; Fila 1: Timing
myGui.Add("Text", "x20 y55 c0x424242", "Interval (ms):")
globalInterval := myGui.Add("Edit", "x120 y52 w80 Background0xFFFFFF", defaults.interval)
myGui.Add("Text", "x220 y55 c0x424242", "KeyPress Delay:")
globalKeyDelay := myGui.Add("Edit", "x330 y52 w80 Background0xFFFFFF", defaults.keyPressDelay)
myGui.Add("Text", "x430 y55 c0x424242", "Cooldown:")
globalCooldown := myGui.Add("Edit", "x510 y52 w80 Background0xFFFFFF", defaults.detectionCooldown)
myGui.Add("Text", "x610 y55 c0x424242", "Variation:")
globalVariation := myGui.Add("Edit", "x680 y52 w80 Background0xFFFFFF", defaults.imageVariation)

; Fila 2: Hotkeys
myGui.Add("Progress", "x20 y85 w740 h1 Background0xE0E0E0 c0xE0E0E0", 100)
myGui.Add("Text", "x20 y95 c0x424242", "Reload Hotkey:")
reloadHotkey := myGui.Add("Hotkey", "x120 y92 w150", defaults.reloadHotkey)
myGui.Add("Text", "x290 y95 c0x757575", "(Press keys)")
myGui.Add("Text", "x400 y95 c0x424242", "Config Hotkey:")
configHotkey := myGui.Add("Hotkey", "x500 y92 w150", defaults.configHotkey)
myGui.Add("Text", "x670 y95 c0x757575", "(Press keys)")

; Info text
myGui.SetFont("s8", "Segoe UI")
myGui.Add("Text", "x20 y125 c0x757575", "ℹ️ Tip: Double-click any button to edit, or click hotkey field and press your desired key combination")
myGui.SetFont("s10", "Segoe UI")

; Sección de botones
myGui.SetFont("s11 Bold", "Segoe UI")
myGui.Add("Text", "x10 y155 w760 h30 +0x200 +Center BackgroundTrans", "Configured Buttons").SetFont("s12 Bold", "Segoe UI")
myGui.SetFont("s10 Norm", "Segoe UI")
myGui.Add("Progress", "x10 y187 w760 h2 Background0x2196F3 c0x2196F3", 100)
buttonList := myGui.Add("ListView", "x20 y195 w740 h250 Background0xFFFFFF", ["File", "Action", "Interval", "KeyDelay", "Cooldown", "Variation", "Active"])
buttonList.ModifyCol(1, 180)
buttonList.ModifyCol(2, 70)
buttonList.ModifyCol(3, 70)
buttonList.ModifyCol(4, 80)
buttonList.ModifyCol(5, 80)
buttonList.ModifyCol(6, 80)
buttonList.ModifyCol(7, 60)
buttonList.OnEvent("DoubleClick", (*) => EditButton())

; Botones de acción con estilo Material
myGui.SetFont("s10 Bold", "Segoe UI")
addBtn := myGui.Add("Button", "x20 y455 w110 h35", "➕ Add Button")
addBtn.OnEvent("Click", (*) => AddButton())
editBtn := myGui.Add("Button", "x140 y455 w110 h35", "✏️ Edit")
editBtn.OnEvent("Click", (*) => EditButton())
delBtn := myGui.Add("Button", "x260 y455 w110 h35", "🗑️ Delete")
delBtn.OnEvent("Click", (*) => DeleteButton())
saveBtn := myGui.Add("Button", "x550 y455 w100 h35 Default", "💾 Save")
saveBtn.OnEvent("Click", (*) => SaveConfig())
restartBtn := myGui.Add("Button", "x660 y455 w100 h35", "🔄 Restart")
restartBtn.OnEvent("Click", (*) => RestartScript())
myGui.SetFont("s10 Norm", "Segoe UI")

; Cargar botones en la lista
RefreshButtonList()

myGui.Show("w780 h505")

; Función para refrescar la lista
RefreshButtonList() {
    buttonList.Delete()
    for btn in buttons {
        interval := btn.HasOwnProp("interval") ? btn.interval : "default"
        keyDelay := btn.HasOwnProp("keyPressDelay") ? btn.keyPressDelay : "default"
        cooldown := btn.HasOwnProp("detectionCooldown") ? btn.detectionCooldown : "default"
        variation := btn.HasOwnProp("imageVariation") ? btn.imageVariation : "default"
        enabled := btn.HasOwnProp("enabled") ? (btn.enabled ? "✓" : "✗") : "✓"
        action := btn.HasOwnProp("action") ? btn.action : "click"
        
        buttonList.Add("", btn.file, action, interval, keyDelay, cooldown, variation, enabled)
    }
}

; Agregar botón
AddButton() {
    global IMAGES_DIR
    file := FileSelect(1, IMAGES_DIR, "Seleccionar imagen del botón", "Imágenes (*.png; *.jpg; *.bmp)")
    if !file
        return
    
    SplitPath(file, &fileName)
    
    ; Crear GUI de configuración
    btnGui := Gui("+Owner" myGui.Hwnd, "Configurar Botón: " fileName)
    btnGui.SetFont("s9")
    
    btnGui.Add("Text", "x10 y10", "Archivo:")
    btnGui.Add("Text", "x150 y10 w300", fileName)
    
    btnGui.Add("Text", "x10 y40", "Acción:")
    actionDrop := btnGui.Add("DropDownList", "x150 y35 w200", ["click", "hotkey"])
    actionDrop.Choose(1)
    
    btnGui.Add("Text", "x10 y70", "Hotkey (presiona las teclas):")
    hotkeyEdit := btnGui.Add("Hotkey", "x150 y65 w200", "^+\")
    
    btnGui.Add("Text", "x10 y100", "Intervalo (ms, vacío = default):")
    intervalEdit := btnGui.Add("Edit", "x250 y95 w100", "")
    
    btnGui.Add("Text", "x10 y130", "KeyPress Delay (ms, vacío = default):")
    keyDelayEdit := btnGui.Add("Edit", "x250 y125 w100", "")
    
    btnGui.Add("Text", "x10 y160", "Cooldown (ms, vacío = default):")
    cooldownEdit := btnGui.Add("Edit", "x250 y155 w100", "")
    
    btnGui.Add("Text", "x10 y190", "Variación (0-255, vacío = default):")
    variationEdit := btnGui.Add("Edit", "x250 y185 w100", "")
    
    enabledCheck := btnGui.Add("Checkbox", "x10 y220 Checked", "Activado")
    
    btnGui.Add("Button", "x150 y250 w100", "Guardar").OnEvent("Click", (*) => SaveButton())
    btnGui.Add("Button", "x260 y250 w100", "Cancelar").OnEvent("Click", (*) => btnGui.Destroy())
    
    SaveButton() {
        btn := {file: fileName}
        
        action := actionDrop.Text
        btn.action := action
        
        if action = "hotkey"
            btn.hotkey := hotkeyEdit.Value
        
        if intervalEdit.Value != ""
            btn.interval := Integer(intervalEdit.Value)
        
        if keyDelayEdit.Value != ""
            btn.keyPressDelay := Integer(keyDelayEdit.Value)
        
        if cooldownEdit.Value != ""
            btn.detectionCooldown := Integer(cooldownEdit.Value)
        
        if variationEdit.Value != ""
            btn.imageVariation := Integer(variationEdit.Value)
        
        btn.enabled := enabledCheck.Value
        
        buttons.Push(btn)
        RefreshButtonList()
        btnGui.Destroy()
        
        ; Copiar archivo a images/ si no está ahí
        destPath := IMAGES_DIR fileName
        if !FileExist(destPath)
            FileCopy(file, destPath, 1)
    }
    
    btnGui.Show("w400 h300")
}

; Editar botón
EditButton() {
    row := buttonList.GetNext()
    if !row {
        MsgBox("Selecciona un botón para editar")
        return
    }
    
    btn := buttons[row]
    
    btnGui := Gui("+Owner" myGui.Hwnd, "Editar Botón: " btn.file)
    btnGui.SetFont("s9")
    
    btnGui.Add("Text", "x10 y10", "Archivo:")
    btnGui.Add("Text", "x150 y10 w300", btn.file)
    
    btnGui.Add("Text", "x10 y40", "Acción:")
    actionDrop := btnGui.Add("DropDownList", "x150 y35 w200", ["click", "hotkey"])
    actionDrop.Text := btn.HasOwnProp("action") ? btn.action : "click"
    
    btnGui.Add("Text", "x10 y70", "Hotkey (presiona las teclas):")
    hotkeyEdit := btnGui.Add("Hotkey", "x150 y65 w200", btn.HasOwnProp("hotkey") ? btn.hotkey : "^+\")
    
    btnGui.Add("Text", "x10 y100", "Intervalo (ms, vacío = default):")
    intervalEdit := btnGui.Add("Edit", "x250 y95 w100", btn.HasOwnProp("interval") ? btn.interval : "")
    
    btnGui.Add("Text", "x10 y130", "KeyPress Delay (ms, vacío = default):")
    keyDelayEdit := btnGui.Add("Edit", "x250 y125 w100", btn.HasOwnProp("keyPressDelay") ? btn.keyPressDelay : "")
    
    btnGui.Add("Text", "x10 y160", "Cooldown (ms, vacío = default):")
    cooldownEdit := btnGui.Add("Edit", "x250 y155 w100", btn.HasOwnProp("detectionCooldown") ? btn.detectionCooldown : "")
    
    btnGui.Add("Text", "x10 y190", "Variación (0-255, vacío = default):")
    variationEdit := btnGui.Add("Edit", "x250 y185 w100", btn.HasOwnProp("imageVariation") ? btn.imageVariation : "")
    
    enabledCheck := btnGui.Add("Checkbox", "x10 y220 " (btn.HasOwnProp("enabled") && btn.enabled ? "Checked" : ""), "Activado")
    
    btnGui.Add("Button", "x150 y250 w100", "Guardar").OnEvent("Click", (*) => UpdateButton())
    btnGui.Add("Button", "x260 y250 w100", "Cancelar").OnEvent("Click", (*) => btnGui.Destroy())
    
    UpdateButton() {
        action := actionDrop.Text
        btn.action := action
        
        if action = "hotkey"
            btn.hotkey := hotkeyEdit.Value
        else if btn.HasOwnProp("hotkey")
            btn.DeleteProp("hotkey")
        
        if intervalEdit.Value != ""
            btn.interval := Integer(intervalEdit.Value)
        else if btn.HasOwnProp("interval")
            btn.DeleteProp("interval")
        
        if keyDelayEdit.Value != ""
            btn.keyPressDelay := Integer(keyDelayEdit.Value)
        else if btn.HasOwnProp("keyPressDelay")
            btn.DeleteProp("keyPressDelay")
        
        if cooldownEdit.Value != ""
            btn.detectionCooldown := Integer(cooldownEdit.Value)
        else if btn.HasOwnProp("detectionCooldown")
            btn.DeleteProp("detectionCooldown")
        
        if variationEdit.Value != ""
            btn.imageVariation := Integer(variationEdit.Value)
        else if btn.HasOwnProp("imageVariation")
            btn.DeleteProp("imageVariation")
        
        btn.enabled := enabledCheck.Value
        
        RefreshButtonList()
        btnGui.Destroy()
    }
    
    btnGui.Show("w400 h300")
}

; Eliminar botón
DeleteButton() {
    row := buttonList.GetNext()
    if !row {
        MsgBox("Selecciona un botón para eliminar")
        return
    }
    
    result := MsgBox("¿Eliminar este botón?", "Confirmar", "YesNo Icon?")
    if result = "Yes" {
        buttons.RemoveAt(row)
        RefreshButtonList()
    }
}

; Guardar configuración
SaveConfig() {
    global CONFIG_FILE
    config := "[Defaults]`n"
    config .= "Interval=" globalInterval.Value "`n"
    config .= "KeyPressDelay=" globalKeyDelay.Value "`n"
    config .= "DetectionCooldown=" globalCooldown.Value "`n"
    config .= "ImageVariation=" globalVariation.Value "`n"
    config .= "ReloadHotkey=" reloadHotkey.Value "`n"
    config .= "ConfigHotkey=" configHotkey.Value "`n`n"
    
    for index, btn in buttons {
        config .= "[Button" index "]`n"
        config .= "File=" btn.file "`n"
        config .= "Action=" (btn.HasOwnProp("action") ? btn.action : "click") "`n"
        
        if btn.HasOwnProp("hotkey")
            config .= "Hotkey=" btn.hotkey "`n"
        
        if btn.HasOwnProp("interval")
            config .= "Interval=" btn.interval "`n"
        
        if btn.HasOwnProp("keyPressDelay")
            config .= "KeyPressDelay=" btn.keyPressDelay "`n"
        
        if btn.HasOwnProp("detectionCooldown")
            config .= "DetectionCooldown=" btn.detectionCooldown "`n"
        
        if btn.HasOwnProp("imageVariation")
            config .= "ImageVariation=" btn.imageVariation "`n"
        
        config .= "Enabled=" (btn.HasOwnProp("enabled") && btn.enabled ? "true" : "false") "`n`n"
    }
    
    FileDelete(CONFIG_FILE)
    FileAppend(config, CONFIG_FILE)
    MsgBox("✓ Configuración guardada", "Éxito")
}

; Cargar configuración
LoadConfig() {
    global defaults, buttons, CONFIG_FILE
    
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
        
        btn := {file: file}
        
        action := IniRead(CONFIG_FILE, section, "Action", "")
        if action != ""
            btn.action := action
        
        hotkey := IniRead(CONFIG_FILE, section, "Hotkey", "")
        if hotkey != ""
            btn.hotkey := hotkey
        
        interval := IniRead(CONFIG_FILE, section, "Interval", "")
        if interval != ""
            btn.interval := Integer(interval)
        
        keyDelay := IniRead(CONFIG_FILE, section, "KeyPressDelay", "")
        if keyDelay != ""
            btn.keyPressDelay := Integer(keyDelay)
        
        cooldown := IniRead(CONFIG_FILE, section, "DetectionCooldown", "")
        if cooldown != ""
            btn.detectionCooldown := Integer(cooldown)
        
        variation := IniRead(CONFIG_FILE, section, "ImageVariation", "")
        if variation != ""
            btn.imageVariation := Integer(variation)
        
        enabled := IniRead(CONFIG_FILE, section, "Enabled", "true")
        btn.enabled := (enabled = "true")
        
        buttons.Push(btn)
        index++
    }
}

; Reiniciar script principal
RestartScript() {
    global RESTART_FLAG
    FileAppend("", RESTART_FLAG)
    Run(A_ScriptDir "\ButtonBot.ahk")
    MsgBox("✓ ButtonBot se reiniciará automáticamente", "Éxito")
}
