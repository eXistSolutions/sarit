xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";

declare variable $home external;
declare variable $target external;

(    
    (: set special permissions for xquery scripts :)
    sm:chmod(xs:anyURI($target || "/modules/pdf.xql"), "rwxr-sr-x")
)
