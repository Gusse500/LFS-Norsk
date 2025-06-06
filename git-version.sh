#!/bin/bash

if [ "$1" = sysv ]; then
    SYSV="INCLUDE"
    SYSTEMD="IGNORE "
elif [ "$1" = systemd ]; then
    SYSV="IGNORE "
    SYSTEMD="INCLUDE"
else
    echo You must provide either \"sysv\" or \"systemd\" as argument
    exit 1
fi

echo "<!ENTITY % sysv    \"$SYSV\">"     >  conditional.ent
echo "<!ENTITY % systemd \"$SYSTEMD\">"  >> conditional.ent

if [ -e LFS-RELEASE ]; then
	exit 0
fi

if ! git status > /dev/null; then
    # Either it's not a git repository or git is unavailable.
    # Just workaround.
    echo "<![ %sysv; ["                                    >  version.ent
    echo "<!ENTITY version           \"unknown\">"         >> version.ent
    echo "]]>"                                             >> version.ent
    echo "<![ %systemd; ["                                 >> version.ent
    echo "<!ENTITY version           \"unknown-systemd\">" >> version.ent
    echo "]]>"                                             >> version.ent
    echo "<!ENTITY releasedate       \"unknown\">"         >> version.ent
    echo "<!ENTITY copyrightdate     \"1999-2023\">"       >> version.ent
    exit 0
fi

export LC_ALL=nb_NO.utf8
export TZ=Europe/Oslo

commit_date=$(git show -s --format=format:"%cd" --date=local)

year=$(date --date "$commit_date" "+%Y")
month=$(date --date "$commit_date" "+%B")
month_digit=$(date --date "$commit_date" "+%m")
day=$(date --date "$commit_date" "+%d" | sed 's/^0//')

case $day in
    "1" | "21" | "31" ) suffix="st";;
    "2" | "22" ) suffix="nd";;
    "3" | "23" ) suffix="rd";;
    * ) suffix="th";;
esac

full_date="$day.$month.$year"

sha="$(git describe --abbrev=1)"
rev=$(echo "$sha" | sed 's/-g[^-]*$//')
version="$rev"
versiond="$rev-systemd"

if [ "$(git diff HEAD | wc -l)" != "0" ]; then
    version="$version-wip"
    versiond="$versiond-wip"
fi

echo "<![ %sysv; ["                                        >  version.ent
echo "<!ENTITY version           \"$version\">"            >> version.ent
echo "]]>"                                                 >> version.ent
echo "<![ %systemd; ["                                     >> version.ent
echo "<!ENTITY version          \"$versiond\">"            >> version.ent
echo "]]>"                                                 >> version.ent
echo "<!ENTITY releasedate       \"$full_date\">"          >> version.ent
echo "<!ENTITY copyrightdate     \"1999-$year\">"          >> version.ent

[ -z "$DIST" ] || echo $version > "$DIST"
