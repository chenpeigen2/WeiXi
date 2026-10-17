extends "res://tests/test_case.gd"

const StickerBook = preload("res://src/logic/sticker_book.gd")


func test_unlock_and_persist_roundtrip() -> void:
	var path := "user://test_stickers_%d.cfg" % Time.get_ticks_usec()
	var book := StickerBook.new(path)
	assert_eq(book.count(), 0)
	assert_eq(book.unlock_next(), 0)
	assert_eq(book.unlock_next(), 1)
	assert_eq(book.count(), 2)

	var reloaded := StickerBook.new(path)
	assert_eq(reloaded.count(), 2, "重新加载保留贴纸")
	assert_true(reloaded.is_unlocked(0))
	assert_true(reloaded.is_unlocked(1))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_unlock_caps_at_total() -> void:
	var path := "user://test_stickers_cap_%d.cfg" % Time.get_ticks_usec()
	var book := StickerBook.new(path)
	for i in range(StickerBook.TOTAL):
		assert_eq(book.unlock_next(), i)
	assert_eq(book.unlock_next(), -1, "集齐后不再解锁")
	assert_eq(book.count(), StickerBook.TOTAL)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
