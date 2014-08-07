xquery version "3.0";

declare namespace fo="http://www.w3.org/1999/XSL/Format";

import module namespace tei2fo="http://exist-db.org/xquery/app/sarit/tei2fo" at "tei2fo.xql";

(:fo:main():)
let $config :=
    <fop version="1.0">
      <!-- Strict user configuration -->
      <strict-configuration>true</strict-configuration>
    
      <!-- Strict FO validation -->
      <strict-validation>true</strict-validation>
    
      <!-- Base URL for resolving relative URLs -->
      <base>./</base>
    
      <!-- Font Base URL for resolving relative font URLs -->
      <font-base>./</font-base>
      <renderers>
          <renderer mime="application/pdf">
            <fonts>
              <auto-detect/>
            </fonts>
            </renderer>
        </renderers>
    </fop>
let $id := request:get-parameter("id", ())
(:return:)
(:    tei2fo:main($id):)
let $pdf := xslfo:render(tei2fo:main($id), "application/pdf", (), $config)
return
    response:stream-binary($pdf, "media-type=application/pdf", $id || ".pdf")