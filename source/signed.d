module yeti16.signed;

short ToSigned(ushort value) {
	if (value & 0x8000) {
		return cast(short) -(cast(short) (~value + 1));
	}
	else {
		return cast(short) value;
	}
}

ushort ToUnsigned(short value) {
	if (value >= 0) {
		return cast(ushort) value;
	}
	else {
		return cast(short) ~(cast(ushort) (-value) + 1);
	}
}
