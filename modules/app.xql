xquery version "3.0";

module namespace app="http://exist-db.org/apps/appblueprint/templates";


import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/appblueprint/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace tei-to-html="http://exist-db.org/xquery/app/tei2html" at "tei2html.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";


declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace h="http://www.w3.org/1999/xhtml";
declare namespace functx="http://www.functx.com";

declare variable $app:EXIDE := 
    let $pkg := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/eXide"]
    let $appLink :=
        if ($pkg) then
            substring-after(util:collection-name($pkg), repo:get-root())
        else
            ()
    let $path := string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), $appLink, "index.html"), "/")
    return
        replace($path, "/+", "/");
    
(:~
 : Process navbar links to cope with browsing.
 :)
declare
    %templates:wrap
function app:nav-set-active($node as node(), $model as map(*)) {
    let $path := request:get-attribute("$exist:path")
    let $res := request:get-attribute("$exist:resource")
    for $li in $node/h:li
    let $link := $li/h:a
    let $href := $link/@href
    return
        element { node-name($li) } {
            if ($href = $res or ($href = "works/" and starts-with($path, "/works/"))) then
                attribute class { "active" }
            else
                (),
            <h:a>
            {
                $link/@* except $link/@href,
                attribute href {
                    if ($link/@href = "works/" and starts-with($path, "/works/")) then
                        "."
                    else if (starts-with($path, "/works/")) then
                        "../" || $link/@href
                    else
                        $link/@href
                },
                $link/node()
            }
            </h:a>,
            $li/h:ul
        }
};

declare function functx:contains-any-of
  ( $arg as xs:string? ,
    $searchStrings as xs:string* )  as xs:boolean {

   some $searchString in $searchStrings
   satisfies contains($arg,$searchString)
 } ;

(:modified by applying functx:escape-for-regex() :)
declare function functx:number-of-matches 
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer {
       
   count(tokenize(functx:escape-for-regex(functx:escape-for-regex($arg)),functx:escape-for-regex($pattern))) - 1
 } ;

declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
 
(:~
 : List SARIT works
 :)
declare 
    %templates:wrap
function app:list-works($node as node(), $model as map(*)) {
    map {
        "works" :=
            for $work in collection($config:remote-data-root)/tei:TEI
            order by app:work-title($work)
            return
                $work
    }
};

declare
    %templates:wrap
function app:work($node as node(), $model as map(*), $id as xs:string) {
    let $work := collection($config:remote-data-root)//id($id)
    return
        map { "work" := $work[1] }
};

declare function app:header($node as node(), $model as map(*)) {
    tei-to-html:render($model("work")/tei:teiHeader)
};

(:You can always see three levels: the current level, is siblings, its parent and its children. 
This means that you can always go up and down (and sideways).
One could leave out or elide the siblings. :)
declare 
    %templates:default("full", "false")
function app:outline($node as node(), $model as map(*), $full as xs:boolean) {
    let $position := $model("work")
    let $root := if ($full) then $position/ancestor::tei:TEI else $position
    let $long := $node/@data-template-details/string()
    let $work := $root/ancestor-or-self::tei:TEI
    return
        if (
            $work/tei:text/tei:front/tei:titlePage, 
            $work/tei:text/tei:front/tei:div, 
            $work/tei:text/tei:body/tei:div, 
            $work/tei:text/tei:back/tei:div
           ) 
        then (
            <ul class="contents">{
                (:if it is not the whole work:)
                if (local-name($root) = ('div', 'titlePage')) then
                    (:if it has divs below itself:)
                    <li>{
                    if ($root/tei:div) then
                        (
                        if ($root/parent::tei:div) 
                        (:show the parent:)
                        then app:toc-div($root/parent::tei:div, $long, $position, 'no-list-item') 
                        (:NB: this creates an empty <li> if there is no div parent:)
                        (:show nothing:)
                        else ()
                        ,
                        for $div in $root/preceding-sibling::tei:div
                        return app:toc-div($div, $long, $position, 'list-item')
                        ,
                        app:toc-div($root, $long, $position, 'list-item')
                        ,
                        <ul>
                            {
                            for $div in $root/tei:div
                            return app:toc-div($div, $long, $position, 'list-item')
                            }
                        </ul>
                        ,
                        for $div in $root/following-sibling::tei:div
                        return app:toc-div($div, $long, $position, 'list-item')
                        )
                    else
                    (
                        (:if it is a leaf:)
                        (:show its parent:)
                        app:toc-div($root/parent::tei:div, $long, $position, 'no-list-item')
                        ,
                        (:show its preceding siblings:)
                        <ul>
                            {
                            for $div in $root/preceding-sibling::tei:div
                            return app:toc-div($div, $long, $position, 'list-item')
                            ,
                            (:show itself:)
                            (:NB: should not have link:)
                            app:toc-div($root, $long, $position, 'list-item')
                            ,
                            (:show its following siblings:)
                            for $div in $root/following-sibling::tei:div
                            return app:toc-div($div, $long, $position, 'list-item')
                            }
                        </ul>
                        )
                       }</li> 
                else
                    (:if it is the whole work:)
                    (
                    if ($work/tei:text/tei:front/tei:titlePage, $work/tei:text/tei:front/tei:div)
                    then
                        <div class="text-front">
                        <h6>Front Matter</h6>
                        {for $div in 
                            (
                            $work/tei:text/tei:front/tei:titlePage, 
                            $work/tei:text/tei:front/tei:div 
                            )
                        return app:toc-div($div, $long, $position, 'list-item')
                        }</div>
                        else ()
                    ,
                    <div class="text-body">
                    <h6>{if ($work/tei:text/tei:front/tei:titlePage, $work/tei:text/tei:front/tei:div, $work/tei:text/tei:back/tei:div) then 'Text' else ''}</h6>
                    {for $div in 
                        (
                        $work/tei:text/tei:body/tei:div 
                        )
                    return app:toc-div($div, $long, $position, 'list-item')
                    }</div>
                    ,
                    if ($work/tei:text/tei:back/tei:div)
                    then
                        <h6 class="text-back">
                        <h6>Back Matter</h6>
                        {for $div in 
                            (
                            $work/tei:text/tei:back/tei:div 
                            )
                        return app:toc-div($div, $long, $position, 'list-item')
                        }</h6>
                    else ()
                    )
            }</ul>
        ) else ()
};

(:based on Joe Wincentowski, http://digital.humanities.ox.ac.uk/dhoxss/2011/presentations/Wicentowski-XMLDatabases-materials.zip:)
declare function app:generate-toc-from-divs($node, $current as element()?, $long as xs:string?) {
    if ($node/tei:div) 
    then
        <ul style="display: none">{
            for $div in $node/tei:div
            return app:toc-div($div, $long, $current, 'list-item')
        }</ul>
    else ()
};

(:based on Joe Wincentowski, http://digital.humanities.ox.ac.uk/dhoxss/2011/presentations/Wicentowski-XMLDatabases-materials.zip:)
declare function app:derive-title($div) {
    if (local-name($div) eq 'div')
    then
        let $n := $div/@n/string()
        let $title := 
            (:if the div has a header:)
            if ($div/tei:head) 
            then
                concat(
                    if ($n) then concat($n, ': ') else ''
                    ,
                    string-join(
                        for $node in $div/tei:head/node() 
                        return data($node)
                    , ' ')
                )
            else
                (:otherwise, take part of the text itself:)
                if (string-length(data($div)) gt 0) 
                then 
                    concat(
                        if ($div/@type) 
                        then concat('[', $div/@type/string(), '] ') 
                        else ''
                    , substring(data($div), 1, 25), '…') 
                else concat('[', $div/@type/string(), ']')
        return $title
    else
        if (local-name($div) eq 'titlePage')
        then tei-to-html:titlePage($div, <options/>)
        else ()
};

(:based on Joe Wincentowski, http://digital.humanities.ox.ac.uk/dhoxss/2011/presentations/Wicentowski-XMLDatabases-materials.zip:)
declare function app:toc-div($div, $long as xs:string?, $current as element()?, $list-item as xs:string?) {
    let $div-id := $div/@xml:id/string()
    let $title := app:derive-title($div)
    return
        if ($list-item eq 'list-item')
        then
            if (count($div/ancestor::tei:div) < 2)
            then
                <li class="{if ($div is $current) then 'current' else 'not-current'}">
                    {
                        if ($div/tei:div and count($div/ancestor::tei:div) < 1) then
                            <a href="#" class="toc-toggle"><i class="glyphicon glyphicon-plus"/></a>
                        else
                            ()
                    }
                    <a href="{$div-id}.html" class="toc-link">{$title}</a> 
                    {if ($long eq 'yes') then app:generate-toc-from-divs($div, $current, $long) else ()}
                </li>
            else ()
        else
            <a href="{$div-id}.html">{$title}</a> 
};

(:~
 : 
 :)
declare function app:work-title($node as node(), $model as map(*), $type as xs:string?) {
    let $suffix := if ($type) then "." || $type else ()
    let $work := $model("work")/ancestor-or-self::tei:TEI
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$work/@xml:id}{$suffix}">{ app:work-title($work) }</a>
};

declare %private function app:work-title($work as element(tei:TEI)?) {
    let $main-title := $work/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type eq 'main']/text()
    let $main-title := if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/text()
    let $commentary-titles := $work/*:teiHeader/*:fileDesc/*:titleStmt/*:title[@type eq 'sub'][@subtype eq 'commentary']/text()
    return
        if ($commentary-titles)
        then tei-to-html:serialize-list($commentary-titles)
        else $main-title
};

declare 
    %templates:wrap
function app:checkbox($node as node(), $model as map(*), $target-texts as xs:string*) {
    let $id := $model("work")/@xml:id/string()
    return (
        attribute { "value" } {
            $id
        },
        if ($id = $target-texts) then
            attribute checked { "checked" }
        else
            ()
    )
};

declare function app:work-author($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $work-commentators := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'commentator']/text()
    let $work-authors := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author[@role eq 'base-author']/text()
    let $work-authors := if ($work-authors) then $work-authors else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/text()
    let $work-authors := if ($work-commentators) then $work-commentators else $work-authors
    let $work-authors := if ($work-authors) then tei-to-html:serialize-list($work-authors) else ()
    return 
        $work-authors    
};

declare function app:work-lang($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $script := $work//tei:text/@xml:lang
    let $script := if ($script eq 'sa-Latn') then 'Roman (IAST)' else 'Devanagari'
    let $auto-conversion := $work//tei:revisionDesc/tei:change[@type eq 'conversion'][@subtype eq 'automatic'] 
    return 
        concat($script, if ($auto-conversion) then ' (automatically converted)' else '')  
};

declare function app:epub-link($node as node(), $model as map(*)) {
    let $id := $model("work")/@xml:id/string()
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$id}.epub">{ $node/node() }</a>
};

declare function app:pdf-link($node as node(), $model as map(*)) {
    let $id := $model("work")/@xml:id/string()
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$node/@href}{$id}.pdf">{ $node/node() }</a>
};

declare function app:zip-link($node as node(), $model as map(*)) {
    let $file := util:document-name($model("work"))
    let $downloadPath := request:get-scheme() ||"://" || request:get-server-name() || ":" || request:get-server-port() || substring-before(request:get-effective-uri(),"/db/apps/sarit/modules/view.xql") || $config:remote-download-root || "/" || substring-before($file,".xml") || ".zip"
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$downloadPath}">{ $node/node() }</a>
};

declare function app:xml-link($node as node(), $model as map(*)) {
    let $doc-path := document-uri(root($model("work")))
    let $eXide-link := $app:EXIDE || "?open=" || $doc-path
    let $rest-link := '/exist/rest' || $doc-path
    return
        if (xmldb:collection-available('/db/apps/eXide'))
        then 
            <a xmlns="http://www.w3.org/1999/xhtml" href="{$eXide-link}" 
                target="eXide" class="eXide-open" data-exide-open="{$doc-path}">{ $node/node() }</a>
        else 
            <a xmlns="http://www.w3.org/1999/xhtml" href="{$rest-link}" target="_blank">{ $node/node() }</a>
};

declare function app:copy-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href {
            let $link := $node/@href
            let $params :=
                string-join(
                    for $param in request:get-parameter-names()
                    for $value in request:get-parameter($param, ())
                    return
                        $param || "=" || $value,
                    "&amp;"
                )
            return
                $link || "?" || $params
        },
        $node/node()
    }
};

declare function app:work-authors($node as node(), $model as map(*)) {
    let $authors := distinct-values(collection($config:remote-data-root)//tei:fileDesc/tei:titleStmt/tei:author)
    let $authors := for $author in $authors order by translate($author, 'ĀŚ', 'AS') return $author 
    let $control := 
        <select multiple="multiple" name="work-authors" class="form-control">
            <option value="all" selected="selected">Search In Texts By Any Author</option>
            {for $author in $authors
            return <option value="{$author}">{$author}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare 
    %templates:wrap
function app:navigation($node as node(), $model as map(*)) {
    let $div := $model("work")
    let $parent := $div/parent::tei:div
    let $prevDiv := $div/preceding::tei:div[1]
    let $prevDiv :=
        if (empty($prevDiv) or $parent >> $prevDiv) then
            $parent
        else
            $prevDiv
    let $nextDiv := ($div//tei:div | $div/following::tei:div)[1]
    let $work := $div/ancestor-or-self::tei:TEI
    return
        map {
            "previous" := $prevDiv,
            "next" := $nextDiv,
            "work" := $work,
            "div" := $div
        }
};

declare
    %templates:wrap
function app:breadcrumbs($node as node(), $model as map(*)) {
    let $ancestors := $model("div")/ancestor-or-self::tei:div
    for $ancestor in $ancestors
    let $id := $ancestor/@xml:id
    return
        <li><a href="{$id}.html">{app:derive-title($ancestor)}</a></li>
};

declare
    %templates:wrap
function app:navigation-title($node as node(), $model as map(*)) {
    element { node-name($node) } {
        attribute href { $model('work')/@xml:id },
        $node/@* except $node/@href,
        app:work-title($model('work'))
    }
};

declare function app:navigation-link($node as node(), $model as map(*), $direction as xs:string) {
    if ($model($direction)) then
        element { node-name($node) } {
            $node/@* except $node/@href,
            attribute href { $model($direction)/@xml:id || ".html" },
            $node/node()
        }
    else
        '&#xA0;' (:hack to keep "Next" from dropping into the hr:) 
};

(: LUCENE :)

declare function app:lucene-view($node as node(), $model as map(*), $id as xs:string, $query as xs:string?) {
    for $div in $model("work")/id($id)
    let $div :=
        if ($query) then
            util:expand((
            $div[.//tei:p[ft:query(., $query)]],
            $div[.//tei:head[ft:query(., $query)]],
            $div[.//tei:lg[ft:query(., $query)]],
            $div[.//tei:trailer[ft:query(., $query)]],
            $div[.//tei:note[ft:query(., $query)]],
            $div[.//tei:list[ft:query(., $query)]],
            $div[.//tei:l[ft:query(., $query)]],
            $div[.//tei:quote[ft:query(., $query)]],
            $div[.//tei:table[ft:query(., $query)]],
            $div[.//tei:listApp[ft:query(., $query)]],
            $div[.//tei:listBibl[ft:query(., $query)]],
            $div[.//tei:cit[ft:query(., $query)]]),
            "add-exist-id=all")
        else
            $div
    let $view := 
        if ($div/tei:div) then
             (:If the current section has child divs, display only the text up to the first div.:) 
            element { node-name($div) } {
                $div/@*,
                $div/tei:div[1]/preceding-sibling::*
            }
        else
            $div
    return
        <div xmlns="http://www.w3.org/1999/xhtml" class="play">
        { tei-to-html:recurse($view, <options/>) }
        </div>
};

declare 
    %templates:default("index", "ngram")
function app:view($node as node(), $model as map(*), $id as xs:string, $index as xs:string, $query as xs:string?) {
        if ($index eq 'ngram')
        then app:ngram-view($node, $model, $id, $query)
        else app:lucene-view($node, $model, $id, $query)
};

(: NGRAM :)
declare function app:ngram-view($node as node(), $model as map(*), $id as xs:string, $query as xs:string?) {
    for $div in $model("work")/id($id)
    let $div :=
        if ($query) then
            util:expand((
            $div[.//tei:p[ngram:wildcard-contains(., $query)]],
            $div[.//tei:head[ngram:wildcard-contains(., $query)]],
            $div[.//tei:lg[ngram:wildcard-contains(., $query)]],
            $div[.//tei:trailer[ngram:wildcard-contains(., $query)]],
            $div[.//tei:note[ngram:wildcard-contains(., $query)]],
            $div[.//tei:list[ngram:wildcard-contains(., $query)]],
            $div[.//tei:l[ngram:wildcard-contains(., $query)]],
            $div[.//tei:quote[ngram:wildcard-contains(., $query)]],
            $div[.//tei:table[ngram:wildcard-contains(., $query)]],
            $div[.//tei:listApp[ngram:wildcard-contains(., $query)]],
            $div[.//tei:listBibl[ngram:wildcard-contains(., $query)]],
            $div[.//tei:cit[ngram:wildcard-contains(., $query)]]),
            "add-exist-id=all")
        else
            $div
    let $view := 
        if ($div/tei:div) then
            (: If the current section has child divs, display only the text up to the first div. :)
            element { node-name($div) } {
                $div/@*,
                $div/tei:div[1]/preceding-sibling::*
            }
        else
            $div
    return
        <div xmlns="http://www.w3.org/1999/xhtml" class="play">
        { tei-to-html:recurse($view, <options/>) }
        </div>
};

(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)
declare 
    %templates:default("index", "ngram")
    %templates:default("mode", "any")
    %templates:default("tei-target", "tei-text")
    %templates:default("scope", "narrow")
    %templates:default("work-authors", "all")
    %templates:default("scripts", "all")
    %templates:default("target-texts", "all")
function app:query($node as node()*, $model as map(*), $query as xs:string?, $index as xs:string, $mode as xs:string, $tei-target as xs:string+, $scope as xs:string, 
    $work-authors as xs:string+, $scripts as xs:string+, $target-texts as xs:string+) {
    (:let $log := console:log("Preparing query..."):)
    let $queryExpr := 
        if ($index eq 'ngram')
        then $query
        else app:create-query($query, $mode)
    (:let $log := console:log($query):)
    return
        if (empty($queryExpr) or $queryExpr = "") then
            let $cached := session:get-attribute("apps.sarit")
            return
                map {
                    "hits" := $cached,
                    "query" := session:get-attribute("apps.sarit.query")
                }
        else
            (:$target-texts will either have the value 'all' or a sequence of text xml:ids.:)
            let $target-texts := 
                (:("target-texts", "all")("work-authors", "all")("scripts", "all"):)
                (:If no texts have been selected and no authors have been selected and no scripts have been selected, search in all texts:)
                if ($target-texts = 'all' and $work-authors = 'all' and $scripts = 'all')
                then 'all' 
                else 
                    (:("target-texts", "not-all")("work-authors", "all")("scripts", "all"):)
                    (:If one or more texts have been selected, but no authors and no scripts have been selected, search in selected texts:)
                    if ($target-texts != 'all' and $work-authors = 'all' and $scripts = 'all')
                    then $target-texts
                    else 
                        (:("target-texts", "all")("work-authors", "not-all")("scripts", "all"):)
                        (:If no texts and no scripts have been selected, but one or more authors have been selected, search in texts selected by author:)
                        if ($target-texts = 'all' and $work-authors != 'all' and $scripts = 'all')
                        then distinct-values(collection($config:remote-data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id)
                        else
                            (:("target-texts", "all")("work-authors", "all")("scripts", "not-all"):)
                            (:If no texts and no authors have been selected, but one or more scripts have been selected, search in texts selected by script:)
                            if ($target-texts = 'all' and $work-authors = 'all' and $scripts != 'all')
                            then distinct-values(collection($config:remote-data-root)//tei:TEI[tei:text/@xml:lang = $scripts]/@xml:id)
                            else
                                (:("target-texts", "not-all")("work-authors", "not-all")("scripts", "not-all"):)
                                (:If one or more texts and one or more scripts and one or more authors have been selected, search in the union of the three:)
                                if ($target-texts != 'all' and $work-authors != 'all' and $scripts != 'all')
                                then ($target-texts, distinct-values(collection($config:remote-data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id), distinct-values(collection($config:remote-data-root)//tei:TEI[tei:text/@xml:lang = $scripts]/@xml:id))
                                else
                                    (:("target-texts", "not-all")("work-authors", "not-all")("scripts", "all"):)
                                    (:If one or more texts and more authors have been selected, but no scripts have been selected, search in the union of selected texts and texts selected by authors:)
                                    if ($target-texts != 'all' and $work-authors != 'all' and $scripts = 'all')
                                    then ($target-texts, distinct-values(collection($config:remote-data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id))
                                    else    
                                        (:("target-texts", "not-all")("work-authors", "all")("scripts", "not-all"):)
                                        (:If one or more texts have been selected and one or more scripts have been selected, but no authors have been selected, search in union of selected texts and texts selected by script:)
                                        if ($work-authors != 'all' and $target-texts = 'all' and $scripts != 'all') 
                                        then ($target-texts, distinct-values(collection($config:remote-data-root)//tei:TEI[tei:text/@xml:lang = $scripts]/@xml:id)) 
                                        else
                                            (:("target-texts", "all")("work-authors", "not-all")("scripts", "not-all"):)
                                            (:If no texts have been selected, but one or more scripts and one or more authors have been selected, search in union of texts selected by author and texts selected by script:)
                                            if ($work-authors != 'all' and $target-texts = 'all' and $scripts != 'all') 
                                            then (distinct-values(collection($config:remote-data-root)//tei:TEI[tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author = $work-authors]/@xml:id), distinct-values(collection($config:remote-data-root)//tei:TEI[./@xml:lang = $scripts]/@xml:id)) 
                                            else ()
            let $context := 
                if ($target-texts = 'all')
                then 
                    if (count($tei-target) eq 2)
                    then collection($config:remote-data-root)/tei:TEI
                    else
                        if ($tei-target = 'tei-text')
                        then collection($config:remote-data-root)/tei:TEI/tei:text
                        else 
                            if ($tei-target = 'tei-header')
                            then collection($config:remote-data-root)/tei:TEI/tei:teiHeader
                            else ()
                else
                    if (count($tei-target) eq 2)
                    then collection($config:remote-data-root)//tei:TEI[@xml:id = $target-texts]
                    else 
                        if ($tei-target = 'tei-text')
                        then collection($config:remote-data-root)//tei:TEI[@xml:id = $target-texts]/tei:text
                        else 
                            if ($tei-target = 'tei-header')
                            then collection($config:remote-data-root)//tei:TEI[@xml:id = $target-texts]/tei:teiHeader
                            else ()
            
            (: LUCENE :)
            let $hits :=
                if ($index eq 'lucene')
                then
                    if ($scope eq 'narrow')
                    then
                        for $hit in 
                            if (count($tei-target) eq 2)
                            then 
                                (
                                $context//tei:p[ft:query(., $queryExpr)],
                                $context//tei:head[ft:query(., $queryExpr)],
                                $context//tei:lg[ft:query(., $queryExpr)],
                                $context//tei:trailer[ft:query(., $queryExpr)],
                                $context//tei:note[ft:query(., $queryExpr)],
                                $context//tei:list[ft:query(., $queryExpr)],
                                $context//tei:l[ft:query(., $queryExpr)],
                                $context//tei:quote[ft:query(., $queryExpr)],
                                $context//tei:table[ft:query(., $queryExpr)],
                                $context//tei:listApp[ft:query(., $queryExpr)],
                                $context//tei:listBibl[ft:query(., $queryExpr)],
                                $context//tei:cit[ft:query(., $queryExpr)],
                                $context//tei:encodingDesc[ft:query(., $queryExpr)],
                                $context//tei:fileDesc[ft:query(., $queryExpr)],
                                $context//tei:profileDesc[ft:query(., $queryExpr)],
                                $context//tei:revisionDesc[ft:query(., $queryExpr)]
                                )
                            else
                                if ($tei-target = 'tei-text')
                                then
                                    (
                                    $context//tei:p[ft:query(., $queryExpr)],
                                    $context//tei:head[ft:query(., $queryExpr)],
                                    $context//tei:lg[ft:query(., $queryExpr)],
                                    $context//tei:trailer[ft:query(., $queryExpr)],
                                    $context//tei:note[ft:query(., $queryExpr)],
                                    $context//tei:list[ft:query(., $queryExpr)],
                                    $context//tei:l[ft:query(., $queryExpr)],
                                    $context//tei:quote[ft:query(., $queryExpr)],
                                    $context//tei:table[ft:query(., $queryExpr)],
                                    $context//tei:listApp[ft:query(., $queryExpr)],
                                    $context//tei:listBibl[ft:query(., $queryExpr)],
                                    $context//tei:cit[ft:query(., $queryExpr)]
                                    )
                                else 
                                    if ($tei-target = 'tei-header')
                                    then 
                                        (
                                        $context//tei:encodingDesc[ft:query(., $queryExpr)],
                                        $context//tei:fileDesc[ft:query(., $queryExpr)],
                                        $context//tei:profileDesc[ft:query(., $queryExpr)],
                                        $context//tei:revisionDesc[ft:query(., $queryExpr)]
                                        )
                                    else ()    
                        order by ft:score($hit) descending
                        return $hit
                    else
                        for $hit in 
                            if (count($tei-target) eq 2)
                            then
                                (
                                $context//tei:div[not(tei:div)][ft:query(., $queryExpr)], 
                                $context//tei:div[not(tei:div)][ft:query(., $queryExpr)],
                                $context/descendant-or-self::tei:teiHeader[ft:query(., $queryExpr)]
                                )
                            else
                                if ($tei-target = 'tei-text')
                                then
                                    (
                                    $context//tei:div[not(tei:div)][ft:query(., $queryExpr)], 
                                    $context//tei:div[not(tei:div)][ft:query(., $queryExpr)]
                                    )
                                else 
                                    if ($tei-target = 'tei-header')
                                    then 
                                        $context/descendant-or-self::tei:teiHeader[ft:query(., $queryExpr)]
                                    else ()
                        order by ft:score($hit) descending
                        return $hit
            (: NGRAM :)
            else
                if ($scope eq 'narrow' and count($tei-target) eq 2)
                then
                    for $hit in 
                        (
                        $context//tei:p[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:head[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:lg[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:trailer[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:note[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:list[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:l[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:quote[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:table[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:listApp[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:listBibl[ngram:wildcard-contains(., $queryExpr)],
                        $context//tei:cit[ngram:wildcard-contains(., $queryExpr)]
                        )
                    order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending 
                    return $hit
                else
                    if ($scope eq 'narrow' and $tei-target eq 'tei-text')
                    then
                        for $hit in 
                            (
                            $context//tei:p[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:head[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:lg[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:trailer[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:note[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:list[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:l[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:quote[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:table[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:listApp[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:listBibl[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:cit[ngram:wildcard-contains(., $queryExpr)]
                            )
                        order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending 
                        return $hit
                    else
                        if ($scope eq 'narrow' and $tei-target eq 'tei-header')
                        then
                        for $hit in 
                            (
                            $context//tei:encodingDesc[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:fileDesc[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:profileDesc[ngram:wildcard-contains(., $queryExpr)],
                            $context//tei:revisionDesc[ngram:wildcard-contains(., $queryExpr)]
                            )
                        order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending 
                        return $hit
                        else
                            if ($scope eq 'broad' and count($tei-target) eq 2)
                            then
                                for $hit in
                                    (
                                    $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queryExpr)],
                                    $context/descendant-or-self::tei:teiHeader[ngram:wildcard-contains(., $queryExpr)]
                                    )
                                order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                return $hit
                            else
                                if ($scope eq 'broad' and $tei-target eq 'tei-text')
                                then
                                    for $hit in 
                                        $context//tei:div[not(tei:div)][ngram:wildcard-contains(., $queryExpr)]
                                    order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                    return $hit
                                else 
                                    if ($scope eq 'broad' and $tei-target eq 'tei-header')
                                    then 
                                    for $hit in (
                                        $context/descendant-or-self::tei:teiHeader[ngram:wildcard-contains(., $queryExpr)]
                                        )
                                        order by $hit/ancestor-or-self::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] ascending
                                        return $hit
                                    else ()
            let $store := (
                session:set-attribute("apps.sarit", $hits),
                session:set-attribute("apps.sarit.query", $queryExpr)
            )
            return
                (: Process nested templates :)
                map {
                    "hits" := $hits,
                    "query" := $queryExpr
                }
};

(:~
    Helper function: create a lucene query from the user input
:)
declare %private function app:create-query($query-string as xs:string?, $mode as xs:string) {
    let $query-string := if ($query-string) then app:sanitize-lucene-query($query-string) else ''
    let $query-string := normalize-space($query-string)
    let $query:=
        (:If the query is in "any" mode and contains any operator used in boolean searches, proximity searches, boosted searches, or regex searches, 
        pass it on to the query parser;:) 
        if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{','[', '(', '<', '@', '#', '&amp;', '~')) and $mode eq 'any')
        then 
            let $luceneParse := app:parse-lucene($query-string)
            let $luceneXML := util:parse($luceneParse)
            let $lucene2xml := app:lucene2xml($luceneXML/node(), $mode)
            return $lucene2xml
        (:otherwise the query is an ordinary term query or one of the special options (phrase, near, fuzzy, wildcard or regex):)
        else
            let $query-string := tokenize($query-string, '\s')
            let $last-item := $query-string[last()]
            let $query-string := 
                if ($last-item castable as xs:integer) 
                then string-join(subsequence($query-string, 1, count($query-string) - 1), ' ') 
                else string-join($query-string, ' ')
            let $query :=
                <query>
                    {
                        if ($mode eq 'any') then
                            for $term in tokenize($query-string, '\s')
                            return <term occur="should">{$term}</term>
                        else if ($mode eq 'all') then
                            <bool>
                            {
                                for $term in tokenize($query-string, '\s')
                                return <term occur="must">{$term}</term>
                            }
                            </bool>
                        else 
                            if ($mode eq 'phrase') 
                            then <phrase>{$query-string}</phrase>
                            else
                                if ($mode eq 'near-unordered')
                                then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="no">{$query-string}</near>
                                else 
                                    if ($mode eq 'near-ordered')
                                    then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="yes">{$query-string}</near>
                                    else 
                                        if ($mode eq 'fuzzy')
                                        then <fuzzy max-edits="{if ($last-item castable as xs:integer and number($last-item) < 3) then $last-item else 2}">{tokenize($query-string, ' ')[1]}</fuzzy>
                                        else 
                                            if ($mode eq 'wildcard')
                                            then <wildcard>{$query-string}</wildcard>
                                            else 
                                                if ($mode eq 'regex')
                                                then <regex>{$query-string}</regex>
                                                else ()
                    }</query>
            return $query
    return $query
    
};

(:~
 : Create a bootstrap pagination element to navigate through the hits.
 :)
declare
    %templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function app:paginate($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        return (
            if ($start = 1) then (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ) else (
                <li>
                    <a href="?start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li>
                    <a href="?start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <li class="active"><a href="?start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                else
                    <li><a href="?start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
            if ($start + $per-page < count($model("hits"))) then (
                <li>
                    <a href="?start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a href="?start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            ) else (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            )
        ) else
            ()
};

(:~
    Create a span with the number of items in the current search result.
:)
declare function app:hit-count($node as node()*, $model as map(*)) {
    <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span>
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare 
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function app:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer) {
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $id := $hit/ancestor-or-self::tei:div[1]/@xml:id/string()
    let $id := if ($id) then $id else ($hit/ancestor-or-self::*/@xml:id)[1]/string()
    let $work-title := app:work-title($hit/ancestor::tei:TEI)
    let $doc-id := $hit/ancestor::tei:TEI/@xml:id
    let $div-ancestor-id := $hit/ancestor::tei:div[1]/@xml:id
    let $div-ancestor-head := $hit/ancestor::tei:div[1]/tei:head/text()
    (:pad hit with surrounding siblings:)
    let $hitExpanded := <hit>{($hit/preceding-sibling::*[1], $hit, $hit/following-sibling::*[1])}</hit>
    let $loc := 
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <a href="{$doc-id}.html">{$work-title}</a>{if ($div-ancestor-head) then ', ' else ''}<a href="{$div-ancestor-id}.html">{$div-ancestor-head}</a>
            </td>
        </tr>
    let $matchId := ($hit/@xml:id, util:node-id($hit))[1]
    let $config := <config width="60" table="yes" link="{$id}.html?query={$model('query')}#{$matchId}"/>
    let $kwic := kwic:summarize($hitExpanded, $config, app:filter#2)
    return
        ($loc, $kwic)        
};

(:~
    Callback function called from the kwic module.
:)
declare %private function app:filter($node as node(), $mode as xs:string) as item()? {
  if ($node/parent::tei:speaker or $node/parent::tei:stage or $node/parent::tei:head) then 
      ()
  else if ($mode eq 'before') then
      concat($node, ' ')
  else 
      concat(' ', $node)
};

declare function app:base($node as node(), $model as map(*)) {
    let $context := request:get-context-path()
    let $app-root := substring-after($config:app-root, "/db/")
    return
        <base xmlns="http://www.w3.org/1999/xhtml" href="{$context}/{$app-root}/"/>
};

(: This functions provides crude way to avoid the most common errors with paired expressions and apostrophes. :)
(: TODO: check order of pairs:)
declare %private function app:sanitize-lucene-query($query-string as xs:string) as xs:string {
    let $query-string := replace($query-string, "'", "''") (:escape apostrophes:)
    (:TODO: notify user if query has been modified.:)
    (:Remove colons – Lucene fields are not supported.:)
    let $query-string := translate($query-string, ":", " ")
    let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) 
	   then $query-string
	   else replace($query-string, '"', ' ') (:if there is an uneven number of quotation marks, delete all quotation marks.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '{') + functx:number-of-matches($query-string, '}')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '{}', ' ') (:if there is an uneven number of braces, delete all braces.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '<') + functx:number-of-matches($query-string, '>')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '<>', ' ') (:if there is an uneven number of angle brackets, delete all angle brackets.:)
    return $query-string
};

(: Function to translate a Lucene search string to an intermediate string mimicking the XML syntax, 
with some additions for later parsing of boolean operators. The resulting intermediary XML search string will be parsed as XML with util:parse(). 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
(:TODO:
The following cases are not covered:
1)
<query><near slop="10"><first end="4">snake</first><term>fillet</term></near></query>
as opposed to
<query><near slop="10"><first end="4">fillet</first><term>snake</term></near></query>

w(..)+d, w[uiaeo]+d is not treated correctly as regex.
:)
declare %private function app:parse-lucene($string as xs:string) {
    (: replace all symbolic booleans with lexical counterparts :)
    if (matches($string, '[^\\](\|{2}|&amp;{2}|!) ')) 
    then
        let $rep := 
            replace(
            replace(
            replace(
                $string, 
            '&amp;{2} ', 'AND '), 
            '\|{2} ', 'OR '), 
            '! ', 'NOT ')
        return app:parse-lucene($rep)                
    else 
        (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :)
        if (matches($string, '[^<](AND|OR|NOT) ')) 
        then
            let $rep := replace($string, '(AND|OR|NOT) ', '<$1/>')
            return app:parse-lucene($rep)
        else 
            (: replace all '+' modifiers in token-initial position with '<AND/>' :)
            if (matches($string, '(^|[^\w&quot;])\+[\w&quot;(]'))
            then
                let $rep := replace($string, '(^|[^\w&quot;])\+([\w&quot;(])', '$1<AND type=_+_/>$2')
                return app:parse-lucene($rep)
            else 
                (: replace all '-' modifiers in token-initial position with '<NOT/>' :)
                if (matches($string, '(^|[^\w&quot;])-[\w&quot;(]'))
                then
                    let $rep := replace($string, '(^|[^\w&quot;])-([\w&quot;(])', '$1<NOT type=_-_/>$2')
                    return app:parse-lucene($rep)
                else 
                    (: replace parentheses with '<bool></bool>' :)
                    (:NB: regex also uses parentheses!:) 
                    if (matches($string, '(^|[\W-[\\]]|>)\(.*?[^\\]\)(\^(\d+))?(<|\W|$)'))                
                    then
                        let $rep := 
                            (: add @boost attribute when string ends in ^\d :)
                            (:if (matches($string, '(^|\W|>)\(.*?\)(\^(\d+))(<|\W|$)')) 
                            then replace($string, '(^|\W|>)\((.*?)\)(\^(\d+))(<|\W|$)', '$1<bool boost=_$4_>$2</bool>$5')
                            else:) replace($string, '(^|\W|>)\((.*?)\)(<|\W|$)', '$1<bool>$2</bool>$3')
                        return app:parse-lucene($rep)
                    else 
                        (: replace quoted phrases with '<near slop="0"></bool>' :)
                        if (matches($string, '(^|\W|>)(&quot;).*?\2([~^]\d+)?(<|\W|$)')) 
                        then
                            let $rep := 
                                (: add @boost attribute when phrase ends in ^\d :)
                                (:if (matches($string, '(^|\W|>)(&quot;).*?\2([\^]\d+)?(<|\W|$)')) 
                                then replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near boost=_$5_>$3</near>$6')
                                (\: add @slop attribute in other cases :\)
                                else:) replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near slop=_$5_>$3</near>$6')
                            return app:parse-lucene($rep)
                        else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :)
                            if (matches($string, '[\w-[<>]]+?~[\d.]*')) 
                            then
                                let $rep := replace($string, '([\w-[<>]]+?)~([\d.]*)', '<fuzzy max-edits=_$2_>$1</fuzzy>')
                                return app:parse-lucene($rep)
                            else (: wrap resulting string in '<query></query>' :)
                                concat('<query>', replace(normalize-space($string), '_', '"'), '</query>')
};

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and util:parse() 
to full-fledged boolean expressions employing XML query syntax. 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
declare %private function app:lucene2xml($node as item(), $mode as xs:string) {
    typeswitch ($node)
        case element(query) return 
            element { node-name($node)} {
            element bool {
            $node/node()/app:lucene2xml(., $mode)
        }
    }
    case element(AND) return ()
    case element(OR) return ()
    case element(NOT) return ()
    case element() return
        let $name := 
            if (($node/self::phrase | $node/self::near)[not(@slop > 0)]) 
            then 'phrase' 
            else node-name($node)
        return
            element { $name } {
                $node/@*,
                    if (($node/following-sibling::*[1] | $node/preceding-sibling::*[1])[self::AND or self::OR or self::NOT or self::bool])
                    then
                        attribute occur {
                            if ($node/preceding-sibling::*[1][self::AND]) 
                            then 'must'
                            else 
                                if ($node/preceding-sibling::*[1][self::NOT]) 
                                then 'not'
                                else 
                                    if ($node[self::bool]and $node/following-sibling::*[1][self::AND])
                                    then 'must'
                                    else
                                        if ($node/following-sibling::*[1][self::AND or self::OR or self::NOT][not(@type)]) 
                                        then 'should' (:must?:) 
                                        else 'should'
                        }
                    else ()
                    ,
                    $node/node()/app:lucene2xml(., $mode)
        }
    case text() return
        if ($node/parent::*[self::query or self::bool]) 
        then
            for $tok at $p in tokenize($node, '\s+')[normalize-space()]
            (:Here the query switches into regex mode based on whether or not characters used in regex expressions are present in $tok.:)
            (:It is not possible reliably to distinguish reliably between a wildcard search and a regex search, so switching into wildcard searches is ruled out here.:)
            (:One could also simply dispense with 'term' and use 'regex' instead - is there a speed penalty?:)
                let $el-name := 
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)') or $mode eq 'regex')
                    then 'regex'
                    else 'term'
                return 
                    element { $el-name } {
                        attribute occur {
                        (:if the term follows AND:)
                        if ($p = 1 and $node/preceding-sibling::*[1][self::AND]) 
                        then 'must'
                        else 
                            (:if the term follows NOT:)
                            if ($p = 1 and $node/preceding-sibling::*[1][self::NOT])
                            then 'not'
                            else (:if the term is preceded by AND:)
                                if ($p = 1 and $node/following-sibling::*[1][self::AND][not(@type)])
                                then 'must'
                                    (:if the term follows OR and is preceded by OR or NOT, or if it is standing on its own:)
                                else 'should'
                    }
                    (:,
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)')) 
                    then
                        (\:regex searches have to be lower-cased:\)
                        attribute boost {
                            lower-case(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$3'))
                        }
                    else ():)
        ,
        (:regex searches have to be lower-cased:)
        lower-case(normalize-space(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$1')))
        }
        else normalize-space($node)
    default return
        $node
};


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