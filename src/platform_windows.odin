#+build windows
package main

import "core:strings"
import "core:sys/windows"

foreign import user32 "system:User32.lib"
foreign user32 {
    GetDpiForSystem :: proc() -> u32 ---
}

platform_pre_init :: proc() {
	velocity_multiplier = -100
	windows.SetProcessDpiAwarenessContext(windows.DPI_AWARENESS_CONTEXT_SYSTEM_AWARE)

}
platform_post_init :: proc() { }

platform_dpi_hack :: proc() -> f64 {
    return f64(GetDpiForSystem()) / 96.0
}

// we don't actually demangle on Windows, because Windows.
demangle_symbol :: proc(name: string, tmp_buffer: []u8) -> (string, bool) {
	return name, true
}

sample_child :: proc(trace: ^Trace, program_name: string, path: string, args: []string) -> (ok: bool) { return }
supports_sampling :: proc() -> (ok: bool) { return }
