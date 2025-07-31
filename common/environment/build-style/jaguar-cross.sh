# Snapshot tarballs get removed after over a year, we can archive the ones we need in distfiles.
case "$DULGE_DISTFILES_FALLBACK" in
	*"mirror.ps4jaguarlinux.site/pub/"*) ;;
	*) DULGE_DISTFILES_FALLBACK+=" mirror.ps4jaguarlinux.site/pub/" ;;
esac

lib32disabled=yes
nopie=yes

nostrip_files+=" libcaf_single.a libgcc.a libgcov.a libgcc_eh.a
 libgnarl_pic.a libgnarl.a libgnat_pic.a libgnat.a libgmem.a"
