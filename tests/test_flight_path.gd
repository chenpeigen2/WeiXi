extends "res://tests/test_case.gd"

const FlightPath = preload("res://src/ui/flight_path.gd")


func test_length_single_segment() -> void:
	assert_eq(FlightPath.length(PackedVector2Array([Vector2(0, 0), Vector2(3, 4)])), 5.0, "3-4-5")


func test_sample_midpoint() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(3, 4)])
	assert_vec_near(FlightPath.sample(p, 2.5), Vector2(1.5, 2.0), "中点")


func test_sample_across_segments() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	assert_vec_near(FlightPath.sample(p, 15.0), Vector2(10, 5), "拐到第二段")


func test_sample_clamps_to_ends() -> void:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	assert_vec_near(FlightPath.sample(p, -5.0), Vector2(0, 0), "负距离取起点")
	assert_vec_near(FlightPath.sample(p, 99.0), Vector2(10, 0), "超程取终点")


func test_sample_empty_path() -> void:
	assert_vec_near(FlightPath.sample(PackedVector2Array(), 3.0), Vector2.ZERO)
