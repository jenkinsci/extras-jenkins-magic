<?xml version="1.0" encoding="UTF-8"?>

<!--
    Convert XML files from PC-Lint (www.gimpel.com) to Checkstyle

    Author: Ewald Arnold hudson-magic@ewald-arnold.de

    Started: 2010-08.05

    $Id: pclint2checkstyle.xsl 19117 2010-08-07 09:18:21Z ewald $

     Licenced under GNU LGPL
-->


<xsl:stylesheet version="1.0" xmlns:str="http://xsltsl.org/string"
                              xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:exsl="http://exslt.org/common"
                              extension-element-prefixes="exsl"
                              exclude-result-prefixes="str">

  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/doc">
    <checkstyle version="4.1">
      <xsl:apply-templates select="message" />
    </checkstyle>
  </xsl:template>

<!--
  <message>
    <file>src\lib\kernel\ustring.cpp</file>
    <line>23</line>
    <type>Warning</type>
    <code>537</code>
    <desc>Repeated include file 'C:\Programme\Borland\CBuilder5\Include\cstdio.h'</desc>
   </message>
 -->
<!--
   <file name="tasks\src\main\java\hudson\plugins\tasks\parser\CsharpNamespaceDetector.java">
      <error line="0"
             severity="error"
             message="Fehlende Package-Dokumentation."
             source="com.puppycrawl.tools.checkstyle.checks.javadoc.PackageHtmlCheck"/>
   </file>
 -->
  <xsl:template match="message">
    <xsl:element name="file">
    
      <xsl:attribute name="name">
        <xsl:choose>
          <xsl:when test="file = ''">
            <xsl:value-of select="'file-not-found'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="file"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <xsl:element name="error">
         <xsl:attribute name="line">
           <xsl:value-of select="line" />
         </xsl:attribute>

         <xsl:attribute name="message">
           <xsl:value-of select="concat('', position(), ' #', code, ': ', desc)" />
         </xsl:attribute>

         <xsl:attribute name="source">
<!--           <xsl:value-of select="" />   -->
         </xsl:attribute>

         <xsl:attribute name="severity">
           <xsl:choose>
             <xsl:when test="type = 'Info' or type = 'info' ">
               <xsl:text>info</xsl:text>
             </xsl:when>
             <xsl:when test="type = 'Warning' or type = 'warning' ">
               <xsl:text>warning</xsl:text>
             </xsl:when>
             <xsl:when test="type = 'Error' or type = 'error' ">
               <xsl:text>error</xsl:text>
             </xsl:when>
             <xsl:otherwise>
               <xsl:text>??type??</xsl:text>
             </xsl:otherwise>
           </xsl:choose>
         </xsl:attribute>
      </xsl:element>
    </xsl:element>

  </xsl:template>

</xsl:stylesheet>
