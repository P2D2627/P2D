class_name CsvLog
extends RefCounted

## A log on disk for playtests, as CSV: each call adds one line at the end, and a new file starts
## with header. An empty path keeps no log; one that cannot be written says so in a warning, and
## the game goes on. Offers logs the answers to the offers with it, and RunStats the deaths.


static func append(path: String, header: String, line: String) -> void:
	if path.is_empty():
		return
	var is_new: bool = not FileAccess.file_exists(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE if is_new else FileAccess.READ_WRITE)
	if file == null:
		push_warning("CsvLog: the log %s cannot be written (%s)."
				% [path, error_string(FileAccess.get_open_error())])
		return
	if is_new:
		file.store_line(header)
	file.seek_end()
	file.store_line(line)
