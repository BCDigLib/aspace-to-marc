# aspace-to-marc

Transforming ASpace dao data into MARC records for ALMA

Emerging workflow currently uses xlst to transform two inputs:

  1. a resource's EAD file 
  2. a file of the resource's dao components expressed as METS and
  concatenated into a single file

to create a MARC file for ALMA import

This initial MiraSpace operational workflow is expected to evolve dramatically

Usage for inital xslt:
 ASpace METS-MARC Stylesheet
  
  Originally Created by LC
  Re-factored to convert METS files exported from ArchivesSpace to MARC for ALMA
 
 Requirements:
  
  -Designed to work with one or more METS files from a *single* resource.
  -Due to deficiences in ASPACE MARC export, the stylesheet must pull information from
    the resources xml file, which should named 'ead.xml' and be in the same directory 
    as the stylesheet
  -Concatenate all the individual METS files into a single file
  		-Remove extraneous xml declarations: <?xml version="1.0" encoding="UTF-8"?>
  		-Correct mets schema location output by ASpace so xslt will work: 
			Output:     xsi:schemaLocation="http://www.loc.gov/standards/mets/mets.xsd"
			Corrected:  xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd"
		-Put a wrapper element <daos> around the file

  Transformation:
  	-Use an xlst 2.0 processor (e.g. use saxon)
  
  Quality Control
  - Use MarcEdit to convert the file from .xml to .mrc to .mrk
  - Use Reports->MARCValidator to ensure the MARC is valid
  - Use Reports->Field Count to make sure the expected number of required fields appeared (based on count of input daos)
  - Use Ctrl+F to find and eyeball the following 
  		- all 024 fields (=024)
  		- all 856 fields  =856  40$3
  		- all 991 files (=991)
