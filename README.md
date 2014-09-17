DFMJSON
=======

DFMJSON is exactly what it sounds like: a library to convert between Delphi's .DFM (or .FMX) format and JSON.  It can be used to parse a DFM file into an Abstract Syntax Tree in JSON, which can then be edited and the results turned back to DFM format.

DFMJSON uses dwsJson from [DWS](https://code.google.com/p/dwscript/) to provide JSON support, so you will need to have it in order to use DFMJSON.  (The dwsJson unit is a standalone part of the DWS library, and using it does not pull the scripting engine into your project.)

DFMJSON includes a simple project called DfmJsonProcessor, which uses DFMJSON to power a scriptable bulk editor for DFM files.  Simply provide it with a path, a filename mask, and a DWS script that transforms JSON data, and it will apply the transformation script to every DFM file that matches the search criteria.  The script will have access to the parsed DFM data via a global variable called "DFM", of type JSONVariant.  Since it uses scripts to modify the data, DfmJsonProcessor does require the entire DWS scripting system.
