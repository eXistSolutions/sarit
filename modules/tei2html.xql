xquery version "3.0";

module namespace tei-to-html="http://exist-db.org/xquery/app/tei2html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: A helper function in case no options are passed to the function :)
declare function tei-to-html:render($content as node()*) as element()+ {
    tei-to-html:render($content, <parameters/>)
};

(: The main function for the tei-to-html module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei-to-html:render($content as node()*, $options as element(parameters)*) as element()+ {
    <div class="document">
        { tei-to-html:dispatch($content, $options) }
    </div>
};

(: Typeswitch routine: Takes any node in a TEI content and either dispatches it to a dedicated 
 : function that handles that content (e.g. div), ignores it by passing it to the recurse() function
 : (e.g. text), or handles it directly (none). :)
declare function tei-to-html:dispatch($nodes as node()*, $options) as item()* {
    for $node in $nodes
    return
        typeswitch($node)
            case text() return $node
            
            case element(tei:TEI) return tei-to-html:recurse($node, $options)
            
            case element(tei:teiHeader) return tei-to-html:teiHeader($node, $options)
                (:contained by: teiCorpus, TEI:)
                (:contains: fileDesc, model.teiHeaderPart*, revisionDesc?:)
            case element(tei:encodingDesc) return tei-to-html:encodingDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( model.encodingDescPart | model.pLike )+:)
            case element(tei:editorialDecl) return tei-to-html:editorialDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: ( model.pLike | model.editorialDeclPart )+:)
            case element(tei:classDecl) return tei-to-html:classDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: taxonomy+:)
            case element(tei:refsDecl) return tei-to-html:refsDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: ( model.pLike+ | cRefPattern+ | refState+ ):)
            case element(tei:fileDesc) return tei-to-html:fileDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( ( titleStmt, editionStmt?, extent?, publicationStmt, seriesStmt?, notesStmt? ), sourceDesc+ ):)
            case element(tei:profileDesc) return tei-to-html:profileDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( model.profileDescPart* ):)
            case element(tei:revisionDesc) return tei-to-html:revisionDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( list | listChange | change+ ):)
            case element(tei:titleStmt) return tei-to-html:titleStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( title+, model.respLike* ):)
            case element(tei:publicationStmt) return tei-to-html:publicationStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( ( ( model.publicationStmtPart.agency ), model.publicationStmtPart.detail* )+ | model.pLike+ ):)
            case element(tei:sourceDesc) return tei-to-html:sourceDesc($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( model.biblLike | model.sourceDescPart | model.listLike )+ ):)
            case element(tei:notesStmt) return tei-to-html:notesStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.noteLike | relatedItem )+:)
            case element(tei:extent) return tei-to-html:extent($node, $options)
                (:contained by: bibl monogr biblFull fileDesc supportDesc:)
                (:contains: macro.phraseSeq:)
            case element(tei:editionStmt) return tei-to-html:editionStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( edition, model.respLike* ) ):)
            case element(tei:seriesStmt) return tei-to-html:seriesStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( title+, ( editor | respStmt )*, ( idno | biblScope )* ) ):)
            case element(tei:listChange) return tei-to-html:listChange($node, $options)
                (:contained by: creation listChange revisionDesc:)
                (:contains: ( listChange | change )+:)
            case element(tei:change) return tei-to-html:change($node, $options)
                (:contained by: listChange revisionDesc recordHist:)
                (:contains: macro.specialPara:)
                
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
            case element(tei:sic) return tei-to-html:sic($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:corr) return tei-to-html:corr($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:del) return tei-to-html:del($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:add) return tei-to-html:add($node, $options)
                (:contains: macro.paraContent:)            
            case element(tei:foreign) return tei-to-html:foreign($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:mentioned) return tei-to-html:mentioned($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:figure) return tei-to-html:figure($node, $options)
            case element(tei:graphic) return tei-to-html:graphic($node, $options)
            case element(tei:table) return tei-to-html:table($node, $options)
            case element(tei:row) return tei-to-html:row($node, $options)
            case element(tei:cell) return tei-to-html:cell($node, $options)
            case element(tei:milestone) return tei-to-html:milestone($node, $options)
            case element(tei:pb) return tei-to-html:pb($node, $options)
            case element(tei:lb) return tei-to-html:lb($node, $options)
            case element(tei:lg) return tei-to-html:lg($node, $options)
            case element(tei:l) return tei-to-html:l($node, $options)
            case element(tei:date) return tei-to-html:date($node, $options)
            case element(tei:name) return tei-to-html:name($node, $options)
            case element(tei:persName) return tei-to-html:persName($node, $options)
            case element(tei:quote) return tei-to-html:quote($node, $options)
            case element(tei:q) return tei-to-html:q($node, $options) (:contains: macro.specialPara:)
            case element(tei:seg) return tei-to-html:seg($node, $options)
            case element(tei:respStmt) return tei-to-html:respStmt($node, $options)
            case element(tei:app) return tei-to-html:app($node, $options)
            case element(tei:note) return tei-to-html:note($node, $options)
            case element(tei:w) return tei-to-html:w($node, $options)
            case element(tei:address) return tei-to-html:address($node, $options)
            case element(tei:addrLine) return tei-to-html:addrLine($node, $options)
            case element(tei:author) return tei-to-html:author($node, $options)
            case element(tei:biblScope) return tei-to-html:biblScope($node, $options)
            case element(tei:bibl) return tei-to-html:bibl($node, $options)
            (:NB: case element(tei:biblStruct) return tei-to-html:biblStruct($node, $options):)
            (:case element(tei:imprint) return tei-to-html:imprint($node, $options) belongs to biblStruct only:)
            (:case element(tei:monogr) return tei-to-html:monogr($node, $options) belongs to biblStruct only:)
            (:case element(tei:analytic) return tei-to-html:analytic($node, $options) belongs to biblStruct only:) 
            case element(tei:byline) return tei-to-html:byline($node, $options)
            case element(tei:caesura) return tei-to-html:caesura($node, $options)
            case element(tei:idno) return tei-to-html:idno($node, $options)
            case element(tei:altIdentifier) return tei-to-html:altIdentifier($node, $options)
            case element(tei:cit) return tei-to-html:cit($node, $options)
            case element(tei:listBibl) return tei-to-html:listBibl($node, $options)
            case element(tei:docAuthor) return tei-to-html:docAuthor($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docDate) return tei-to-html:docDate($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docImprint) return tei-to-html:docImprint($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docTitle) return tei-to-html:docTitle($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:emp) return tei-to-html:emp($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:figDesc) return tei-to-html:figDesc($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:listTranspose) return tei-to-html:listTranspose($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:locus) return tei-to-html:locus($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msContents) return tei-to-html:msContents($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msDesc) return tei-to-html:msDesc($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msIdentifier) return tei-to-html:msIdentifier($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msName) return tei-to-html:msName($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:num) return tei-to-html:num($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:ptr) return tei-to-html:ptr($node, $options)
                (:contains: empty:)
            case element(tei:publisher) return tei-to-html:publisher($node, $options)
                (:contained by: bibl imprint publicationStmt docImprint:)
                (:contains: macro.phraseSeq:)
            case element(tei:pubPlace) return tei-to-html:pubPlace($node, $options)
                (:contained by: bibl imprint publicationStmt docImprint:)
                (:contains: macro.phraseSeq:)
            case element(tei:rs) return tei-to-html:rs($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:series) return tei-to-html:series($node, $options)
                (:contained by: bibl biblStruct:)
                (:contains: ( text | model.gLike | title | model.ptrLike | editor | respStmt | biblScope | idno | textLang | model.global )*:)
            case element(tei:settlement) return tei-to-html:settlement($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:space) return tei-to-html:space($node, $options)
                (:contains: ( model.descLike | model.certLike )*:)
            case element(tei:title) return tei-to-html:title($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:titlePage) return tei-to-html:titlePage($node, $options)
                (:contained by: msContents back front:)
                (:contains: ( model.global*, ( model.titlepagePart ), ( model.titlepagePart | model.global )* ):)
            case element(tei:titlePart) return tei-to-html:titlePart($node, $options)
                (:contained by: msItem back docTitle front titlePage:) 
                (:contains: macro.paraContent:)
            case element(tei:trailer) return tei-to-html:trailer($node, $options)
                (:contains: ( text | lg | model.gLike | model.phrase | model.inter | model.lLike | model.global )*:)
            case element(tei:witDetail) return tei-to-html:witDetail($node, $options)
                (:contains: macro.phraseSeq:)
            (:tei:floatingText:)
            case element(exist:match) return tei-to-html:exist-match($node, $options)
            
            default return tei-to-html:recurse($node, $options)
};

(: Recurses through the child nodes and sends them tei-to-html:dispatch() :)
declare function tei-to-html:recurse($node as node(), $options) as item()* {
    for $node in $node/node()
    return
        tei-to-html:dispatch($node, $options)
};

(:search target:)
declare function tei-to-html:div($node as element(tei:div)?, $options) as element()* {
    if ($node/@type eq 'adhyāya')
    then
        if ($node//tei:persName)
        then
            (
            <a class="linebefore"/>
            ,
            <div class="notes" id="{tei-to-html:get-id($node)}">
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
                <div class="notes" id="{tei-to-html:get-id($node)}">
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
        <div id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</div>
};

(:search target:)
declare function tei-to-html:head($node as element(tei:head), $options) as element() {
    (: div heads :)
    if ($node/parent::tei:div) then
        let $type := $node/parent::tei:div/@type
        let $div-level := count($node/ancestor::div)
        return
            element {concat('h', $div-level + 2)} {tei-to-html:recurse($node, $options)} (:NB: add id attribute:)
    (: figure heads :)
    else if ($node/parent::tei:figure) then
        if ($node/parent::tei:figure/parent::tei:p) then
            <strong id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</strong>
        else (: if ($node/parent::tei:figure/parent::tei:div) then :)
            <p><strong id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</strong></p>
    (: list heads :)
    else if ($node/parent::tei:list) then
        <li id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</li>
    (: table heads :)
    else if ($node/parent::tei:table) then
        <p class="center" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</p>
    (: other heads? :)
    else if ($node/parent::tei:listWit)
    then <h4>{tei-to-html:recurse($node, $options)}</h4>
    else <span style="color: red;" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</span>
};

(:search target:)
declare function tei-to-html:p($node as element(tei:p), $options) as element()+ {
    let $rend := $node/@rend
    return 
        if ($rend = ('right', 'center', 'first', 'indent') ) 
        then
            <p class="{concat('p', '-', data($rend))}" title="tei:p" id="{tei-to-html:get-id($node)}">{ tei-to-html:recurse($node, $options) }</p>
        else 
            <p class="p" title="tei:p" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:hi($node as element(tei:hi), $options) as element()* {
    let $rend := $node/@rend
    return
        if ($rend = 'bold') 
        then
            <strong title="tei:hi">{tei-to-html:recurse($node, $options)}</strong>
        else
            if ($rend = 'it') then
                <em title="tei:hi">{tei-to-html:recurse($node, $options)}</em>
            else 
                if ($rend = 'sc') then
                <span title="tei:hi" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
                else 
                    <span class="hi" title="tei:hi">{tei-to-html:recurse($node, $options)}</span>
};

(:search target:)
declare function tei-to-html:list($node as element(tei:list), $options) as element()+ {
        if ($options/*:param[@name='ordered']/@value eq 'true')
        then 
            <ol title="tei:list" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</ol>
        else
            <ul title="tei:list" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</ul>
};

declare function tei-to-html:item($node as element(tei:item), $options) as element()+ {
        <li class="item" title="tei:item">{tei-to-html:recurse($node, $options)}</li>
};

(:search target:)
declare function tei-to-html:label($node as element(tei:label), $options) as element()* {
    if ($node/parent::tei:list) 
    then 
        <dt title="tei:label" id="{tei-to-html:get-id($node)}">{$node/text()}</dt>
    else 
        <div class="label" title="tei:label" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</div>
};

(:NB: resolve target!:)
declare function tei-to-html:ref($node as element(tei:ref), $options) {
    let $div-type := $options/*:param[@name = 'div-type']/@value
    let $target := data($node/@target)
    
    return
        switch ($div-type)
            case "toc" return
                element a { 
                    attribute href { $target },
                    attribute title {concat('tei:ref', ' with @target ', $target)},
                    attribute target { '_blank' },
                    tei-to-html:recurse($node, $options) 
                    }
           default return
                if (starts-with($target, "http"))
                then
                    element a { 
                        attribute href { $target },
                        attribute title {concat('tei:ref', ' with @target ', $target)},
                        attribute target { '_blank' },
                        tei-to-html:recurse($node, $options) 
                        }
                else
                    if (contains($node/ancestor::*/local-name(), "teiHeader"))
                    then
                        element a { 
                            attribute href { $target },
                            attribute title {concat('tei:ref', ' with @target ', $target)},
                            tei-to-html:recurse($node, $options) 
                            }
                    else <span class="inline-quote" title="tei:ref" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</span>                      
};

declare function tei-to-html:foreign($node as element(tei:foreign), $options) as element() {
    <span class="foreign" title="tei:foreign">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:idno($node as element(tei:idno), $options) as element() {
    <div class="idno" title="tei:idno">{tei-to-html:recurse($node, $options)}</div>    
};

declare function tei-to-html:altIdentifier($node as element(tei:altIdentifier), $options) as element() {
    <div class="altIdentifier" title="tei:altIdentifier">{tei-to-html:recurse($node, $options)}</div>    
};

declare function tei-to-html:mentioned($node as element(tei:mentioned), $options) as element() {
    <span class="mentioned" title="tei:mentioned">{tei-to-html:recurse($node, $options)}</span>
};
declare function tei-to-html:said($node as element(tei:said), $options) as element() {
    <p class="said" title="tei:said">{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:sp($node as element(tei:sp), $options) as element()+ {
    if ($node/tei:l) 
    then
        <div xmlns="http://www.w3.org/1999/xhtml" class="sp" title="tei:sp">
        { 
            for $l in $node/tei:l
            return
                tei-to-html:recurse($l, <options/>) }
        </div>
    else
        <div xmlns="http://www.w3.org/1999/xhtml" class="sp" title="tei:sp">
            { for $speaker in $node/tei:speaker return tei-to-html:recurse($speaker, <options/>) }
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
            <span title="tei:seg" class="{$letter}">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:figure($node as element(tei:figure), $options) as element()+ {
    <div class="figure" title="tei:figure">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:graphic($node as element(tei:graphic), $options) {
    let $url := $node/@url
    let $head := $node/following-sibling::tei:head
    let $width := if ($node/@width) then $node/@width else '800px'
    let $relative-image-path := $options/*:param[@name='relative-image-path']/@value
    return
        <span title="tei:graphic"><img src="{if (starts-with($url, '/')) then $url else concat($relative-image-path, $url)}" alt="{normalize-space($head[1])}" width="{$width}"/></span>
};

(:search target:)
declare function tei-to-html:table($node as element(tei:table), $options) as element()+ {
    <table title="tei:table" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</table>
};

declare function tei-to-html:row($node as element(tei:row), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <tr title="tei:row">{if ($label) then attribute class {'label'} else ()}{tei-to-html:recurse($node, $options)}</tr>
};

declare function tei-to-html:cell($node as element(tei:cell), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <td title="tei:cell">{
            if ($label) 
            then attribute class {'label'} 
            else ()
            }
            {tei-to-html:recurse($node, $options)}
            </td>
};

declare function tei-to-html:pb($node as element(tei:pb), $options) {
    <span class="pb" title="tei:pb">
        <a id="pg{$node/@n/string()}"/>
        {$node/@n/string()}
    </span>
};

(:search target:)
declare function tei-to-html:lg($node as element(tei:lg), $options) as element()+ {
   if ($node/@type eq 'base-text')
    then
        <div xmlns="http://www.w3.org/1999/xhtml" class="lg base-text" title="tei:lg base-text"  id="{tei-to-html:get-id($node)}">
            {tei-to-html:recurse($node, $options)}
        </div>
    else
        if ($node/../@type eq 'base-text')
        then
            <div xmlns="http://www.w3.org/1999/xhtml" class="lg" title="tei:lg base-text"  id="{tei-to-html:get-id($node)}">
                {tei-to-html:recurse($node, $options)}
            </div>
        else
            <div xmlns="http://www.w3.org/1999/xhtml" class="lg" title="tei:lg"  id="{tei-to-html:get-id($node)}">
                {tei-to-html:recurse($node, $options)}
            </div>
};

(:search target:)
declare function tei-to-html:l($node as element(tei:l), $options) as element()+ {
    let $class := if ($node[last()]) then "l final" else "l non-final" 
    return
     if ($node/parent::tei:lg/@type eq 'base-text')
     then
        <div class="{$class}" title="tei:l base-text" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</div>
     else
        <div class="{$class}" title="tei:l" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</div>

};

declare function tei-to-html:date($node as element(tei:date), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="date" title="tei:date" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="date" title="tei:date" >{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:name($node as element(tei:name), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="name" title="tei:name" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="name" title="tei:name">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:persName($node as element(tei:persName), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="name" title="tei:persName" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="name"title="tei:persName" >{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:milestone($node as element(tei:milestone), $options) as element()+ {
    (:if ($node/@unit eq 'rule') 
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
        else:)
            <hr/>
};

(:search target:)
declare function tei-to-html:quote($node as element(tei:quote), $options) {
    if ($node/@type eq 'base-text')
    then
        <blockquote class="base-text" title="tei:quote base-text" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</blockquote>
    else
        <span class="inline-quote" title="tei:quote" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:said($node as element(tei:said), $options) {
    <span class="said">{tei-to-html:recurse($node, $options)}</span>
};

(:search target:)
declare function tei-to-html:teiHeader($node as element(tei:teiHeader), $options) as element()+ {
        <div class="teiHeader" id="{tei-to-html:get-id($node)}">
            {tei-to-html:dispatch($node/tei:fileDesc/tei:titleStmt, $options)}
            
            <div class="extHeader">
                <button type="button" class="btn btn-default" data-toggle="collapse" data-target="#extHeader">
                    <span class="glyphicon glyphicon-th-list"/> Toggle Full Header
                </button>
                <div id="extHeader" class="collapse">
                    <div class="fileDesc">
                    { tei-to-html:dispatch($node/tei:fileDesc/*[not(self::tei:titleStmt)], $options) }
                    </div>
                    { tei-to-html:dispatch($node/*[not(self::tei:fileDesc)], $options) }
                </div>
            </div>
        </div>
};

(:search target:)
declare function tei-to-html:encodingDesc($node as element(tei:encodingDesc), $options) as element()+ {
    <div class="encodingDesc" id="{tei-to-html:get-id($node)}">
        <h3>Encoding Description</h3>
        {tei-to-html:recurse($node, $options)}</div>
};

(:search target:)
declare function tei-to-html:fileDesc($node as element(tei:fileDesc), $options) as element()+ {
    <div class="fileDesc" id="{tei-to-html:get-id($node)}">
        {tei-to-html:recurse($node, $options)}
    </div>
};

(:search target:)
declare function tei-to-html:profileDesc($node as element(tei:profileDesc), $options) as element()+ {
    (:abstract calendarDesc creation  textClass:)
    let $textClass := $node/tei:textClass
    let $langUsage := $node/tei:langUsage
    return
        <div id="{tei-to-html:get-id($node)}">
            {if ($textClass)
            then
                <div class="textClass">
                    <h4>Text Classification</h4>
                    {tei-to-html:recurse($node, $options)}</div>
            else ()}
            
            {if ($langUsage)
            then
                <div class="langUsage">
                    <h4>Language Usage</h4>
                    {
                    for $language in $langUsage/tei:language
                    return
                        <div>
                            {$language}{' '}{if ($language/@ident) then $language/@ident/string() else ''}{' '}{if ($language/@usage) then ($language/@usage/string() || '%') else ''}
                        </div>
                    }</div>
            else ()}
        </div>
};

(:search target:)
declare function tei-to-html:revisionDesc($node as element(tei:revisionDesc), $options) as element()+ {
    (:listChange:)
    <div class="revisionDesc" id="{tei-to-html:get-id($node)}">
    <h3>Revision Description</h3>
        <ul>
            {tei-to-html:recurse($node, $options)}
        </ul>
    </div>
};

declare function tei-to-html:notesStmt($node as element(tei:notesStmt), $options) as element()+ {
    <div class="notesStmt">
    <h4>Notes Statement</h4>
        {for $note in $node/tei:note
        return
            <div class="note" title="tei:note">
                <span class="note" title="tei:note">{tei-to-html:recurse($node/*, $options)}</span>
            </div>
        }
    </div>
};

declare function tei-to-html:app($node as element()+, $options) as element()+ {
    let $title := "Apparatus"
    let $lem := $node/tei:lem
    let $notes := $node/tei:note
    let $rdgs := $node/tei:rdg
    let $siglum := ""
    let $content := (
                if ($lem/@wit)
                then 
                    concat('&lt;span class="appentry"&gt;&lt;span class="siglum"&gt;',$siglum,'&lt;/span&gt;: ',$lem,'&lt;/span&gt;')
                else '',
                if ($notes)
                then
                    for $note in $notes
                    return
                        concat('&lt;span class="appentry"&gt;&lt;span class="siglum"&gt;Note:&lt;/span&gt; ',$note,'&lt;/span&gt;')
                else '',
                if ($rdgs)
                then 
                    for $rdg in $rdgs
                    let $siglum := translate(translate($rdg/@wit/string(), '#', ''), ' ', '')
                    return
                        concat('&lt;span class="appentry"&gt;&lt;span class="siglum"&gt;',$siglum,'&lt;/span&gt;: ',$rdg,'&lt;/span&gt;')
                else '')
    return
    (<button type="button" class="btn btn-lg btn-primary popover-dismiss" data-toggle="popover" title="{$title}" data-content="{$content}">a</button>, 
    <span style="style=display:none"></span>)
};

(:SR:)
(:search target:)
declare function tei-to-html:note($node as element()+, $options) as element()+ {
    let $resp := $node/@resp
    let $place := $node/@place
    let $title := concat('Note',
        if ($resp or $place) then ' — ' else '',
        if ($resp) then concat('resp: ', $resp) else '', 
        if ($resp and $place) then '; ' else '', 
        if ($place) then concat('place: ', $place) else '')
    return
    if (
        $node/parent::tei:head or 
        $node/ancestor::tei:bibl or 
        $node/ancestor::tei:biblFull or 
        $node/ancestor::tei:biblStruct or 
        $node/ancestor::tei:teiHeader)
    then 
        <div class="note" title="tei:note" id="{tei-to-html:get-id($node)}">
            <span class="note" title="tei:note">{tei-to-html:recurse($node, $options)}</span>
        </div>
    else
    (:<span class="note" title="tei:note">{'('}{tei-to-html:recurse($node, $options)}{')'}</span>:)
    (<button type="button" class="btn btn-lg btn-primary popover-dismiss" data-toggle="popover" id="{tei-to-html:get-id($node)}" title="{$title}" data-content="{tei-to-html:recurse($node, $options)}">n</button>, 
    <span style="style=display:none"></span>)
    (:    let $id := util:hash(util:random(), "md5")
    return
    <span class="note" title="tei:note">
    <button class="btn btn-primary btn-lg" data-toggle="modal" data-target="{concat('#', $id)}" id="{tei-to-html:get-id($node)}">ⓝ</button>
    <div class="modal fade" id="{$id}" tabindex="-1" role="dialog" aria-labelledby="{concat($id, '-label')}" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">
                        <span aria-hidden="true">x</span><span class="sr-only">Close</span></button>
                    <h4 class="modal-title" id="{concat($id, '-label')}">Note</h4>
                </div>
                <div class="modal-body">
                    {tei-to-html:recurse($node, $options)}
                </div>
            </div>
        </div>
    </div></span>
:)
};

declare function tei-to-html:extent($node as element(tei:extent), $options) as element()+ {
    <div class="extent">
        <h4>Extent</h4>
        {tei-to-html:recurse($node, $options)}
    </div>
};

declare function tei-to-html:change($node as element(tei:change), $options) {
    let $when := 
        if ($node/@when) 
        then $node/@when/string() 
        else 
            if ($node/@when-iso)
            then substring($node/@when-iso/string(), 1, 10)
            else ()
    let $who := $node/@who
    let $who := 
        if (starts-with($who, '#'))
        then tei-to-html:resolve-xml-id($who, $options)
        else 
            if ($who)
            then $who 
            else ''
    return 
        if (contains($node, ':') and $node/*) (:taken as indicator that the text has been marked fully up:)
        then <li class="change">{if ($when) then $when else ()} {tei-to-html:recurse($node, $options)}</li>
        else <li class="change">{concat($when, if (contains($node, ':')) then '' else if ($when) then ': ' else '', $node/string(), if ($who) then ' By ' else '', $who)}</li>
};

declare function tei-to-html:listChange($node as element(tei:listChange), $options) {
    for $change in $node/tei:change
    return
        tei-to-html:change($change, $options)
};

declare function tei-to-html:bibl($node as element(tei:bibl), $options) {
    if ($node/tei:bibl/text())
    then tei-to-html:bibl-loose($node, $options)
    else tei-to-html:bibl-element-only($node, $options)
};

declare function tei-to-html:bibl-element-only($node as element(tei:bibl), $options) as element()+ {
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
        <table id="{$node/@xml:id}" title="tei:bibl">
        {
            for $title in $titles
            return 
                <tr class="title" title="tei:title"><td>Title:</td><td>{tei-to-html:recurse($title, $options)}</td></tr>
            ,
            for $author in $authors
            return 
                <tr class="author" title="tei:author"><td>Author:</td><td>{tei-to-html:recurse($author, $options)}</td></tr>
            ,
            for $editor in $editors
            return 
                <tr class="editor" title="tei:editor"><td>Editor:</td><td>{tei-to-html:recurse($editor, $options)}</td></tr>
            ,
            for $publisher in $publishers
            return 
                <tr class="publisher" title="tei:publisher"><td>Publisher:</td><td>{tei-to-html:recurse($publisher, $options)}</td></tr>
            ,
            for $pubPlace in $pubPlaces
            return 
                <tr class="pubPlace" title="tei:pubPlace"><td>Place of Publication:</td><td>{tei-to-html:recurse($pubPlace, $options)}</td></tr>
            ,
            for $extent in $extents
            return 
                <tr class="extent" title="tei:extent"><td>Extent:</td><td>{tei-to-html:recurse($extent, $options)}</td></tr>
            ,
            for $date in $dates
            return 
                <tr class="date" title="tei:date"><td>Date:</td><td>{tei-to-html:recurse($date, $options)}</td></tr>
            ,
            for $series in $seriess
            return 
                <tr class="series" title="tei:series"><td>Series:</td><td>{tei-to-html:recurse($series, $options)}</td></tr>
            ,
            for $note in $notes
            return 
                <tr class="note" title="tei:note"><td>Note:</td><td>{tei-to-html:recurse($note, $options)}</td></tr>
        }
        </table>
        )
    return
        if ($node/../local-name() eq 'note')
        then
            <div class="hanging-indent">{$result}</div>
        else $result
};

declare function tei-to-html:bibl-loose($node as element(tei:bibl), $options) as element()+ {
    <div class="bibl" title="bibl">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:sourceDesc($node as element(tei:sourceDesc), $options) as element()+ {
    <div class="sourceDesc">
        <h4>Source Description</h4>
        {tei-to-html:recurse($node, $options)}
    </div>
};

declare function tei-to-html:editorialDecl($node as element(tei:editorialDecl), $options) as element()+ {
    <div class="editorialDesc">
        <h4>Editorial Description</h4>
        {tei-to-html:recurse($node, $options)}
    </div>
};

declare function tei-to-html:classDecl($node as element(tei:classDecl), $options) as element()+ {
        let $taxonomy := $node/tei:taxonomy/@xml:id/string() (:a little strange that this attribute should be used here:)
        return
            <div class="classDecl">
                <h4>Classification Declarations (Taxonomy: {$taxonomy})</h4>
                <div class="classification">{$node//tei:bibl/text()}</div>
            </div>
};

declare function tei-to-html:refsDecl($node as element(tei:refsDecl), $options) as element()+ {
        <div class="refsDecl">
            <h4>References Declarations</h4>
            <div class="classification">{tei-to-html:recurse($node, $options)}</div>
        </div>
};
declare function tei-to-html:publicationStmt($node as element(tei:publicationStmt), $options) as element()+ {
        (:distributor:)
        let $authority := $node/tei:authority
        let $date := $node/tei:date
        let $authority := 
            if ($authority) 
            then 
                <h5>Published by {tei-to-html:serialize-list($authority)}{if ($date) then concat(', ', $date) else ''}.</h5>
            else ()
        
        let $availability := $node/tei:availability
        let $availability-status : = $availability/@status/string()
        let $availability := 
            if ($availability-status) 
            then 
                (
                <h5>Availability: {$availability-status}</h5>
                , 
                <div class="copyright-notice">{tei-to-html:recurse($node, $options)}</div>
                )
            else ()
        
        let $idno := 
            if ($node/tei:idno) 
            then 
                <div class="idno" title="tei:idno"><h5>Identifier</h5>{$node/tei:idno}</div>
            else ()
        
        return
            <div class="publicationStmt">
            <h4>Publication Statement</h4>
                {$authority}
                {$availability}
                {$idno}
            </div>
};

declare function tei-to-html:respStmt($node as element(tei:respStmt)*, $options) {
    let $responsibilties := distinct-values($node/tei:resp)
    return
    for $responsibilty in $responsibilties
        return
            <li>{replace(normalize-space($responsibilty),'\.+$','')}: 
                {tei-to-html:serialize-list(
                    (
                    $node[tei:resp = $responsibilty]/tei:persName
                    ,
                    $node[tei:resp = $responsibilty]/tei:orgName
                    ,
                    $node[tei:resp = $responsibilty]/tei:name
                    ))}
            </li>
};

declare function tei-to-html:titleStmt($node as element(tei:titleStmt), $options) as element() {
        let $main-title := 
            if ($node/*:title[@type eq 'main']) 
            then <span title="tei:title">{$node/*:title[@type eq 'main']/text()}</span> 
            else <span title="tei:title">{$node/*:title[not(@type)][1]/text()}</span>
        
        let $commentary-subtitles := $node/*:title[@type eq 'sub'][@subtype eq 'commentary']/text()
        let $commentary-subtitles := 
            if ($commentary-subtitles) 
            then <h4 title="tei:title">With the {if (count($commentary-subtitles) eq 1) then 'Commentary' else 'Commentaries'}{' '}{string-join($commentary-subtitles, ', ')}</h4> 
            else ()
        
        let $edition-subtitles := $node/*:title[@type eq 'sub'][@subtype eq 'edition-type' or not(@subtype)]/text()
        let $edition-subtitles := 
            if ($edition-subtitles) 
            then <h5 title="tei:title">{string-join($edition-subtitles, ', ')}</h5> 
            else ()
        
        let $authors := $node/tei:author[not(@role)]
        let $authors := 
            if ($authors) 
            then 
                <h3 class="indent" title="tei:author">
                    {'By '}
                    {tei-to-html:serialize-list(
                        for $author in $authors return tei-to-html:recurse($author, $options))}
                </h3> else ()
        
        let $commentators := $node/tei:author[@role eq 'commentator']
        let $commentators := 
            if ($commentators) 
            then
                <h4 class="indent" title="tei:author">
                    {'By '}
                    {tei-to-html:serialize-list(
                        for $commentator in $commentators return tei-to-html:recurse($commentator, $options))}
                    </h4>
            else ()
        
        let $editors := $node/tei:editor
        let $editors := 
            if ($editors) 
            then 
                <li title="tei:editor">
                    {'Editor'}
                    {if (count($editors) gt 1) then 's' else ''}
                    {': '}
                    {tei-to-html:serialize-list(
                        for $editor in $editors return tei-to-html:recurse($editor, $options))}
                </li> 
            else ()
        
        let $funders := $node/tei:funder
        let $funders := 
            if ($funders) 
            then
                <li title="tei:funder">
                    {'Funder'}
                    {if (count($funders) gt 1) then 's' else ''}
                    {': '}
                    {tei-to-html:serialize-list(
                        for $funder in $funders return tei-to-html:recurse($funder, $options))}
                </li> 
            else ()
        
        let $principals := $node/tei:principal
        let $principals := 
            if ($principals) 
            then
                <li title="tei:principal">
                    {'Principal'}
                    {if (count($principals) gt 1) then 's' else ''}
                    {': '}
                    {tei-to-html:serialize-list(
                        for $principal in $principals return tei-to-html:recurse($principal, $options))}
                </li>
            else ()
        
        let $sponsors := $node/tei:sponsor
        let $sponsors := 
            if ($sponsors) 
            then 
                <li title="tei:sponsor">
                    {'Sponsor'}
                    {if (count($sponsors) gt 1) then 's' else ''}
                    {': '}
                    {tei-to-html:serialize-list(
                        for $sponsor in $sponsors return tei-to-html:recurse($sponsor, $options))}
                </li>
            else ()
        
        let $meetings := $node/tei:meeting
        let $meetings := 
            if ($meetings) 
            then 
                <li title="tei:meeting">
                    {'Meeting'}
                    {if (count($meetings) gt 1) then 's' else ''}
                    {': '}
                    {tei-to-html:serialize-list(
                        for $meeting in $meetings return tei-to-html:recurse($meeting, $options))}
                </li>
            else ()
        
        let $respStmt := tei-to-html:respStmt($node/tei:respStmt, $options)
        
        return
            <div class="titleStmt" title="tei:titleStmt">
                <h2>{$main-title}</h2>
                {$authors}
                {$commentary-subtitles}
                {$commentators}
                {$edition-subtitles}
                
                <ul>
                {$editors}
                {$funders}
                {$principals}
                {$sponsors}
                {$meetings}
                {$respStmt}
                </ul>
            </div>
};

declare function tei-to-html:editionStmt($node as element(tei:editionStmt), $options) as element()+ {
            <div class="editionStmt">
                <h4>Edition Statement</h4>
                {tei-to-html:recurse($node, $options)}                
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

declare function tei-to-html:resolve-xml-id($node as attribute(), $options) {
    let $absoluteURI := resolve-uri($node, base-uri($node))
    let $node := replace($node, '^#?(.*)$', '$1')
    return
        doc($absoluteURI)/id($node)/text()
};

(:Below are a number of dummy functions, dividing into empty, block-level and inline elements:)

declare function tei-to-html:w($node as element(tei:w), $options) as element() {
    <span class="w" title="tei:w">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:address($node as element(tei:address), $options) as element() {
    <span class="address" title="tei:address">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:addrLine($node as element(tei:addrLine), $options) as element() {
    <span class="addrLine" title="tei:addrLine">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:author($node as element(tei:author), $options) as element()+ {
    <div class="author" title="tei:author">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:biblScope($node as element(tei:biblScope), $options) as element()+ {
    <div class="biblScope" title="tei:biblScope">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:byline($node as element(tei:byline), $options) as element()+ {
    <div class="byline" title="tei:byline">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:caesura($node as element(tei:caesura), $options) as element() {
    <span class="caesura" title="tei:caesura">{tei-to-html:recurse($node, $options)}</span>
};

(:search target:)
declare function tei-to-html:cit($node as element(tei:cit), $options) as element() {
    <span class="cit" title="tei:cit">{tei-to-html:recurse($node, $options)}</span>
};

(:search target:)
declare function tei-to-html:listBibl($node as element(tei:listBibl), $options) as element()+ {
    <div class="listBibl" title="tei:listBibl">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:seriesStmt($node as element(tei:seriesStmt), $options) as element()+ {
    <div class="seriesStmt" title="tei:seriesStmt">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:docAuthor($node as element(tei:docAuthor), $options) as element()+ {
    <div class="docAuthor" title="tei:docAuthor">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:docDate($node as element(tei:docDate), $options) as element()+ {
    <div class="docDate" title="tei:docDate">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:docImprint($node as element(tei:docImprint), $options) as element()+ {
    <div class="docImprint" title="tei:docImprint">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:docTitle($node as element(tei:docTitle), $options) as element()+ {
    <div class="docTitle" title="tei:docTitle">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:emp($node as element(tei:emp), $options) as element() {
    <span class="emp" title="tei:emp">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:figDesc($node as element(tei:figDesc), $options) as element()+ {
    <div class="figDesc" title="tei:figDesc">{tei-to-html:recurse($node, $options)}</div>
};

(:can be both block and inline:)
declare function tei-to-html:listTranspose($node as element(tei:listTranspose), $options) as element()+ {
    <div class="listTranspose" title="tei:listTranspose">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:locus($node as element(tei:locus), $options) as element() {
    <span class="locus" title="tei:locus">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:msContents($node as element(tei:msContents), $options) as element()+ {
    <div class="msContents" title="tei:msContents">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:msDesc($node as element(tei:msDesc), $options) as element()+ {
    <div class="msDesc">
        <h4>Manuscript Description</h4>
        {tei-to-html:recurse($node, $options)}
    </div>
};

declare function tei-to-html:msIdentifier($node as element(tei:msIdentifier), $options) as element()+ {
    <div class="msIdentifier">
        <h5>Manuscript Identifier</h5>
        {tei-to-html:recurse($node, $options)}
    </div>
};

declare function tei-to-html:msName($node as element(tei:msName), $options) as element()+ {
    <div class="msName" title="tei:msName">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:num($node as element(tei:num), $options) as element() {
    <span class="num" title="tei:num">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:ptr($node as element(tei:ptr), $options) as element() {
    <span class="ptr" title="tei:ptr"/>
};

declare function tei-to-html:publisher($node as element(tei:publisher), $options) as element()+ {
    <div class="publisher" title="tei:publisher">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:pubPlace($node as element(tei:pubPlace), $options) as element()+ {
    <div class="pubPlace" title="tei:pubPlace">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:q($node as element(tei:q), $options) as element() {
    if ($node/@type eq 'lemma')
    then
        <span class="lemma" title="tei:q">{tei-to-html:recurse($node, $options)}</span>
    else    
        <span class="q" title="tei:q">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:rs($node as element(tei:rs), $options) as element() {
    <span class="rs" title="tei:rs">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:series($node as element(tei:series), $options) as element()+ {
    <div class="series" title="tei:series">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:settlement($node as element(tei:settlement), $options) as element() {
    <span class="settlement" title="tei:settlement">{tei-to-html:recurse($node, $options)}</span>
};

(:is most often empty:)
declare function tei-to-html:space($node as element(tei:space), $options) as element() {
    <span class="space" title="tei:space">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:title($node as element(tei:title), $options) as element() {
    <span class="title" title="tei:title">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:titlePage($node as element(tei:titlePage), $options) as element()+ {
    (:argument byline docEdition docImprint docTitle titlePart:)
    let $id := $node/@xml:id/string()
    let $docAuthors := $node/tei:docAuthor
    let $docAuthors := 
        if ($docAuthors) 
        then 
            (', by '
            ,
            tei-to-html:serialize-list(
                for $docAuthor in $docAuthors return tei-to-html:recurse($docAuthor, $options))
            )
        else ()
    let $docDates := $node/tei:docDate
    let $docDates := 
        if ($docDates) 
        then 
            (' ('
            ,
            tei-to-html:serialize-list(
                for $docDate in $docDates return tei-to-html:recurse($docDate, $options))
            ,
            ') '
            )
        else ()
    let $docImprints := $node/tei:docImprint
    let $docImprints :=  
        if ($docImprints) 
        then 
            (' ('
            ,
            tei-to-html:serialize-list(
                for $docImprint in $docImprints return tei-to-html:recurse($docImprint, $options))
            ,
            ') '
            )
        else ()
    let $docTitles := $node/tei:docTitle
    let $docTitles := 
        if ($docTitles)
        then
            <span class="title-italic">{
            tei-to-html:serialize-list(
                for $docTitle in $docTitles 
                let $titleParts := $docTitle/tei:titlePart
                return 
                    for $titlePart in $titleParts
                    return 
                        tei-to-html:recurse($titlePart, $options))
            }</span>
        else ()
    let $titleParts := $node/tei:titlePart
    let $titleParts := 
        if ($titleParts)
        then
            tei-to-html:serialize-list(
                for $titlePart in $titleParts return tei-to-html:recurse($titlePart, $options))
        else ()
    let $other-elements := $node/(tei:* except (tei:titlePart, tei:docTitle, tei:docImprint, tei:docDate, tei:docAuthor))

    return
    <div class="titlePage" title="tei:titlePage">
    <h7>Title Page</h7>
        <a href="{$id}.html">
        <div>
            {$docTitles}
            {$titleParts}
            {$docAuthors}
            {$docImprints}
            {$docDates}
        </div>
        </a>
    </div>
};

declare function tei-to-html:titlePart($node as element(tei:titlePart), $options) as element()+ {
    <div class="titlePart" title="tei:titlePart">{tei-to-html:recurse($node, $options)}</div>
};

(:search target:)
declare function tei-to-html:trailer($node as element(tei:trailer), $options) as element()+ {
    <div class="trailer" title="tei:trailer" id="{tei-to-html:get-id($node)}">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:witDetail($node as element(tei:witDetail), $options) as element() {
    <span class="title" title="tei:witDetail">{tei-to-html:recurse($node, $options)}</span>
};

(:only for free-standing tei:sic; tei:choice normally formats tei:sic.:)
(:SR:)
declare function tei-to-html:sic($node as element(tei:sic), $options) as element() {
    <span class="sic" title="tei:sic">{'{'}{tei-to-html:recurse($node, $options)}{'}'}</span>
};

(:SR:)
declare function tei-to-html:corr($node as element(tei:corr), $options) as element() {
    <span class="corr" title="tei:corr">{'['}{tei-to-html:recurse($node, $options)}{']'}</span>
};

(:SR:)
declare function tei-to-html:del($node as element(tei:del), $options) as element() {
    <span class="del" title="tei:del" style="text-decoration:line-through;">{'['}{tei-to-html:recurse($node, $options)}{']'}</span>
};

(:SR:)
declare function tei-to-html:add($node as element(tei:add), $options) as element() {
    let $place := $node/@place
    return
        if ($place = ('sup', 'above'))
        then <span class="add" title="tei:add" style="vertical-align:super;font-size.83em;">{'⟨'}{tei-to-html:recurse($node, $options)}{'⟩'}</span>
        else
            if ($place = ('sub', 'below'))
            then <span class="add" title="tei:add" style="vertical-align:sub;font-size:.83em;">{'⟨'}{tei-to-html:recurse($node, $options)}{'⟩'}</span>
            else <span class="add" title="tei:add">{'⟨'}{tei-to-html:recurse($node, $options)}{'⟩'}</span>

};
