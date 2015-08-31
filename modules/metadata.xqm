xquery version "3.0";

module namespace metadata = "http://exist-db.org/ns/sarit/metadata/";

import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";

declare variable $metadata:metadata := doc($config:remote-root || "/metadata.xml")/*;
