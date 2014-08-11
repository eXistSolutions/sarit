package org.exist.xquery.modules.sarit;

import org.exist.xquery.AbstractInternalModule;
import org.exist.xquery.FunctionDef;

import java.util.List;
import java.util.Map;

/**
 * XQuery module providing functions to transliterate devanagari to romanized sanskrit.
 */
public class SaritModule extends AbstractInternalModule {

    public final static String NAMESPACE_URI = "http://exist-db.org/xquery/sarit";
    public final static String PREFIX = "sarit";

    public final static FunctionDef[] functions = {
        new FunctionDef(Transliterate.signatures[0], Transliterate.class),
        new FunctionDef(Transliterate.signatures[1], Transliterate.class)
    };

    public SaritModule(Map<String, List<? extends Object>> parameters) {
        super(functions, parameters, false);
    }

    @Override
    public String getNamespaceURI() {
        return NAMESPACE_URI;
    }

    @Override
    public String getDefaultPrefix() {
        return PREFIX;
    }

    @Override
    public String getDescription() {
        return "XQuery module providing functions to transliterate devanagari to romanized sanskrit.";
    }

    @Override
    public String getReleaseVersion() {
        return "2.2";
    }
}
