class_name CardReader
extends Node

## Reads the cards locked during the preparation phase, one slot at a time, and
## loops back to the first card after a reload pause. Pure logic: it plays
## nothing itself, it only announces what it reads (CombatRuntime plays the
## effects, the UI draws the playhead).

signal slot_entered(card_index: int, slot_index: int, plays: bool)
signal card_played(instance: CardInstance, card_index: int)
signal loop_completed(loop_count: int)
## The current slot ends (before the next one, or before a reload).
signal slot_exited(card_index: int, slot_index: int)
## The whole track was read: nothing plays for `duration` seconds, then it restarts.
signal reload_started(duration: float)
signal reload_finished

## Tempo of the room. The reader advances one slot every `beats_per_slot` beats,
## so 120 BPM with 3 beats per slot = one slot every 1.5 s.
@export var bpm: float = 80.0
@export var beats_per_slot: float = 1.5
## Pause after the last card before the track is read again.
@export var reload_duration: float = 2.5

var sequence: Array[CardInstance] = []
var card_index: int = 0
var slot_index: int = 0
var loop_count: int = 0
var is_running: bool = false
var is_reloading: bool = false

var _elapsed: float = 0.0

func get_slot_duration() -> float:
	return 60.0 / maxf(bpm, 1.0) * maxf(beats_per_slot, 0.01)

## Progress inside the current slot, 0 to 1. Used to animate the playhead.
func get_slot_progress() -> float:
	return clampf(_elapsed / get_slot_duration(), 0.0, 1.0)

## Progress of the reload, 0 to 1 (0 when not reloading).
func get_reload_progress() -> float:
	return clampf(_elapsed / reload_duration, 0.0, 1.0) if is_reloading and reload_duration > 0.0 else 0.0

func set_sequence(new_sequence: Array[CardInstance]) -> void:
	sequence = new_sequence
	reset()

func reset() -> void:
	card_index = 0
	slot_index = 0
	loop_count = 0
	_elapsed = 0.0
	is_reloading = false

func start() -> void:
	if sequence.is_empty():
		return
	is_running = true
	_elapsed = 0.0
	_enter_current_slot()

func stop() -> void:
	is_running = false

func _process(delta: float) -> void:
	if not is_running or sequence.is_empty():
		return
	_elapsed += delta
	# Accumulator instead of a Timer: no drift, and a lag spike does not swallow a slot.
	while true:
		if is_reloading:
			if _elapsed < reload_duration:
				return
			_elapsed -= reload_duration
			is_reloading = false
			reload_finished.emit()
			_enter_current_slot()
			continue
		if _elapsed < get_slot_duration():
			return
		_elapsed -= get_slot_duration()
		slot_exited.emit(card_index, slot_index)
		if _step_cursor():
			is_reloading = true
			reload_started.emit(reload_duration)
		else:
			_enter_current_slot()

## Returns true when the whole track was read (the reader is back on the first card).
func _step_cursor() -> bool:
	slot_index += 1
	if slot_index < _current_slot_count():
		return false
	slot_index = 0
	card_index += 1
	if card_index < sequence.size():
		return false
	card_index = 0
	loop_count += 1
	loop_completed.emit(loop_count)
	return true

func _enter_current_slot() -> void:
	# The temporality is read again on every pass: a card may have changed it.
	card_index = wrapi(card_index, 0, sequence.size())
	var instance := sequence[card_index]
	slot_index = wrapi(slot_index, 0, instance.slot_count())
	var plays := instance.plays_at(slot_index)
	slot_entered.emit(card_index, slot_index, plays)
	if plays:
		card_played.emit(instance, card_index)

func _current_slot_count() -> int:
	if sequence.is_empty():
		return 1
	return sequence[wrapi(card_index, 0, sequence.size())].slot_count()
