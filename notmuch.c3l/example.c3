// c3c compile test.c3 notmuch.c3i -l notmuch                                                                            notmuch-c3/notmuch.c3l [15:15:32]
import std::io;
import nm;

fn int main() {
	Status s;
	Database d;
	ZString database_path;

	// open database
	s = d.open_with_config(database_path, DatabaseMode.READONLY);
	if (s == Status.SUCCESS) {
		io::printn("database: open");
	} else {
		io::printfn("database: failed to open: %s", d.err);
		return (int)s;
	}

	{|
		// list all tags in the database
		Tags tags = d.get_all_tags();
		defer tags.destroy();
		nm::@foreach(tags; ZString tag) {
			io::printfn("tag: %s", tag);
		};
	|};

	{|
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

		Messages! msgs = q.search_messages();
		if (catch excuse = msgs) {
			io::printfn("query: search messages failed: %s", excuse);
			return;
		}
		defer msgs.destroy();

		nm::@foreach(msgs; Message m) {
			io::printfn("subject: %s", m.header("subject"));
		};
	|};

	// close database
   	s = d.destroy();
	if (s == Status.SUCCESS) {
		io::printn("database: close");
	} else {
		io::printn("database: failed to close");
	}
	return (int)s;

}
