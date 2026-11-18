extends Control
## Neon Tic Tac Toe - everything is drawn in code.

const BG_TOP := Color("1a1040")
const BG_BOT := Color("0a2f4f")
const X_COL := Color("ff4d94")
const O_COL := Color("2de2ff")
const GOLD := Color("ffd66b")
const WHITE := Color(1, 1, 1, 1)

const LINES := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
const CPU_MISTAKE_CHANCE := 0.18
const HIT_NEW := 100
const HIT_MODE := 101


class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var rot := 0.0
	var spin := 0.0
	var col := Color.WHITE
	var life := 0.0
	var size := Vector2(10, 18)


class Ripple:
	var pos := Vector2.ZERO
	var t := 0.0
	var col := Color.WHITE


var board: Array = []
var marks_t: Array = []
var turn := 1
var starter := 1
var game_over := false
var win_line: Array = []
var vs_cpu := true
var score_x := 0
var score_o := 0
var score_d := 0
var win_t := 0.0
var time := 0.0
var cpu_timer := -1.0
var press_target := -1

var u := 1.0
var last_size := Vector2.ZERO
var board_rect := Rect2()
var cell := 100.0
var title_y := 0.0
var score_y := 0.0
var status_y := 0.0
var btn_new := Rect2()
var btn_mode := Rect2()

var confetti: Array[Particle] = []
var ripples: Array[Ripple] = []
var stars: Array[Vector3] = []
var sb := StyleBoxFlat.new()
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	for i in 46:
		stars.append(Vector3(rng.randf(), rng.randf(), rng.randf() * TAU))
	_layout()
	_new_round()


# ------------------------------------------------------------ layout
func _layout() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	u = minf(w / 720.0, h / 1280.0)
	var total := 1088.0 * u
	var y0 := maxf(10.0 * u, (h - total) * 0.5)
	var side := 634.0 * u
	title_y = y0 + 55.0 * u
	score_y = y0 + 110.0 * u
	status_y = y0 + 262.0 * u
	board_rect = Rect2(w * 0.5 - side * 0.5, y0 + 320.0 * u, side, side)
	cell = side / 3.0
	var by := board_rect.end.y + 50.0 * u
	var bw := (side - 24.0 * u) * 0.5
	btn_new = Rect2(board_rect.position.x, by, bw, 84.0 * u)
	btn_mode = Rect2(board_rect.end.x - bw, by, bw, 84.0 * u)


func _cell_center(i: int) -> Vector2:
	var col := i % 3
	var row := i / 3
	return board_rect.position + Vector2(col + 0.5, row + 0.5) * cell


func _cell_rect(i: int) -> Rect2:
	var c := _cell_center(i)
	return Rect2(c - Vector2(cell, cell) * 0.5, Vector2(cell, cell)).grow(-9.0 * u)


# ------------------------------------------------------------ game logic
func _new_round() -> void:
	board = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	marks_t = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	win_line = []
	game_over = false
	win_t = 0.0
	turn = starter
	cpu_timer = -1.0
	if vs_cpu and turn == 2:
		cpu_timer = 0.7


func _find_line(b: Array) -> Array:
	for l in LINES:
		var a: int = b[l[0]]
		if a != 0 and a == b[l[1]] and a == b[l[2]]:
			return l
	return []


func _play(i: int) -> void:
	if game_over or board[i] != 0:
		return
	board[i] = turn
	marks_t[i] = 0.0
	_add_ripple(i)
	_buzz(18)
	win_line = _find_line(board)
	if win_line.size() > 0:
		game_over = true
		win_t = -0.35
		if turn == 1:
			score_x += 1
		else:
			score_o += 1
		starter = 3 - starter
		if not (vs_cpu and turn == 2):
			_burst()
		_buzz(70)
	elif not board.has(0):
		game_over = true
		score_d += 1
		starter = 3 - starter
	else:
		turn = 3 - turn
		if vs_cpu and turn == 2:
			cpu_timer = 0.6


func _minimax(b: Array, player: int, depth: int) -> int:
	var line := _find_line(b)
	if line.size() > 0:
		return 10 - depth if b[line[0]] == 2 else depth - 10
	if not b.has(0):
		return 0
	var best := -100 if player == 2 else 100
	for i in 9:
		if b[i] == 0:
			b[i] = player
			var s := _minimax(b, 3 - player, depth + 1)
			b[i] = 0
			best = maxi(best, s) if player == 2 else mini(best, s)
	return best


func _cpu_move() -> void:
	cpu_timer = -1.0
	if game_over or turn != 2:
		return
	var moves: Array = []
	for i in 9:
		if board[i] == 0:
			moves.append(i)
	if moves.is_empty():
		return
	var pick: int = moves[rng.randi() % moves.size()]
	if rng.randf() > CPU_MISTAKE_CHANCE:
		var best := -1000
		var best_moves: Array = []
		for i in moves:
			board[i] = 2
			var s := _minimax(board, 1, 1)
			board[i] = 0
			if s > best:
				best = s
				best_moves = [i]
			elif s == best:
				best_moves.append(i)
		pick = best_moves.pick_random()
	_play(pick)


func _buzz(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _add_ripple(i: int) -> void:
	var r := Ripple.new()
	r.pos = _cell_center(i)
	r.col = X_COL if board[i] == 1 else O_COL
	ripples.append(r)


func _burst() -> void:
	var colors := [X_COL, O_COL, GOLD, WHITE]
	var origin := board_rect.get_center()
	for i in 110:
		var p := Particle.new()
		p.pos = origin + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-60.0, 60.0)) * u
		var ang := rng.randf_range(-PI, 0.0)
		var spd := rng.randf_range(300.0, 1100.0) * u
		p.vel = Vector2(cos(ang), sin(ang)) * spd
		p.rot = rng.randf() * TAU
		p.spin = rng.randf_range(-9.0, 9.0)
		p.col = colors[rng.randi() % colors.size()]
		p.life = rng.randf_range(1.6, 2.8)
		p.size = Vector2(rng.randf_range(8.0, 14.0), rng.randf_range(14.0, 26.0)) * u
		confetti.append(p)


# ------------------------------------------------------------ input
func _gui_input(event: InputEvent) -> void:
	var e := event as InputEventMouseButton
	if e == null or e.button_index != MOUSE_BUTTON_LEFT:
		return
	if e.pressed:
		press_target = _hit(e.position)
	else:
		var t := _hit(e.position)
		if t != -1 and t == press_target:
			_activate(t)
		press_target = -1


func _hit(p: Vector2) -> int:
	if btn_new.has_point(p):
		return HIT_NEW
	if btn_mode.has_point(p):
		return HIT_MODE
	if board_rect.has_point(p):
		var c := int((p.x - board_rect.position.x) / cell)
		var r := int((p.y - board_rect.position.y) / cell)
		return clampi(r, 0, 2) * 3 + clampi(c, 0, 2)
	return -1


func _activate(t: int) -> void:
	if t == HIT_NEW:
		_new_round()
	elif t == HIT_MODE:
		vs_cpu = not vs_cpu
		score_x = 0
		score_o = 0
		score_d = 0
		starter = 1
		_new_round()
	elif game_over:
		_new_round()
	elif not (vs_cpu and turn == 2):
		_play(t)


# ------------------------------------------------------------ update
func _process(delta: float) -> void:
	time += delta
	if size != last_size:
		last_size = size
		_layout()
	for i in 9:
		if board[i] != 0:
			marks_t[i] = minf(1.0, float(marks_t[i]) + delta * 3.2)
	if game_over and win_line.size() > 0:
		win_t = minf(1.0, win_t + delta * 1.8)
	if cpu_timer >= 0.0:
		cpu_timer -= delta
		if cpu_timer < 0.0:
			_cpu_move()
	for i in range(confetti.size() - 1, -1, -1):
		var p := confetti[i]
		p.vel.y += 900.0 * u * delta
		p.vel *= 1.0 - 0.6 * delta
		p.pos += p.vel * delta
		p.rot += p.spin * delta
		p.life -= delta
		if p.life <= 0.0 or p.pos.y > size.y + 40.0:
			confetti.remove_at(i)
	for i in range(ripples.size() - 1, -1, -1):
		ripples[i].t += delta * 1.8
		if ripples[i].t >= 1.0:
			ripples.remove_at(i)
	queue_redraw()


# ------------------------------------------------------------ drawing helpers
func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


func _card(r: Rect2, fill: Color, radius: float, border: Color, bw: float, shadow: float = 0.0, shadow_col: Color = Color(0, 0, 0, 0.35)) -> void:
	sb.bg_color = fill
	sb.set_corner_radius_all(int(radius))
	sb.set_border_width_all(int(maxf(bw, 0.0)))
	sb.border_color = border
	sb.shadow_size = int(shadow)
	sb.shadow_color = shadow_col
	sb.shadow_offset = Vector2(0, shadow * 0.25)
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func _text(txt: String, center: Vector2, px: float, col: Color, bold: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var fs := int(px)
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := center.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	var pos := Vector2(center.x - w * 0.5, base)
	if bold:
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(1, int(px * 0.05)), col)
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _glow_line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	if a.distance_to(b) < 0.5:
		return
	var mult := [3.0, 2.1, 1.45]
	var alp := [0.07, 0.12, 0.2]
	for k in 3:
		var c := col
		c.a = col.a * float(alp[k])
		draw_line(a, b, c, w * float(mult[k]), true)
	draw_line(a, b, col, w, true)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)
	var hot := col.lerp(WHITE, 0.6)
	hot.a = col.a * 0.85
	draw_line(a, b, hot, w * 0.32, true)


func _glow_arc(c: Vector2, r: float, col: Color, w: float, t: float) -> void:
	if t <= 0.001:
		return
	var a0 := -PI * 0.5
	var a1 := a0 + TAU * t
	var mult := [3.0, 2.1, 1.45]
	var alp := [0.07, 0.12, 0.2]
	for k in 3:
		var gc := col
		gc.a = col.a * float(alp[k])
		draw_arc(c, r, a0, a1, 72, gc, w * float(mult[k]), true)
	draw_arc(c, r, a0, a1, 72, col, w, true)
	draw_circle(c + Vector2(cos(a0), sin(a0)) * r, w * 0.5, col)
	draw_circle(c + Vector2(cos(a1), sin(a1)) * r, w * 0.5, col)
	var hot := col.lerp(WHITE, 0.6)
	hot.a = col.a * 0.85
	draw_arc(c, r, a0, a1, 72, hot, w * 0.32, true)


# ------------------------------------------------------------ drawing
func _draw() -> void:
	if size.x < 2.0:
		return
	_draw_background()
	_draw_title()
	_draw_scores()
	_draw_status()
	_draw_board()
	_draw_buttons()
	_draw_confetti()


func _draw_background() -> void:
	var s := size
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0.0), s, Vector2(0.0, s.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOT, BG_BOT])
	)
	var orb_cols := [X_COL, O_COL, Color("8a5cff"), O_COL, X_COL]
	for i in 5:
		var ph := time * (0.18 + i * 0.05) + i * 1.7
		var pos := Vector2(s.x * (0.5 + 0.42 * sin(ph)), s.y * (0.5 + 0.40 * cos(ph * 0.8 + i)))
		var c: Color = orb_cols[i]
		c.a = 0.035
		for k in 4:
			draw_circle(pos, (260.0 - k * 55.0) * u, c)
	for st in stars:
		var tw := 0.5 + 0.5 * sin(time * 1.6 + st.z)
		draw_circle(Vector2(st.x * s.x, st.y * s.y), (1.2 + 1.4 * tw) * u, Color(1, 1, 1, 0.12 + 0.4 * tw))


func _draw_title() -> void:
	var t := "TIC  TAC  TOE"
	var font := ThemeDB.fallback_font
	var fs := int(56.0 * u)
	var spacing := 7.0 * u
	var widths: Array[float] = []
	var total := 0.0
	for ch in t:
		var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + spacing
		widths.append(cw)
		total += cw
	total -= spacing
	var x := size.x * 0.5 - total * 0.5
	var base := title_y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	for i in t.length():
		var col := X_COL.lerp(O_COL, float(i) / float(t.length() - 1))
		var pos := Vector2(x, base)
		var glow := Color(col.r, col.g, col.b, 0.2)
		draw_string_outline(font, pos, t[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(10.0 * u), glow)
		draw_string_outline(font, pos, t[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(1, int(3.0 * u)), col)
		draw_string(font, pos, t[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += widths[i]


func _draw_scores() -> void:
	var side := board_rect.size.x
	var gap := 16.0 * u
	var cw := (side - gap * 2.0) / 3.0
	var ch := 120.0 * u
	var labels := ["YOU" if vs_cpu else "PLAYER X", "DRAW", "CPU" if vs_cpu else "PLAYER O"]
	var vals := [score_x, score_d, score_o]
	var cols := [X_COL, Color("c9c4e8"), O_COL]
	for i in 3:
		var r := Rect2(board_rect.position.x + i * (cw + gap), score_y, cw, ch)
		var active := (not game_over) and ((i == 0 and turn == 1) or (i == 2 and turn == 2))
		var col: Color = cols[i]
		var pulse := 0.65 + 0.35 * sin(time * 4.0)
		var border := Color(col.r, col.g, col.b, pulse if active else 0.25)
		var fill := Color(col.r, col.g, col.b, 0.12 if active else 0.05)
		var glow := Color(col.r, col.g, col.b, 0.3)
		_card(r, fill, 24.0 * u, border, (3.0 if active else 1.5) * u, 18.0 * u if active else 0.0, glow)
		_text(str(labels[i]), Vector2(r.get_center().x, r.position.y + 34.0 * u), 22.0 * u, Color(col.r, col.g, col.b, 0.95))
		_text(str(vals[i]), Vector2(r.get_center().x, r.position.y + 82.0 * u), 54.0 * u, WHITE, true)


func _draw_status() -> void:
	var msg := ""
	var col := WHITE
	if game_over:
		if win_line.size() > 0:
			var w: int = board[win_line[0]]
			col = X_COL if w == 1 else O_COL
			if vs_cpu:
				msg = "You win!" if w == 1 else "CPU wins"
			else:
				msg = "Player %s wins!" % ("X" if w == 1 else "O")
		else:
			msg = "It's a draw"
			col = GOLD
	else:
		col = X_COL if turn == 1 else O_COL
		if vs_cpu:
			msg = "Your turn" if turn == 1 else "CPU is thinking" + ".".repeat(int(time * 3.0) % 4)
		else:
			msg = "Player %s's turn" % ("X" if turn == 1 else "O")
	var px := 42.0 * u
	var y := status_y
	if game_over:
		px *= 1.0 + 0.05 * sin(time * 6.0)
		y -= 8.0 * u
	_text(msg, Vector2(size.x * 0.5, y), px, col, true)
	if game_over:
		_text("tap the board to play again", Vector2(size.x * 0.5, status_y + 26.0 * u), 21.0 * u, Color(1, 1, 1, 0.55))


func _draw_board() -> void:
	_card(board_rect.grow(16.0 * u), Color(1, 1, 1, 0.045), 40.0 * u, Color(1, 1, 1, 0.12), 1.5 * u, 30.0 * u)
	for i in 9:
		var fill := Color(1, 1, 1, 0.07)
		if press_target == i and board[i] == 0 and not game_over:
			fill = Color(1, 1, 1, 0.17)
		if win_line.has(i) and win_t > 0.0:
			fill = Color(GOLD.r, GOLD.g, GOLD.b, 0.10 + 0.05 * sin(time * 6.0))
		_card(_cell_rect(i), fill, 26.0 * u, Color(1, 1, 1, 0.10), 1.5 * u)
	for rp in ripples:
		var rc := rp.col
		rc.a = 0.5 * (1.0 - rp.t)
		draw_arc(rp.pos, cell * (0.2 + 0.45 * rp.t), 0.0, TAU, 48, rc, 4.0 * u, true)
	for i in 9:
		if board[i] != 0:
			var dim := 1.0
			if game_over and win_line.size() > 0 and not win_line.has(i):
				dim = 0.4
			_draw_mark(i, dim)
	if game_over and win_line.size() > 0 and win_t > 0.0:
		_draw_win_line()


func _draw_mark(i: int, dim: float) -> void:
	var c := _cell_center(i)
	var t := ease_out_cubic(float(marks_t[i]))
	var r := cell * 0.27
	var w := 17.0 * u
	if board[i] == 1:
		var col := Color(X_COL.r, X_COL.g, X_COL.b, dim)
		var t1 := clampf(t * 2.0, 0.0, 1.0)
		var t2 := clampf(t * 2.0 - 1.0, 0.0, 1.0)
		var a1 := c + Vector2(-r, -r)
		var b1 := c + Vector2(r, r)
		var a2 := c + Vector2(r, -r)
		var b2 := c + Vector2(-r, r)
		_glow_line(a1, a1.lerp(b1, t1), col, w)
		if t2 > 0.0:
			_glow_line(a2, a2.lerp(b2, t2), col, w)
	else:
		var col := Color(O_COL.r, O_COL.g, O_COL.b, dim)
		_glow_arc(c, r * 1.12, col, w, t)


func _draw_win_line() -> void:
	var a := _cell_center(int(win_line[0]))
	var b := _cell_center(int(win_line[2]))
	var d := (b - a).normalized()
	a -= d * cell * 0.32
	b += d * cell * 0.32
	var tip := a.lerp(b, ease_out_cubic(win_t))
	var pulse := 1.0 + 0.12 * sin(time * 9.0)
	_glow_line(a, tip, GOLD, 12.0 * u * pulse)


func _draw_buttons() -> void:
	_button(btn_new, "NEW GAME", GOLD, press_target == HIT_NEW)
	_button(btn_mode, "VS CPU" if vs_cpu else "2 PLAYERS", O_COL, press_target == HIT_MODE)


func _button(r: Rect2, label: String, col: Color, pressed: bool) -> void:
	var rr := r
	if pressed:
		rr = r.grow(-4.0 * u)
	var fill := Color(col.r, col.g, col.b, 0.22 if pressed else 0.14)
	var border := Color(col.r, col.g, col.b, 0.85)
	var glow := Color(col.r, col.g, col.b, 0.25)
	_card(rr, fill, 28.0 * u, border, 2.5 * u, 16.0 * u, glow)
	_text(label, rr.get_center(), 28.0 * u, col.lerp(WHITE, 0.35), true)


func _draw_confetti() -> void:
	for p in confetti:
		var c := p.col
		c.a = clampf(p.life, 0.0, 1.0)
		draw_set_transform(p.pos, p.rot, Vector2(1.0, cos(p.life * 8.0 + p.spin)))
		draw_rect(Rect2(-p.size * 0.5, p.size), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
