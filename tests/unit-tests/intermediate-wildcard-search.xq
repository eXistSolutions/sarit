xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $data := collection("/data/sarit")

let $term-query-string := <query><term>suKena</term></query>
let $leading-wildcard-query-string := <query><wildcard>*uKena</wildcard></query>
let $intermediate-wildcard-query-string := <query><wildcard>suK*na</wildcard></query>
let $trailing-wildcard-query-string := <query><wildcard>suKen*</wildcard></query>
let $all-wildcard-query-string := <query><wildcard>*uK*n*</wildcard></query>

return 
    (
        count($data//tei:l[ft:query(., $term-query-string)])
        ,
        count($data//tei:l[ft:query(., $leading-wildcard-query-string)])
        ,
        count($data//tei:l[ft:query(., $intermediate-wildcard-query-string)])
        ,
        count($data//tei:l[ft:query(., $trailing-wildcard-query-string)])
        ,
        count($data//tei:l[ft:query(., $all-wildcard-query-string)])
    )
    