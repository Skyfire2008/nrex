package nrex.core;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.MacroStringTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

using Lambda;
using StringTools;

class Macro{

	macro public static function buildEntity(): Array<Field>{
		var fields: Array<Field>=Context.getBuildFields();
		var currentClass=Context.getLocalClass().get();

		//extract names of groups contained from metadata and add a field for every group to entity
		var groupTypes: Array<Type>=[];
		currentClass.meta.extract("has")[0].params.iter(function(param){
			var name=param.getValue();
			var type=Context.getType(name);
			groupTypes.push(type);

			fields.push({ //create a new group field
				name: makeVarName(name),
				pos: Context.currentPos(),
				access: [APublic],
				kind: FVar(type.toComplexType(), null)
			});
		});

		currentClass.meta.remove("has"); //remove metadata

		return fields;
	}

	macro public static function buildGroup(): Array<Field>{
		var fields: Array<Field>=Context.getBuildFields();

		//if user has not defined a constructor
		if(!fields.exists(function(field){return field.name=="new";})){

			var constrArgs: Array<FunctionArg>=[{name: "owner", type: "Entity".toComplex(), opt: false}]; //TODO: consider fetching all inherited fields, if want to support subclasses
			var exprs: Array<Expr>=[macro super(owner)]; //add super constructor call

			//for every field: if its a var, add it to arguments and add an assignment to constructor
			for(field in fields){

				switch(field.kind){
					case(FVar(type, _)):
						constrArgs.push({ //create constructor arg
							name: field.name,
							type: type,
							opt: false
						});
						//if(field.name!="owner"){ //create assignment
							exprs.push(macro $p{["this", field.name]}=$i{field.name});
						//}
					default:
				}
			}

			//add constructor to fields
			fields.push({
				name: "new",
				pos: Context.currentPos(),
				access: [APublic],
				kind: FFun({
					args: constrArgs,
					expr: macro $b{exprs},
					params: [],
					ret: null
				})
			});
		}

		return fields;
	}

	public static inline function makeVarName(groupName: String): String{
		var nameBuf: StringBuf=new StringBuf();

		var words=groupName.split(".");
		for(i in 0...words.length){
			var word=words[i];
			if(i==0){
				nameBuf.add(word.substr(0, 1).toLowerCase());
			}else{
				nameBuf.add(word.substr(0, 1).toUpperCase());
			}
			nameBuf.addSub(word, 1);
		}

		return nameBuf.toString();
	}

}