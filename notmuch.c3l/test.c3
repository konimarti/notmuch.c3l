// c3c compile test.c3 notmuch.c3i -l notmuch                                                                            notmuch-c3/notmuch.c3l [15:15:32]
module nm;

import std::io;

/*
* TODOs: move foreach to a struct Tags as a method
*
*/
macro @foreach(tags; @body(tag)) {
	for (; nm::notmuch_tags_valid(tags); ) {
		@body(nm::notmuch_tags_get(tags));
		nm::notmuch_tags_move_to_next(tags);
	}
}

fn int main() {
	
	Notmuch_database_t *db;
	ZString db_path;
	ZString config_path;
	ZString profile;
	ZString err;

	// open database
	Status status = nm::notmuch_database_open_with_config (
				   db_path, // char* db_path
				   DatabaseMode.READONLY,
				   config_path, // char *config_path,
				   profile, // char *profile,
				   &db, &err);
	if (status == Status.SUCCESS) {
		io::printn("database: open");
	} else {
		io::printfn("database: failed to open: %s", err);
		return (int)status;
	}

	// handle tags
	Notmuch_tags_t *tags = nm::notmuch_database_get_all_tags(db);

	@foreach(tags; ZString tag) {
		io::printfn("tag: %s", (ZString)tag);
	};

	nm::notmuch_tags_destroy(tags);

	// close database
   	status = nm::notmuch_database_destroy(db);
	if (status == Status.SUCCESS) {
		io::printn("database: close");
	} else {
		io::printn("database: failed to close");
	}
	return (int)status;

}
