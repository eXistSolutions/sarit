xquery version "3.0";

module namespace tei2fo="http://exist-db.org/xquery/app/sarit/tei2fo";

import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";
import module namespace counter="http://exist-db.org/xquery/counter" at "java:org.exist.xquery.modules.counter.CounterModule";
    
declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:  Sample doc: Pramāṇavārttika :)

declare variable $tei2fo:font := "Siddhanta, serif";
declare variable $tei2fo:fontSize := 12;
declare variable $tei2fo:lineHeight := "18pt";

declare variable $tei2fo:subTitleHeader := map {
    "font-size" := "14pt",
    "line-height" := "21pt",
    "space-before" := "14pt",
    "space-after" := "7pt",
    "keep-with-next.within-page" := "always"
};

(: A helper function in case no options are passed to the function :)
declare function tei2fo:render($content as node()*) as element()+ {
    (
        counter:create("footnotes", 1),
        tei2fo:render($content, <parameters/>),
        counter:destroy("footnotes")
    )[2]
};

(: The main function for the tei2fo module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei2fo:render($content as node()*, $options as element(parameters)*) as element()+ {
    <fo:block>
        { tei2fo:dispatch($content, $options) }
    </fo:block>
};

(: Typeswitch routine: Takes any node in a TEI content and either dispatches it to a dedicated 
 : function that handles that content (e.g. div), ignores it by passing it to the recurse() function
 : (e.g. text), or handles it directly (none). :)
declare function tei2fo:dispatch($nodes as node()*, $options) as item()* {
    for $node in $nodes
    return
        typeswitch($node)
            case text() return $node
            
            case element(tei:TEI) return tei2fo:recurse($node, $options)
            
            case element(tei:teiHeader) return tei2fo:teiHeader($node, $options)
                (:contained by: teiCorpus, TEI:)
                (:contains: fileDesc, model.teiHeaderPart*, revisionDesc?:)
            case element(tei:encodingDesc) return tei2fo:encodingDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( model.encodingDescPart | model.pLike )+:)
            case element(tei:editorialDecl) return tei2fo:editorialDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: ( model.pLike | model.editorialDeclPart )+:)
            case element(tei:classDecl) return tei2fo:classDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: taxonomy+:)
            case element(tei:refsDecl) return tei2fo:refsDecl($node, $options)
                (:contained by: encodingDesc only:)
                (:contains: ( model.pLike+ | cRefPattern+ | refState+ ):)
            case element(tei:fileDesc) return tei2fo:fileDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( ( titleStmt, editionStmt?, extent?, publicationStmt, seriesStmt?, notesStmt? ), sourceDesc+ ):)
            case element(tei:profileDesc) return tei2fo:profileDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( model.profileDescPart* ):)
            case element(tei:revisionDesc) return tei2fo:revisionDesc($node, $options)
                (:contained by: teiHeader only:)
                (:contains: ( list | listChange | change+ ):)
            case element(tei:titleStmt) return tei2fo:titleStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( title+, model.respLike* ):)
            case element(tei:publicationStmt) return tei2fo:publicationStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( ( ( model.publicationStmtPart.agency ), model.publicationStmtPart.detail* )+ | model.pLike+ ):)
            case element(tei:sourceDesc) return tei2fo:sourceDesc($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( model.biblLike | model.sourceDescPart | model.listLike )+ ):)
            case element(tei:notesStmt) return tei2fo:notesStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.noteLike | relatedItem )+:)
            case element(tei:extent) return tei2fo:extent($node, $options)
                (:contained by: bibl monogr biblFull fileDesc supportDesc:)
                (:contains: macro.phraseSeq:)
            case element(tei:editionStmt) return tei2fo:editionStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( edition, model.respLike* ) ):)
            case element(tei:seriesStmt) return tei2fo:seriesStmt($node, $options)
                (:contained by: biblFull fileDesc:)
                (:contains: ( model.pLike+ | ( title+, ( editor | respStmt )*, ( idno | biblScope )* ) ):)
            case element(tei:listChange) return tei2fo:listChange($node, $options)
                (:contained by: creation listChange revisionDesc:)
                (:contains: ( listChange | change )+:)
            case element(tei:change) return tei2fo:change($node, $options)
                (:contained by: listChange revisionDesc recordHist:)
                (:contains: macro.specialPara:)
                
            case element(tei:text) return tei2fo:recurse($node, $options)
            case element(tei:front) return tei2fo:recurse($node, $options)
            case element(tei:body) return tei2fo:recurse($node, $options)
            case element(tei:back) return tei2fo:recurse($node, $options)
            
            case element(tei:div) return tei2fo:div($node, $options)
            case element(tei:div1) return tei2fo:div($node, $options)
            case element(tei:div2) return tei2fo:div($node, $options)
            case element(tei:div3) return tei2fo:div($node, $options)
            case element(tei:div4) return tei2fo:div($node, $options)
            case element(tei:head) return tei2fo:head($node, $options)
            case element(tei:p) return tei2fo:p($node, $options)
            
            case element(tei:hi) return tei2fo:hi($node, $options)
            case element(tei:list) return tei2fo:list($node, $options)
            case element(tei:item) return tei2fo:item($node, $options)
            case element(tei:label) return tei2fo:label($node, $options)
            case element(tei:ref) return tei2fo:ref($node, $options)
            case element(tei:said) return tei2fo:said($node, $options)
            case element(tei:sic) return tei2fo:sic($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:corr) return tei2fo:corr($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:del) return tei2fo:del($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:add) return tei2fo:add($node, $options)
                (:contains: macro.paraContent:)            
            case element(tei:foreign) return tei2fo:foreign($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:mentioned) return tei2fo:mentioned($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:figure) return tei2fo:figure($node, $options)
            case element(tei:graphic) return tei2fo:graphic($node, $options)
            case element(tei:table) return tei2fo:table($node, $options)
            case element(tei:row) return tei2fo:row($node, $options)
            case element(tei:cell) return tei2fo:cell($node, $options)
            case element(tei:milestone) return tei2fo:milestone($node, $options)
            case element(tei:pb) return tei2fo:pb($node, $options)
            case element(tei:lb) return tei2fo:lb($node, $options)
            case element(tei:lg) return tei2fo:lg($node, $options)
            case element(tei:l) return tei2fo:l($node, $options)
            case element(tei:date) return tei2fo:date($node, $options)
            case element(tei:name) return tei2fo:name($node, $options)
            case element(tei:persName) return tei2fo:persName($node, $options)
            case element(tei:quote) return tei2fo:quote($node, $options)
            case element(tei:q) return tei2fo:q($node, $options) (:contains: macro.specialPara:)
            case element(tei:seg) return tei2fo:seg($node, $options)
            case element(tei:respStmt) return tei2fo:respStmt($node, $options)
            case element(tei:note) return tei2fo:note($node, $options)
            case element(tei:w) return tei2fo:w($node, $options)
            case element(tei:address) return tei2fo:address($node, $options)
            case element(tei:addrLine) return tei2fo:addrLine($node, $options)
            case element(tei:author) return tei2fo:author($node, $options)
            case element(tei:biblScope) return tei2fo:biblScope($node, $options)
            case element(tei:bibl) return tei2fo:bibl($node, $options)
            (:NB: case element(tei:biblStruct) return tei2fo:biblStruct($node, $options):)
            (:case element(tei:imprint) return tei2fo:imprint($node, $options) belongs to biblStruct only:)
            (:case element(tei:monogr) return tei2fo:monogr($node, $options) belongs to biblStruct only:)
            (:case element(tei:analytic) return tei2fo:analytic($node, $options) belongs to biblStruct only:) 
            case element(tei:byline) return tei2fo:byline($node, $options)
            case element(tei:caesura) return tei2fo:caesura($node, $options)
            case element(tei:cit) return tei2fo:cit($node, $options)
            case element(tei:listBibl) return tei2fo:listBibl($node, $options)
            case element(tei:docAuthor) return tei2fo:docAuthor($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docDate) return tei2fo:docDate($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docImprint) return tei2fo:docImprint($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:docTitle) return tei2fo:docTitle($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:emp) return tei2fo:emp($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:figDesc) return tei2fo:figDesc($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:listTranspose) return tei2fo:listTranspose($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:locus) return tei2fo:locus($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msContents) return tei2fo:msContents($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msDesc) return tei2fo:msDesc($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msIdentifier) return tei2fo:msIdentifier($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:msName) return tei2fo:msName($node, $options)
                (:contained by: :)
                (:contains: :)
            case element(tei:num) return tei2fo:num($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:ptr) return tei2fo:ptr($node, $options)
                (:contains: empty:)
            case element(tei:publisher) return tei2fo:publisher($node, $options)
                (:contained by: bibl imprint publicationStmt docImprint:)
                (:contains: macro.phraseSeq:)
            case element(tei:pubPlace) return tei2fo:pubPlace($node, $options)
                (:contained by: bibl imprint publicationStmt docImprint:)
                (:contains: macro.phraseSeq:)
            case element(tei:rs) return tei2fo:rs($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:series) return tei2fo:series($node, $options)
                (:contained by: bibl biblStruct:)
                (:contains: ( text | model.gLike | title | model.ptrLike | editor | respStmt | biblScope | idno | textLang | model.global )*:)
            case element(tei:settlement) return tei2fo:settlement($node, $options)
                (:contains: macro.phraseSeq:)
            case element(tei:space) return tei2fo:space($node, $options)
                (:contains: ( model.descLike | model.certLike )*:)
            case element(tei:title) return tei2fo:title($node, $options)
                (:contains: macro.paraContent:)
            case element(tei:titlePage) return tei2fo:titlePage($node, $options)
                (:contained by: msContents back front:)
                (:contains: ( model.global*, ( model.titlepagePart ), ( model.titlepagePart | model.global )* ):)
            case element(tei:titlePart) return tei2fo:titlePart($node, $options)
                (:contained by: msItem back docTitle front titlePage:) 
                (:contains: macro.paraContent:)
            case element(tei:trailer) return tei2fo:trailer($node, $options)
                (:contains: ( text | lg | model.gLike | model.phrase | model.inter | model.lLike | model.global )*:)
            case element(tei:witDetail) return tei2fo:witDetail($node, $options)
                (:contains: macro.phraseSeq:)
            (:tei:floatingText:)
            
            case element(exist:match) return tei2fo:exist-match($node, $options)
            
            default return tei2fo:recurse($node, $options)
};

(: Recurses through the child nodes and sends them tei2fo:dispatch() :)
declare function tei2fo:recurse($node as node(), $options) as item()* {
    for $node in $node/node()
    return
        tei2fo:dispatch($node, $options)
};

declare function tei2fo:div($node as element(tei:div), $options) as node()+ {
    if ($node/tei:head) then
        <fo:block>
        {tei2fo:recurse($node, $options)}
        </fo:block>
    else
        <fo:block space-before="1em" space-after="1em">
        {tei2fo:recurse($node, $options)}
        </fo:block>
};

declare function tei2fo:head($node as element(tei:head), $options) as element() {
    (: div heads :)
    if ($node/parent::tei:div) then
        let $type := $node/parent::tei:div/@type
        let $div-level := count($node/ancestor::tei:div)
        let $last := empty($node/following-sibling::*[1][self::tei:head])
        let $first := empty($node/preceding-sibling::*[1][self::tei:head])
        return
            switch ($div-level)
                case 0 case 1 return
                    <fo:block font-size="36pt" font-weight="normal" space-after="{if ($last) then 36 else 0}pt"
                        space-before="{if ($first) then 36 else 0}pt"
                        keep-with-next.within-page="always" line-height="36pt"
                        page-break-before="{if ($node/preceding-sibling::tei:head) then '' else 'always'}">
                        {tei2fo:recurse($node, $options)}
                    </fo:block>
                case 2 return
                    <fo:block font-size="24pt" font-weight="normal" space-after="{if ($last) then 24 else 0}pt"
                        space-before="{if ($first) then 24 else 0}pt"
                        keep-with-next.within-page="always" line-height="24pt">
                        {tei2fo:recurse($node, $options)}
                    </fo:block>
                case 3 return
                    <fo:block font-size="18pt" font-weight="normal" space-after="{if ($last) then 18 else 0}pt"
                        keep-with-next.within-page="always" line-height="18pt"
                        space-before="{if ($first) then 18 else 0}pt">
                        {tei2fo:recurse($node, $options)}
                    </fo:block>
                default return
                    <fo:block font-weight="bold" space-after="{if ($last) then 12 else 0}pt"
                        keep-with-next.within-page="always">
                        {$div-level}: {tei2fo:recurse($node, $options)}
                    </fo:block>
    (: figure heads :)
    else if ($node/parent::tei:figure) then
        if ($node/parent::tei:figure/parent::tei:p) then
            <fo:inline font-weight="bold">{tei2fo:recurse($node, $options)}</fo:inline>
        else (: if ($node/parent::tei:figure/parent::tei:div) then :)
            <fo:block font-weight="bold">{tei2fo:recurse($node, $options)}</fo:block>
    (: list heads :)
    else if ($node/parent::tei:list) then
        <li>{tei2fo:recurse($node, $options)}</li>
    (: table heads :)
    else if ($node/parent::tei:table) then
        <fo:block text-align="center">{tei2fo:recurse($node, $options)}</fo:block>
    (: other heads? :)
    else
        <fo:inline color="red">{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:p($node as element(tei:p), $options) as element()+ {
    let $rend := $node/@rend
    return 
        if ($rend = ('right', 'center', 'first', 'indent') ) then
            <fo:block text-align="{$rend}">{ tei2fo:recurse($node, $options) }</fo:block>
        else
            <fo:block text-align="left" text-indent="{if ($node/ancestor::tei:note|$node/ancestor::tei:teiHeader) then 0 else 2}em"
                hyphenate="true">{tei2fo:recurse($node, $options)}</fo:block>
};

declare function tei2fo:hi($node as element(tei:hi), $options) as element()* {
    let $rend := $node/@rend
    return
        if ($rend = 'bold') 
        then
            <fo:inline font-weight="bold">{tei2fo:recurse($node, $options)}</fo:inline>
        else
            if ($rend = 'it') then
                <fo:inline font-style="italic">{tei2fo:recurse($node, $options)}</fo:inline>
            else 
                if ($rend = 'sc') then
                <fo:inline font-variant="small-caps">{tei2fo:recurse($node, $options)}</fo:inline>
                else 
                    <fo:inline font-style="italic">{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:list($node as element(tei:list), $options) as element()+ {
    let $label-length :=
        if ($node/tei:label) then
            max($node/tei:label ! string-length(.))
        else
            1
    return
        <fo:list-block provisional-distance-between-starts="{$label-length}em">
        {tei2fo:recurse($node, $options)}
        </fo:list-block>
};

declare function tei2fo:item($node as element(tei:item), $options) as element()? {
    if ($node/preceding-sibling::tei:label) then
        ()
    else
        <fo:list-item>
            <fo:list-item-label><fo:block/></fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
            </fo:list-item-body>
        </fo:list-item>
};

declare function tei2fo:label($node as element(tei:label), $options) as element()* {
    if ($node/parent::tei:list) 
    then
        <fo:list-item>
            <fo:list-item-label end-indent="label-end()">
                <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>{tei2fo:recurse($node/following-sibling::tei:item[1], $options)}</fo:block>
            </fo:list-item-body>
        </fo:list-item>
    else 
        <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:xmlid($node as element(), $options) as element() {
    <a name="{$node/@xml:id}"/>
};

(:NB: resolve target!:)
declare function tei2fo:ref($node as element(tei:ref), $options) {
    let $target := $node/@target
    return
        <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:foreign($node as element(tei:foreign), $options) as element() {
    <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:mentioned($node as element(tei:mentioned), $options) as element() {
    <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};
declare function tei2fo:said($node as element(tei:said), $options) as element() {
    <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:exist-match($node as element(), $options) as element() {
    <fo:inline>{ $node/node() }</fo:inline>                    
};

declare function tei2fo:lb($node as element(tei:lb), $options) as element()? {
    ()
};

declare function tei2fo:seg($node as element(tei:seg), $options) as element() {
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
            <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:figure($node as element(tei:figure), $options) as element()+ {
    (
        <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
    )
};

declare function tei2fo:graphic($node as element(tei:graphic), $options) {
    let $url := $node/@url
    let $head := $node/following-sibling::tei:head
    let $width := if ($node/@width) then $node/@width else '800px'
    let $relative-image-path := $options/*:param[@name='relative-image-path']/@value
    return
        <span title="tei:graphic"><img src="{if (starts-with($url, '/')) then $url else concat($relative-image-path, $url)}" alt="{normalize-space($head[1])}" width="{$width}"/></span>
};

declare function tei2fo:table($node as element(tei:table), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <table title="tei:table">{tei2fo:recurse($node, $options)}</table>
    )
};

declare function tei2fo:row($node as element(tei:row), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <tr title="tei:row">{if ($label) then attribute class {'label'} else ()}{tei2fo:recurse($node, $options)}</tr>
};

declare function tei2fo:cell($node as element(tei:cell), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <td title="tei:cell">{
            if ($label) 
            then attribute class {'label'} 
            else ()
            }
            {tei2fo:recurse($node, $options)}
            </td>
};

declare function tei2fo:pb($node as element(tei:pb), $options) {
    <fo:inline font-size=".75em" padding-left=".5em" padding-right=".5em">/p. {$node/@n/string()}/</fo:inline>
(:    <fo:float float="right">:)
(:        <fo:block margin-left="3mm">P. {$node/@n/string()}</fo:block>:)
(:    </fo:float>:)
};

declare function tei2fo:lg($node as element(tei:lg), $options) as element()+ {
    <fo:block space-before="1em" space-after="1em">
        {tei2fo:recurse($node, $options)}
    </fo:block>
};

declare function tei2fo:l($node as element(tei:l), $options) as element()+ {
    let $class := if ($node[last()]) then "l final" else "l non-final" 
    let $rend := $node/@rend
    return
        if ($node/@rend eq 'i2') then 
            <fo:block padding-left="2em">{tei2fo:recurse($node, $options)}</fo:block>
        else 
            <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
};

declare function tei2fo:date($node as element(tei:date), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="date" title="tei:date" style="font-variant: small-caps;">{tei2fo:recurse($node, $options)}</span>
        else 
            <span class="date" title="tei:date" >{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:name($node as element(tei:name), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="name" title="tei:name" style="font-variant: small-caps;">{tei2fo:recurse($node, $options)}</span>
        else 
            <span class="name" title="tei:name">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:persName($node as element(tei:persName), $options) {
    let $rend := $node/@rend
    return
        if ($rend eq 'sc') 
        then 
            <span class="name" title="tei:persName" style="font-variant: small-caps;">{tei2fo:recurse($node, $options)}</span>
        else 
            <span class="name" title="tei:persName">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:milestone($node as element(tei:milestone), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
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
    )
};

declare function tei2fo:quote($node as element(tei:quote), $options) {
    <fo:block margin-left="6em">{tei2fo:recurse($node, $options)}</fo:block>
};

declare function tei2fo:said($node as element(tei:said), $options) {
    <span class="said">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:teiHeader($node as element(tei:teiHeader), $options) as element()+ {
    <fo:block page-break-after="always">
        {tei2fo:dispatch($node/tei:fileDesc/tei:titleStmt, $options)}
    </fo:block>,
    <fo:block page-break-after="always">
        { tei2fo:dispatch($node/tei:fileDesc/*[not(self::tei:titleStmt)], $options) }
        { tei2fo:dispatch($node/*[not(self::tei:fileDesc)], $options) }
    </fo:block>
};

declare function tei2fo:encodingDesc($node as element(tei:encodingDesc), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="encodingDesc">
        <h3>Encoding Description</h3>
        {tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:fileDesc($node as element(tei:fileDesc), $options) as element()+ {
    <fo:block>
        {tei2fo:recurse($node, $options)}
    </fo:block>
};

declare function tei2fo:profileDesc($node as element(tei:profileDesc), $options) as element()+ {
    (:abstract calendarDesc creation  textClass:)
    let $textClass := $node/tei:textClass
    let $langUsage := $node/tei:langUsage
    return
        <fo:block>
            {
                if ($textClass) then
                    <fo:block>
                        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Text Classification</fo:block>
                        {tei2fo:recurse($node, $options)}
                    </fo:block>
                else ()
            }
            
            {
                if ($langUsage) then
                    <fo:block>
                        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Language Usage</fo:block>
                        {
                        for $language in $langUsage/tei:language
                        return
                            <fo:block>
                                {$language}{' '}{if ($language/@ident) then $language/@ident/string() else ''}{' '}{if ($language/@usage) then ($language/@usage/string() || '%') else ''}
                            </fo:block>
                        }</fo:block>
                else ()
            }
        </fo:block>
};

declare function tei2fo:revisionDesc($node as element(tei:revisionDesc), $options) as element()+ {
    <fo:block>
        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Revision Description</fo:block>
        <fo:list-block provisional-distance-between-starts="8em">
            {tei2fo:recurse($node, $options)}
        </fo:list-block>
    </fo:block>
};

declare function tei2fo:notesStmt($node as element(tei:notesStmt), $options) as element()+ {
    <fo:block>
        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Notes Statement</fo:block>
        {
            for $note in $node/tei:note
            return
                tei2fo:recurse($note, $options)
        }
    </fo:block>
};

(:SR:)
(:use ⓝ to mark:)
declare function tei2fo:note($node as element(tei:note), $options) as element()+ {
    if ($node/ancestor::tei:note) then
        <fo:inline-container>{tei2fo:recurse($node, $options)}</fo:inline-container>
    else
        let $number := counter:next-value("footnotes")
        return
            <fo:footnote>
                <fo:inline baseline-shift="super" font-size="8pt" padding-left="0.25em" padding-right="0.5em">{$number}</fo:inline>
                <fo:footnote-body start-indent="0mm" end-indent="0mm" text-indent="0mm" white-space-treatment="preserve">
                    <fo:list-block provisional-label-separation="2mm" provisional-distance-between-starts="4em" 
                        font-size="9pt" line-height="11pt">
                        <fo:list-item>
                            <fo:list-item-label end-indent="label-end()">
                                <fo:block>{ $number }</fo:block>
                            </fo:list-item-label>
                            <fo:list-item-body start-indent="body-start()">
                                <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
                            </fo:list-item-body>
                        </fo:list-item>
                    </fo:list-block>
                </fo:footnote-body>
            </fo:footnote>
};

declare function tei2fo:extent($node as element(tei:extent), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="extent">
        <h4>Extent</h4>
        {tei2fo:recurse($node, $options)}
    </div>
    )
};

declare function tei2fo:change($node as element(tei:change), $options) {
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
        then tei2fo:resolve-xml-id($who, $options)
        else 
            if ($who)
            then $who 
            else ''
    return 
        if (contains($node, ':') and $node/*) (:taken as indicator that the text has been marked fully up:)
        then 
            <fo:list-item>
                <fo:list-item-label end-indent="label-end()"><fo:block>{if ($when) then $when else ()}</fo:block></fo:list-item-label>
                <fo:list-item-body start-indent="body-start()">
                    <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
                </fo:list-item-body>
            </fo:list-item>
        else 
            <fo:list-item>
                <fo:list-item-label end-indent="label-end()"><fo:block>{concat($when, if (contains($node, ':')) then '' else if ($when) then ': ' else '')}</fo:block></fo:list-item-label>
                <fo:list-item-body start-indent="body-start()">
                    <fo:block>{$node/string()}{if ($who) then ' By ' else ''}{$who}</fo:block>
                </fo:list-item-body>
            </fo:list-item>
};

declare function tei2fo:listChange($node as element(tei:listChange), $options) {
    for $change in $node/tei:change
    return
        tei2fo:change($change, $options)
};

declare function tei2fo:bibl($node as element(tei:bibl), $options) {
    if ($node/tei:bibl/text())
    then tei2fo:bibl-loose($node, $options)
    else tei2fo:bibl-element-only($node, $options)
};

declare function tei2fo:bibl-element-only($node as element(tei:bibl), $options) as element()+ {
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
        <fo:table>
            <fo:table-column column-number="1" column-width="30%"/>
            <fo:table-column column-number="2" column-width="70%"/>
            <fo:table-body>
            {
                for $title in $titles
                return 
                    <fo:table-row>
                        <fo:table-cell><fo:block>Title:</fo:block></fo:table-cell>
                        <fo:table-cell>
                        <fo:block>
                        {
                            tei2fo:recurse($title, $options)
                        }
                        </fo:block>
                        </fo:table-cell>
                    </fo:table-row>
                ,
                for $author in $authors
                return 
                    <fo:table-row><fo:table-cell><fo:block>Author:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($author, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $editor in $editors
                return 
                    <fo:table-row><fo:table-cell><fo:block>Editor:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($editor, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $publisher in $publishers
                return 
                    <fo:table-row><fo:table-cell><fo:block>Publisher:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($publisher, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $pubPlace in $pubPlaces
                return 
                    <fo:table-row><fo:table-cell><fo:block>Place of Publication:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($pubPlace, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $extent in $extents
                return 
                    <fo:table-row><fo:table-cell><fo:block>Extent:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($extent, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $date in $dates
                return 
                    <fo:table-row><fo:table-cell><fo:block>Date:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($date, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $series in $seriess
                return 
                    <fo:table-row><fo:table-cell><fo:block>Series:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($series, $options)}</fo:block></fo:table-cell></fo:table-row>
                ,
                for $note in $notes
                return 
                    <fo:table-row><fo:table-cell><fo:block>Note:</fo:block></fo:table-cell><fo:table-cell><fo:block>{tei2fo:recurse($note, $options)}</fo:block></fo:table-cell></fo:table-row>
            }
            </fo:table-body>
        </fo:table>
        )
    return
        if ($node/../local-name() eq 'note')
        then
            <fo:block>{$result}</fo:block>
        else $result
};

declare function tei2fo:bibl-loose($node as element(tei:bibl), $options) as element()+ {
    <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
};

declare function tei2fo:sourceDesc($node as element(tei:sourceDesc), $options) as element()+ {
    <fo:block>
        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Source Description</fo:block>
        {tei2fo:recurse($node, $options)}
    </fo:block>
};

declare function tei2fo:editorialDecl($node as element(tei:editorialDecl), $options) as element()+ {
    <fo:block>
        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Editorial Description</fo:block>
        {tei2fo:recurse($node, $options)}
    </fo:block>
};

declare function tei2fo:classDecl($node as element(tei:classDecl), $options) as element()+ {
        let $taxonomy := $node/tei:taxonomy/@xml:id/string() (:a little strange that this attribute should be used here:)
        return
            <fo:block>
                <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Classification Declarations (Taxonomy: {$taxonomy})</fo:block>
                <fo:block>{$node//tei:bibl/text()}</fo:block>
            </fo:block>
};

declare function tei2fo:refsDecl($node as element(tei:refsDecl), $options) as element()+ {
        <fo:block>
            <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}References Declarations</fo:block>
            <fo:block>{tei2fo:recurse($node, $options)}</fo:block>
        </fo:block>
};

declare function tei2fo:publicationStmt($node as element(tei:publicationStmt), $options) as element()+ {
        (:distributor:)
        let $authority := $node/tei:authority
        let $date := $node/tei:date
        let $authority := 
            if ($authority) 
            then 
                <fo:block>Published by {tei2fo:serialize-list($authority)}{if ($date) then concat(', ', $date) else ''}.</fo:block>
            else ()
        
        let $availability := $node/tei:availability
        let $availability-status := $availability/@status/string()
        let $availability := 
            if ($availability-status) 
            then 
                (
                <fo:block>Availability: {$availability-status}</fo:block>
                , 
                <fo:block>
                {for $p at $i in $availability/tei:p
                return
                    tei2fo:p($p, $options)}
                </fo:block>
                )
            else ()
        
        let $idno := 
            if ($node/tei:idno) 
            then 
                <fo:block><fo:block>Identifier</fo:block>{$node/tei:idno/text()}</fo:block>
            else ()
        
        return
            <fo:block>
                <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Publication Statement</fo:block>
                {$authority}
                {$availability}
                {$idno}
            </fo:block>
};

declare function tei2fo:respStmt($node as element(tei:respStmt)*, $options) {
    let $responsibilties := distinct-values($node/tei:resp)
    return
    for $responsibilty in $responsibilties
        return
            <fo:block>{replace(normalize-space($responsibilty),'\.+$','')}: 
                {tei2fo:serialize-list(
                    (
                    $node[tei:resp = $responsibilty]/tei:persName
                    ,
                    $node[tei:resp = $responsibilty]/tei:orgName
                    ,
                    $node[tei:resp = $responsibilty]/tei:name
                    ))}
            </fo:block>
};

declare function tei2fo:titleStmt($node as element(tei:titleStmt), $options) as element() {
        let $main-title := 
            if ($node/*:title[@type eq 'main']) 
            then $node/*:title[@type eq 'main']/text()
            else $node/*:title[not(@type)][1]/text()
        
        let $commentary-subtitles := $node/*:title[@type eq 'sub'][@subtype eq 'commentary']/text()
        let $commentary-subtitles := 
            if ($commentary-subtitles) then 
                <fo:block font-size="24pt" text-align="center" line-height="36pt">
                    With the {if (count($commentary-subtitles) eq 1) then 'Commentary' else 'Commentaries'}{' '}{string-join($commentary-subtitles, ', ')}
                </fo:block>
            else ()
        
        let $edition-subtitles := $node/*:title[@type eq 'sub'][@subtype eq 'edition-type' or not(@subtype)]/text()
        let $edition-subtitles := 
            if ($edition-subtitles) 
            then <fo:block>{string-join($edition-subtitles, ', ')}</fo:block> 
            else ()
        
        let $authors := $node/tei:author[not(@role)]
        let $authors := 
            if ($authors) 
            then 
                <fo:block font-size="20pt" space-before="20pt" line-height="30pt">
                    {'By '}
                    {tei2fo:serialize-list(
                        for $author in $authors return tei2fo:recurse($author, $options))}
                </fo:block> else ()
        
        let $commentators := $node/tei:author[@role eq 'commentator']
        let $commentators := 
            if ($commentators) 
            then
                <fo:block font-size="20pt" space-before="20pt" line-height="30pt">
                    {'By '}
                    {tei2fo:serialize-list(
                        for $commentator in $commentators return tei2fo:recurse($commentator, $options))}
                    </fo:block>
            else ()
        
        let $editors := $node/tei:editor
        let $editors := 
            if ($editors) 
            then 
                <fo:block>
                    {'Editor'}
                    {if (count($editors) gt 1) then 's' else ''}
                    {': '}
                    {tei2fo:serialize-list(
                        for $editor in $editors return tei2fo:recurse($editor, $options))}
                </fo:block> 
            else ()
        
        let $funders := $node/tei:funder
        let $funders := 
            if ($funders) 
            then
                <fo:block>
                    {'Funder'}
                    {if (count($funders) gt 1) then 's' else ''}
                    {': '}
                    {tei2fo:serialize-list(
                        for $funder in $funders return tei2fo:recurse($funder, $options))}
                </fo:block> 
            else ()
        
        let $principals := $node/tei:principal
        let $principals := 
            if ($principals) 
            then
                <fo:block>
                    {'Principal'}
                    {if (count($principals) gt 1) then 's' else ''}
                    {': '}
                    {tei2fo:serialize-list(
                        for $principal in $principals return tei2fo:recurse($principal, $options))}
                </fo:block>
            else ()
        
        let $sponsors := $node/tei:sponsor
        let $sponsors := 
            if ($sponsors) 
            then 
                <fo:block>
                    {'Sponsor'}
                    {if (count($sponsors) gt 1) then 's' else ''}
                    {': '}
                    {tei2fo:serialize-list(
                        for $sponsor in $sponsors return tei2fo:recurse($sponsor, $options))}
                </fo:block>
            else ()
        
        let $meetings := $node/tei:meeting
        let $meetings := 
            if ($meetings) 
            then 
                <fo:block>
                    {'Meeting'}
                    {if (count($meetings) gt 1) then 's' else ''}
                    {': '}
                    {tei2fo:serialize-list(
                        for $meeting in $meetings return tei2fo:recurse($meeting, $options))}
                </fo:block>
            else ()
        
        let $respStmt := tei2fo:respStmt($node/tei:respStmt, $options)
        
        return
            <fo:block>
                <fo:block font-size="38pt" line-height="1.2em" space-after="40pt" text-align="center">
                {$main-title}
                </fo:block>
                {$authors}
                {$commentary-subtitles}
                {$commentators}
                {$edition-subtitles}
                
                <fo:block space-before="60pt">
                {$editors}
                {$funders}
                {$principals}
                {$sponsors}
                {$meetings}
                {$respStmt}
                </fo:block>
            </fo:block>
};

declare function tei2fo:editionStmt($node as element(tei:editionStmt), $options) as element()+ {
    <fo:block>
        <fo:block>{tei2fo:attributes($tei2fo:subTitleHeader)}Edition Statement</fo:block>
        {tei2fo:recurse($node, $options)}                
    </fo:block>
};

declare function tei2fo:serialize-list($sequence as item()+) as xs:string {       
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

declare %private function tei2fo:get-id($node as element()) {
    ($node/@xml:id, $node/@exist:id)[1]
};

declare function tei2fo:resolve-xml-id($node as attribute(), $options) {
    let $absoluteURI := resolve-uri($node, base-uri($node))
    let $node := replace($node, '^#?(.*)$', '$1')
    return
        doc($absoluteURI)/id($node)/text()
};

(:Below are a number of dummy functions, dividing into empty, block-level and inline elements:)

declare function tei2fo:w($node as element(tei:w), $options) as element() {
    <span class="w" title="tei:w">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:address($node as element(tei:address), $options) as element() {
    <span class="address" title="tei:address">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:addrLine($node as element(tei:addrLine), $options) as element() {
    <span class="addrLine" title="tei:addrLine">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:author($node as element(tei:author), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="author" title="tei:author">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:biblScope($node as element(tei:biblScope), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="biblScope" title="tei:biblScope">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:byline($node as element(tei:byline), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="byline" title="tei:byline">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:caesura($node as element(tei:caesura), $options) as element() {
    <span class="caesura" title="tei:caesura">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:cit($node as element(tei:cit), $options) as element() {
    <span class="cit" title="tei:cit">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:listBibl($node as element(tei:listBibl), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="listBibl" title="tei:listBibl">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:seriesStmt($node as element(tei:seriesStmt), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="seriesStmt" title="tei:seriesStmt">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:docAuthor($node as element(tei:docAuthor), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="docAuthor" title="tei:docAuthor">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:docDate($node as element(tei:docDate), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="docDate" title="tei:docDate">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:docImprint($node as element(tei:docImprint), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="docImprint" title="tei:docImprint">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:docTitle($node as element(tei:docTitle), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="docTitle" title="tei:docTitle">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:emp($node as element(tei:emp), $options) as element() {
    <span class="emp" title="tei:emp">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:figDesc($node as element(tei:figDesc), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="figDesc" title="tei:figDesc">{tei2fo:recurse($node, $options)}</div>
    )
};

(:can be both block and inline:)
declare function tei2fo:listTranspose($node as element(tei:listTranspose), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="listTranspose" title="tei:listTranspose">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:locus($node as element(tei:locus), $options) as element() {
    <span class="locus" title="tei:locus">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:msContents($node as element(tei:msContents), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="msContents" title="tei:msContents">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:msDesc($node as element(tei:msDesc), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="msDesc" title="tei:msDesc">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:msIdentifier($node as element(tei:msIdentifier), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="msIdentifier" title="tei:msIdentifier">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:msName($node as element(tei:msName), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="msName" title="tei:msName">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:num($node as element(tei:num), $options) as element() {
    <span class="num" title="tei:num">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:ptr($node as element(tei:ptr), $options) as element() {
    <span class="ptr" title="tei:ptr"/>
};

declare function tei2fo:publisher($node as element(tei:publisher), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="publisher" title="tei:publisher">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:pubPlace($node as element(tei:pubPlace), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="pubPlace" title="tei:pubPlace">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:q($node as element(tei:q), $options) as element() {
    <fo:inline>"{tei2fo:recurse($node, $options)}"</fo:inline>
};

declare function tei2fo:rs($node as element(tei:rs), $options) as element() {
    <span class="rs" title="tei:rs">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:series($node as element(tei:series), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="series" title="tei:series">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:settlement($node as element(tei:settlement), $options) as element() {
    <span class="settlement" title="tei:settlement">{tei2fo:recurse($node, $options)}</span>
};

(:is most often empty:)
declare function tei2fo:space($node as element(tei:space), $options) as element() {
    <span class="space" title="tei:space">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:title($node as element(tei:title), $options) as element() {
    <span class="title" title="tei:title">{tei2fo:recurse($node, $options)}</span>
};

declare function tei2fo:titlePage($node as element(tei:titlePage), $options) as element()+ {
    (:argument byline docEdition docImprint docTitle titlePart:)
    let $id := $node/@xml:id/string()
    let $docAuthors := $node/tei:docAuthor
    let $docAuthors := 
        if ($docAuthors) 
        then 
            (', by '
            ,
            tei2fo:serialize-list(
                for $docAuthor in $docAuthors return tei2fo:recurse($docAuthor, $options))
            )
        else ()
    let $docDates := $node/tei:docDate
    let $docDates := 
        if ($docDates) 
        then 
            (' ('
            ,
            tei2fo:serialize-list(
                for $docDate in $docDates return tei2fo:recurse($docDate, $options))
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
            tei2fo:serialize-list(
                for $docImprint in $docImprints return tei2fo:recurse($docImprint, $options))
            ,
            ') '
            )
        else ()
    let $docTitles := $node/tei:docTitle
    let $docTitles := 
        if ($docTitles)
        then
            <span class="title-italic">{
            tei2fo:serialize-list(
                for $docTitle in $docTitles 
                let $titleParts := $docTitle/tei:titlePart
                return 
                    for $titlePart in $titleParts
                    return 
                        tei2fo:recurse($titlePart, $options))
            }</span>
        else ()
    let $titleParts := $node/tei:titlePart
    let $titleParts := 
        if ($titleParts)
        then
            tei2fo:serialize-list(
                for $titlePart in $titleParts return tei2fo:recurse($titlePart, $options))
        else ()
    let $other-elements := $node/(tei:* except (tei:titlePart, tei:docTitle, tei:docImprint, tei:docDate, tei:docAuthor))
    let $log := util:log("DEBUG", ("##$other-elementsxxx): ", $other-elements))

    return
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
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
    )
};

declare function tei2fo:titlePart($node as element(tei:titlePart), $options) as element()+ {
    (
    if ($node/@xml:id) then <a class="anchor" id="{$node/@xml:id}"/> else ()
    ,
    <div class="titlePart" title="tei:titlePart">{tei2fo:recurse($node, $options)}</div>
    )
};

declare function tei2fo:trailer($node as element(tei:trailer), $options) as element()+ {
    <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

declare function tei2fo:witDetail($node as element(tei:witDetail), $options) as element() {
    <fo:inline>{tei2fo:recurse($node, $options)}</fo:inline>
};

(:only for free-standing tei:sic; tei:choice normally formats tei:sic.:)
(:SR:)
declare function tei2fo:sic($node as element(tei:sic), $options) as element() {
    <fo:inline>{'{'}{tei2fo:recurse($node, $options)}{'}'}</fo:inline>
};

(:SR:)
declare function tei2fo:corr($node as element(tei:corr), $options) as element() {
    <fo:inline>{'['}{tei2fo:recurse($node, $options)}{']'}</fo:inline>
};

(:SR:)
declare function tei2fo:del($node as element(tei:del), $options) as element() {
    <fo:inline text-decoration="line-through">{'['}{tei2fo:recurse($node, $options)}{']'}</fo:inline>
};

(:SR:)
declare function tei2fo:add($node as element(tei:add), $options) as element() {
    let $place := $node/@place
    return
        if ($place = ('sup', 'above'))
        then <span class="add" title="tei:add" style="vertical-align:super;font-size.83em;">{'⟨'}{tei2fo:recurse($node, $options)}{'⟩'}</span>
        else
            if ($place = ('sub', 'below'))
            then <span class="add" title="tei:add" style="vertical-align:sub;font-size:.83em;">{'⟨'}{tei2fo:recurse($node, $options)}{'⟩'}</span>
            else <span class="add" title="tei:add">{'⟨'}{tei2fo:recurse($node, $options)}{'⟩'}</span>

};


declare function tei2fo:titlepage($header as element(tei:teiHeader))   {
    <fo:page-sequence master-reference="SARIT-Content">
        <fo:flow flow-name="xsl-region-body" font-family="{$tei2fo:font}"
            font-size="{$tei2fo:fontSize}pt" line-height="1.2em">
        { tei2fo:render($header) }
        </fo:flow>
    </fo:page-sequence>
};

declare function tei2fo:table-of-contents($work as element(tei:TEI)) {
    <fo:page-sequence master-reference="SARIT-Content">
        <fo:flow flow-name="xsl-region-body" font-family="{$tei2fo:font}">
        <fo:block font-size="30pt" space-after="1em" font-family="Arial, Helvetica, sans-serif">Table of Contents</fo:block>
        {
            for $act at $act-count in $work/tei:text/tei:body/tei:div
            return
                <fo:block space-after="3mm">
                    <fo:block text-align-last="justify">
                        {$act/tei:head/text()}
                        <fo:leader leader-pattern="dots"/>
                        <fo:page-number-citation ref-id="{generate-id($act)}"/>
                    </fo:block>
                    {
                        for $scene at $scene-count in $act/tei:div
                        return
                            <fo:block text-align-last="justify" margin-left="4mm">
                                {$scene/tei:head/text()}
                                <fo:leader leader-pattern="dots"/>
                                <fo:page-number-citation ref-id="{generate-id($scene)}"/>
                            </fo:block>
                    }
                </fo:block>
        }
        </fo:flow>
    </fo:page-sequence>
};

declare function tei2fo:main($id as xs:string) {
    let $play := collection($config:remote-data-root)/tei:TEI[@xml:id = $id]
    return
        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="SARIT-left" margin-top="10mm"
                        margin-bottom="10mm" margin-left="24mm"
                        margin-right="12mm" page-height="297mm" page-width="210mm">
                    <fo:region-body margin-bottom="10mm" margin-top="16mm"/>
                    <fo:region-before region-name="head-left" extent="10mm"/>
                </fo:simple-page-master>
                <fo:simple-page-master master-name="SARIT-right" margin-top="10mm"
                        margin-bottom="10mm" margin-left="12mm"
                        margin-right="24mm" page-height="297mm" page-width="210mm">
                    <fo:region-body margin-bottom="10mm" margin-top="16mm"/>
                    <fo:region-before region-name="head-right" extent="10mm"/>
                </fo:simple-page-master>
                <fo:page-sequence-master master-name="SARIT-Content">
                    <fo:repeatable-page-master-alternatives>
                        <fo:conditional-page-master-reference 
                            master-reference="SARIT-right" odd-or-even="odd"/>
                        <fo:conditional-page-master-reference 
                            master-reference="SARIT-left" odd-or-even="even"/>
                    </fo:repeatable-page-master-alternatives>
                </fo:page-sequence-master>
            </fo:layout-master-set>
            { tei2fo:titlepage($play/tei:teiHeader) }
            <fo:page-sequence master-reference="SARIT-Content">
                
                <fo:static-content flow-name="head-left">
                    <fo:block margin-bottom="0.7mm" text-align-last="justify" font-family="{$tei2fo:font}">
                        <fo:page-number/>
                        <fo:leader/>
                        <fo:retrieve-marker retrieve-class-name="title"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="head-right">
                    <fo:block margin-bottom="0.7mm" text-align-last="justify" font-family="{$tei2fo:font}">
                        <fo:retrieve-marker retrieve-class-name="title"/>
                        <fo:leader/>
                        <fo:page-number/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="xsl-footnote-separator">
                    <fo:block text-align-last="justify" margin-top="4mm" space-after="2mm">
                        <fo:leader leader-length="40%" rule-thickness="2pt" leader-pattern="rule" color="grey"/>
                    </fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body" font-family="{$tei2fo:font}"
                    font-size="{$tei2fo:fontSize}pt" line-height="{$tei2fo:lineHeight}"
                    xml:lang="sa" language="sa" hyphenate="true">
                    { tei2fo:render($play/tei:text/tei:body/tei:div) }
                </fo:flow>                         
            </fo:page-sequence>
        </fo:root>
};

declare function tei2fo:attributes($attrs as map(*)) {
    for $key in map:keys($attrs)
    return
        attribute { $key } { $attrs($key) }
};