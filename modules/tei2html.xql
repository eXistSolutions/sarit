module namespace tei-to-html="http://exist-db.org/xquery/app/tei2html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: A helper function in case no options are passed to the function :)
declare function tei-to-html:render($content as node()*) as element() {
    tei-to-html:render($content, ())
};

(: The main function for the tei-to-html module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei-to-html:render($content as node()*, $options as element(parameters)*) as element() {
    <div class="document">
        { tei-to-html:dispatch($content, $options) }
    </div>
};

(: Typeswitch routine: Takes any node in a TEI content and either dispatches it to a dedicated 
 : function that handles that content (e.g. div), ignores it by passing it to the recurse() function
 : (e.g. text), or handles it directly (none). :)
declare function tei-to-html:dispatch($node as node()*, $options) as item()* {
    typeswitch($node)
        case text() return $node
        case element(tei:TEI) return tei-to-html:recurse($node, $options)
        
        case element(tei:teiHeader) return tei-to-html:teiHeader($node, $options)
        
        case element(tei:text) return tei-to-html:recurse($node, $options)
        case element(tei:front) return tei-to-html:recurse($node, $options)
        case element(tei:body) return tei-to-html:recurse($node, $options)
        case element(tei:back) return tei-to-html:recurse($node, $options)
        
        case element(tei:div) return tei-to-html:div($node, $options)
        case element(tei:head) return tei-to-html:head($node, $options)
        case element(tei:p) return tei-to-html:p($node, $options)
        case element(tei:hi) return tei-to-html:hi($node, $options)
        case element(tei:list) return tei-to-html:list($node, $options)
        case element(tei:item) return tei-to-html:item($node, $options)
        case element(tei:label) return tei-to-html:label($node, $options)
        case element(tei:ref) return tei-to-html:ref($node, $options)
        case element(tei:sp) return tei-to-html:sp($node, $options)
        case element(tei:said) return tei-to-html:said($node, $options)
        case element(tei:foreign) return tei-to-html:foreign($node, $options)
        case element(tei:mentioned) return tei-to-html:mentioned($node, $options)
        case element(tei:lb) return tei-to-html:lb($node, $options)
        case element(tei:figure) return tei-to-html:figure($node, $options)
        case element(tei:graphic) return tei-to-html:graphic($node, $options)
        case element(tei:table) return tei-to-html:table($node, $options)
        case element(tei:row) return tei-to-html:row($node, $options)
        case element(tei:cell) return tei-to-html:cell($node, $options)
        case element(tei:pb) return tei-to-html:pb($node, $options)
        case element(tei:lg) return tei-to-html:lg($node, $options)
        case element(tei:l) return tei-to-html:l($node, $options)
        case element(tei:name) return tei-to-html:name($node, $options)
        case element(tei:milestone) return tei-to-html:milestone($node, $options)
        case element(tei:quote) return tei-to-html:quote($node, $options)
        case element(tei:seg) return tei-to-html:seg($node, $options)
        case element(tei:bibl) return tei-to-html:bibl($node, $options)
        case element(tei:respStmt) return tei-to-html:respStmt($node, $options)
        case element(exist:match) return tei-to-html:exist-match($node, $options)
        default return tei-to-html:recurse($node, $options)
};

(: Recurses through the child nodes and sends them tei-to-html:dispatch() :)
declare function tei-to-html:recurse($node as node(), $options) as item()* {
    for $node in $node/node()
    return 
        tei-to-html:dispatch($node, $options)
};

declare function tei-to-html:div($node as element(tei:div), $options) {
    if ($node/@xml:id) 
    then tei-to-html:xmlid($node, $options) 
    else ()
    ,
    if ($node/@type eq 'adhyāya')
    then
        if ($node//tei:persName)
        then
            (
            <a class="linebefore"/>
            ,
            <div class="notes">
                <h3>Persons mentioned</h3>
                <ul>
                {
                for $persName in $node//tei:persName
                let $key := $persName/@key 
                order by $key
                return
                    if (not($key = $persName/preceding::tei:persName/@key))
                    then
                      <li>
                        {
                        concat(translate($key,'#',''), ': ')
                        ,
                        for $key in $persName/@key[.=$key]
                        let $keycount := count($persName/preceding::tei:persName/@key[.=$key]) + 1
                        return
                          <a href="{$key}{$keycount}">{concat($keycount, ' ')}</a>
                        }
                      </li>
                    else ()      
                }
                </ul>
            </div>
            )
        else
            if ($node//tei:ref[@cRef])
            then
                (
                <a class="linebefore"/>
                ,
                <div class="notes">
                    <h3>Texts quoted</h3>
                    <ul>
                    {
                    for $ref in $node//tei:ref[@cRef]
                    let $cRef := $ref/@cRef 
                    let $key := substring-before($cRef,'.') 
                    order by $cRef
                    return
                        if (not(preceding::tei:ref[contains(@cRef,$key)]))
                        then
                          <li>
                            {
                            <strong>{concat(@key, ': ')}</strong>
                            ,
                            for $key in $node//tei:ref[contains(@cRef, $key)]
                            
                            return
                              <a href="{$cRef}">{concat(substring-after($cRef,'.'), ' ')}</a>
                            }
                          </li>
                        else ()      
                    }
                    </ul>
                </div>
                )
            else ()
    else        
        tei-to-html:recurse($node, $options)
};

declare function tei-to-html:head($node as element(tei:head), $options) as element() {
    (: div heads :)
    if ($node/parent::tei:div) then
        let $type := $node/parent::tei:div/@type
        let $div-level := count($node/ancestor::div)
        return
            element {concat('h', $div-level + 2)} {tei-to-html:recurse($node, $options)}
    (: figure heads :)
    else if ($node/parent::tei:figure) then
        if ($node/parent::tei:figure/parent::tei:p) then
            <strong>{tei-to-html:recurse($node, $options)}</strong>
        else (: if ($node/parent::tei:figure/parent::tei:div) then :)
            <p><strong>{tei-to-html:recurse($node, $options)}</strong></p>
    (: list heads :)
    else if ($node/parent::tei:list) then
        <li>{tei-to-html:recurse($node, $options)}</li>
    (: table heads :)
    else if ($node/parent::tei:table) then
        <p class="center">{tei-to-html:recurse($node, $options)}</p>
    (: other heads? :)
    else
        tei-to-html:recurse($node, $options)
};

declare function tei-to-html:p($node as element(tei:p), $options) as element() {
    let $rend := $node/@rend
    return 
        if ($rend = ('right', 'center') ) 
        then
            <p>{ attribute class {data($rend)} }{ tei-to-html:recurse($node, $options) }</p>
        else 
            <p>{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:hi($node as element(tei:hi), $options) as element()* {
    let $rend := $node/@rend
    return
        if ($rend = 'it') then
            <em>{tei-to-html:recurse($node, $options)}</em>
        else if ($rend = 'sc') then
            <span style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="hi">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:list($node as element(tei:list), $options) as element() {
    <ul>{tei-to-html:recurse($node, $options)}</ul>
};

declare function tei-to-html:item($node as element(tei:item), $options) as element()+ {
    if ($node/@xml:id) then tei-to-html:xmlid($node, $options) else (),
    <li>{tei-to-html:recurse($node, $options)}</li>
};

declare function tei-to-html:label($node as element(tei:label), $options) as element() {
    if ($node/parent::tei:list) then 
        (
        <dt>{$node/text()}</dt>,
        <dd>{$node/following-sibling::tei:item[1]}</dd>
        )
    else tei-to-html:recurse($node, $options)
};

declare function tei-to-html:xmlid($node as element(), $options) as element() {
    <a name="{$node/@xml:id}"/>
};

declare function tei-to-html:ref($node as element(tei:ref), $options) {
    let $target := $node/@target
    return
        element a { 
            attribute href { $target },
            attribute title { $target },
            attribute target { '_blank' },
            tei-to-html:recurse($node, $options) 
            }
};

declare function tei-to-html:foreign($node as element(tei:foreign), $options) as element() {
    <span class="foreign">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:mentioned($node as element(tei:mentioned), $options) as element() {
    <span class="mentioned">{tei-to-html:recurse($node, $options)}</span>
};
declare function tei-to-html:said($node as element(tei:said), $options) as element() {
    <p class="said">{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:sp($node as element(tei:sp), $options) as element() {
    if ($node/tei:l) then
        <div xmlns="http://www.w3.org/1999/xhtml" class="sp" id="{tei-to-html:get-id($node)}">{ tei-to-html:recurse($node/node(), <options/>) }</div>
    else
        <div xmlns="http://www.w3.org/1999/xhtml" class="sp" id="{tei-to-html:get-id($node)}">
            { tei-to-html:recurse($node/tei:speaker, <options/>) }
            <p class="p-ab">{ tei-to-html:recurse($node/tei:ab, <options/>) }</p>
        </div>                
};

declare function tei-to-html:exist-match($node as element(), $options) as element() {
    <mark xmlns="http://www.w3.org/1999/xhtml">{ $node/node() }</mark>                    
};



declare function tei-to-html:lb($node as element(tei:lb), $options) as element() {
    <span class="padabreak"/>
};

declare function tei-to-html:seg($node as element(tei:seg), $options) as element() {
    (:NB: This had <xsl:variable name="letter" select="substring(@xml:id,string-length(@xml:id))"/> What does this means?:)
    let $letter := 
        if ($node/@type eq 'pada' and local-name($node/..) eq 'l')
        then $node/@xml:id/string()
        else
            if ($node/../following-sibling::l)
            then 
                if ($node/following-sibling::seg)
                then 'a'
                else 'b'
            else
                if ($node/following-sibling::seg)
                then 'c'
                else 'd'
        return
            <span class="{$letter}">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:figure($node as element(tei:figure), $options) {
    <div class="figure">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:graphic($node as element(tei:graphic), $options) {
    let $url := $node/@url
    let $head := $node/following-sibling::tei:head
    let $width := if ($node/@width) then $node/@width else '800px'
    let $relative-image-path := $options/*:param[@name='relative-image-path']/@value
    return
        <img src="{if (starts-with($url, '/')) then $url else concat($relative-image-path, $url)}" alt="{normalize-space($head[1])}" width="{$width}"/>
};

declare function tei-to-html:table($node as element(tei:table), $options) as element() {
    <table>{tei-to-html:recurse($node, $options)}</table>
};

declare function tei-to-html:row($node as element(tei:row), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <tr>{if ($label) then attribute class {'label'} else ()}{tei-to-html:recurse($node, $options)}</tr>
};

declare function tei-to-html:cell($node as element(tei:cell), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <td>{if ($label) then attribute class {'label'} else ()}{tei-to-html:recurse($node, $options)}</td>
};

declare function tei-to-html:pb($node as element(tei:pb), $options) {
    if ($node/@xml:id) 
    then tei-to-html:xmlid($node, $options) 
    else ()
    ,
    if ($options/*:param[@name='show-page-breaks']/@value = 'true') then
        <span class="pagenumber">
        <a id="pg{$node/@n/string()}"/>{
            concat('Page ', $node/@n/string())
        }</span>
    else ()
};

declare function tei-to-html:lg($node as element(tei:lg), $options) {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"></a> else ()
    ,
    <div xmlns="http://www.w3.org/1999/xhtml" class="lg" id="{tei-to-html:get-id($node)}">
        { 
        for $child in $node/node()
        return tei-to-html:recurse($child, <options/>) 
        }
    </div>
    )
};

declare function tei-to-html:l($node as element(tei:l), $options) {
    let $class := if ($node[last()]) then "l final" else "l non-final" 
    let $rend := $node/@rend
    return
        if ($node/@rend eq 'i2') then 
            <div class="{$class}" style="padding-left: 2em;">{tei-to-html:recurse($node, $options)}</div>
        else 
            <div class="{$class}">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:name($node as element(tei:name), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') then 
            <span class="name" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="name">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:milestone($node as element(tei:milestone), $options) {
    if ($node/@unit eq 'rule') 
    then
        if ($node/@rend eq 'stars') 
        then 
            <div style="text-align: center">* * *</div>
        else 
            if ($node/@rend eq 'hr') 
            then
                <hr style="margin: 7px;"/>
            else
                <hr/>
    else
        if ($node/@unit eq 'metricalgroup') 
        then
            <div class="metricalgroup">* * *</div>
        else
            <hr/>
};

declare function tei-to-html:quote($node as element(tei:quote), $options) {
    <blockquote>{tei-to-html:recurse($node, $options)}</blockquote>
};

declare function tei-to-html:said($node as element(tei:said), $options) {
    <span class="said">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:teiHeader($node as element(tei:teiHeader), $options) {
    tei-to-html:fileDesc($node/tei:fileDesc, $options)
};

declare function tei-to-html:fileDesc($node as element(tei:fileDesc), $options) {
    tei-to-html:titleStmt($node/tei:titleStmt, $options),
    tei-to-html:publicationStmt($node/tei:publicationStmt, $options),
    tei-to-html:sourceDesc($node/tei:sourceDesc, $options)
    (:
    let $encodingDesc := $node/tei:encodingDesc
    let $revisionDesc := $node/tei:revisionDesc:)
};

declare function tei-to-html:bibl($node as element(tei:bibl), $options) {
    let $authors := $node/tei:author
    let $titles := $node/tei:title
    let $editors := $node/tei:editor
    let $publishers := $node/tei:publisher
    (:let $meetings := $node/tei:meeting:)
    (:let $principals := $node/tei:principal:)
    (:let $sponsors := $node/tei:sponsor:)
    (:let $respStmts := $node/tei:respStmt:)
    let $pubPlaces := $node/tei:pubPlace
    let $dates := $node/tei:date
    let $seriess := $node/tei:series
    let $notes := $node/tei:note
    let $extents := $node/tei:extent
    let $result :=
    
        (
        for $title in $titles
        return 
            <div class="title">Title: {tei-to-html:recurse($title, $options)}</div>
        ,
        for $author in $authors
        return 
            <div class="author">Author: {tei-to-html:recurse($author, $options)}</div>
        ,
        for $editor in $editors
        return 
            <div class="editor">Editor: {tei-to-html:recurse($editor, $options)}</div>
        ,
        for $publisher in $publishers
        return 
            <div class="publisher">Publisher: {tei-to-html:recurse($publisher, $options)}</div>
        ,
        for $pubPlace in $pubPlaces
        return 
            <div class="pubPlace">Place of Publication: {tei-to-html:recurse($pubPlace, $options)}</div>
        ,
        for $extent in $extents
        return 
            <div class="extent">Extent: {tei-to-html:recurse($extent, $options)}</div>
        ,
        for $date in $dates
        return 
            <div class="date">Date: {tei-to-html:recurse($date, $options)}</div>
        ,
        for $series in $seriess
        return 
            <div class="series">Series: {tei-to-html:recurse($series, $options)}</div>
        ,
        for $note in $notes
        return 
            <div class="note">Note: {tei-to-html:recurse($note, $options)}</div>
        )
    return
        if ($node/../local-name() eq 'note')
        then
            <div class="hanging-indent">{$result}</div>
        else $result
};
declare function tei-to-html:sourceDesc($node as element(tei:sourceDesc), $options) {
        <div class="sourceDesc">
            <h3>Source Description</h3>
            {tei-to-html:bibl($node/tei:bibl, $options)}
        </div>
};

declare function tei-to-html:publicationStmt($node as element(tei:publicationStmt), $options) {
        let $authority := $node/tei:authority
        let $date := $node/tei:date
        let $authority := if ($authority) then <h2>Published by {tei-to-html:serialize-list($authority)}{if ($date) then concat(', ', $date) else ''}.</h2> else ()        
        
        let $availability := $node/tei:availability
        let $availability-status : = $availability/@status/string()
        let $availability := 
            if ($availability-status) 
            then 
                (
                <h4>Availability: {$availability-status}</h4>
                , 
                for $p at $i in $availability/tei:p
                return
                    (:if ($i = (2, 3, 8))
                    then tei-to-html:p($p, $options)
                    else ():)
                    tei-to-html:p($p, $options)
                )
            else ()       
        return
            <div class="publicationStmt">
            <h4>Publication Statement</h4>
                {$authority}
                {$availability}
            </div>
};
declare function tei-to-html:respStmt($node as element(tei:respStmt)*, $options) {
    let $responsibilties := distinct-values($node/tei:resp)
    return
    for $responsibilty in $responsibilties
        return
            <h3>{replace(normalize-space($responsibilty),'\.+$','')}: 
                {tei-to-html:serialize-list(
                    (
                    $node[tei:resp = $responsibilty]/tei:persName
                    ,
                    $node[tei:resp = $responsibilty]/tei:orgName
                    ,
                    $node[tei:resp = $responsibilty]/tei:name
                    ))}
            </h3>
};

declare function tei-to-html:titleStmt($node as element(tei:titleStmt), $options) {
        let $main-title := 
            if ($node/tei:title[@type eq 'main']) 
            then $node/tei:title[@type eq 'main']/text() 
            else $node/tei:title[1]/text()
        let $subtitles := $node/*:title[@type eq 'sub']/text()
        let $subtitles := if ($subtitles) then <h3>{string-join($subtitles, ', ')}</h3> else ()  
        
        let $authors := $node/tei:author
        let $authors := if ($authors) then <h2>By {tei-to-html:serialize-list($authors)}</h2> else ()
        
        let $editors := $node/tei:editor
        let $editors := if ($editors) then <h3>Editor{if (count($editors) gt 1) then 's' else ''}: {tei-to-html:serialize-list($editors)}</h3> else ()
        
        let $funders := $node/tei:funder
        let $funders := if ($funders) then <h3>Funder{if (count($funders) gt 1) then 's' else ''}: {tei-to-html:serialize-list($funders)}</h3> else ()
        
        let $principals := $node/tei:principal
        let $principals := if ($principals) then <h3>Principal{if (count($principals) gt 1) then 's' else ''}: {tei-to-html:serialize-list($principals)}</h3> else ()
        
        let $sponsors := $node/tei:sponsor
        let $sponsors := if ($sponsors) then <h3>Sponsor{if (count($sponsors) gt 1) then 's' else ''}: {tei-to-html:serialize-list($node/tei:sponsor)}</h3> else ()
        
        let $meetings := $node/tei:meeting
        let $meetings := if ($meetings) then <h3>Meetings: {tei-to-html:serialize-list($node/tei:meeting)}</h3> else ()
        
        let $respStmt := tei-to-html:respStmt($node/tei:respStmt, $options)
        
        return
            <div xmlns="http://www.w3.org/1999/xhtml" class="titleStmt">
                <a href="works/{$node/ancestor::tei:TEI/@xml:id}.html"><h1>{$main-title}</h1></a>
                {$authors}
                {$subtitles}
                {$editors}
                {$funders}
                {$principals}
                {$sponsors}
                {$meetings}
                {$respStmt}
            </div>
};

declare function tei-to-html:serialize-list($sequence as item()+) as xs:string {       
    let $sequence-count := count($sequence)
    return
    if ($sequence-count eq 1)
        then $sequence
        else
            if ($sequence-count eq 2)
            then concat(
                subsequence($sequence, 1, $sequence-count - 1),
                (:Places " and " before last item.:)
                ' and ',
                $sequence[$sequence-count]
                )
            else concat(
                (:Places ", " after all items that do not come last.:)
                string-join(subsequence($sequence, 1, $sequence-count - 1)
                , ', ')
                ,
                (:Places ", and " before item that comes last.:)
                ', and ',
                $sequence[$sequence-count]
                )
};

declare %private function tei-to-html:get-id($node as element()) {
    ($node/@xml:id, $node/@exist:id)[1]
};