# Notmuch bindings for C3

### Prerequisites

-   `libnotmuch` should be installed on your system. See [installation instructions](https://notmuchmail.org/#index7h2).

### Usage

```c3
[usage tbd]
```

### Notes

-   Notmuch functions are renamed as follows: `notmuch_threads_get` -> `notmuch::threads_get`.

-   Constant definitions (`#define ... ...` in C) keep the same name and value.

-   Most notmuch typedefs are converted to C3 types.

-   Prefix for enums are stripped `NOTMUCH_STATUS_SUCCESS` -> `SUCCESS`.

-   All string equivalents (e.g. `const char *`) are converted to ZStrings.
