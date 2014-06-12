xquery version "3.0";

module namespace app="http://exist-db.org/apps/appblueprint/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute: data-template="app:test" or class="app:test" (deprecated). 
 : The function has to take 2 default parameters. Additional parameters are automatically mapped to
 : any matching request or function parameter.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)

declare function app:list-downloads($node as node(), $model as map(*)) {
    let $child-resources := xmldb:get-child-resources($config:remote-data-root)
    let $xml-resources := for $file in $child-resources 
                            return 
                                if(contains($file, ".xml") and $file ne "00-SARIT-TEI-header-template.xml")
                                then (
                                    let $header := doc($config:remote-data-root || "/" || $file)//tei:titleStmt
                                    let $title := $header//tei:title[@type eq "main"]
                                    let $subtitle := $header//tei:title[@type eq "sub"][1]
                                    let $author :=  if(exists($header//tei:respStmt/tei:persName)) 
                                                    then (string-join($header//tei:respStmt/tei:persName,', '))
                                                    else (
                                                        if(exists($header//tei:respStmt/tei:orgName))
                                                        then ($header//tei:respStmt/tei:orgName)
                                                        else (
                                                            if(exists($header//tei:respStmt/tei:name))
                                                            then ($header//tei:respStmt/tei:name)
                                                            else string-join($header//tei:author,', ')
                                                            
                                                        )
                                                        
                                                    )
                                                    
                                    let $bytes := xmldb:size($config:remote-data-root, $file)
                                    
                                    let $size := if($bytes lt 1048576) 
                                                    then (format-number($bytes div 1024,"#,###.##") || "kB") 
                                                    else (format-number($bytes div 1048576,"#,###.##") || "MB" )
                                                    
                                    let $downloadPath := request:get-scheme() ||"://" || request:get-server-name() || ":" || request:get-server-port() || substring-before(request:get-effective-uri(),"/db/apps/sarit/modules/view.xql") || $config:remote-download-root || "/" || substring-before($file,".xml") || ".zip"
                                    
                                    return 
                                        <div style="border-top:1px solid gray;padding-top:5px;" class="row">
                                            <div class="col-md-12">
                                                <p><strong>{$title/text()}</strong> - <small>{$subtitle/text()}</small></p>
                                                <p>Author(s): {$author}</p>
                                                <p>File: <a href="{$downloadPath}">{xmldb:decode($file)}</a> - Size: {$size}</p>
                                            </div>
                                        </div>
                                )
                                else ()
                            
    return     
        $xml-resources
    
};




