<?xml version="1.0" encoding="UTF-8"?>

<!--
    Convert XML files from Bullseye (www.bullseye.com) to Cobertura.

    Author: Ewald Arnold hudson-magic@ewald-arnold.de

    Started: 2010-07.25

    $Id: bullseye2cobertura.xsl 19073 2010-08-05 08:33:44Z ewald $

    Limitations:

     Bullseye does no sort of line/class/file coverage. It just keeps lines for
     method entry and decisions like if and case labels. It detects if try blocks
     were successfully left at their end or catch blocks were entered.

     The resulting  line-rate reflects just a small subset of the actual source lines.

     Licenced under GNU LGPL
-->


<xsl:stylesheet version="1.0" xmlns:str="http://xsltsl.org/string" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl" exclude-result-prefixes="str">

  <xsl:import href="hm-common.xsl"/>

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="root"/>

  <xsl:param name="namespaces"/>

  <!-- ==================================================== -->
  <!-- make-ns                                              -->
  <!-- ==================================================== -->

  <xsl:template name="make-ns">
    <xsl:param name="list" />

    <xsl:choose>
      <xsl:when test="contains($list, ',')">
        <xsl:element name="name">
          <xsl:copy-of select="concat(substring-before($list, ','),'::')" />
        </xsl:element>
        <xsl:call-template name="make-ns">
          <xsl:with-param name="list" select="substring-after($list, ',')" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:element name="name">
          <xsl:copy-of select="concat($list, '::')" />
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:variable name="ns">
    <xsl:call-template name="make-ns">
      <xsl:with-param name="list" select="$namespaces" />
    </xsl:call-template>
  </xsl:variable>

  <!-- ==================================================== -->
  <!-- remove-ns                                            -->
  <!-- ==================================================== -->

  <xsl:template name="remove-ns">
    <xsl:param name="method" />

    <xsl:variable name="offset">
      <xsl:for-each select="exsl:node-set($ns)/name">
        <xsl:if test="starts-with($method, text())">
          <xsl:copy-of select="string-length(text())+1"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="string-length($offset) != 0">
        <xsl:copy-of select="substring($method, $offset)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="substring($method, 1)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================== -->
  <!-- split-method-name                                    -->
  <!-- ==================================================== -->

  <xsl:template name="split-method-name">
    <xsl:param name="method" />

    <xsl:variable name="stripped-name">
      <xsl:call-template name="remove-ns">
        <xsl:with-param name="method" select="$method" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:element name="signature">
      <xsl:text>(L</xsl:text>
      <xsl:call-template name="str:substring-before-last">
        <xsl:with-param name="text">
          <xsl:call-template name="str:substring-after-last">
            <xsl:with-param name="text" select="$stripped-name"/>
            <xsl:with-param name="chars" select="'('"/>
          </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="chars" select="')'"/>
      </xsl:call-template>
      <xsl:text>;)</xsl:text>
    </xsl:element>

    <xsl:variable name="stripped-method">
      <xsl:call-template name="str:substring-before-last">
        <xsl:with-param name="text" select="$stripped-name"/>
        <xsl:with-param name="chars" select="'('"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="contains($stripped-method, '::')">
        <xsl:element name="class">
          <xsl:call-template name="str:substring-before-last">
            <xsl:with-param name="text" select="$stripped-method"/>
            <xsl:with-param name="chars" select="'::'"/>
          </xsl:call-template>
        </xsl:element>
        <xsl:element name="func">
          <xsl:call-template name="str:substring-after-last">
            <xsl:with-param name="text" select="$stripped-method"/>
            <xsl:with-param name="chars" select="'::'"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:when>

      <xsl:otherwise>
        <xsl:element name="class">
          <xsl:copy-of select="'$global$'"/>
        </xsl:element>
        <xsl:element name="func">
          <xsl:copy-of select="$stripped-method"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- ==================================================== -->
  <!-- fn                                                   -->
  <!-- ==================================================== -->

  <xsl:template match="fn" name="fn">

    <xsl:variable name="cd-ratio">
      <xsl:call-template name="cd-ratio" />
    </xsl:variable>

    <xsl:variable name="line-ratio">
      <xsl:call-template name="line-ratio" />
    </xsl:variable>

    <xsl:variable name="signature">
      <xsl:copy-of select="method-parts/signature" />
    </xsl:variable>

    <xsl:variable name="func">
      <xsl:copy-of select="method-parts/func" />
    </xsl:variable>
<!--
    <xsl:message>
      <xsl:text> Parts: </xsl:text>
      <xsl:copy-of select="method-parts/class" />
      <xsl:text> :: </xsl:text>
      <xsl:copy-of select="$func" />
      <xsl:text> == </xsl:text>
      <xsl:copy-of select="$signature" />
    </xsl:message>

    <xsl:copy-of select="." />
 -->
    <method name="{$func}" signature="{$signature}" line-rate="{$line-ratio}" branch-rate="{$cd-ratio}">
      <lines>
        <xsl:for-each select="probe">

          <xsl:variable name="hits">
            <xsl:choose>
              <xsl:when test="@event= 'full'">
                <xsl:text>1</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'none'">
                <xsl:text>0</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'true'">
                <xsl:text>1</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'false'">
                <xsl:text>1</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="concat(@hits, ' hits ???')" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="con-cov">
            <xsl:choose>
              <xsl:when test="@event= 'full'">
                <xsl:text>100% (2/2)</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'none'">
                <xsl:text>0% (0/2)</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'true'">
                <xsl:text>50% (1/2)</xsl:text>
              </xsl:when>
              <xsl:when test="@event= 'false'">
                <xsl:text>50% (1/2)</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="concat(@event, ' event ???')" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:choose>

            <xsl:when test="@kind = 'decision'">
              <line number="{@line}" hits="{$hits}" branch="true" condition-coverage="{$con-cov}"/>
            </xsl:when>

            <xsl:when test="@kind = 'switch-label'">
              <line number="{@line}" hits="{$hits}" branch="false" />
            </xsl:when>

            <xsl:when test="@kind = 'catch'">
              <line number="{@line}" hits="{$hits}" branch="false" />
            </xsl:when>

            <xsl:when test="@kind = 'try'">
              <line number="{@line}" hits="{$hits}" branch="false" />
            </xsl:when>

            <xsl:when test="@kind = 'condition'">
          <!-- part of decision, but can't safely be mapped back -->
              <line number="{@line}" hits="{$hits}" branch="true" condition-coverage="{$con-cov}"/>
            </xsl:when>

            <xsl:when test="@kind = 'function'">
              <line number="{@line}" hits="{$hits}" branch="false" />
            </xsl:when>

            <xsl:when test="@kind = 'constant'">
              <line number="{@line}" hits="{$hits}" branch="false" />
            </xsl:when>

            <xsl:otherwise>
              <line number="{@line}" hits="{concat(@kind, ' kind ???')}" branch="false" />
            </xsl:otherwise>

          </xsl:choose>
        </xsl:for-each>
      </lines>
    </method>
  </xsl:template>

  <!-- ==================================================== -->
  <!-- src                                                  -->
  <!-- ==================================================== -->

  <xsl:template match="src" name="src">
    <xsl:param name="current-path" />
    <xsl:param name="current-package" />
<!--
    <xsl:message>
      <xsl:copy-of select="concat('src: ', @name)" />
    </xsl:message>
 -->
    <xsl:variable name="cd-ratio">
      <xsl:call-template name="cd-ratio" />
    </xsl:variable>

    <xsl:variable name="line-ratio">
      <xsl:call-template name="line-ratio" />
    </xsl:variable>

    <xsl:if test="count(fn) != 0">

      <xsl:variable name="class-set">
        <xsl:for-each select="fn">

          <xsl:element name="fn">
            <xsl:copy-of select="node()|@*" />
            <xsl:element name="method-parts">
              <xsl:call-template name="split-method-name">
                <xsl:with-param name="method" select="@name" />
              </xsl:call-template>
            </xsl:element>
          </xsl:element>

        </xsl:for-each>
      </xsl:variable>

      <xsl:call-template name="class">
        <xsl:with-param name="call-type"       select="'full'"/>
        <xsl:with-param name="current-path"    select="$current-path"/>
        <xsl:with-param name="current-package" select="$current-package"/>
        <xsl:with-param name="class-set"       select="exsl:node-set($class-set)" />
      </xsl:call-template>

    </xsl:if>

  </xsl:template>

  <!-- ==================================================== -->
  <!-- class                                                -->
  <!-- ==================================================== -->

  <xsl:template name="class">
    <xsl:param name="current-path" />
    <xsl:param name="current-package" />
    <xsl:param name="class-set" />
    <xsl:param name="call-type" />
<!--
    <xsl:message>
      <xsl:copy-of select="concat('call-type: ', $call-type)" />
    </xsl:message>
 -->
    <xsl:if test="count($class-set/fn)">

      <xsl:variable name="cd-ratio">
        <xsl:call-template name="cd-ratio">
          <xsl:with-param name="cov"   select="sum($class-set/fn[@cd_total != 0]/@cd_cov)" />
          <xsl:with-param name="total" select="sum($class-set/fn[@cd_total != 0]/@cd_total)" />
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="line-ratio">
        <xsl:call-template name="line-ratio" />
      </xsl:variable>

      <xsl:variable name="current-class" select="exsl:node-set($class-set)/fn[1]/method-parts/class" />
<!--
      <xsl:message>
        <xsl:copy-of select="concat('current class: ', $current-class)" />
      </xsl:message>
 -->
      <class name="{$current-class}" filename="{$current-path}" line-rate="{$line-ratio}" branch-rate="{$cd-ratio}">
        <methods>
          <xsl:for-each select="$class-set/fn[method-parts/class = $current-class]">
<!--
            <xsl:message>
              <xsl:text>foreach fn: </xsl:text><xsl:copy-of select="$current-class" />
            </xsl:message>
 -->
            <xsl:apply-templates select="." />

          </xsl:for-each>
        </methods>
      </class>

      <xsl:variable name="class-rest">
        <xsl:for-each select="$class-set/fn[method-parts/class != $current-class]">
<!--
          <xsl:message>
            <xsl:copy-of select="concat('fwd class-rest: ', method-parts/class)" />
          </xsl:message>
 -->
          <xsl:element name="fn">
            <xsl:copy-of select="node()|@*" />
          </xsl:element>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="count(exsl:node-set($class-rest)/fn)">

        <xsl:call-template name="class">
          <xsl:with-param name="call-type"       select="'rest'"/>
          <xsl:with-param name="current-path"    select="$current-path"/>
          <xsl:with-param name="current-package" select="$current-package"/>
          <xsl:with-param name="class-set"       select="exsl:node-set($class-rest)" />
        </xsl:call-template>

      </xsl:if>

    </xsl:if>

  </xsl:template>

  <!-- ==================================================== -->
  <!-- folder                                               -->
  <!-- ==================================================== -->

  <xsl:template match="folder" name="folder">
    <xsl:param name="current-path" />
    <xsl:param name="current-package" />

    <xsl:if test="src">

      <xsl:variable name="line-ratio">
        <xsl:call-template name="line-ratio" />
      </xsl:variable>

      <xsl:variable name="cd-ratio">
        <xsl:call-template name="cd-ratio" />
      </xsl:variable>

      <package name="{$current-package}" line-rate="{$line-ratio}" branch-rate="{$cd-ratio}" complexity="1.0">
        <classes>

          <xsl:for-each select="src">
            <xsl:call-template name="src">
              <xsl:with-param name="current-path"    select="concat($current-path, '/',    @name)" />
              <xsl:with-param name="current-package" select="concat($current-package, '.', @name)" />
            </xsl:call-template>
          </xsl:for-each>

        </classes>
      </package>

    </xsl:if>

    <xsl:for-each select="folder">
      <xsl:call-template name="folder">
        <xsl:with-param name="current-path"    select="concat($current-path, '/',    @name)" />
        <xsl:with-param name="current-package" select="concat($current-package, '.', @name)" />
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

   <!-- ==================================================== -->
   <!-- BullseyeCoverage                                     -->
   <!-- ==================================================== -->

  <xsl:template match="/BullseyeCoverage">

   <xsl:variable name="cd-ratio">
      <xsl:call-template name="cd-ratio">
        <xsl:with-param name="cov"   select="folder/@cd_cov"   />
        <xsl:with-param name="total" select="folder/@cd_total" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="line-ratio">
      <xsl:call-template name="line-ratio" />
    </xsl:variable>

    <coverage line-rate="{$line-ratio}" branch-rate="{$cd-ratio}" version="1.9" timestamp="1240339705747">

      <sources>
        <source>
          <xsl:value-of select="$root" />
        </source>
      </sources>

      <packages>

        <xsl:for-each select="folder">
          <xsl:call-template name="folder">
            <xsl:with-param name="current-path"    select="@name" />
            <xsl:with-param name="current-package" select="@name" />
          </xsl:call-template>
        </xsl:for-each>

      </packages>
    </coverage>

  </xsl:template>

  <!-- ==================================================== -->
  <!-- cd-ratio                                             -->
  <!-- ==================================================== -->

  <xsl:template name="cd-ratio">
    <xsl:param name="cov"   select="@cd_cov" />
    <xsl:param name="total" select="@cd_total" />
<!--
    <xsl:message>
      <xsl:copy-of select="concat(' cd_cov: ',   $cov)"/>
      <xsl:copy-of select="concat(' cd_total: ', $total)"/>
    </xsl:message>
 -->
    <xsl:choose>
      <xsl:when test="$total = '' or $total + $cov = 0">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="$total = 0">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$cov div $total" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================== -->
  <!-- line-ratio                                             -->
  <!-- ==================================================== -->

  <xsl:template name="line-ratio">
    <xsl:param name="cov"   select="count(.//probe[not(@column) and @event != 'none'])" />
    <xsl:param name="total" select="count(.//probe[not(@column)])" />
    <xsl:choose>
      <xsl:when test="$total + $cov = 0">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="$total = 0">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$cov div $total" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

