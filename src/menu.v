module iui

import gg
import gx
import v.util.version { full_v_version }

[heap]
pub struct Menubar {
	Component_A
pub mut:
	// app   &Window
	theme &Theme
	items []MenuItem
	tik   int
}

pub fn (mut bar Menubar) add_child(com MenuItem) {
	bar.items << com
}

[deprecated]
pub fn (mut bar Menubar) is_hovering() bool {
	for mut item in bar.items {
		if item.show_items {
			return true
		}
	}
	return false
}

[heap]
pub struct MenuItem {
	Component_A
pub mut:
	items          []MenuItem
	text           string
	icon           &Image
	shown          bool
	show_items     bool
	no_paint_bg    bool
	click_event_fn fn (mut Window, MenuItem)
}

[parms]
pub struct MenuItemConfig {
	text           string
	icon           &Image = unsafe { nil }
	click_event_fn fn (mut Window, MenuItem) = fn (mut win Window, item MenuItem) {}
	children       []&MenuItem
}

pub fn (mut item MenuItem) add_child(com MenuItem) {
	item.items << com
}

// TODO: [deprecated: 'Replaced with menu_item(MenuItemConfig)']
pub fn menuitem(text string) &MenuItem {
	return &MenuItem{
		text: text
		shown: false
		show_items: false
		icon: 0
		click_event_fn: fn (mut win Window, item MenuItem) {}
	}
}

pub fn menu_item(confg MenuItemConfig) &MenuItem {
	mut item := &MenuItem{
		text: confg.text
		shown: false
		show_items: false
		icon: confg.icon
		click_event_fn: confg.click_event_fn
	}
	for kid in confg.children {
		item.add_child(kid)
	}
	return item
}

pub fn (mut com MenuItem) set_click(b fn (mut Window, MenuItem)) {
	com.click_event_fn = b
}

[params]
pub struct MenubarConfig {
	theme &Theme = unsafe { nil }
}

pub fn menu_bar(cfg MenubarConfig) &Menubar {
	return &Menubar{
		theme: cfg.theme
	}
}

pub fn menubar(app &Window, theme Theme) &Menubar {
	return &Menubar{
		// app: app
		theme: &theme
	}
}

pub fn (mut bar Menubar) draw(ctx &GraphicsContext) {
	wid := if bar.width > 0 { bar.width } else { gg.window_size().width }

	if bar.theme == unsafe { nil } {
		bar.theme = ctx.theme
	}

	ctx.theme.menu_bar_fill_fn(bar.x, bar.y, wid - 1, 26, ctx)
	ctx.gg.draw_rect_empty(bar.x, bar.y, wid, 26, ctx.theme.menubar_border)

	mut mult := 0
	mut win := ctx.win

	for mut item in bar.items {
		win.draw_menu_button(ctx, mult, bar.y + 1, 56, 25, mut item)
		if item.width > 0 {
			mult += item.width + 4
		} else {
			mult += 56
		}
	}
}

fn (mut app Window) get_bar() &Menubar {
	return app.bar
}

fn (mut app Window) set_bar_tick(val int) {
	if app.bar != unsafe { nil } {
		app.bar.tik = val
	}
}

fn (item &MenuItem) get_bg(app &Window, hover bool, click bool) gx.Color {
	shown_items := item.show_items && item.items.len > 0

	if click || shown_items {
		return app.theme.button_bg_click
	}

	if hover {
		return app.theme.button_bg_hover
	}

	return app.theme.menubar_background
}

fn (mut app Window) draw_menu_button(ctx &GraphicsContext, x int, y int, width_ int, height int, mut item MenuItem) {
	size := text_width(app, item.text) / 2
	half_line_height := ctx.line_height / 2

	width := if item.width > 0 { item.width + 4 } else { width_ }

	midx := x + (width / 2)
	midy := y + (height / 2)

	hover := (abs(midx - app.mouse_x) < (width / 2)) && (abs(midy - app.mouse_y) < (height / 2))
	clicked := ((abs(midx - app.click_x) < (width / 2)) && (abs(midy - app.click_y) < (height / 2)))

	bg := item.get_bg(app, hover, clicked)

	// Detect Click
	if clicked && !item.show_items {
		item.show_items = true
		app.set_bar_tick(0)

		item.click_event_fn(mut app, *item)

		if item.text == 'About iUI' {
			about := open_about_modal(app)
			app.add_child(about)
		}
	}

	if item.show_items && item.items.len > 0 {
		app.set_bar_tick(0)
		mut wid := 120

		for mut sub in item.items {
			sub_size := text_width(app, sub.text + '...')
			if wid < sub_size {
				wid = sub_size
			}
		}

		app.draw_filled_rect(x, y + height, wid, (item.items.len * 30) + 2, 2, app.theme.dropdown_background,
			app.theme.dropdown_border)

		mut mult := 0
		for mut sub in item.items {
			app.draw_menu_button(ctx, x + 1, y + height + mult + 1, wid - 3, 29, mut sub)
			mult += 30
		}
	}

	if item.show_items && (item.items.len == 0 || (app.click_x != -1 && app.click_y != -1))
		&& !clicked {
		item.is_mouse_rele = true
		item.show_items = false
	}
	if app.bar != unsafe { nil } && !item.show_items && app.bar.tik < 99 {
		app.bar.tik++
	}

	// Draw Button Background & Border
	if !item.no_paint_bg && bg != app.theme.menubar_background {
		ctx.gg.draw_rounded_rect_filled(x + 1, y, width - 1, height - 1, 4, bg)
	}

	// Draw Button Text
	if item.icon != unsafe { nil } {
		item.icon.set_pos(x + (width / 2) - (item.icon.width / 2), y)
		item.icon.draw(ctx)
	} else {
		ctx.draw_text((x + (width / 2)) - size, y + (height / 2) - half_line_height + 2,
			item.text, ctx.font, gx.TextCfg{
			size: app.font_size
			color: app.theme.text_color
		})
	}

	mut com := &Component(item)
	com.draw_event_fn(mut app, com)
	invoke_draw_event(com, ctx)
}

fn open_about_modal(app &Window) &Modal {
	mut about := modal(app, 'About iUI')
	about.in_height = 250
	about.in_width = 370

	mut title := label(app, 'iUI ')
	title.set_pos(40, 16)
	title.set_config(16, false, true)
	title.pack()
	about.add_child(title)

	mut lbl := label(app, "Isaiah's UI Toolkit for V.\nVersion: ${version}\nCompiled with " +
		full_v_version(false))
	lbl.set_pos(40, 70)
	about.add_child(lbl)

	gh := link(
		text: 'Github'
		url: 'https://github.com/isaiahpatton/ui'
		bounds: Bounds{
			x: 40
			y: 135
		}
		pack: true
	)
	about.add_child(gh)

	mut copy := label(app, 'Copyright © 2021-2023 Isaiah.')
	copy.set_pos(40, 185)
	copy.set_config(12, true, false)
	about.add_child(copy)
	return about
}
