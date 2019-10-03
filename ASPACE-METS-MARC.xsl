<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:mets="http://www.loc.gov/METS/"
	xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ead="urn:isbn:1-931666-22-9">
	<!-- 
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
  		
  
    -->

	<xsl:include href="MARC21slimUtils.xsl"/>



	<xsl:variable name="ead" select="document('ead.xml')"/>
	<xsl:variable name="relator" select="document('marc-relator-terms.xml')"/>
	
	<xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>
	<xsl:variable name="standalone">
		<xsl:if test="$ead//ead:eadid/@url">
			<xsl:text>FALSE</xsl:text>
		</xsl:if>	
		<xsl:if test="not($ead//ead:eadid/@url)">
			<xsl:text>TRUE</xsl:text>
		</xsl:if>
	</xsl:variable>
	<xsl:template match="/daos">
		<marc:collection>
			
			<xsl:apply-templates/>
		</marc:collection>
	</xsl:template>

	<xsl:template match="mets:metsHdr"/>
	<xsl:template match="mets:dmdSec"/>
	<xsl:template match="mets:dmdSec[1]">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mets:amdSec"/>
	<xsl:template match="mets:fileSec"/>
	<xsl:template match="mets:structMap"/>

	<!-- ead templates-->



	<!--<xsl:template match="ead:c[descendant::ead:unitid=$unitid]">-->
	<xsl:template match="ead:c">
		<xsl:param name="unitid"/>

		<xsl:if test="descendant::ead:unitid=$unitid">
			<xsl:if test="ead:c[not(child::unitid=$unitid)]">
				<marc:subfield code="g">

					<xsl:value-of select="ead:did/ead:unittitle"/>
					<xsl:text>, </xsl:text>
				</marc:subfield>

			</xsl:if>

		</xsl:if>

		<xsl:apply-templates select="ead:c">
			<xsl:with-param name="unitid">
				<xsl:value-of select="$unitid"/>
			</xsl:with-param>
		</xsl:apply-templates>


	</xsl:template>




	<!--mods templates-->
	<xsl:template match="mods:mods">
		<xsl:variable name="unitid">
			<xsl:value-of
				select="substring-before(/mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
			/>
		</xsl:variable>
		<marc:record xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
			<marc:leader>
				<!-- 00-04 -->
				<xsl:text>     </xsl:text>
				<!-- 05 -->
				<xsl:text>n</xsl:text>
				<!-- 06 -->
				<xsl:apply-templates mode="leader" select="mods:typeOfResource[1]"/>
				<!-- 07 -->
				<xsl:choose>
					<xsl:when test="$standalone='TRUE'">
						<xsl:text>m</xsl:text>						
					</xsl:when>
					<xsl:otherwise>
						<!--archival subunit-->
						<xsl:text>d</xsl:text>
					</xsl:otherwise>
				</xsl:choose>

				<!-- 08 -->
				<!--Default will be archival control for BC custom -->
				<xsl:text>a</xsl:text>
				<!-- 09 -->
				<xsl:text>a</xsl:text>
				<!-- 10 -->
				<xsl:text>2</xsl:text>
				<!-- 11 -->
				<xsl:text>2</xsl:text>
				<!-- 12-16 -->
				<xsl:text>     </xsl:text>
				<!-- 17 -->
				<xsl:text>7</xsl:text>
				<!-- 18 -->
				<xsl:text>i</xsl:text>
				<!-- 19 -->
				<xsl:text>#</xsl:text>
				<!-- 20-23 -->
				<xsl:text>4500</xsl:text>
			</marc:leader>
			<xsl:call-template name="controlRecordInfo"/>
			<marc:controlfield tag="008">
				<xsl:variable name="typeOf008">
					<xsl:apply-templates mode="ctrl008" select="mods:typeOfResource"/>
				</xsl:variable>
				<!-- 00-05 -->
				<xsl:choose>
					<xsl:when test="ancestor::mets:mets/mets:metsHdr">

						<xsl:value-of
							select="translate(substring(ancestor::mets:mets/mets:metsHdr/@CREATEDATE,3,8),'-','')"
						/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>      </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<!-- 06 - 14 -->
				<xsl:variable name="unitid">
					<xsl:value-of
						select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
					/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when
						test="substring-before($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@normal, '/')=substring-after($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@normal , '/')">
						<xsl:text>s</xsl:text>
						<xsl:value-of
							select="substring($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@normal,1,4)"/>
						<xsl:text>||||</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<!--From Kathryn, for an item published somewhere in a probable range of years, the 008 06 
							code would be q (Questionable: Exact date for a single date item is not known but a range of 
							years for the date can be specified (e.g., between 1824 and 1846).  m is more for multiple 
							items published over a span of years, or for a single item executed over a range of years, 
							like a painting.
							
							If you can get close enough to guess at a single year, you would use s, even though it's a guess.-->
						
						<xsl:choose>
							<xsl:when test="$ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@certainty='questionable'">
								<xsl:text>q</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>m</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
			
						<xsl:value-of
							select="substring($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@normal,1,4)"/>
						
						<xsl:value-of
							select="substring(substring-after($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate/@normal, '/'),1,4)"
						/>
					</xsl:otherwise>
					
					
				</xsl:choose>
				
				
				


				<!-- 15-17 -->
				<xsl:choose>
					<!-- v3 place -->
					<xsl:when
						test="mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry']">
						<!-- v3 fixed marc:code reference and authority change-->
						<xsl:value-of
							select="mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry']"/>
						<!-- 1/04 fix -->
						<xsl:if
							test="string-length(mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry'])=2">
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>mau</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<!-- 18-21 - MU -->
				<xsl:if test="$typeOf008='MU'">
					<xsl:text>||||</xsl:text>
				</xsl:if>
				<!-- 18-22 - MM -->
				<xsl:if test="$typeOf008='MM'">
					<xsl:text>#####</xsl:text>
				</xsl:if>
				<!-- 18-20 - VM -->
				<xsl:if test="$typeOf008='VM'">
					<xsl:text>nnn</xsl:text>
				</xsl:if>
				<!-- 18-21 - BK -->
				<xsl:if test="$typeOf008='BK'">

					<xsl:choose>
						<xsl:when
							test="mods:relatedItem/mods:part/mods:detail[1]/mods:title[text()='Anansi Stories']">

							<xsl:text>ag||</xsl:text>
						</xsl:when>
						<xsl:otherwise>||||</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

				<!-- 21 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='SE'">
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='database'">d</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='loose-leaf'">l</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='newspaper'">n</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='periodical'">p</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='series'">m</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='web site'">w</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$typeOf008='VM'">
						<xsl:text>#</xsl:text>
					</xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
				<!-- 22 -->
				<!-- 1/04 fix -->
				<xsl:if
					test="$typeOf008='BK' or $typeOf008='CF' or $typeOf008='MU' or $typeOf008='VM' ">

					<xsl:choose>
						<xsl:when test="mods:targetAudience[@authority='marctarget']">
							<xsl:apply-templates mode="ctrl008"
								select="mods:targetAudience[@authority='marctarget']"/>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>

					</xsl:choose>
				</xsl:if>
				<!-- 23 -->
				<xsl:choose>
					<xsl:when
						test="$typeOf008='BK' or $typeOf008='MU' or $typeOf008='SE' or $typeOf008='MM'"
						>o</xsl:when>

				</xsl:choose>
				<!-- 24-27 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='BK'">
						<xsl:call-template name="controlField008-24-27"/>
					</xsl:when>
					<xsl:when test="$typeOf008='MP'">
						<xsl:text>|</xsl:text>
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='atlas'">e</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='globe'">d</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
						</xsl:choose>
						<xsl:text>||</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='CF'">
						<xsl:text>||</xsl:text>
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='database'">e</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='font'">f</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='game'">g</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='numerical data'"
								>a</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='sound'">h</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
						</xsl:choose>
						<xsl:text>|</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='VM'">
						<xsl:text>#####</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='MU'">
						<xsl:text>||||</xsl:text>
					</xsl:when>
					<xsl:otherwise>

						<xsl:text>####</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<!-- 28 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='MU'">
						<xsl:text>|</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>#</xsl:text>
					</xsl:otherwise>
				</xsl:choose>

				<!-- 29 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='BK' or $typeOf008='SE'">
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='conference publication'"
								>1</xsl:when>
							<xsl:otherwise>0</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$typeOf008='MP' or $typeOf008='VM'">

						<xsl:text>0</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='MU'">
						
						<xsl:text>|</xsl:text>
					</xsl:when>
				</xsl:choose>
				<!-- 30-31 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='BK'">
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='festschrift'"
								>1</xsl:when>
							<xsl:otherwise>0</xsl:otherwise>
						</xsl:choose>
						<xsl:text>0</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='MU'">
						<xsl:text>||</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>##</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<!-- 32 -->
				<xsl:text>#</xsl:text>
				<!-- 33 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='VM'">
						<xsl:choose>
							<xsl:when test="mods:subject[@authority='gmgpc']/mods:topic='Prints'"
								>c</xsl:when>
							<xsl:otherwise>i</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$typeOf008='BK'">
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='comic strip'"
								>c</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='fiction'">1</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='essay'">e</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='drama'">d</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='humor, satire'"
								>h</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='letter'">i</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='novel'">f</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='short story'"
								>j</xsl:when>
							<xsl:when test="mods:genre[@authority='marc']='speech'">s</xsl:when>
							<xsl:when
								test="mods:relatedItem/mods:part/mods:detail[1]/mods:title[text()='Anansi Stories']"
								>j</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>|</xsl:otherwise>
				</xsl:choose>
				<!-- 34 -->
				<xsl:choose>
					<xsl:when test="$typeOf008='BK'">
						<xsl:choose>
							<xsl:when test="mods:genre[@authority='marc']='biography'">d</xsl:when>
						</xsl:choose>
						<xsl:choose>
							<xsl:when
								test="contains(mods:titleInfo[@usage='primary']/mods:title, 'Diary')"
								>d</xsl:when>


							<xsl:otherwise>|</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$typeOf008='VM'">
						<xsl:text>n</xsl:text>
					</xsl:when>
					<xsl:when test="$typeOf008='MU'">
						<xsl:text>#</xsl:text>
					</xsl:when>
					<xsl:otherwise>|</xsl:otherwise>
				</xsl:choose>
				<!-- 35-37 -->
				<xsl:choose>
					<!-- v3 language -->
					<!-- BC Custom fixes LC bug, only language code, not text, should go to 008-->
					<!-- handle bad data in athletics-->
					<xsl:when
						test="mods:relatedItem[@*]/mods:identifier[@type='accession number']='BC.1986.019'">
						<xsl:text>zxx</xsl:text>
					</xsl:when>
					<xsl:when test="mods:language/mods:languageTerm[@type='code']">
						<xsl:value-of select="mods:language/mods:languageTerm[@type='code']"/>
					</xsl:when>

					<xsl:otherwise>
						<xsl:text>|||</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<!-- 38-39 -->
				<xsl:text>#d</xsl:text>
			</marc:controlfield>
			<xsl:call-template name="marc024"/>
			<xsl:call-template name="source"/>
			<xsl:apply-templates/>
			<!--temp Anansi data fix-->
			<xsl:if test="not(mods:subject)">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">655</xsl:with-param>
					<xsl:with-param name="ind1"> </xsl:with-param>
					<xsl:with-param name="ind2">7</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">Manuscripts.</marc:subfield>
						<marc:subfield code="2">gmgpc</marc:subfield>

					</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
			<xsl:call-template name="burns-owner"/>
			<xsl:if test="$standalone='FALSE'">
			<xsl:call-template name="marc773"/>
			</xsl:if>
			<xsl:call-template name="marc856-FindingAid"/>
			<xsl:call-template name="marc856-0bject"/>
			<xsl:if test="$standalone = 'TRUE'">
				<xsl:call-template name="standalone"/>
			</xsl:if>
			<xsl:call-template name="marc940"/>
			<xsl:call-template name="marc991"/>

		</marc:record>

	</xsl:template>

	<xsl:template match="mods:typeOfResource" mode="leader">

		<xsl:choose>

			<xsl:when test="text()='text'">t</xsl:when>
			<!-- assumption all ASpace stuff is manuscript; made because ASpace METS export has no manuscript attribute-->
			<xsl:when test="text()='cartographic' and @manuscript='yes'">f</xsl:when>
			<xsl:when test="text()='cartographic'">e</xsl:when>

			<xsl:when test="text()='notated music'">d</xsl:when>
			<!-- v3 musical/non -->
			<xsl:when test="text()='sound recording-nonmusical'">i</xsl:when>
			<xsl:when test="text()='sound recording'">j</xsl:when>
			<xsl:when test="text()='sound recording-musical'">j</xsl:when>
			<xsl:when test="text()='still image'">k</xsl:when>
			<xsl:when test="text()='moving image'">g</xsl:when>
			<xsl:when test="text()='three dimensional object'">r</xsl:when>
			<xsl:when test="text()='software, multimedia'">m</xsl:when>
			<xsl:when test="text()='mixed material'">p</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="controlRecordInfo">
		<!--<xsl:template match="mods:recordInfo">-->

		<marc:controlfield tag="001">
			<xsl:text>dao</xsl:text>
			<xsl:value-of select="format-number(ancestor::mets:dmdSec/@ID, '0000000000')"/>
		</marc:controlfield>
		<marc:controlfield tag="003">ArchivesSpace</marc:controlfield>


		<xsl:choose>
			<xsl:when test="mods:typeOfResource='text'">
				<marc:controlfield tag="006">m####|o##d########</marc:controlfield>
			</xsl:when>
			<xsl:when test="mods:typeOfResource='still image'">
				<marc:controlfield tag="006">m####|o##c########</marc:controlfield>
			</xsl:when>
			<xsl:when test="mods:typeOfResource='mixed material'">
				<marc:controlfield tag="006">m####|o##m########</marc:controlfield>
			</xsl:when>
			<xsl:when test="mods:typeOfResource='notated music'">
				<marc:controlfield tag="006">m####|o##c########</marc:controlfield>
			</xsl:when>
		</xsl:choose>

		<xsl:choose>
			<xsl:when test="mods:physicalDescription/mods:digitalOrigin='born digital'">
				<marc:controlfield tag="007">cr#cz#||||||||</marc:controlfield>
				<!--useless test-->
			</xsl:when>
			<xsl:otherwise>
				<marc:controlfield tag="007">cr#cz#|||||a||</marc:controlfield>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:typeOfResource" mode="ctrl008">
		<xsl:choose>
			<xsl:when test="text()='text' and @manuscript='yes'">BK</xsl:when>
			<xsl:when test="text()='text'">
				<xsl:choose>
					<xsl:when test="../mods:originInfo/mods:issuance='monographic'">BK</xsl:when>
					<xsl:when test="../mods:originInfo/mods:issuance='continuing'">SE</xsl:when>
					<xsl:otherwise>BK</xsl:otherwise>
					<!-- ASPACE does not have mods:issuance-->
				</xsl:choose>
			</xsl:when>
			<xsl:when test="text()='cartographic' and @manuscript='yes'">MP</xsl:when>
			<xsl:when test="text()='cartographic'">MP</xsl:when>
			<xsl:when test="text()='notated music' and @manuscript='yes'">MU</xsl:when>
			<xsl:when test="text()='notated music'">MU</xsl:when>
			<xsl:when test="text()='sound recording'">MU</xsl:when>
			<!-- v3 musical/non -->
			<xsl:when test="text()='sound recording-nonmusical'">MU</xsl:when>
			<xsl:when test="text()='sound recording-musical'">MU</xsl:when>
			<xsl:when test="text()='still image'">VM</xsl:when>
			<xsl:when test="text()='still image' and @manuscript='yes'">VM</xsl:when>
			<xsl:when test="text()='moving image'">VM</xsl:when>
			<xsl:when test="text()='three dimensional object'">VM</xsl:when>
			<xsl:when test="text()='software, multimedia'">CF</xsl:when>
			<xsl:when test="text()='mixed material'">MM</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="controlField008-24-27">
		<xsl:variable name="chars">
			<xsl:for-each select="mods:genre[@authority='marc']">
				<xsl:choose>
					<xsl:when test=".='abstract of summary'">a</xsl:when>
					<xsl:when test=".='bibliography'">b</xsl:when>
					<xsl:when test=".='catalog'">c</xsl:when>
					<xsl:when test=".='dictionary'">d</xsl:when>
					<xsl:when test=".='directory'">r</xsl:when>
					<xsl:when test=".='discography'">k</xsl:when>
					<xsl:when test=".='encyclopedia'">e</xsl:when>
					<xsl:when test=".='filmography'">q</xsl:when>
					<xsl:when test=".='handbook'">f</xsl:when>
					<xsl:when test=".='index'">i</xsl:when>
					<xsl:when test=".='law report or digest'">w</xsl:when>
					<xsl:when test=".='legal article'">g</xsl:when>
					<xsl:when test=".='legal case and case notes'">v</xsl:when>
					<xsl:when test=".='legislation'">l</xsl:when>
					<xsl:when test=".='patent'">j</xsl:when>
					<xsl:when test=".='programmed text'">p</xsl:when>
					<xsl:when test=".='review'">o</xsl:when>
					<xsl:when test=".='statistics'">s</xsl:when>
					<xsl:when test=".='survey of literature'">n</xsl:when>
					<xsl:when test=".='technical report'">t</xsl:when>
					<xsl:when test=".='theses'">m</xsl:when>
					<xsl:when test=".='treaty'">z</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:call-template name="makeSize">
			<xsl:with-param name="string" select="$chars"/>
			<xsl:with-param name="length" select="4"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="makeSize">
		<xsl:param name="string"/>
		<xsl:param name="length"/>
		<xsl:variable name="nstring" select="normalize-space($string)"/>
		<xsl:variable name="nstringlength" select="string-length($nstring)"/>
		<xsl:choose>
			<xsl:when test="$nstringlength&gt;$length">
				<xsl:value-of select="substring($nstring,1,$length)"/>
			</xsl:when>
			<xsl:when test="$nstringlength&lt;$length">
				<xsl:value-of select="$nstring"/>
				<xsl:call-template name="buildSpaces">
					<xsl:with-param name="spaces" select="$length - $nstringlength"/>
					<xsl:with-param name="char">|</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nstring"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="source">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">040</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">MChB-B</marc:subfield>
				<marc:subfield code="b">eng</marc:subfield>
				<marc:subfield code="c">MChB-B</marc:subfield>
				<marc:subfield code="e">dacs</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>


	</xsl:template>

	<xsl:template name="marc024">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="ind1">7</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">
					<xsl:text>2345.2/</xsl:text>
					<xsl:value-of
						select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
					/>
				</marc:subfield>
				<marc:subfield code="2">hdl</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="mods:dateCreated"/>

	<!--personal name-->
	<xsl:template match="mods:name[@type='personal']">

		<xsl:choose>
			<!--	<xsl:when test="self::node()[1] and ancestor::mods:mods/descendant::mods:roleTerm[text()='pht' or text()='cre' or text()='aut' or text()='crp']/@type='code'">-->
			<xsl:when
				test="self::node()[1] and self::node()/descendant::mods:roleTerm[text()='creator']/@type='text'">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">100</xsl:with-param>
					<xsl:with-param name="ind1">1</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">
							<xsl:value-of select="mods:namePart[@type='family']"/>
							<xsl:text>, </xsl:text>
							<xsl:value-of select="mods:namePart[@type='given'][1]"/>

							<xsl:choose>
								<xsl:when
									test="mods:namePart[@type='date'] or (mods:namePart[@type='termsOfAddress'] != '')">
									<xsl:text>, </xsl:text>
								</xsl:when>
								<xsl:when test="mods:namePart[@type='given'][2]">
									<marc:subfield code="q">
										<xsl:text>(</xsl:text>
										<xsl:value-of select="mods:namePart[@type='given'][2]"/>
										<xsl:text>)</xsl:text>
									</marc:subfield>
								</xsl:when>
								<xsl:when test="mods:role">,</xsl:when>
								<xsl:otherwise>.</xsl:otherwise>

							</xsl:choose>

						</marc:subfield>





						<!-- v3 termsOfAddress -->
						<xsl:for-each select="mods:namePart[@type='termsOfAddress']">
							<xsl:if test="mods:namePart[@type='termsOfAddress'] != ''">
								<marc:subfield code="c">
									<xsl:value-of
										select="string-length(mods:namePart[@type='termsOfAddress'])"/>
									<!--<xsl:if
									test="mods:namePart[@type='date'] or following-sibling::mods:role">
									<xsl:text>,</xsl:text>
								</xsl:if>-->
								</marc:subfield>
							</xsl:if>
						</xsl:for-each>
						<xsl:variable name="unitid">
							<xsl:value-of
								select="substring-before(/mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
							/>
						</xsl:variable>

						<xsl:if
							test="$ead//ead:did[child::ead:unitid=$unitid]/ead:origination[@label='creator']/ead:persname">
							<xsl:variable name="date">
								<xsl:value-of
									select="substring-after(substring-after($ead//ead:did[child::ead:unitid=$unitid]/ead:origination[@label='creator']/ead:persname, ','),',')"
								/>
							</xsl:variable>

							<xsl:if test="string-length($date) &gt; 3">

								<marc:subfield code="d">

									<xsl:value-of select="normalize-space($date)"/>
									<xsl:text>,</xsl:text>
								</marc:subfield>
							</xsl:if>
						</xsl:if>
						<!-- v3 role -->
						<xsl:variable name="code">
							<xsl:value-of
								select="$ead//ead:did[child::ead:unitid=$unitid]/ead:origination[@label='creator']/ead:persname/@role"
							/>
						</xsl:variable>

						<marc:subfield code="e">
							<xsl:value-of
								select="$relator//marc-relator-terms/relator[child::code=$code]/term"/>
							<xsl:text>.</xsl:text>
						</marc:subfield>


						<marc:subfield code="4">
							<xsl:value-of
								select="$ead//ead:did[child::ead:unitid=$unitid]/ead:origination[@label='creator']/ead:persname/@role"
							/>
						</marc:subfield>

						<xsl:for-each select="mods:affiliation">
							<marc:subfield code="u">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:for-each>
						<xsl:for-each select="mods:description">
							<marc:subfield code="g">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:for-each>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">700</xsl:with-param>
					<xsl:with-param name="ind1">1</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">
							<xsl:value-of select="mods:namePart[@type='family']"/>
							<xsl:if
								test="mods:namePart[@type='family']and mods:namePart[@type='given']"
								>, </xsl:if>
							<xsl:value-of select="mods:namePart[@type='given']"/>
							<xsl:choose>
								<xsl:when
									test="not(mods:namePart[@type='termsofAddress'] or mods:namePart[@type='date'] or mods:role)"
									>.</xsl:when>
								<xsl:otherwise>,</xsl:otherwise>
							</xsl:choose>
						</marc:subfield>

						<xsl:for-each select="mods:namePart[@type='termsOfAddress']">
							<marc:subfield code="c">
								<xsl:value-of select="."/>
								<xsl:text>,</xsl:text>
							</marc:subfield>
						</xsl:for-each>
						<xsl:for-each select="mods:namePart[@type='date']">
							<marc:subfield code="d">
								<xsl:value-of select="."/>
								<xsl:text>,</xsl:text>
							</marc:subfield>
						</xsl:for-each>

						<xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
							<marc:subfield code="e">
								<xsl:value-of select="lower-case(.)"/>
								<xsl:text>.</xsl:text>
							</marc:subfield>
						</xsl:for-each>
						<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
							<marc:subfield code="4">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:for-each>
						<xsl:for-each select="mods:affiliation">
							<marc:subfield code="u">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:for-each>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Title Info elements -->
	<xsl:template match="mods:titleInfo[not(ancestor-or-self::mods:subject)][not(@type)][1]">

		<xsl:param name="ind1-245">
			<!-- determine if title main entry-->
			<xsl:choose>
				<xsl:when
					test="ancestor::mods:mods/descendant::mods:roleTerm[text()='creator']/@type='text'">
					<xsl:text>1</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>0</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:param>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">245</xsl:with-param>
			<xsl:with-param name="ind1" select="$ind1-245"/>
			<xsl:with-param name="ind2" select="string-length(mods:nonSort)"/>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="titleInfo">
		<xsl:choose>
			<xsl:when test="$standalone='TRUE' and mods:title !=$ead//ead:archdesc[@level='collection']/ead:did/ead:unittitle">
				<marc:subfield code="a">
					
					<xsl:value-of select="normalize-space($ead//ead:archdesc[@level='collection']/ead:did/ead:unittitle)"/>
					<xsl:text>.</xsl:text>
				</marc:subfield>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="mods:title">
					<marc:subfield code="a">
						<xsl:value-of select="../mods:nonSort"/>
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text>.</xsl:text>
					</marc:subfield>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>

		<!-- 1/04 fix -->
		<xsl:for-each select="mods:subTitle">
			<marc:subfield code="b">
				<xsl:value-of select="."/>
			</marc:subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:partNumber">
			<marc:subfield code="n">
				<xsl:value-of select="."/>

			</marc:subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:partName">
			<marc:subfield code="p">
				<xsl:value-of select="."/>
			</marc:subfield>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="marc264">
		<xsl:variable name="unitid">
			<xsl:value-of
				select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
			/>
		</xsl:variable>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">264</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="c">
					<xsl:value-of select="$ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate"/>
					<xsl:if test="not(substring($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate, string-length($ead//ead:did[child::ead:unitid=$unitid]/ead:unitdate),1)='?')">
						<xsl:text>.</xsl:text>
					</xsl:if>
					
				
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>

	</xsl:template>

	<xsl:template name="marc300">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">300</xsl:with-param>
			<xsl:with-param name="subfields">


				<marc:subfield code="a">
					<xsl:text>1 online resource (</xsl:text>
					<xsl:choose>
						<xsl:when test="contains(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[position()=last], 'target')">
	
					<xsl:value-of
						select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file) - 1"/>
					<xsl:text> image</xsl:text>

					<xsl:if
						test="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file) &gt; 2">
						<xsl:text>s</xsl:text>

					</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of
								select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file)"/>
							<xsl:text> image</xsl:text>

							<xsl:if
								test="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file) &gt; 1">
								<xsl:text>s</xsl:text>

							</xsl:if>
						</xsl:otherwise>

					</xsl:choose>
					<xsl:text>)</xsl:text>
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:typeOfResource">
		<xsl:call-template name="marc264"/>
		<xsl:call-template name="marc300"/>
		<xsl:choose>

			<xsl:when test="text()='still image'">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">336</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">still image</marc:subfield>
						<marc:subfield code="b">
							<xsl:value-of select="substring(. , 1, 3)"/>
						</marc:subfield>
						<marc:subfield code="2">
							<xsl:text>rdacontent</xsl:text>
						</marc:subfield>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="text()='text'">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">336</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">
							<xsl:value-of select="."/>
						</marc:subfield>
						<marc:subfield code="b">
							<xsl:text>txt</xsl:text>
						</marc:subfield>
						<marc:subfield code="2">
							<xsl:text>rdacontent</xsl:text>
						</marc:subfield>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
				<xsl:when test="text()='notated music'">
					<xsl:call-template name="datafield">
						<xsl:with-param name="tag">336</xsl:with-param>
						<xsl:with-param name="subfields">
							<marc:subfield code="a">
								<xsl:value-of select="."/>
							</marc:subfield>
							<marc:subfield code="b">
								<xsl:text>ntm</xsl:text>
							</marc:subfield>
							<marc:subfield code="2">
								<xsl:text>rdacontent</xsl:text>
							</marc:subfield>
						</xsl:with-param>
					</xsl:call-template>
			</xsl:when>



		</xsl:choose>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">337</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">computer</marc:subfield>
				<marc:subfield code="b">c</marc:subfield>
				<marc:subfield code="2">
					<xsl:text>rdamedia</xsl:text>
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">338</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">online resource</marc:subfield>
				<marc:subfield code="b">cr</marc:subfield>
				<marc:subfield code="2">
					<xsl:text>rdacarrier</xsl:text>

				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:language"/>
	<xsl:template match="mods:note">

		<xsl:choose>
			<xsl:when test=".='reformatted digital' or .='digitized other analog'">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">533</xsl:with-param>
					<xsl:with-param name="subfields">
						<marc:subfield code="a">Electronic reproduction.</marc:subfield>
						<marc:subfield code="b">Chestnut Hill, Mass. :</marc:subfield>
						<marc:subfield code="c">Boston College, </marc:subfield>
						<marc:subfield code="d">
							<xsl:value-of
								select="substring(ancestor::mets:mets/mets:metsHdr/@CREATEDATE, 1,4)"/>
							<xsl:text>.</xsl:text>
						</marc:subfield>

					</xsl:with-param>
				</xsl:call-template>

			</xsl:when>
		</xsl:choose>

	</xsl:template>

    <xsl:template match="mods:identifier"/>

	<xsl:template match="mods:accessCondition">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">
				<xsl:choose>
					<xsl:when test="@type='restrictionOnAccess'">506</xsl:when>
					<xsl:when test="@type='useAndReproduction'">540</xsl:when>
					<xsl:when test="@type='use and reproduction'">540</xsl:when>
					<!-- BC Custom-->

				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">



				<marc:subfield code="a">
					<xsl:value-of select="normalize-space(.)"/>
				</marc:subfield>


			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<!--work around to map genre to 655 -  Because we are putting mods:genre/marc 655 into mods:subject due to system constraints
	(ASpace doesn't have a field that exports to mods:genre in the way we need it to.-->
	
	<xsl:template match="mods:subject[local-name(*[1])='genre']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">655</xsl:with-param>
			
			<xsl:with-param name="ind2">
				<xsl:choose>
					<xsl:when test="@authority='tucua' or @authority='lctgm' or @authority='gmgpc'"
						>7</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
				
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">
					<xsl:value-of
						select="concat(translate(substring(*[1] , 1, 1),
						'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
						substring(*[1],2,string-length(*[1])-1))"/>
					<xsl:text>.</xsl:text>
					
				</marc:subfield>
				<xsl:if test="@authority='tucua' or @authority='lctgm' or @authority='gmgpc'">
					<marc:subfield code="2">
						<xsl:value-of select="@authority"/>
					</marc:subfield>
				</xsl:if>
			</xsl:with-param>
			
		</xsl:call-template>
	</xsl:template>
	
	
	
	<xsl:template match="mods:subject[local-name(*[1])='topic' or local-name(*[1])='occupation']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">650</xsl:with-param>

			<xsl:with-param name="ind2">
				<xsl:choose>
				
					<xsl:when test="@authority='tucua' or @authority='lctgm' or @authority='gmgpc'">
						<!-- commenting this out for future work; this scenario should never exist with our current ASpace exports
						7--></xsl:when>
			
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>

			</xsl:with-param>

			<xsl:with-param name="subfields">
				<marc:subfield code="a">
					<xsl:value-of
						select="concat(translate(substring(*[1] , 1, 1),
						'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
						substring(*[1],2,string-length(*[1])-1))"/>

				</marc:subfield>
				<xsl:for-each select="following-sibling::node()">
					<xsl:choose>
						<xsl:when test="local-name()='geographic'">
							<marc:subfield code="z">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:when>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="local-name()='genre'">
							<marc:subfield code="v">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:when>
						<xsl:when test="local-name()='temporal'">
							<marc:subfield code="y">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:when>
						<xsl:when test="local-name()='topic'">
							<marc:subfield code="x">
								<xsl:value-of select="."/>
							</marc:subfield>
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
				<xsl:if test="@authority='tucua' or @authority='lctgm' or @authority='gmgpc'">
					<marc:subfield code="2">
						<xsl:value-of select="@authority"/>
					</marc:subfield>
				</xsl:if>


			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:subject">
		<xsl:apply-templates/>
	</xsl:template>
	
	

	

	<xsl:template name="burns-owner">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">710</xsl:with-param>
			<xsl:with-param name="ind1">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">Boston College.</marc:subfield>
				<marc:subfield code="b">John J. Burns Library,</marc:subfield>
				<marc:subfield code="e">owner.</marc:subfield>
				<marc:subfield code="4">own</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="marc773">

		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">773</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<!-- v3 displaylabel -->
				<marc:subfield code="t">
					<xsl:value-of
						select="normalize-space($ead//ead:archdesc[@level='collection']/ead:did/ead:unittitle)"/>
					<xsl:text>, </xsl:text>
				</marc:subfield>

				<marc:subfield code="d">
					<xsl:value-of
						select="normalize-space($ead//ead:filedesc/ead:titlestmt/ead:subtitle)"/>
					<xsl:text>, </xsl:text>
				</marc:subfield>


				<xsl:apply-templates select="$ead//ead:archdesc/ead:dsc/ead:c">
					<xsl:with-param name="unitid">
						<xsl:value-of
							select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
						/>
					</xsl:with-param>
				</xsl:apply-templates>

				<marc:subfield code="o">
					<xsl:value-of select="$ead//ead:filedesc/ead:titlestmt/ead:titleproper/ead:num"/>
					<xsl:text>.</xsl:text>
				</marc:subfield>

			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="marc856-FindingAid">
		<xsl:if test="$ead//ead:eadid/@url">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind1">4</xsl:with-param>
			<xsl:with-param name="ind2">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="3">
					<xsl:text>About the </xsl:text>
					<xsl:value-of select="$ead//ead:archdesc/ead:did/ead:unittitle"/>
				</marc:subfield>
				<marc:subfield code="u">
					<xsl:value-of select="$ead//ead:eadid/@url"/>
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
		</xsl:if>
	</xsl:template>


	<xsl:template name="marc856-0bject">
		<xsl:param name="count">
			<xsl:if test="contains(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[position()=last], 'target')">		
				<xsl:value-of
					select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file) - 1"/>
			</xsl:if>
			<xsl:if test="not(contains(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[position()=last], 'target'))">		
				<xsl:value-of
					select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file)"/>
			</xsl:if>
		</xsl:param>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind1">4</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			
			<xsl:with-param name="subfields">
				<marc:subfield code="3">
					<xsl:value-of select="$count"/>
					<xsl:choose>
						<xsl:when test="$count &gt; 1">
							<xsl:text> images</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text> image</xsl:text>
						</xsl:otherwise>
					</xsl:choose>				
				</marc:subfield>

				<marc:subfield code="u">
					<xsl:text>https://library.bc.edu/iiif/view/</xsl:text>
					<xsl:value-of
						select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"/>

				</marc:subfield>


				<marc:subfield code="q">
					<xsl:for-each select="mods:note">
						<xsl:if test="contains(., 'tiff')">
							<xsl:text>image/tiff</xsl:text>
						</xsl:if>
					</xsl:for-each>
				</marc:subfield>
				<marc:subfield code="z">
					<xsl:text>View online resource (</xsl:text>
					<xsl:value-of select="$count"/>
					<xsl:choose>
						<xsl:when test="$count &gt; 1">
							<xsl:text> images)</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text> image)</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</marc:subfield>

			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="marc940">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">940</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2"> </xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">
					<xsl:value-of
						select="lower-case(translate($ead//ead:archdesc/ead:did/ead:unitid,'.',''))"
					/>
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>


	<xsl:template name="marc991">
		<xsl:param name="count">
			<xsl:if test="contains(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[position()=last], 'target')">		
				<xsl:value-of
					select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file) - 1"/>
			</xsl:if>
			<xsl:if test="not(contains(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[position()=last], 'target'))">		
				<xsl:value-of
					select="count(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file)"/>
			</xsl:if>
		</xsl:param>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">991</xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">DAO</marc:subfield>
				<marc:subfield code="c">
					<xsl:value-of
						select="$count"
					/>
				</marc:subfield>
				<marc:subfield code="l">
					<xsl:text>ead:c@LEVEL=</xsl:text>
					<xsl:choose>
						<xsl:when test="contains(mods:note[@type='dimensions'], 'item')">
							<xsl:text>item</xsl:text>
						</xsl:when>
						<xsl:when test="contains(mods:note[@type='dimensions'], 'file')">
							<xsl:text>file</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="unitid">
								<xsl:value-of
									select="substring-before(ancestor::mets:mets/mets:fileSec/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '_000')"
								/>
							</xsl:variable>
							<xsl:value-of select="$ead//ead:did[child::ead:unitid=$unitid]/parent::node()/@level">
								
							</xsl:value-of>
						</xsl:otherwise>
					</xsl:choose>
				</marc:subfield>

				<marc:subfield code="t">
					<xsl:value-of
						select="substring-before(ancestor::mets:mets/mets:fileSec[1]/mets:fileGrp[1]/mets:file[1]/mets:FLocat/@xlink:href, '.')"
					/>
				</marc:subfield>
				<marc:subfield code="r">
					<xsl:text>MiraSpace Batch DAO</xsl:text>
					<xsl:text> (</xsl:text>
					<xsl:value-of
						select="concat(substring(ancestor::mets:mets/mets:metsHdr/@CREATEDATE,1,10),'T',substring(ancestor::mets:mets/mets:metsHdr/@CREATEDATE,12,8))"/>
					<xsl:text>)</xsl:text>
				</marc:subfield>
				<marc:subfield code="g">
					<xsl:choose>
						<xsl:when test="mods:subject">
							<xsl:value-of select="translate(mods:subject/mods:genre,'.','')"/>
						</xsl:when>
						<!--temp Anansi data fix-->
						<xsl:otherwise>
							<xsl:text>Manuscripts</xsl:text>
						</xsl:otherwise>
					</xsl:choose>

				</marc:subfield>
				<marc:subfield code="2">
					<xsl:choose>
						<xsl:when test="mods:subject">
							<xsl:value-of select="mods:subject/@authority"/>
						</xsl:when>
						<!--temp Anansi data fix-->
						<xsl:otherwise>
							<xsl:text>gmgpc</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>

	</xsl:template>
	
	<xsl:template name="standalone">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">940</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2"> </xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="a">Standalone</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">776</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2"> </xsl:with-param>
			<xsl:with-param name="subfields">
				<marc:subfield code="c">Original</marc:subfield>
				<marc:subfield code="w">(Alma)</marc:subfield>
			</xsl:with-param>
		</xsl:call-template>
		
	</xsl:template>



</xsl:stylesheet>
