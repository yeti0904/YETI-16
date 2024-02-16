module yeti16.types;

import std.format;

struct Vec2(T) {
	T x, y;

	this(T px, T py) {
		x = px;
		y = py;
	}

	string toString() {
		return format("(%s, %s)", x, y);
	}
}
