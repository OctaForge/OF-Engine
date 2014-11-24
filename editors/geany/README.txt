This is a Geany filetype for OctaScript.

Install filetypes.Octascript.conf to $HOME/.config/geany/filedefs.

Then open Geany, go to Tools->Configuration Files->filetype_extensions.conf.

Make it look like this at least (merge if you already have it):

[Extensions]
Octascript=*.oct;
[Groups]
Script=Octascript;

Restart Geany, enjoy highlighting.

Note that nested comments are not supported with Geany's lexer.
