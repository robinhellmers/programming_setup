#!/bin/bash


define(){ IFS=$'\n' read -r -d '' ${1} || true; }

# PS1_original='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m'\
# '\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

define CONTENT <<'EOF'
PS1_custom='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\['\
'\033[01;34m\]\w\[\033[00m\]\$ '
EOF

FILENAME='/home/private/git-repos/programming_setup/testfile'


exists_in_file()
{
    FILENAME="$1"
    FILECONTENT=$(<$1)
    CONTENT_TO_CHECK="$2"

    echo "CONTENT TO CHECK:"
    echo "$line"
    echo ""

    echo "$FILECONTENT" | grep -Fxn "$line" --color
}




# while IFS= read -r line
# do
#     echo "*************************************************************"
#     exists_in_file "$FILENAME" "$line"
# done <<< "$CONTENT"

echo "FILECONTENT:"
echo "$FILECONTENT"

echo "CONTENT:"
echo "$CONTENT"

# Replace backslashes with double backslashes
# CONTENT=$(echo "$CONTENT" | sed 's/\\/\\\\/g')
# awk -v n=8 -v s="$CONTENT" 'NR == n {print s} {print}' testfile > outfile



SED_CONTENT=$(echo "$CONTENT" | sed 's/\\/\\\\/g')
echo "Replaced all backlashes with double"
echo "$SED_CONTENT"
SED_CONTENT=$(echo "$SED_CONTENT" | sed -E 's/[\\\\]$/\\\\/gm')
echo "Replaced last backslash with extra backslash:"
echo "$SED_CONTENT"

echo "sed CONTENT:"
echo "$SED_CONTENT"

sed -i "15i $SED_CONTENT" $FILENAME