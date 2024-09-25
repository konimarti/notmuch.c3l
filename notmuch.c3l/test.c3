// c3c compile test.c3 notmuch.c3i -l notmuch                                                                            notmuch-c3/notmuch.c3l [15:15:32]
module nm;

import std::io;

/*
* TODOs:
* - we have to explicitly cast the enums to be used?
*
*/


/*
macro @foreach(a; @body(index, value))
{
    for (int i = 0; i < a.len; i++)
    {
        @body(i, a[i]);
    }
}

fn void test()
{
    double[] a = { 1.0, 2.0, 3.0 };
    @foreach(a; int index, double value)
    {
        io::printfn("a[%d] = %f", index, value);
    };
}
*/

/* works nicely
macro @foreach(tags; @body(tag)) {
	for (; nm::notmuch_tags_valid(tags); nm::notmuch_tags_move_to_next(tags)) {
		 @body(nm::notmuch_tags_get(tags));
	}
}
*/

macro valid(list) {
	$if $typeof(list) == Notmuch_tags_t:
 		return nm::notmuch_tags_valid(list);
	$else
 		return @unreachable("not possible");
	$endif
}

macro next(list) {
	$if $typeof(list) == Notmuch_tags_t:
 		return nm::notmuch_tags_move_to_next(list);
	$else
 		return @unreachable("not possible");
	$endif
}

macro get(list) {
	$if $typeof(list) == Notmuch_tags_t:
 		return nm::notmuch_tags_get(list);
	$else
 		return @unreachable("not possible");
	$endif
}

macro @foreach(list; @body(tag)) {
	for (; valid(list); next(list)) {
		 @body(get(list));
	}
}

fn int main() {
	
	Notmuch_database_t *db;
	char *err;

	// open database
	Notmuch_status_t status = nm::notmuch_database_open_with_config ("/home/km/Documents/maildir",
				   (int)DatabaseMode.READONLY,
				   (char*)0, //char *config_path,
				   (char*)0, //char *profile,
				   &db, &err);
	if (status == (int)Status.SUCCESS) {
		io::printn("database: open");
	} else {
		io::printfn("database: failed to open: %s", err);
		return (int)status;
	}

	// handle tags
	Notmuch_tags_t *tags = nm::notmuch_database_get_all_tags(db);

	// while ((bool)nm::notmuch_tags_valid(tags)) {
	// 	char *tag = nm::notmuch_tags_get(tags);
	// 	io::printfn("tag: %s", (ZString)tag);
	// 	(void)nm::notmuch_tags_move_to_next(tags);
	// }

	@foreach(tags; char* tag) {
		io::printfn("tag: %s", (ZString)tag);
	};

	(void)nm::notmuch_tags_destroy(tags);

	// close database
   	status = nm::notmuch_database_destroy(db);
	if (status == (int)Status.SUCCESS) {
		io::printn("database: close");
	} else {
		io::printn("database: failed to close");
	}
	return status;

}
