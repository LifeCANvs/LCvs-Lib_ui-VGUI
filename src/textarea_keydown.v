module iui

import gg

fn is_enter(key gg.KeyCode) bool {
	return key == .enter || key == .kp_enter
}

fn (mut win Window) textarea_key_down(key gg.KeyCode, ev &gg.Event, mut com TextArea) {
	if !com.is_selected {
		return
	}
	if key == .right {
		com.caret_left += 1
	} else if key == .left {
		com.caret_left -= 1
	} else if key == .up {
		if com.caret_top > 0 {
			com.caret_top -= 1
		}
	} else if key == .down {
		if com.caret_top < com.lines.len - 1 {
			com.caret_top += 1
		}
	} else {
		mod := ev.modifiers
		if mod == 8 {
			// Windows Key
			return
		}
		if mod == 2 {
			com.ctrl_down = true
		}

		if key == .backspace {
			line := com.lines[com.caret_top]

			com.last_letter = 'backspace'
			mut bevnt := com.before_txtc_event_fn(mut win, *com)
			if bevnt {
				// 'true' indicates cancel event
				return
			}

			if com.caret_left == 0 && com.caret_top == 0 {
				return
			}

			if com.caret_left - 1 >= 0 {
				new_line := line.substr(0, com.caret_left - 1) +
					line.substr(com.caret_left, line.len)
				com.lines[com.caret_top] = new_line
				com.caret_left -= 1
			} else {
				// EOL
				line_text := line
				com.delete_current_line()
				com.lines[com.caret_top] = com.lines[com.caret_top] + line_text
			}
		} else {
			win.textarea_key_down_typed(key, ev, mut com)
		}
	}
}

fn (mut win Window) textarea_key_down_typed(key gg.KeyCode, ev &gg.Event, mut com TextArea) {
	mod := ev.modifiers

	mut enter := is_enter(key)

	if key == .left_shift || key == .right_shift {
		win.shift_pressed = true
		return
	}

	mut letter := ''

	if ev.typ == .char {
		resu := utf32_to_str(ev.char_code)
		letter = resu
		com.last_letter = letter
	}

	$if emscripten ? {
		if ev.typ == .char && ev.char_code == 13 {
			enter = true
		}
	}

	if enter {
		com.last_letter = 'enter'
	}

	bevnt := com.before_txtc_event_fn(mut win, *com)
	if bevnt {
		// 'true' indicates cancel event
		return
	}

	if !enter && mod != 2 {
		if com.lines.len == 0 {
			com.lines << ' '
			com.caret_top = 0
		}

		line := com.lines[com.caret_top]

		if letter.len > 1 {
			// For extended unicode
			mut myrunes := line.runes()
			myrunes.insert(com.caret_left, letter.runes()[0])
			com.lines[com.caret_top] = myrunes.string()
			unsafe {
				myrunes.free()
			}
		} else {
			new_line := line.substr_ni(0, com.caret_left) + letter +
				line.substr_ni(com.caret_left, line.len)
			com.lines[com.caret_top] = new_line
		}
	}

	com.last_letter = letter
	com.text_change_event_fn(win, com)

	if enter {
		current_line := com.lines[com.caret_top]
		if com.caret_left == current_line.len {
			com.caret_top += 1
			com.lines.insert(com.caret_top, '')
			if current_line.starts_with('\t') {
				com.lines[com.caret_top] = '\t'
			}
		} else {
			keep_line := current_line.substr(0, com.caret_left)
			new_line := current_line.substr_ni(com.caret_left, current_line.len)

			com.lines[com.caret_top] = keep_line

			com.caret_top += 1
			com.lines.insert(com.caret_top, '')
			com.lines[com.caret_top] = new_line
			com.caret_left = 0
		}
	} else if mod != 2 {
		if letter.len > 0 {
			com.caret_left += 1
		}
	}
}
