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
def QuerySyntax = Notmuch_query_syntax_t;

/*
 * Macros
 *
 */
macro bool @ok(status) => (status == Status.SUCCESS) ? true : false;

macro bool return_bool(b) => (b == notmuch::TRUE) ? true : false;

macro @foreach(iterator; @body(item)) {
	for (; iterator.valid(); iterator.next()) {
		@body(iterator.get());
	}
}

/*
 * Errors
 *
 */
fault Err {
	DATABASE_INDEX_FILE_FAILED,
	DATABASE_FIND_MESSAGE_FAILED,
	QUERY_WITH_SYNTAX_FAILED,
	QUERY_COUNT_THREADS_FAILED,
	QUERY_COUNT_MESSAGES_FAILED,
	QUERY_SEARCH_THREADS_FAILED,
	QUERY_SEARCH_MESSAGES_FAILED,
	MESSAGE_HAS_MAILDIR_FLAG_FAILED,
	MESSAGE_GET_FLAG_FAILED
}

/*
 * Database
 *
 */
struct Database {
	Notmuch_database_t *db;
	ZString err;
}

fn Status Database.create(&self, ZString path) {
	return notmuch::database_create(path, &self.db);
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

fn Status Database.begin_atomic(&self) {
	return notmuch::database_begin_atomic(self.db);
}

fn Status Database.end_atomic(&self) {
	return notmuch::database_end_atomic(self.db);
}

fn IndexOpts* Database.default_indexopts(&self) {
	return notmuch::database_get_default_indexopts(self.db);
}

fn Message! Database.index_file(&self, ZString filename, IndexOpts* opts) {
	Message m;
	Status s = notmuch::database_index_file(self.db, filename, opts, &m.message);
	if (s != Status.SUCCESS && s != Status.DUPLICATEMESSAGEID) {
		return Err.DATABASE_INDEX_FILE_FAILED?;
	}
	return m;
}

fn Message! Database.find_message(&self, ZString message_id) {
	Message m;
	Status s = notmuch::database_find_message(self.db, message_id, &m.message);
	if (!@ok(s)) {
		return Err.DATABASE_FIND_MESSAGE_FAILED?;
	}
	return m;
}

fn Message! Database.find_message_by_filename(&self, ZString filename) {
	Message m;
	Status s = notmuch::database_find_message_by_filename(self.db, filename, &m.message);
	if (!@ok(s)) {
		return Err.DATABASE_FIND_MESSAGE_FAILED?;
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

fn Query! Database.query_create_with_syntax(&self, ZString query_string, QuerySyntax syntax) {
	Query q;
	Status s = notmuch::query_create_with_syntax(self.db, query_string, syntax, &q.query);
	if (!@ok(s)) {
		return Err.QUERY_WITH_SYNTAX_FAILED?;
	}
	return q;
}


fn Tags Database.all_tags(&self) {
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
	Status status;
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
	if (!@ok(self.status)) {
		return Err.QUERY_SEARCH_THREADS_FAILED?;
	}
	return Threads{threads};
}

fn Messages! Query.search_messages(&self) {
	Notmuch_messages_t *messages;
	self.status = notmuch::query_search_messages(self.query, &messages);
	if (!@ok(self.status)) {
		return Err.QUERY_SEARCH_MESSAGES_FAILED?;
	}
	return Messages{messages};
}

fn uint! Query.count_threads(&self) {
	uint count;
	self.status = notmuch::query_count_threads(self.query, &count);
	if (!@ok(self.status)) {
		return Err.QUERY_COUNT_THREADS_FAILED?;
	}
	return count;
}

fn uint! Query.count_messages(&self) {
	uint count;
	self.status = notmuch::query_count_messages(self.query, &count);
	if (!@ok(self.status)) {
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

fn ZString Thread.thread_id(&self) {
	return notmuch::thread_get_thread_id(self.thread);
}

fn int Thread.total_messages(&self) {
	return notmuch::thread_get_total_messages(self.thread);
}

fn int Thread.total_files(&self) {
	return notmuch::thread_get_total_files(self.thread);
}

fn int Thread.matched_messages(&self) {
	return notmuch::thread_get_matched_messages(self.thread);
}

fn Messages Thread.toplevel_messages(&self) {
	Messages m;
	m.messages = notmuch::thread_get_toplevel_messages(self.thread);
	return m;
}

fn Messages Thread.messages(&self) {
	Messages m;
	m.messages = notmuch::thread_get_messages(self.thread);
	return m;
}

fn ZString Thread.authors(&self) {
	return notmuch::thread_get_authors(self.thread);
}

fn ZString Thread.subject(&self) {
	return notmuch::thread_get_subject(self.thread);
}

fn Time_t Thread.oldest_date(&self) {
	return notmuch::thread_get_oldest_date(self.thread);
}

fn Time_t Thread.newest_date(&self) {
	return notmuch::thread_get_newest_date(self.thread);
}

fn Tags Thread.tags(&self) {
	Tags t;
	t.tags = notmuch::thread_get_tags(self.thread);
	return t;
}

fn void Thread.destroy(&self) {
	notmuch::thread_destroy(self.thread);
}

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
	Status s = notmuch::message_get_flag_st(self.message, flag, &is_set);
	if (!@ok(s)) {
		return Err.MESSAGE_GET_FLAG_FAILED?;
	}
	return return_bool(is_set);
}

fn void Message.set_flag(&self, MessageFlag flag, bool value) {
	Notmuch_bool_t v = notmuch::FALSE;
	if (value) {
		v = notmuch::TRUE;
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
	Status s = notmuch::message_has_maildir_flag_st(self.message, flag, &is_set);
	if (!@ok(s)) {
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

