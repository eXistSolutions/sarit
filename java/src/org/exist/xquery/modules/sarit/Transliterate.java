package org.exist.xquery.modules.sarit;

import com.ibm.icu.text.Transliterator;
import org.exist.dom.QName;
import org.exist.xquery.*;
import org.exist.xquery.value.*;

public class Transliterate extends BasicFunction {

    public final static FunctionSignature signatures[] = {
        new FunctionSignature(
            new QName("create", SaritModule.NAMESPACE_URI, SaritModule.PREFIX),
            "Creates a transliterator from a rule string and registers it under the given id.",
            new SequenceType[] {
                    new FunctionParameterSequenceType("id", Type.STRING, Cardinality.EXACTLY_ONE,
                            "the id by which the created transliterator will be known"),
                    new FunctionParameterSequenceType("rules", Type.STRING, Cardinality.EXACTLY_ONE,
                            "rule set to use for initializing the transliterator. Will be cached.")
            },
            new FunctionReturnSequenceType(Type.EMPTY, Cardinality.EXACTLY_ONE, "empty")
        ),
        new FunctionSignature(
            new QName("transliterate", SaritModule.NAMESPACE_URI, SaritModule.PREFIX),
            "Call the transliterator with the given id to transliterate a string of text.",
            new SequenceType[] {
                    new FunctionParameterSequenceType("id", Type.STRING, Cardinality.EXACTLY_ONE,
                            "id of the transliterator to use"),
                    new FunctionParameterSequenceType("text", Type.STRING, Cardinality.ZERO_OR_ONE,
                            "text to be transliterated")
            },
            new FunctionReturnSequenceType(Type.STRING, Cardinality.ZERO_OR_ONE, "Transliterated string")
        )
    };

    public Transliterate(XQueryContext context, FunctionSignature signature) {
        super(context, signature);
    }

    @Override
    public Sequence eval(Sequence[] args, Sequence sequence) throws XPathException {
        final String id = args[0].getStringValue();
        if (isCalledAs("create")) {
            final String rules = args[1].getStringValue();
            final Transliterator transliterator = Transliterator.createFromRules(id, rules, Transliterator.FORWARD);
            Transliterator.registerInstance(transliterator);
        } else {
            final String text = args[1].getStringValue();
            final Transliterator transliterator = Transliterator.getInstance(id);
            if (transliterator == null) {
                throw new XPathException(this, "Unknown transliterator: " + id);
            }
            return new StringValue(transliterator.transliterate(text));
        }
        return Sequence.EMPTY_SEQUENCE;
    }
}
