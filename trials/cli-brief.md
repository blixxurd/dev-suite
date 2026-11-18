We want a command-line tool that finds broken links in a folder of Markdown files, to run before publishing docs.

1. Given a folder, it checks every link to another file in that folder and every link to a heading, and lists the broken ones with file and line.
2. It works offline. Web links are counted, not fetched.
3. Output is readable by default, with `--json` for scripts.
4. Exit code 0 when nothing is broken, 1 when something is, 2 when it was called wrongly or couldn't read the folder.
5. Written in Python.

Not wanted: fixing links, checking web links, a config file.
