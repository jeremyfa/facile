package facile;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

class EnumAbstractMacro {

    public static macro function getValues(typePath:Expr):Expr {

        // From: https://code.haxe.org/category/macros/enum-abstract-values.html

        // Get the type from a given expression converted to string.
        // This will work for identifiers and field access which is what we need,
        // it will also consider local imports. If expression is not a valid type path or type is not found,
        // compiler will give a error here.
        var type = Context.getType(typePath.toString());

        // Switch on the type and check if it's an abstract with @:enum metadata
        switch (type.follow()) {
            case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):
                // enum abstract values are actually static fields of the abstract implementation class,
                // marked with @:enum and @:impl metadata. We generate an array of expressions that access those fields.
                // Note that this is a bit of implementation detail, so it can change in future Haxe versions, but it's been
                // stable so far.
                var valueExprs = [];
                for (field in ab.impl.get().statics.get()) {
                    if (field.meta.has(":enum") && field.meta.has(":impl")) {
                        var fieldName = field.name;
                        valueExprs.push(macro $typePath.$fieldName);
                    }
                }
                // Return collected expressions as an array declaration.
                return macro $a{valueExprs};
            default:
                // The given type is not an abstract, or doesn't have @:enum metadata, show a nice error message.
                throw new Error(type.toString() + " should be enum abstract", typePath.pos);
        }
    }

    public static macro function toCamelStringSwitch(typePath:Expr, e:Expr):Expr {

        var type = Context.getType(typePath.toString());

        switch (type.follow()) {
            case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):

                var cases:Array<Case> = [];
                for (field in ab.impl.get().statics.get()) {
                    if (field.meta.has(":enum") && field.meta.has(":impl")) {
                        var fieldName = field.name;
                        var camelName = TextUtils.upperCaseToCamelCase(fieldName);
                        cases.push({
                            values: [macro $typePath.$fieldName],
                            expr: macro $v{camelName}
                        });
                    }
                }

                return { pos: e.pos, expr: ESwitch(e, cases, null) };

            default:
                // The given type is not an abstract, or doesn't have @:enum metadata, show a nice error message.
                throw new Error(type.toString() + " should be enum abstract", typePath.pos);
        }
    }

    public static macro function toStringSwitch(typePath:Expr, e:Expr):Expr {

        var type = Context.getType(typePath.toString());

        switch (type.follow()) {
            case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):

                var cases:Array<Case> = [];
                for (field in ab.impl.get().statics.get()) {
                    if (field.meta.has(":enum") && field.meta.has(":impl")) {
                        var fieldName = field.name;
                        cases.push({
                            values: [macro $typePath.$fieldName],
                            expr: macro $v{fieldName}
                        });
                    }
                }

                return { pos: e.pos, expr: ESwitch(e, cases, null) };

            default:
                // The given type is not an abstract, or doesn't have @:enum metadata, show a nice error message.
                throw new Error(type.toString() + " should be enum abstract", typePath.pos);
        }
    }

    public static macro function fromStringSwitch(typePath:Expr, e:Expr):Expr {

        var type = Context.getType(typePath.toString());

        switch (type.follow()) {
            case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):

                var first:Expr = null;
                var cases:Array<Case> = [];
                for (field in ab.impl.get().statics.get()) {
                    if (field.meta.has(":enum") && field.meta.has(":impl")) {
                        var fieldName = field.name;
                        cases.push({
                            values: [macro $v{fieldName}],
                            expr: macro $typePath.$fieldName
                        });

                        if (first == null) {
                            first = macro {
                                throw "Cannot convert \"" + str_ + "\" to " + $v{ab.name};
                                $typePath.$fieldName;
                            }
                        }
                    }
                }

                var strAssign = macro var str_ = $e;
                var strRef = macro str_;

                return { pos: e.pos, expr: EBlock([
                    strAssign,
                    { pos: e.pos, expr: ESwitch(strRef, cases, first) }
                ])};

            default:
                // The given type is not an abstract, or doesn't have @:enum metadata, show a nice error message.
                throw new Error(type.toString() + " should be enum abstract", typePath.pos);
        }
    }

}
