package main

import "core:fmt"
import "core:math"
import "core:sort"
import "core:slice"
import rl "vendor:raylib"

// -------------------------------------------- ELEMENT --------------------------------------------

ElementHandle :: distinct uint
NIL_HANDLE :: ElementHandle(max(uint))

Element :: struct {
	handle: ElementHandle,
	parent: ^Element,
	position: [2]f32,
	z: i32,
}

make_element :: proc() -> Element {
	return Element{
		handle = new_handle(),
		parent = nil,
		position = {0, 0},
		z = 0,
	}
}

calc_element_position :: proc(using element: ^Element) -> [2]f32 {
	if parent != nil {
		return position + calc_element_position(parent)
	}
	else {
		return position
	}
}

// -------------------------------------------- PANEL --------------------------------------------

Color :: rl.Color

Panel :: struct {
	using element: Element,
	dimensions: [2]f32,
	color: Color,
}

make_panel :: proc() -> (ElementHandle, ^Panel) {
	element := make_element()
	handle := element.handle
	global_data.panels[handle] = Panel{
		element = element,
		dimensions = {0, 0},
		color = {0, 0, 0, 0},
	}
	panel: ^Panel = &global_data.panels[handle]
	return handle, panel
}

delete_panel :: proc(panel_handle: ElementHandle) {
	if !(panel_handle in global_data.panels) {
		return
	}
	delete_key(&global_data.panels, panel_handle)
}

get_panel :: proc(handle: ElementHandle) -> ^Panel {
	return &global_data.panels[handle]
}

is_handle_valid :: proc(handle: ElementHandle) -> bool {
	return handle in global_data.panels
}

// -------------------------------------------- GLOBAL DATA --------------------------------------------

global_data: struct {
	elements: map[ElementHandle]Element,
	panels: map[ElementHandle]Panel,
	sorted_panels: [dynamic]^Panel,
	next_element_handle: ElementHandle,
}

initialize_global_data :: proc() {
	using global_data
	elements = make(map[ElementHandle]Element)
	panels = make(map[ElementHandle]Panel)
	sorted_panels = make([dynamic]^Panel)
	next_element_handle = ElementHandle(0)
}

destroy_global_data :: proc() {
	delete(global_data.elements)
	delete(global_data.panels)
	delete(global_data.sorted_panels)
}

new_handle :: proc() -> (handle: ElementHandle) {
	handle = global_data.next_element_handle
	global_data.next_element_handle += 1
	return
}

// -------------------------------------------- APPLICATION --------------------------------------------

app_data: struct {
	main_panel: ^Panel,
	panel1: ^Panel,
	panel2: ^Panel,
	time: f32,
}

update :: proc(delta_time: f32) {
	app_data.time += delta_time

	clear(&global_data.sorted_panels)
	for handle, &panel in global_data.panels {
		append(&global_data.sorted_panels, &panel)
	}

	slice.sort_by(global_data.sorted_panels[:], proc(a, b: ^Panel) -> bool { return a.z < b.z })

	app_data.panel1.position.x = 100 + 100 * math.sin(app_data.time * math.PI)
	app_data.panel1.position.y = 100 + 100 * math.cos(app_data.time * math.PI)

	for &panel in global_data.sorted_panels {
		
	}
}

draw :: proc() {
	rl.BeginDrawing()
	{
		rl.ClearBackground(rl.WHITE)
		// rl.DrawText("Window text", 100, 100, 18, rl.BLACK)

		for panel in global_data.sorted_panels {
			position := calc_element_position(panel)
			rl.DrawRectangle(
				cast(i32)position.x,
				cast(i32)position.y,
				cast(i32)panel.dimensions.x,
				cast(i32)panel.dimensions.y,
				panel.color,
			)
		}
	}
	rl.EndDrawing()
}

WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: 480

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Title")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	initialize_global_data()
	defer destroy_global_data()

	h_main_panel, main_panel := make_panel()
	main_panel.color = rl.GRAY
	main_panel.position = {0, 0}
	main_panel.dimensions = {WINDOW_WIDTH, WINDOW_HEIGHT}
	main_panel.z = 0
	app_data.main_panel = main_panel

	h_panel1, panel1 := make_panel()
	panel1.parent = main_panel
	panel1.color = rl.RED
	panel1.position = {100, 100}
	panel1.dimensions = {100, 100}
	panel1.z = 1
	app_data.panel1 = panel1

	h_panel2, panel2 := make_panel()
	panel2.parent = panel1
	panel2.color = rl.GREEN
	panel2.position = {100, 0}
	panel2.dimensions = {100, 100}
	panel2.z = 2
	app_data.panel2 = panel2

	for !rl.WindowShouldClose() {
		update(rl.GetFrameTime())
		draw()
	}
}
