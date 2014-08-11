xquery version "3.0";

import module namespace sarit="http://exist-db.org/xquery/sarit";
import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";

declare variable $devnag2roman := doc($config:app-root || "/modules/transliteration-rules.xml")/transliteration/rules[@id = "devnag2roman"];
declare variable $roman2devnag := doc($config:app-root || "/modules/transliteration-rules.xml")/transliteration/rules[@id = "roman2devnag"];

declare function local:init() {
    sarit:create("devnag2roman", $devnag2roman/string()),
    sarit:create("roman2devnag", $roman2devnag/string())
};

declare function local:transform($nodes as node()*, $mode as xs:string?) {
    for $node in $nodes
    return
        typeswitch($node)
            case element() return
                let $lang := $node/@xml:lang
                let $newMode :=
                    if ($lang) then
                        if ($lang = "sa-Deva") then
                            "devnag2roman"
                        else
                            "roman2devnag"
                    else
                        $mode
                return
                    element { node-name($node) } {
                        $node/@* except $node/@xml:lang,
                        if ($lang) then
                            attribute xml:lang { if ($lang = "sa-Deva") then "sa-Latn" else "sa-Deva" }
                        else
                            (),
                        local:transform($node/node(), $newMode)
                    }
            case text() return
                if ($mode) then
                    sarit:transliterate($mode, $node)
                else
                    $node
            default return
                $node
};


local:init(),
let $doc := request:get-parameter("doc", ())
return
    if ($doc) then
        local:transform(doc($config:remote-data-root || "/" || $doc)/*, ())
    else
        ()