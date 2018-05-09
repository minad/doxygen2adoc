all:
	doxygen Doxyfile-c
	xsltproc -o doc/all.xml doc/xml/combine.xslt doc/xml/index.xml
	xsltproc -o example.adoc adoc.xsl doc/all.xml
	./adoc-postprocess.pl example.adoc
