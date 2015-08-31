xquery version "3.0";

import module namespace config="http://exist-db.org/apps/appblueprint/config" at "/apps/sarit/modules/config.xqm";
import module namespace tei-to-html = "http://exist-db.org/xquery/app/tei2html" at "/apps/sarit/modules/tei2html.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8"/>
<title>HTML pagination</title>
</head>
<body>
{tei-to-html:recurse(doc("/apps/sarit-data/data/arunadatta-sarvangasundara.xml")/*, <options/>)}
</body>
</html>
