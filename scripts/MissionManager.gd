extends RefCounted

const PHASE_ENDS = [35.0, 85.0, 235.0, 280.0, 300.0]

static func phase_limits(duration: float) -> Array:
	return PHASE_ENDS.map(func(v): return v * duration / 300.0)

static func phase_at(elapsed: float, limits: Array) -> int:
	for i in range(limits.size()):
		if elapsed < float(limits[i]): return i
	return 4

# Two warm-up, two workshop, then battle and two final boss examples.
static func question_phase(completed: int, target: int) -> int:
	if completed >= target: return 4
	if completed >= target - 2: return 3
	if completed >= 4: return 2
	if completed >= 2: return 1
	return 0
