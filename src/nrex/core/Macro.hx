package nrex.core;

import haxe.ds.StringMap;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.MacroStringTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

using Lambda;
using StringTools;

class Macro{

	/**
	 * Maps group to fields, that should be included in an entity that has the given group
	 * so that they can be calculated once per group
	 */
	private static var groupFields: StringMap<Array<Field>>=new StringMap<Array<Field>>();

	/**
	 * Builds an entity:
	 * 		1)Every group an entity has is added as a field with getter
	 * 		2)Variable fields of groups that entity has are combined together
	 * 		if there are several vars with same name, the first one counts
	 * 		so that the user can define them themself
	 */
	macro public static function buildEntity(): Array<Field>{
		var fields: Array<Field>=Context.getBuildFields(); 

		var currentClass=Context.getLocalClass().get();

		//EXTRACT GROUP NAMES AND FOR EVERY GROUP...
		var groupTypes: Array<Type>=[];
		currentClass.meta.extract("has")[0].params.iter(function(param){
			var name=param.getValue();
			var type=Context.getType(name);

			//TODO: will I need this?
			groupTypes.push(type);

			//get current group fields
			var currentFields: Array<Field>=groupFields.get(name);
			if(currentFields==null){ //if no fields for current group, add them
				var tempFields=type.getClass().fields.get();
				
				//filter out non-normal-access non-variables
				tempFields=tempFields.filter(function(f){
					switch(f.kind){
						case FVar(AccNormal, AccNormal): return true;
						default: return false;
					}
				});

				//convert class fields to build fields and add them
				currentFields=new Array<Field>();
				tempFields.iter(function(f){
					currentFields.push(cf2f(f));
				});

				groupFields.set(name, currentFields);

			}

			//add group fields to entity
			currentFields.iter(function(f){
				fields.push(f);
			});

			fields.push({ //create a new group field
				name: makeVarName(name),
				pos: Context.currentPos(),
				access: [APublic],
				kind: FVar(type.toComplexType(), null)
			});
		});

		//add 

		currentClass.meta.remove("has"); //remove metadata

		return fields;
	}

	/**
	 * Builds a group:
	 * 		1)Adds a constructor, assigning values to every var of the group
	 */
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

	/**
	 * Converts ClassFields to build Fields
	 */
	private static function cf2f(field: ClassField): Field{
		//TODO: add checks and shit here

		var result: Field={
			access: [APublic],
			kind: FVar(field.type.toComplexType()),
			name: field.name,
			pos: Context.currentPos()
		};
		return result;
	}

	//TODO: instead consider using name of the class
	/**
	 * Generates names for fields, containing entities' groups.
	 * 
	 * Names are generated from group names according to following rules:
	 * 		1)Every letter after a period becomes capitalized
	 * 		2)Periods are removed
	 * 		3)First letter is changed to lowercase
	 * 	
	 * Examples:
	 * 		"MoveGroup" -> "moveGroup"
	 * 		"nrex.groups.MoveGroup" -> "nrexGroupsMoveGroup"
	 */
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