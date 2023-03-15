// Based on the Counter example at
// https://eugenkiss.github.io/7guis/tasks
import gg
import iui as ui

[console]
fn main() {
	// Create Window
	mut window := ui.window(ui.get_system_theme(), 'Counter', 230, 200)

	window.debug_draw = true

	// Create an HBox
	mut hbox := ui.hbox(window)
	hbox.set_bounds(10, 10, 230, 80)

	// Create the Label
	mut lbl := ui.label(window, '0')
	lbl.set_bounds(42, 20, 0, 0)
	lbl.pack()

	// Create Count Button
	mut btn := ui.button(
		text: 'Count'
		bounds: ui.Bounds{64, 13, 0, 0}
		click_event_fn: on_click
		should_pack: true
		user_data: &lbl
	)

	btn.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		dump('DRAW')
	})

	// Add to HBox
	hbox.add_child(lbl)
	hbox.add_child(btn)
	hbox.pack()

	// Show Window
	window.add_child(hbox)
	window.gg.run()
}

// on click event function
// The Label we want to update is sent as data.
fn on_click(win &ui.Window, btn voidptr, data voidptr) {
	mut lbl := &ui.Label(data)
	current_value := lbl.text.int()
	lbl.text = (current_value + 1).str()
	lbl.pack()
}
