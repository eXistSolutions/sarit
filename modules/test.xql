xquery version "3.0";

import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";


let $child-resources := xmldb:get-child-resources($config:remote-data-root)
let $xml-resources := for $child in $child-resources 
                        return 
                            if(contains($child, ".xml") and $child ne "00-SARIT-TEI-header-template.xml")
                            then (
                                let $title := doc($config:remote-data-root || "/" || $child)//tei:title[@type eq "main"]
                                return 
                                    <p>{$title/text()}</p>
                            )
                            else ()
                        
return     

<div style="border:1px solid gray;">
    {$xml-resources}
</div>