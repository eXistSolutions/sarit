xquery version "3.0";

module namespace metadata = "http://exist-db.org/ns/sarit/metadata/";

import module namespace config = "http://exist-db.org/apps/appblueprint/config" at "config.xqm";
import module "http://expath.org/ns/pdf";

declare variable $metadata:metadata := doc($config:remote-root || "/metadata.xml")/*;

declare function metadata:count-pdf-pages() {
    let $pdf-files-collection := $config:remote-root || "/download/pdf/"
    let $pdf-work-pages :=
        for $pdf-file-name in xmldb:get-child-resources($pdf-files-collection)
        let $pdf-file-path := $pdf-files-collection || $pdf-file-name
        
        return map:get(pdf:get-metadata(util:binary-doc($pdf-file-path)), "number-of-pages")
        
    let $pdf-work-pages-total := sum($pdf-work-pages)
    
    let $store-pdf-work-pages-total := update value $metadata:metadata/metadata:number-of-pdf-pages with $pdf-work-pages-total

    
    return $pdf-work-pages-total
};
