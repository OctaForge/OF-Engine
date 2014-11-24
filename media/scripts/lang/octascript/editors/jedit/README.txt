This is a jEdit mode for OctaScript.

Install to $HOME/.jedit/modes.

Create the file "catalog" in that directory if it doesn't
exist already and paste this line inside:

<MODE NAME="octascript" FILE="octascript.xml" FILE_NAME_GLOB="*.oct"/>

It should look roughly like this:

<?xml version="1.0"?>
<!DOCTYPE MODES SYSTEM "catalog.dtd">
<MODES>
<MODE NAME="octascript" FILE="octascript.xml" FILE_NAME_GLOB="*.oct"/>
</MODES>

