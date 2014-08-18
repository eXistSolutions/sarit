xquery version "3.0";

declare boundary-space preserve;

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:change-attributes($node as node(), $new-name as xs:string, $new-content as item(), $action as xs:string, $target-element-names as xs:string+, $target-attribute-names as xs:string+) as node()+ {
    if ($node instance of element()) 
    then
        element {node-name($node)} 
        {
            if ($action = 'attach-attribute-to-element' and name($node) = $target-element-names)
            then ($node/@*, attribute {$new-name} {$new-content})
            else 
            $node/@*
            ,
            for $child in $node/node()
            return $child        
        }
    else $node
};

declare function local:add-references($element as element()) as element() {
    element {node-name($element)}
    {$element/@*,
    for $child in $element/node()
        return
            if ($child instance of element() and $child/parent::element()/@xml:id)
            then
                if (not($child/@xml:id))
                then
                    let $local-name := local-name($child)
                    let $preceding-siblings := $child/preceding-sibling::element()
                    let $preceding-siblings := count($preceding-siblings[local-name(.) eq $local-name])
                    let $following-siblings := $child/following-sibling::element()
                    let $following-siblings := count($following-siblings[local-name(.) eq $local-name])
                    let $seq-no := 
                        if ($preceding-siblings = 0 and $following-siblings = 0)
                        then ''
                        else $preceding-siblings + 1
                    let $id-value := concat($child/../@xml:id, '-', $local-name, if ($seq-no) then '-' else '', $seq-no)
                    return
                        local:change-attributes($child, 'xml:id', $id-value, 'attach-attribute-to-element', ('body', 'trailer', 'fw', 'div', 'hi', 'docAuthor', 'quote', 'docTitle', 'head', 'note', 'titlePage', 'text', 'cell', 'front', 'l', 'table', 'row', 'ref', 'seg', 'pb', 'lg', 'q', 'p', 'ab', 'lb', 'foreign', 'titlePart'), '')
                else local:add-references($child)
            else
                 if ($child instance of element())
                 then local:add-references($child)
                 else $child
      }
};

declare function local:add-references-recursively($now as element()) as element() {
  let $next := local:add-references($now)
  return
    if (deep-equal($now, $next))
    then $now
    else local:add-references-recursively($next)
};

(:http://wiki.tei-c.org/index.php/XML_Whitespace
#1 Retain one leading space if the node isn't first, has non-space content, and has leading space.
#2 Retain one trailing space if the node isn't last, isn't first, and has trailing space. 
#3 Retain one trailing space if the node isn't last, is first, has trailing space, and has non-space content.
#4 Retain a single space if the node is an only child and only has space content.:)
declare function local:tei-normalize-space($input)
{
   element {node-name($input)}
      {$input/@*,
          for $child in $input/node()
              return
               if ($child instance of element())
                 then local:tei-normalize-space($child)
                 else 
                     if ($child instance of text())
                     then 
                        (:#1 Retain one leading space if node isn't first, has non-space content, and has leading space:)
                        if ($child/position() ne 1 and matches($child,'^\s') and normalize-space($child) ne '')
                        then (' ', normalize-space($child))
                        else
                            (:#4 retain one space, if the node is an only child, and has content but it's all space:)
                            if ($child/last() eq 1 and string-length($child) ne 0 and normalize-space($child) eq '')
                            (:NB: this overrules standard normalization:)
                            then ' ' 
                            else 
                                (:#2 if the node isn't last, isn't first, and has trailing space, retain trailing space and collapse and trim the rest:)
                                if ($child/position() ne 1 and $child/position() ne last() and matches($child,'\s$'))
                                then (normalize-space($child), ' ')
                                else 
                                    (:#3 if the node isn't last, is first, has trailing space, and has non-space content, then keep trailing space:)
                                    if ($child/position() eq 1 and matches($child,'\s$') and normalize-space($child) ne '')
                                    then (normalize-space($child), ' ')
                                    (:if the node is an only child, and has content which is not all space, then trim and collapse, that is, apply standard normalization:)
                                    else normalize-space($child)
                     (:output comments and pi's:)
                     else $child
      }
};


let $doc := doc('/db/apps/sarit-data/data/tsp-dn.xml')/*
let $doc := local:tei-normalize-space($doc)
let $doc := local:add-references-recursively($doc)
return $doc
