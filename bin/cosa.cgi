#!/bin/bash

# Chess Opening Study Aid

# $COSA is set in cosa-ui
. $COSA/lib/utils
. $COSA/cfg/cfg.sh
. $COSA/lib/web.sh

main() {
    echo 'Content-Type: text/html'
    echo
    cat <<__PAGE__
<html>
<head>
    <title>Welcome to COSA!</title>
</html>
<body>
    <b>Chess Opening Study Aid v$COSA_VERSION</b> ... <b>COSA</b> - <i>It's a thing</i> ...</br>
    <pre>
$(env | sort)
    </pre>
</body>
</html>
__PAGE__
}


QUERY_STRING


cv_gen_page '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page.html
cv_gen_page -r '4k2r/P2Nqpp1/1Q1Q1p2/2bb2n1/1p1pP3/6n1/1Q3P2/2KR3R' foo >~/tmp/page2.html



main
exit $?

# EOF
