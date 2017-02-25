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

		//extract names of groups contained by entity from the metadata
		var groupNames: Array<String>=[];
		currentClass.meta.extract("has")[0].params.iter(function(param){
			groupNames.push(param.getValue());
		});

		groupNames.iter(function(name){
			var type=Context.getType(name);
			trace(makeVarName(name));
			trace(type.toComplexType());
		});

		currentClass.meta.remove("has"); //remove metadata

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
				nameBuf.add(word.substr(0, 1).toUpperCase())
			}
			nameBuf.addSub(word, 1);
		}

		return nameBuf.toString();
	}

}