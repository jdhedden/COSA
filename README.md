### Chess Opening Study Aid
#### *COSA ... It's a thing*
The **Chess Opening Study Aid** is a command line tool written in Bash for
building personal databases of chess openings and games.  Additionally, it
provides a front-end to the **Stockfish** chess engine for analyzing board
positions.

#### Quick Start
1.  *cd* into the repository directory.
2.  Run *bin/cosa.sh*.  This will open the default *Openings* database, and
display the single sample opening.
3.  Type *help* for the list of commands.

A web UI is provided which uses the *httpd* feature of
[busybox](https://busybox.net).  After installing *busybox*, *cd* into the
repository directory, and then run *bin/cosa-ui*.

#### Development Status
This software is at a *beta* maturity level.  It is functional, robust, and
there are currently no known bugs.  (Though, my development motto is "There's
always one more bug.") All of the intended features are fully implemented, and
I use it for my own personal chess study.

What is missing is mostly documentation and *how to*s/tutorials.

#### Keywords (for ye olde search engines)

* Chess / Stockfish
* Bash / Shell / Terminal / Command line
* Tree data structure (implemented in lib/utils_tree)

###### EOF
