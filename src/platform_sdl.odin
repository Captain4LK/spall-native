#+build linux, windows
package main

import "core:fmt"
import "core:os"
import "core:strings"

import SDL "vendor:sdl3"
import gl "vendor:OpenGL"

default_cursor: ^SDL.Cursor
pointer_cursor: ^SDL.Cursor
text_cursor:    ^SDL.Cursor

GFX_Context :: struct {
	window: ^SDL.Window,

	rects:      [dynamic]DrawRect,
	text_rects: [dynamic]TextRect,
}

_resolve_key :: proc(code: SDL.Keycode) -> KeyType {
   switch code {
   case SDL.K_A: return .A
   case SDL.K_B: return .B
   case SDL.K_C: return .C
   case SDL.K_D: return .D
   case SDL.K_E: return .E
   case SDL.K_F: return .F
   case SDL.K_G: return .G
   case SDL.K_H: return .H
   case SDL.K_I: return .I
   case SDL.K_J: return .J
   case SDL.K_K: return .K
   case SDL.K_L: return .L
   case SDL.K_M: return .M
   case SDL.K_N: return .N
   case SDL.K_O: return .O
   case SDL.K_P: return .P
   case SDL.K_Q: return .Q
   case SDL.K_R: return .R
   case SDL.K_S: return .S
   case SDL.K_T: return .T
   case SDL.K_U: return .U
   case SDL.K_V: return .V
   case SDL.K_W: return .W
   case SDL.K_X: return .X
   case SDL.K_Y: return .Y
   case SDL.K_Z: return .Z

   case SDL.K_KP_0: return ._0
   case SDL.K_KP_1: return ._1
   case SDL.K_KP_2: return ._2
   case SDL.K_KP_3: return ._3
   case SDL.K_KP_4: return ._4
   case SDL.K_KP_5: return ._5
   case SDL.K_KP_6: return ._6
   case SDL.K_KP_7: return ._7
   case SDL.K_KP_8: return ._8
   case SDL.K_KP_9: return ._9

   case SDL.K_EQUALS:       return .Equal
   case SDL.K_MINUS:        return .Minus
   case SDL.K_LEFTBRACKET:  return .LeftBracket
   case SDL.K_RIGHTBRACKET: return .RightBracket
   case SDL.K_APOSTROPHE:   return .Quote
   case SDL.K_SEMICOLON:    return .Semicolon
   case SDL.K_BACKSLASH:    return .Backslash
   case SDL.K_COMMA:        return .Comma
   case SDL.K_SLASH:        return .Slash
   case SDL.K_PERIOD:       return .Period
   case SDL.K_GRAVE:        return .Grave
   case SDL.K_RETURN:       return .Return
   case SDL.K_TAB:          return .Tab
   case SDL.K_SPACE:        return .Space
   case SDL.K_BACKSPACE:    return .Backspace
   case SDL.K_ESCAPE:       return .Escape
   case SDL.K_CAPSLOCK:     return .CapsLock

   case SDL.K_LALT:   return .LeftAlt
   case SDL.K_RALT:   return .RightAlt
   case SDL.K_LCTRL:  return .LeftControl
   case SDL.K_RCTRL:  return .RightControl
   case SDL.K_LGUI:   return .LeftSuper
   case SDL.K_RGUI:   return .RightSuper
   case SDL.K_LSHIFT: return .LeftShift
   case SDL.K_RSHIFT: return .RightShift

   case SDL.K_F1:  return .F1
   case SDL.K_F2:  return .F2
   case SDL.K_F3:  return .F3
   case SDL.K_F4:  return .F4
   case SDL.K_F5:  return .F5
   case SDL.K_F6:  return .F6
   case SDL.K_F7:  return .F7
   case SDL.K_F8:  return .F8
   case SDL.K_F9:  return .F9
   case SDL.K_F10: return .F10
   case SDL.K_F11: return .F11
   case SDL.K_F12: return .F12

   case SDL.K_HOME:     return .Home
   case SDL.K_END:      return .End
   case SDL.K_PAGEUP:   return .PageUp
   case SDL.K_PAGEDOWN: return .PageDown
   case SDL.K_DELETE:   return .FwdDelete

   case SDL.K_LEFT:  return .Left
   case SDL.K_RIGHT: return .Right
   case SDL.K_DOWN:  return .Down
   case SDL.K_UP:    return .Up
	}

	return .None
}

dpi_hack_val := 0.0
create_context :: proc(title: cstring, width, height: int) -> (GFX_Context, f64, f64, f64) {
	gfx := GFX_Context{}

	orig_window_width := i32(width)
	orig_window_height := i32(height)

	platform_pre_init()

	dpr := 0.0
	dpi_hack_val = platform_dpi_hack()
	if dpi_hack_val > 0 {
		dpr = dpi_hack_val
		orig_window_width = i32(f64(orig_window_width) * dpr)
		orig_window_height = i32(f64(orig_window_height) * dpr)
	}

	res: bool = SDL.Init({.VIDEO})

	GL_VERSION_MAJOR :: 3
	GL_VERSION_MINOR :: 3
	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GLProfile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	SDL.GL_SetAttribute(.MULTISAMPLEBUFFERS, 1)
	SDL.GL_SetAttribute(.MULTISAMPLESAMPLES, 2)
	SDL.GL_SetAttribute(SDL.GLAttr.FRAMEBUFFER_SRGB_CAPABLE, 1)

	SDL.SetHint(SDL.HINT_MOUSE_FOCUS_CLICKTHROUGH, "1")

	window := SDL.CreateWindow(title, i32(width), i32(height), {.OPENGL, .RESIZABLE, .HIGH_PIXEL_DENSITY})
	if window == nil {
		fmt.eprintln("Failed to create window")
		os.exit(1)
	}

	platform_post_init()

	default_cursor = SDL.CreateSystemCursor(.DEFAULT)
	pointer_cursor = SDL.CreateSystemCursor(.POINTER)
	text_cursor    = SDL.CreateSystemCursor(.TEXT)

	gl_context := SDL.GL_CreateContext(window)
	if gl_context == nil {
		fmt.eprintln("Failed to create gl context!")
		os.exit(1)
	}

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

	version_str := gl.GetString(gl.VERSION)
	if version_str == "1.1.0" {
		fmt.eprintf("GL version is too old! Got %s, needs at least %d.%d.0\n", version_str, GL_VERSION_MAJOR, GL_VERSION_MINOR)
		os.exit(1)
	}

	if opt.full_speed {
		SDL.GL_SetSwapInterval(0)
	} else {
		SDL.GL_SetSwapInterval(-1)
	}

	real_window_width: i32
	real_window_height: i32
	pretend_window_width: i32
	pretend_window_height: i32
	SDL.GetWindowSize(window, &pretend_window_width, &pretend_window_height)
   // TODO(LHB): does this behave the same as SDL_GetDrawableSize for this purpose?
	SDL.GetWindowSizeInPixels(window, &real_window_width, &real_window_height)
	width := f64(pretend_window_width)
	height := f64(pretend_window_height)

	// on certain platforms (windows) we need to grab the DPI explicitly, on certain (mac or linux)
	// we can infer it from the window size we got vs the window size we asked for (it scales it up
	// based on DPI).
	if dpi_hack_val < 0 {
		dpr_w := f64(real_window_width) / f64(pretend_window_width)
		dpr_h := f64(real_window_height) / f64(pretend_window_height)
		dpr = dpr_w
		width = width * dpr
		height = height * dpr
	}

	gfx.window = window
	gfx.rects = make([dynamic]DrawRect)
	gfx.text_rects = make([dynamic]TextRect)
	return gfx, dpr, width, height
}

get_next_event :: proc(gfx: ^GFX_Context, wait: bool) -> PlatformEvent {
	event: SDL.Event = ---
	ret: bool
	if wait {
		ret = bool(SDL.WaitEvent(&event))
	} else {
		ret = bool(SDL.PollEvent(&event))
	}
	if !ret {
		return PlatformEvent{type = .None}
	}

	#partial switch event.type {
		case .QUIT: return PlatformEvent{type = .Exit}
		case .MOUSE_MOTION: {
			x := f64(event.motion.x)
			y := f64(event.motion.y)
			if dpi_hack_val > 0 {
				x /= dpr
				y /= dpr
			}

			return PlatformEvent{type = .MouseMoved, x = x, y = y}
		}
		case .MOUSE_BUTTON_UP: {
			type := MouseButtonType.None
			switch event.button.button {
			case SDL.BUTTON_LEFT: type = .Left
			case SDL.BUTTON_RIGHT: type = .Right
			}
			if type != .None {
				x := f64(event.button.x)
				y := f64(event.button.y)
				if dpi_hack_val > 0 {
					x /= dpr
					y /= dpr
				}

				return PlatformEvent{type = .MouseUp, mouse = type, x = x, y = y}
			}
		}
		case .MOUSE_BUTTON_DOWN: {
			type := MouseButtonType.None
			switch event.button.button {
			case SDL.BUTTON_LEFT: type = .Left
			case SDL.BUTTON_RIGHT: type = .Right
			}
			if type != .None {
				x := f64(event.button.x)
				y := f64(event.button.y)
				if dpi_hack_val > 0 {
					x /= dpr
					y /= dpr
				}

				return PlatformEvent{type = .MouseDown, mouse = type, x = x, y = y}
			}
		}
		case .MOUSE_WHEEL: {
			return PlatformEvent{type = .Scroll, y = f64(event.wheel.y)}
		}
		case .KEY_DOWN: {
			key := _resolve_key(event.key.key)
			return PlatformEvent{type = .KeyDown, key = key}
		}
		case .KEY_UP: {
			key := _resolve_key(event.key.key)
			return PlatformEvent{type = .KeyUp, key = key}
		}
		case .DROP_FILE: {
			file_name := strings.clone_from_cstring(event.drop.data)
			return PlatformEvent{type = .FileDropped, str = file_name}
		}
		case .DROP_TEXT: {
		}
		case .WINDOW_RESIZED: {
         w := f64(event.window.data1)
         h := f64(event.window.data2)
         if dpi_hack_val < 0 {
            w *= dpr
            h *= dpr
         }

         return PlatformEvent{type = .Resize, w = w, h = h}
		}
		case .TEXT_INPUT: {
			r_une := string(cstring(rawptr(&event.text.text)))
			rune_str := strings.clone(r_une)
			return PlatformEvent{type = .Rune, str = rune_str}
		}
	}

	return PlatformEvent{type = .More}
}

swap_buffers :: proc(gfx: ^GFX_Context) {
	SDL.GL_SwapWindow(gfx.window)
}

set_fullscreen :: proc(gfx: ^GFX_Context, fullscreen: bool) -> (int, int) {
   SDL.SetWindowFullscreen(gfx.window, fullscreen)
	iw : i32
	ih : i32
	SDL.GetWindowSize(gfx.window, &iw, &ih)
	return int(iw), int(ih)
}

set_cursor :: proc(gfx: ^GFX_Context, type: string) {
   res: bool
	switch type {
	case "auto":    res = SDL.SetCursor(default_cursor)
	case "pointer": res = SDL.SetCursor(pointer_cursor)
	case "text":    res = SDL.SetCursor(text_cursor)
	}
	is_hovering = true
}
reset_cursor :: proc(gfx: ^GFX_Context) { 
	set_cursor(gfx, "auto") 
	is_hovering = false
}

get_clipboard :: proc(gfx: ^GFX_Context) -> string {
	return string(cstring(SDL.GetClipboardText()))
}
set_clipboard :: proc(gfx: ^GFX_Context, text: string) {
	cstr_text := strings.clone_to_cstring(text, context.temp_allocator)
	SDL.SetClipboardText(cstr_text)
}

set_window_title :: proc(gfx: ^GFX_Context, title: cstring) {
	SDL.SetWindowTitle(gfx.window, title)
}
