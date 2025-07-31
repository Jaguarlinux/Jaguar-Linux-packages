# vim: set ts=4 sw=4 et:

update_hash_cache() {
    local cache="$DULGE_SRCDISTDIR/by_sha256"
    local distfile curfile
    mkdir -p "$cache"
    find "$DULGE_SRCDISTDIR" -type f | grep -v by_sha256 | while read -r distfile; do
        cksum=$($DULGE_DIGEST_CMD "$distfile")
        curfile="${distfile##*/}"
        ln -vf "$distfile" "${cache}/${cksum}_${curfile}"
    done
}
