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

let $query :=
<query>
    <bool>
        <regex occur="should">gṛhītagrah.*</regex>
    </bool>
</query> 
let $context := collection($config:remote-data-root)/tei:TEI/tei:text


return
    <result>
        {
            for $hit in
                (
                    $context//tei:p[ft:query(., $query)],
                    $context//tei:head[ft:query(., $query)],
                    $context//tei:lg[ft:query(., $query)],
                    $context//tei:trailer[ft:query(., $query)],
                    $context//tei:note[ft:query(., $query)],
                    $context//tei:list[ft:query(., $query)],
                    $context//tei:l[not(local-name(./..) eq 'lg')][ft:query(., $query)],
                    $context//tei:quote[ft:query(., $query)],
                    $context//tei:table[ft:query(., $query)],
                    $context//tei:listApp[ft:query(., $query)],
                    $context//tei:listBibl[ft:query(., $query)],
                    $context//tei:cit[ft:query(., $query)],
                    $context//tei:label[ft:query(., $query)]
                )    
            return util:expand($hit, "add-exist-id=all")
        }
    </result>
