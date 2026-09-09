# Register the autoload function directory and declare `rp`.
# The function body is not parsed until `rp` is first called.
fpath=("${0:A:h}/functions" $fpath)
autoload -Uz rp
