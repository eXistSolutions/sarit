xquery version "3.0";


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace fo="http://www.w3.org/1999/XSL/Format";

declare option output:method "xml";
declare option output:media-type "application/xml";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace tei2fo="http://exist-db.org/xquery/app/sarit/tei2fo" at "tei2fo.xql";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";
(:  Set to 'ah' for AntennaHouse, 'fop' for Apache fop :)
declare variable $local:PROCESSOR := "ah";

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
      <font-base>file:///d:/Servers/sarit/fonts</font-base>
      <renderers>
          <renderer mime="application/pdf">
            <fonts>
                <!-- register a particular font -->
                <font kerning="yes"
                    metrics-url="siddhanta.xml"
                    embed-url="siddhanta.ttf">
                    <font-triplet name="Siddhanta" style="normal" weight="normal"/>
                </font>
                <font kerning="yes"
                    metrics-url="sanskrit2003.xml"
                    embed-url="Sanskrit2003.ttf">
                    <font-triplet name="Sanskrit2003" style="normal" weight="normal"/>
                </font>
            </fonts>
            </renderer>
        </renderers>
    </fop>
let $log := console:log("sarit", "Calling fop ...")
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
    let $result := (
        console:log("sarit", "Calling AntennaHouse ..."),
        process:execute(
            (
                "AHFCmd", "-d", $file || ".fo", "-o", $file || ".pdf", "-x", "2",
                "-peb", "1", "-pdfver", "PDF1.6", 
                "-p", "@PDF",
                "-tpdf"
            ), $options
        )
    )
    return (
        console:log("sarit", $result),
        if ($result/@exitCode = 0) then
            let $pdf := file:read-binary($file || ".pdf")
            return
                response:stream-binary($pdf, "media-type=application/pdf", $id || ".pdf")
        else
            $result
    )
};

let $id := request:get-parameter("id", ())
let $token := request:get-parameter("token", ())
let $source := request:get-parameter("source", ())
let $start := util:system-time()
let $fo := tei2fo:main($id)
return (
    console:log("sarit", "Generated fo for " || $id || " in " || util:system-time() - $start),
    response:set-cookie("sarit.token", $token),
    if ($source) then
        $fo
    else
        switch ($local:PROCESSOR)
            case "ah" return
                local:antenna-house($id, $fo)
            default return
                local:fop($id, $fo)
)