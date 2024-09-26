module nm;

import notmuch;

/*
 * Aliases for notmuch enums
 *
 */
def Status = Notmuch_status_t;
def DatabaseMode = Notmuch_database_mode_t;

/*
 * Database
 *
 */
struct Database {
	Notmuch_database_t *db;
}

fn Status Database.create(&self, ZString path) {
	return notmuch::database_create (path, &self.db);
}

fn Status Database.destroy(&self) {
	return notmuch::database_destroy(self.db);
}

fn Status Database.open_with_config (&self, 
		ZString database_path,
		DatabaseMode mode,
		ZString config_path,
		ZString profile,
		ZString *error_message) {

	return notmuch::database_open_with_config(
				database_path,
				mode,
				config_path,
				profile,
				&self.db,
				error_message,
			);
}

fn Tags Database.get_all_tags(&self) {
	return Tags{notmuch::database_get_all_tags(self.db)};
}

/*
 * Tags
 *
 */
struct Tags {
	Notmuch_tags_t *tags;
}

fn void Tags.destroy(&self) {
	notmuch::tags_destroy(self.tags);
}

macro @foreach(tags; @body(tag)) {
	for (; notmuch::tags_valid(tags); ) {
		@body(notmuch::tags_get(tags));
		notmuch::tags_move_to_next(tags);
	}
}

