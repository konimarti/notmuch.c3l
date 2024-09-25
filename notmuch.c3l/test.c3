// c3c compile test.c3 notmuch.c3i -l notmuch                                                                            notmuch-c3/notmuch.c3l [15:15:32]
module nm;

import std::io;

/*
* TODOs:
* - we have to explicitly cast the enums to be used?
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
	char *err;

	// open database
	Notmuch_status_t status = nm::notmuch_database_open_with_config (
				   (char*)0, // char* db_path
				   DatabaseMode.READONLY,
				   (char*)0, // char *config_path,
				   (char*)0, // char *profile,
				   &db, &err);
	if (status == (int)Status.SUCCESS) {
		io::printn("database: open");
	} else {
		io::printfn("database: failed to open: %s", err);
		return (int)status;
	}

	// handle tags
	Notmuch_tags_t *tags = nm::notmuch_database_get_all_tags(db);

	@foreach(tags; char* tag) {
		io::printfn("tag: %s", (ZString)tag);
	};

	nm::notmuch_tags_destroy(tags);

	// close database
   	status = nm::notmuch_database_destroy(db);
	if (status == (int)Status.SUCCESS) {
		io::printn("database: close");
	} else {
		io::printn("database: failed to close");
	}
	return status;

}
