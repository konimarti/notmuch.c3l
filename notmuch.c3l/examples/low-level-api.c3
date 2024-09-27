// c3c compile-run examples/high-level-api.c3 notmuch.c3i wrapper.c3 -l notmuch                                          notmuch-c3/notmuch.c3l [14:30:20]
import std::io;
import notmuch;

fn void main() {
	Notmuch_database_t *d;
	ZString database_path;
	ZString config_path;
	ZString profile;
	ZString err;

	// open database
	Notmuch_status_t s = notmuch::database_open_with_config(database_path,
		Notmuch_database_mode_t.READONLY, config_path, profile, &d, &err);
	if (s != Notmuch_status_t.SUCCESS) {
		io::printfn("database: failed to open: %s (%s)", err, s);
		return;
	}
	defer {
		// destroy database
		s = notmuch::database_destroy(d);
		if (s != Notmuch_status_t.SUCCESS) {
			io::printfn("database: failed to close: %s", s);
		}
	}

	// list all tags in the database
	Notmuch_tags_t *tags = notmuch::database_get_all_tags(d);
	defer notmuch::tags_destroy(tags);

	for (; notmuch::tags_valid(tags); notmuch::tags_move_to_next(tags)) {
		io::printfn("tag: %s",notmuch::tags_get(tags));
	}
}
