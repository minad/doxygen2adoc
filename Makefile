all:
	doxygen Doxyfile-c
	java -jar saxon/saxon9he.jar -o:doc/all.xml doc/xml/index.xml doc/xml/combine.xslt
	java -jar saxon/saxon9he.jar -o:example.adoc doc/all.xml adoc.xsl
	./adoc-postprocess.pl example.adoc
