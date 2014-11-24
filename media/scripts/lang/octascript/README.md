OctaScript
==========

## The OctaForge scripting language

OctaScript is a language that was created specifically for OctaForge. However,
it's usable standalone as well. It differs from other languages by compiling
to LuaJIT bytecode, leveraging its high performance and unlike transpilers,
this approach allows it to provide correct debug info and implement a lot more
features in an easier manner.

This repository contains a standalone version of OctaScript, not dependent
upon the OctaForge engine.

Support for text editors and various tools is also stored here.

The language, editor modes and everything else are provided under the terms
of the University of Illinois/NCSA Open Source License (similar to BSD 3 clause).

Editor support:

* jEdit
* Geany
* Kate
* Qt Creator
* KDevelop
* GNU Nano
* Vim (syntax, no indent)

Qt Creator and KDevelop are supported as they use Kate's language
files. Other editors using the same editor component are supported
as well.

Future editor support:

* Emacs
* Sublime Text
* gEdit
* Notepad++

Tools support:

* Highlight

Future tools support:

* Pygments
