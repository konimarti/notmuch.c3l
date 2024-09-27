// c3c compile-run examples/high-level-api.c3 notmuch.c3i wrapper.c3 -l notmuch                                          notmuch-c3/notmuch.c3l [14:30:20]
import std::io;
import nm;

fn void main() {
	Database d;
	ZString database_path;

	// open database
	Status s = d.open_with_config(database_path, DatabaseMode.READONLY);
	if (!nm::@ok(s)) {
		io::printfn("database: failed to open: %s (%s)", d.err, s);
		return;
	}
	defer {
		// destroy database
		s = d.destroy();
		if (!nm::@ok(s)) {
			io::printfn("database: failed to close: %s", s);
		}
	}

	// list all tags in the database
	Tags tags = d.all_tags();
	defer tags.destroy();

	nm::@foreach(tags; ZString tag) {
		io::printfn("tag: %s", tag);
	};

	// query messages
	ZString query_string = "tag:inbox";
	Query q = d.query_create(query_string);
	defer q.destroy();

	// count messages in query
	uint! count = q.count_messages();
	if (catch excuse = count) {
		io::printfn("query: count messages failed: %s (status: %s)", excuse, q.status);
	} else {
		io::printfn("\nquery '%s' contains %d messages.\n", query_string, count);
	}

	// print subject line for each message in query
	Messages! msgs = q.search_messages();
	if (catch excuse = msgs) {
		io::printfn("query: search messages failed: %s", excuse);
		return;
	} 
	defer msgs.destroy();

	nm::@foreach(msgs; Message m) {
		io::printfn("subject: %s", m.header("subject"));
	};
}
