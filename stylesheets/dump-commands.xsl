<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
                version="1.0">

<!-- XSLT stylesheet to extract commands from [B,H]LFS books. -->

  <xsl:variable name="newline">
    <xsl:text>&#xA;</xsl:text>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
      <!-- The dirs names -->
    <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
    <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
    <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
      <!-- The file names -->
    <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
    <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
      <!-- The build order -->
    <xsl:variable name="position" select="position()"/>
    <xsl:variable name="order">
      <xsl:choose>
        <xsl:when test="string-length($position) = 1">
          <xsl:text>00</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:when test="string-length($position) = 2">
          <xsl:text>0</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$position"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <!-- Creating dirs and files -->
    <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
      <xsl:apply-templates select=".//screen"/>
    </exsl:document>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput">
      <xsl:choose>
        <xsl:when test="@role = 'root'">
          <xsl:text># Kjør dette som root</xsl:text>
          <xsl:value-of select="$newline"/>
          <xsl:apply-templates select="userinput"/>
          <xsl:text># Avslutt root kommandoer</xsl:text>
          <xsl:value-of select="$newline"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="userinput"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$newline"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:if test=".//replaceable">
      <xsl:text># Denne blokken må redigeres for å passe dine behov.</xsl:text>
      <xsl:value-of select="$newline"/>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:value-of select="$newline"/>
    <xsl:if test=".//replaceable">
      <xsl:text># Slutt på redigerbar blokk.</xsl:text>
      <xsl:value-of select="$newline"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:text>**REDIGERINGMEG</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>REDIGERINGMEG**</xsl:text>
  </xsl:template>

</xsl:stylesheet>
