xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $data := collection("/data/sarit")

let $all-wildcard-query-string := <query><wildcard>*uK*n*</wildcard></query>
let $hits := collection("/data/sarit")//tei:l[ft:query(., $all-wildcard-query-string)]

return
	<result hits-number="{count($hits)}"> 
		{
			$hits
		}
	</result>
    