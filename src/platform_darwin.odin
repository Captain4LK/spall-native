#+build darwin

package main

import "core:fmt"
import "core:strings"
import NS "core:sys/darwin/Foundation"

platform_pre_init :: proc() {
	velocity_multiplier = -15
}
platform_post_init :: proc() {
	user_defaults := NS.UserDefaults.standardUserDefaults()
	flag_str := NS.String.alloc()->initWithOdinString("AppleMomentumScrollSupported")
	user_defaults->setBoolForKey(true, flag_str)
}
platform_dpi_hack :: proc() -> f64 {
	return -1
}

foreign import abi "system:c++abi"
foreign abi {
	@(link_name="__cxa_demangle") _cxa_demangle :: proc(name: rawptr, out_buf: rawptr, len: rawptr, status: rawptr) -> cstring ---
}

demangle_symbol :: proc(name: string, tmp_buffer: []u8) -> (string, bool) {
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)

	buffer_size := len(tmp_buffer)

	status : i32 = 0
	ret_str := _cxa_demangle(rawptr(name_cstr), raw_data(tmp_buffer), &buffer_size, &status)
	if status == -2 {
		return name, true
	} else if status != 0 {
		return "", false
	}

	return string(ret_str), true
}

supports_sampling :: proc() -> (ok: bool) { return false }
