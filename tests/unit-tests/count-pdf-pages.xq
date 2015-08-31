xquery version "3.0";

import module "http://expath.org/ns/pdf";
import module namespace config="http://exist-db.org/apps/appblueprint/config" at "/apps/sarit/modules/config.xqm";

let $pdf-files-collection := $config:remote-root || "/download/pdf/"
let $pdf-work-pages :=
    for $pdf-file-name in xmldb:get-child-resources($pdf-files-collection)
    let $pdf-file-path := $pdf-files-collection || $pdf-file-name
    
    return map:get(pdf:get-metadata(util:binary-doc($pdf-file-path)), "number-of-pages")
    
let $pdf-work-pages-total := sum($pdf-work-pages)

return $pdf-work-pages-total
