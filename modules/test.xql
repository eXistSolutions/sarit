xquery version "3.0";


let $child-resources := xmldb:get-child-resources("/db/apps/sarit-data/data")
let $xml-resources := for $child in $child-resources 
                        return 
                            if(contains($child, ".xml"))
                            then ($child)
                            else ()
                        
return $xml-resources            