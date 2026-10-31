extends RefCounted

const PHASE_ENDS = [35.0, 85.0, 235.0, 280.0, 300.0]

static func phase_limits(duration: float) -> Array:
	return PHASE_ENDS.map(func(v): return v * duration / 300.0)

static func phase_at(elapsed: float, limits: Array) -> int:
	for i in range(limits.size()):
		if elapsed < float(limits[i]): return i
	return 4
