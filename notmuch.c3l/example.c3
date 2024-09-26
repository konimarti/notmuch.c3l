// c3c compile test.c3 notmuch.c3i -l notmuch                                                                            notmuch-c3/notmuch.c3l [15:15:32]
import std::io;
import nm;

fn int main() {
	Status s;
	Database d;
	ZString err;

	// open database
	s = d.open_with_config("", DatabaseMode.READONLY, "", "", &err);
	if (s == Status.SUCCESS) {
		io::printn("database: open");
	} else {
		io::printfn("database: failed to open: %s", err);
		return (int)s;
	}

	// handle tags
	Tags tags = d.get_all_tags();
	nm::@foreach(tags.tags; ZString tag) {
		io::printfn("tag: %s", tag);
	};
	tags.destroy();

	// close database
   	s = d.destroy();
	if (s == Status.SUCCESS) {
		io::printn("database: close");
	} else {
		io::printn("database: failed to close");
	}
	return (int)s;

}
