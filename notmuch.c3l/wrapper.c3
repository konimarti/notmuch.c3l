module nm;
import notmuch;
import libc;

/*
 * Aliases for notmuch enums
 *
 */
def Status = Notmuch_status_t;
def DatabaseMode = Notmuch_database_mode_t;
def Exclude = Notmuch_exclude_t;
def Sort = Notmuch_sort_t;
def MessageFlag = Notmuch_message_flag_t;
def IndexOpts = Notmuch_indexopts_t;

/*
 * Macros
 *
 */
macro @foreach(iterator; @body(item)) {
	for (; iterator.valid(); iterator.next()) {
		@body(iterator.get());
	}
}

macro bool @ok(status) => (status == Status.SUCCESS) ? true : false;

/*
 * Errors
 *
 */
fault Err {
	DATABASE_INDEX_FILE_FAILED,
	QUERY_COUNT_THREADS_FAILED,
	QUERY_COUNT_MESSAGES_FAILED,
	QUERY_SEARCH_THREADS_FAILED,
	QUERY_SEARCH_MESSAGES_FAILED,
	MESSAGE_HAS_MAILDIR_FLAG_FAILED,
	MESSAGE_GET_FLAG_FAILED
}

/*
 * Macros
 *
 */
macro bool return_bool(b) => (b == notmuch::TRUE) ? true : false;

/*
 * Database
 *
 */
struct Database {
	Notmuch_database_t *db;
	ZString err;
}

fn Status Database.create(&self, ZString path) {
	return notmuch::database_create (path, &self.db);
}

fn Status Database.destroy(&self) {
	return notmuch::database_destroy(self.db);
}

fn Status Database.open_with_config (&self, ZString database_path, 
	DatabaseMode mode,
	ZString config_path = ZString{}, 
	ZString profile = ZString{}
) {
	return notmuch::database_open_with_config(database_path, mode,
		config_path, profile, &self.db, &self.err);
}

fn Status Database.close(&self) {
	return notmuch::database_close(self.db);
}

fn Status Database.reopen(&self, DatabaseMode mode) {
	return notmuch::database_reopen(self.db, mode);
}

fn bool Database.needs_upgrade(&self) {
	return return_bool(notmuch::database_needs_upgrade(self.db));
}

fn Status Database.upgrade(&self, ProgressNotify pn, uptr closure) {
	return notmuch::database_upgrade(self.db, pn, closure);
}

fn IndexOpts* Database.get_default_indexopts(&self) {
	return notmuch::database_get_default_indexopts(self.db);
}

fn Message! Database.index_file(&self, ZString filename, IndexOpts* opts) {
	Message m;
	Notmuch_status_t s = notmuch::database_index_file(self.db, filename, opts, &m.message);
	if (s != Status.SUCCESS && s != Status.DUPLICATEMESSAGEID) {
		return Err.DATABASE_INDEX_FILE_FAILED?;
	}
	return m;
}

fn Status Database.remove_message(&self, ZString filename) {
	return notmuch::database_remove_message(self.db, filename);
}

fn Query Database.query_create(&self, ZString query_string) {
	Query q;
	q.query = notmuch::query_create(self.db, query_string);
	return q;
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

fn bool Tags.valid(&self) {
	return return_bool(notmuch::tags_valid(self.tags));
}

fn ZString Tags.get(&self) {
	return notmuch::tags_get(self.tags);
}

fn void Tags.next(&self) {
	notmuch::tags_move_to_next(self.tags);
}

fn void Tags.destroy(&self) {
	notmuch::tags_destroy(self.tags);
}

/*
 * Query
 *
 */
struct Query {
	Notmuch_query_t *query;
	Notmuch_status_t status;
}

fn void Query.set_omit_excluded(&self, Exclude omit_excluded) {
	notmuch::query_set_omit_excluded(self.query, omit_excluded);
}

fn void Query.set_sort(&self, Sort sort) {
	notmuch::query_set_sort(self.query, sort);
}

fn Status Query.add_tag_exclude(&self, ZString tag) {
	self.status = notmuch::query_add_tag_exclude(self.query, tag);
	return self.status;
}

fn Threads! Query.search_threads(&self) {
	Notmuch_threads_t *threads;
	self.status = notmuch::query_search_threads(self.query, &threads);
	if (self.status != Status.SUCCESS) {
		return Err.QUERY_SEARCH_THREADS_FAILED?;
	}
	return Threads{threads};
}

fn Messages! Query.search_messages(&self) {
	Notmuch_messages_t *messages;
	self.status = notmuch::query_search_messages(self.query, &messages);
	if (self.status != Status.SUCCESS) {
		return Err.QUERY_SEARCH_MESSAGES_FAILED?;
	}
	return Messages{messages};
}

fn uint! Query.count_threads(&self) {
	uint count;
	self.status = notmuch::query_count_threads(self.query, &count);
	if (self.status != Status.SUCCESS) {
		return Err.QUERY_COUNT_THREADS_FAILED?;
	}
	return count;
}

fn uint! Query.count_messages(&self) {
	uint count;
	self.status = notmuch::query_count_messages(self.query, &count);
	if (self.status != Status.SUCCESS) {
		return Err.QUERY_COUNT_THREADS_FAILED?;
	} 
	return count;
}

fn void Query.destroy(&self) {
	notmuch::query_destroy(self.query);
}

/*
 * Threads
 *
 */
struct Threads {
	Notmuch_threads_t *threads;
}

fn bool Threads.valid(&self) {
	return return_bool(notmuch::threads_valid(self.threads));
}

fn Thread Threads.get(&self) {
	Thread t;
	t.thread = notmuch::threads_get(self.threads);
	return t;
}

fn void Threads.next(&self) {
	notmuch::threads_move_to_next(self.threads);
}

fn void Threads.destroy(&self) {
	notmuch::threads_destroy(self.threads);
}

/*
 * Thread
 *
 */
 struct Thread {
	 Notmuch_thread_t *thread;
 }

 /* TODO
extern fn ZString thread_get_thread_id (Notmuch_thread_t *thread) @extern("notmuch_thread_get_thread_id");
extern fn int thread_get_total_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_total_messages");
extern fn int thread_get_total_files (Notmuch_thread_t *thread) @extern("notmuch_thread_get_total_files");
extern fn Notmuch_messages_t * thread_get_toplevel_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_toplevel_messages");
extern fn Notmuch_messages_t * thread_get_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_messages");
extern fn int thread_get_matched_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_matched_messages");
extern fn ZString thread_get_authors (Notmuch_thread_t *thread) @extern("notmuch_thread_get_authors");
extern fn ZString thread_get_subject (Notmuch_thread_t *thread) @extern("notmuch_thread_get_subject");
extern fn Time_t thread_get_oldest_date (Notmuch_thread_t *thread) @extern("notmuch_thread_get_oldest_date");
extern fn Time_t thread_get_newest_date (Notmuch_thread_t *thread) @extern("notmuch_thread_get_newest_date");
extern fn Notmuch_tags_t * thread_get_tags (Notmuch_thread_t *thread) @extern("notmuch_thread_get_tags");
extern fn void thread_destroy (Notmuch_thread_t *thread) @extern("notmuch_thread_destroy");
*/

/*
 * Messages
 *
 */
struct Messages {
	Notmuch_messages_t *messages;
}

fn Tags Messages.collect_tags(&self) {
	return Tags{notmuch::messages_collect_tags(self.messages)};
}

fn bool Messages.valid(&self) {
	return return_bool(notmuch::messages_valid(self.messages));
}

fn Message Messages.get(&self) {
	Message m;
	m.message = notmuch::messages_get(self.messages);
	return m;
}

fn void Messages.next(&self) {
	notmuch::messages_move_to_next(self.messages);
}

fn void Messages.destroy(&self) {
	notmuch::messages_destroy(self.messages);
}

/*
 * Message
 *
 */
struct Message {
	Notmuch_message_t *message;
}

fn ZString Message.message_id(&self) {
	return notmuch::message_get_message_id(self.message);
}

fn ZString Message.thread_id(&self) {
	return notmuch::message_get_thread_id(self.message);
}

fn Messages Message.replies(&self) {
	Messages msgs;
	msgs.messages = notmuch::message_get_replies(self.message);
	return msgs;
}

fn int Message.count_files(&self) {
	return notmuch::message_count_files(self.message);
}

fn ZString Message.filename(&self) {
	return notmuch::message_get_filename(self.message);
}

struct Filenames {
	Notmuch_filenames_t *filenames;
}

fn Filenames Message.filenames(&self) {
	Filenames names;
	names.filenames = notmuch::message_get_filenames(self.message);
	return names;
}

fn Status Message.reindex(&self, IndexOpts *opts) {
	return notmuch::message_reindex(self.message, opts);
}

fn bool! Message.flag(&self, MessageFlag flag) {
	Notmuch_bool_t is_set;
	Notmuch_status_t s = notmuch::message_get_flag_st(self.message, flag, &is_set);
	if (s != Status.SUCCESS) {
		return Err.MESSAGE_GET_FLAG_FAILED?;
	}
	return return_bool(is_set);
}

fn void Message.set_flag(&self, MessageFlag flag, bool value) {
	Notmuch_bool_t v = 0;
	if (value) {
		v = 1;
	}
	notmuch::message_set_flag(self.message, flag, v);
}

fn Time_t Message.date(&self) {
	return notmuch::message_get_date(self.message);
}

fn ZString Message.header(&self, ZString header) {
	return notmuch::message_get_header(self.message, header);
}

fn Tags Message.tags(&self) {
	return Tags{notmuch::message_get_tags(self.message)};
}

fn Status Message.add_tag(&self, ZString tag) {
	return notmuch::message_add_tag(self.message, tag);
}

fn Status Message.remove_tag(&self, ZString tag) {
	return notmuch::message_remove_tag(self.message, tag);
}

fn Status Message.remove_all_tag(&self) {
	return notmuch::message_remove_all_tags(self.message);
}

fn Status Message.maildir_flags_to_tags(&self) {
	return notmuch::message_maildir_flags_to_tags(self.message);
}

fn Status Message.tags_to_maildir_flags(&self) {
	return notmuch::message_tags_to_maildir_flags(self.message);
}

fn bool! Message.has_maildir_flag(&self, char flag) {
	Notmuch_bool_t is_set;
	Notmuch_status_t s = notmuch::message_has_maildir_flag_st(self.message, flag, &is_set);
	if (s != Status.SUCCESS) {
		return Err.MESSAGE_HAS_MAILDIR_FLAG_FAILED?;
	}
	return return_bool(is_set);
}

fn Status Message.freeze(&self) {
	return notmuch::message_freeze(self.message);
}

fn Status Message.thaw(&self) {
	return notmuch::message_thaw(self.message);
}

fn void Message.destroy(&self) {
	return notmuch::message_destroy(self.message);
}


/*
extern fn ZString status_to_string (Notmuch_status_t status) @extern("Notmuch_status_to_string");
extern fn Notmuch_status_t database_create (ZString path, Notmuch_database_t **database) @extern("notmuch_database_create");
extern fn Notmuch_status_t database_create_verbose (ZString path, Notmuch_database_t **database, ZString *error_message) @extern("notmuch_database_create_verbose");
extern fn Notmuch_status_t database_open (ZString path,
extern fn Notmuch_status_t database_open_verbose (ZString path,
extern fn Notmuch_status_t database_open_with_config (ZString database_path,
extern fn Notmuch_status_t database_load_config (ZString database_path,
extern fn Notmuch_status_t database_create_with_config (ZString database_path,
extern fn ZString database_status_string (Notmuch_database_t *notmuch) @extern("notmuch_database_status_string");
extern fn Notmuch_status_t database_close (Notmuch_database_t *database) @extern("notmuch_database_close");
extern fn Notmuch_status_t database_compact (ZString path,
extern fn Notmuch_status_t database_compact_db (Notmuch_database_t *database,
extern fn Notmuch_status_t database_destroy (Notmuch_database_t *database) @extern("notmuch_database_destroy");
extern fn ZString database_get_path (Notmuch_database_t *database) @extern("notmuch_database_get_path");
extern fn uint database_get_version (Notmuch_database_t *database) @extern("notmuch_database_get_version");
extern fn Notmuch_bool_t database_needs_upgrade (Notmuch_database_t *database) @extern("notmuch_database_needs_upgrade");
extern fn Notmuch_status_t database_upgrade (Notmuch_database_t *database, ProgressNotify pn,
extern fn Notmuch_status_t database_begin_atomic (Notmuch_database_t *notmuch) @extern("notmuch_database_begin_atomic");
extern fn Notmuch_status_t database_end_atomic (Notmuch_database_t *notmuch) @extern("notmuch_database_end_atomic");
extern fn ulong database_get_revision (Notmuch_database_t *notmuch,
extern fn Notmuch_status_t database_get_directory (Notmuch_database_t *database,
extern fn Notmuch_status_t database_index_file (Notmuch_database_t *database,
extern fn Notmuch_status_t
extern fn Notmuch_status_t database_remove_message (Notmuch_database_t *database,
extern fn Notmuch_status_t
extern fn Notmuch_status_t database_find_message_by_filename (Notmuch_database_t *notmuch,
extern fn Notmuch_tags_t * database_get_all_tags (Notmuch_database_t *db) @extern("notmuch_database_get_all_tags");
extern fn Notmuch_status_t database_reopen (Notmuch_database_t *db, Notmuch_database_mode_t mode) @extern("notmuch_database_reopen");

extern fn Notmuch_query_t * query_create (Notmuch_database_t *database,
extern fn Notmuch_status_t query_create_with_syntax (Notmuch_database_t *database,
extern fn ZString query_get_query_string (Notmuch_query_t *query) @extern("notmuch_query_get_query_string");
extern fn Notmuch_database_t * query_get_database (Notmuch_query_t *query) @extern("notmuch_query_get_database");
extern fn void query_set_omit_excluded (Notmuch_query_t *query,
extern fn void query_set_sort (Notmuch_query_t *query, Notmuch_sort_t sort) @extern("notmuch_query_set_sort");
extern fn Notmuch_sort_t query_get_sort (Notmuch_query_t *query) @extern("notmuch_query_get_sort");
extern fn Notmuch_status_t query_add_tag_exclude (Notmuch_query_t *query, ZString tag) @extern("notmuch_query_add_tag_exclude");
extern fn Notmuch_status_t query_search_threads (Notmuch_query_t *query, Notmuch_threads_t **out) @extern("notmuch_query_search_threads");
extern fn Notmuch_status_t query_search_messages (Notmuch_query_t *query, Notmuch_messages_t **out) @extern("notmuch_query_search_messages");
extern fn void query_destroy (Notmuch_query_t *query) @extern("notmuch_query_destroy");

extern fn Notmuch_bool_t threads_valid (Notmuch_threads_t *threads) @extern("notmuch_threads_valid");
extern fn Notmuch_thread_t * threads_get (Notmuch_threads_t *threads) @extern("notmuch_threads_get");
extern fn void threads_move_to_next (Notmuch_threads_t *threads) @extern("notmuch_threads_move_to_next");
extern fn void threads_destroy (Notmuch_threads_t *threads) @extern("notmuch_threads_destroy");

extern fn Notmuch_status_t query_count_messages (Notmuch_query_t *query, uint *count) @extern("notmuch_query_count_messages");
extern fn Notmuch_status_t query_count_messages_st (Notmuch_query_t *query, uint *count) @extern("notmuch_query_count_messages_st") @deprecated;
extern fn Notmuch_status_t query_count_threads (Notmuch_query_t *query, uint *count) @extern("notmuch_query_count_threads");
extern fn Notmuch_status_t query_count_threads_st (Notmuch_query_t *query, uint *count) @extern("notmuch_query_count_threads_st") @deprecated;

extern fn ZString thread_get_thread_id (Notmuch_thread_t *thread) @extern("notmuch_thread_get_thread_id");
extern fn int thread_get_total_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_total_messages");
extern fn int thread_get_total_files (Notmuch_thread_t *thread) @extern("notmuch_thread_get_total_files");
extern fn Notmuch_messages_t * thread_get_toplevel_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_toplevel_messages");
extern fn Notmuch_messages_t * thread_get_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_messages");
extern fn int thread_get_matched_messages (Notmuch_thread_t *thread) @extern("notmuch_thread_get_matched_messages");
extern fn ZString thread_get_authors (Notmuch_thread_t *thread) @extern("notmuch_thread_get_authors");
extern fn ZString thread_get_subject (Notmuch_thread_t *thread) @extern("notmuch_thread_get_subject");
extern fn Time_t thread_get_oldest_date (Notmuch_thread_t *thread) @extern("notmuch_thread_get_oldest_date");
extern fn Time_t thread_get_newest_date (Notmuch_thread_t *thread) @extern("notmuch_thread_get_newest_date");
extern fn Notmuch_tags_t * thread_get_tags (Notmuch_thread_t *thread) @extern("notmuch_thread_get_tags");
extern fn void thread_destroy (Notmuch_thread_t *thread) @extern("notmuch_thread_destroy");

extern fn Notmuch_bool_t messages_valid (Notmuch_messages_t *messages) @extern("notmuch_messages_valid");
extern fn Notmuch_message_t * messages_get (Notmuch_messages_t *messages) @extern("notmuch_messages_get");
extern fn void messages_move_to_next (Notmuch_messages_t *messages) @extern("notmuch_messages_move_to_next");
extern fn void messages_destroy (Notmuch_messages_t *messages) @extern("notmuch_messages_destroy");
extern fn Notmuch_tags_t * messages_collect_tags (Notmuch_messages_t *messages) @extern("notmuch_messages_collect_tags");

extern fn Notmuch_database_t * message_get_database (Notmuch_message_t *message) @extern("notmuch_message_get_database");
extern fn ZString message_get_message_id (Notmuch_message_t *message) @extern("notmuch_message_get_message_id");
extern fn ZString message_get_thread_id (Notmuch_message_t *message) @extern("notmuch_message_get_thread_id");
extern fn Notmuch_messages_t * message_get_replies (Notmuch_message_t *message) @extern("notmuch_message_get_replies");
extern fn int message_count_files (Notmuch_message_t *message) @extern("notmuch_message_count_files");
extern fn ZString message_get_filename (Notmuch_message_t *message) @extern("notmuch_message_get_filename");
extern fn Notmuch_filenames_t * message_get_filenames (Notmuch_message_t *message) @extern("notmuch_message_get_filenames");
extern fn Notmuch_status_t message_reindex (Notmuch_message_t *message,
extern fn Notmuch_bool_t message_get_flag (Notmuch_message_t *message,
extern fn Notmuch_status_t message_get_flag_st (Notmuch_message_t *message,
extern fn void message_set_flag (Notmuch_message_t *message,
extern fn Time_t message_get_date (Notmuch_message_t *message) @extern("notmuch_message_get_date");
extern fn ZString message_get_header (Notmuch_message_t *message, ZString header) @extern("notmuch_message_get_header");
extern fn Notmuch_tags_t * message_get_tags (Notmuch_message_t *message) @extern("notmuch_message_get_tags");
extern fn Notmuch_status_t message_add_tag (Notmuch_message_t *message, ZString tag) @extern("notmuch_message_add_tag");
extern fn Notmuch_status_t message_remove_tag (Notmuch_message_t *message, ZString tag) @extern("notmuch_message_remove_tag");
extern fn Notmuch_status_t message_remove_all_tags (Notmuch_message_t *message) @extern("notmuch_message_remove_all_tags");
extern fn Notmuch_status_t message_maildir_flags_to_tags (Notmuch_message_t *message) @extern("notmuch_message_maildir_flags_to_tags");
extern fn Notmuch_bool_t message_has_maildir_flag (Notmuch_message_t *message, char flag) @extern("notmuch_message_has_maildir_flag") @deprecated;
extern fn Notmuch_status_t message_has_maildir_flag_st (Notmuch_message_t *message, char flag, Notmuch_bool_t *is_set) @extern("notmuch_message_has_maildir_flag_st");
extern fn Notmuch_status_t message_tags_to_maildir_flags (Notmuch_message_t *message) @extern("notmuch_message_tags_to_maildir_flags");
extern fn Notmuch_status_t message_freeze (Notmuch_message_t *message) @extern("notmuch_message_freeze");
extern fn Notmuch_status_t message_thaw (Notmuch_message_t *message) @extern("notmuch_message_thaw");
extern fn void message_destroy (Notmuch_message_t *message) @extern("notmuch_message_destroy");

extern fn Notmuch_status_t message_get_property (Notmuch_message_t *message, ZString key, ZString *value) @extern("notmuch_message_get_property");
extern fn Notmuch_status_t message_add_property (Notmuch_message_t *message, ZString key, ZString value) @extern("notmuch_message_add_property");
extern fn Notmuch_status_t message_remove_property (Notmuch_message_t *message, ZString key, ZString value) @extern("notmuch_message_remove_property");
extern fn Notmuch_status_t message_remove_all_properties (Notmuch_message_t *message, ZString key) @extern("notmuch_message_remove_all_properties");
extern fn Notmuch_status_t message_remove_all_properties_with_prefix (Notmuch_message_t *message, ZString prefix) @extern("notmuch_message_remove_all_properties_with_prefix");
extern fn Notmuch_status_t message_count_properties (Notmuch_message_t *message, ZString key, uint *count) @extern("notmuch_message_count_properties");
extern fn Notmuch_message_properties_t * message_get_properties (Notmuch_message_t *message, ZString key, Notmuch_bool_t exact) @extern("notmuch_message_get_properties");

extern fn Notmuch_bool_t message_properties_valid (Notmuch_message_properties_t *properties) @extern("notmuch_message_properties_valid");
extern fn void message_properties_move_to_next (Notmuch_message_properties_t *properties) @extern("notmuch_message_properties_move_to_next");
extern fn ZString message_properties_key (Notmuch_message_properties_t *properties) @extern("notmuch_message_properties_key");
extern fn ZString message_properties_value (Notmuch_message_properties_t *properties) @extern("notmuch_message_properties_value");
extern fn void message_properties_destroy (Notmuch_message_properties_t *properties) @extern("notmuch_message_properties_destroy");
*/
