# Notmuch bindings for C3

Notmuch bindings for C3 with a high-level C3 wrapper API.

### Requirements

-   `libnotmuch` should be installed on your system.
    See [installation instructions](https://notmuchmail.org/#index7h2).

### Setup

Add the path to the `notmuch.c3l` folder to `dependency-search-paths` and
`notmuch` to `dependencies` in your `project.json` file:

```json
{
    "dependency-search-paths": ["lib", "<path_to_notmuch.c3l_folder>"],
    "dependencies": ["notmuch"]
}
```

### Examples

#### Direct libnotmuch access

```c3
// c3c compile-run examples/low-level-api.c3 notmuch.c3i wrapper.c3 -l notmuch
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


```

#### High-level C3 API for notmuch

```c3
// c3c compile-run examples/high-level-api.c3 notmuch.c3i wrapper.c3 -l notmuch
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
```

### Notes

-   Notmuch functions are renamed as follows: `notmuch_threads_get` ->
    `notmuch::threads_get`.

-   Constant definitions (`#define ... ...` in C) keep the same name and value.

-   Most notmuch typedefs are converted to C3 types. Notmuch types are
    capitalized: `notmuch_status_t` -> `Notmuch_status_t`.

-   Prefix for enums are stripped `NOTMUCH_STATUS_SUCCESS` -> `SUCCESS`.

-   All string equivalents (e.g. `const char *`) are converted to ZStrings.
