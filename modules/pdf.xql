xquery version "3.0";

declare namespace fo="http://www.w3.org/1999/XSL/Format";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace tei2fo="http://exist-db.org/xquery/app/sarit/tei2fo" at "tei2fo.xql";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";
(:  Set to 'ah' for AntennaHouse, 'fop' for Apache fop :)
declare variable $local:PROCESSOR := "fop";

declare function local:fop($id as xs:string, $fo as element()) {
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
let $pdf := xslfo:render($fo, "application/pdf", (), $config)
return
    response:stream-binary($pdf, "media-type=application/pdf", $id || ".pdf")
};

declare function local:antenna-house($id as xs:string, $fo as element()) {
    let $file := 
        $local:WORKING_DIR || "/" || encode-for-uri($id) || 
        format-dateTime(current-dateTime(), "-[Y0000][M00][D00]-[H00][m00]") || "-" || request:get-remote-addr()
    let $serialized := file:serialize($fo, $file || ".fo", "indent=no")
    let $options :=
        <option>
            <workingDir>{system:get-exist-home()}</workingDir>
        </option>
    let $result :=
        process:execute(
            (
                "AHFCmd", "-d", $file || ".fo", "-o", $file || ".pdf", "-x", "2",
                "-peb", "1", "-pdfver", "PDF1.6", 
                "-p", "@PDF",
                "-tpdf"
            ), $options
        )
    return
        if ($result/@exitCode = 0) then
            let $pdf := file:read-binary($file || ".pdf")
            return
                response:stream-binary($pdf, "media-type=application/pdf", $id || ".pdf")
        else
            $result
};

let $id := request:get-parameter("id", ())
let $source := request:get-parameter("source", ())
let $fo := tei2fo:main($id)
return
    if ($source) then
        $fo
    else
        switch ($local:PROCESSOR)
            case "ah" return
                local:antenna-house($id, $fo)
            default return
                local:fop($id, $fo)