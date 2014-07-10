xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $collection := '/db/apps/sarit-data-sarit/data'
let $title := 'vatsyayana-nyayabhasya.xml'
let $doc := doc(concat($collection, '/', $title))
let $elements := $doc//tei:div
let $subelements :=
    for $element in $elements/*
        return local-name($element)
let $subelements := distinct-values($subelements)
    return string-join($subelements, ', ')