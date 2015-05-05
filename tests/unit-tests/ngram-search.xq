xquery version "3.0";

import module namespace config="http://exist-db.org/apps/appblueprint/config" at "/apps/sarit/modules/config.xqm";
import module namespace tei-to-html = "http://exist-db.org/xquery/app/tei2html" at "/apps/sarit/modules/tei2html.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare %private function local:get-content($div as element()) {
    if ($div instance of element(tei:teiHeader)) then 
        $div
    else
        if ($div instance of element(tei:div)) then
            if ($div/tei:div) then
                if (count(($div/tei:div[1])/preceding-sibling::*) < 5) then
                    let $child := $div/tei:div[1]
                    return
                        element { node-name($div) } {
                            $div/@*,
                            $child/preceding-sibling::*,
                            local:get-content($child)
                        }
                else
                    element { node-name($div) } {
                        $div/@*,
                        $div/tei:div[1]/preceding-sibling::*
                    }
            else
                $div
        else $div
};

let $query := "gṛhītagrah.*"
let $context := collection($config:remote-data-root)/tei:TEI/tei:text


return
    <result>
        {    
            for $hit in
                (
                    $context//tei:p[ngram:wildcard-contains(., $query[1])],
                    $context//tei:head[ngram:wildcard-contains(., $query[1])],
                    $context//tei:lg[ngram:wildcard-contains(., $query[1])],
                    $context//tei:trailer[ngram:wildcard-contains(., $query[1])],
                    $context//tei:note[ngram:wildcard-contains(., $query[1])],
                    $context//tei:list[ngram:wildcard-contains(., $query[1])],
                    $context//tei:l[not(local-name(./..) eq 'lg')][ngram:wildcard-contains(., $query[1])],
                    $context//tei:quote[ngram:wildcard-contains(., $query[1])],
                    $context//tei:table[ngram:wildcard-contains(., $query[1])],
                    $context//tei:listApp[ngram:wildcard-contains(., $query[1])],
                    $context//tei:listBibl[ngram:wildcard-contains(., $query[1])],
                    $context//tei:cit[ngram:wildcard-contains(., $query[1])],
                    $context//tei:label[ngram:wildcard-contains(., $query[1])],
                    $context//tei:encodingDesc[ngram:wildcard-contains(., $query[1])],
                    $context//tei:fileDesc[ngram:wildcard-contains(., $query[1])],
                    $context//tei:profileDesc[ngram:wildcard-contains(., $query[1])],
                    $context//tei:revisionDesc[ngram:wildcard-contains(., $query[1])]
                )    
            return util:expand($hit, "add-exist-id=all")
        }
    </result>            
