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

#### Changelog

* Version 0.7.2 - 2019-12-03
    * Changed command for starting a new line of study

* Version 0.7.1 - 2019-12-02
    * Fix line truncation
    * Fix line selection
    * Fix version

* Version 0.6.0 - 2019-12-01
    * Capability to add a new line on start
    * Added web interface debugging mode
    * Fixes to web interface

* Version 0.5.0 - 2019-10-13
    * Web interface

* Version 0.4.1 - 2019-10-09
    * Fixes to DB saves and engine move processing

* Version 0.4.0 - 2019-10-08
    * Handle full algebraic notation (from search engines)

* Version 0.3.0 - 2019-10-08
    * Fix en passant captures

* Version 0.2.0 - 2019-10-03
    * Command to cleanup logs and/or engine result file
    * Added command line usage

* Version 0.1.0 - 2019-10-02
    * Case-insensitivity for moves

* Version 0.0.0 - 2019-09-20
    * Extracted configurable items to cfg/cfg.sh
    * Added cfg/my_cfg.sh for user configuration customizations
    * Miscellaneous cleanups
    * Added versioning

* 2019-09-20
    * Initial import to github

#### Keywords (for ye olde search engines)

* Chess / Stockfish
* Bash / Shell / Terminal / Command line
* Tree data structure (implemented in lib/utils_tree)

###### EOF
