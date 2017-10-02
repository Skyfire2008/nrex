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
	 * Builds the game object:
	 * 		1)Adds instances of all subclasses of System as private fields
	 * 		2)Adds an update method
	 */
	macro public static function buildGame(): Array<Field>{
		var fields: Array<Field>=Context.getBuildFields();
		
		//var systemType=Context.getType("nrex.core.System");
		trace(Context.getClassPath());

		return fields;
	}

	/**
	 * Builds an entity:
	 * 		1)Every group an entity has is added as a field with getter
	 * 		2)Components(variable fields) of groups that entity has are combined together
	 * 		if there are several vars with same name, the last one counts
	 * 		so that the user can define them themself
	 */
	macro public static function buildEntity(): Array<Field>{
		var fields: Array<Field>=Context.getBuildFields(); 

		var currentClass=Context.getLocalClass().get();

		var groupTypes: Array<Type>=[];
		var components: StringMap<Field>=new StringMap<Field>();

		//FOR EVERY GROUP, ADD THE GROUP FIELD TO ENTITY AND COMPONENTS TO THE COMPONENTS SET
		currentClass.meta.extract("has")[0].params.iter(function(param){
			var name=param.getValue();
			var type=Context.getType(name);

			//TODO: will I need this?
			groupTypes.push(type);

			//get current group's components
			var currentComponents: Array<Field>=groupFields.get(name);
			if(currentComponents==null){ //if no components for current group found, add them
				var tempFields=type.getClass().fields.get();
				
				//filter out non-normal-access non-variables
				tempFields=tempFields.filter(function(f){
					switch(f.kind){
						case FVar(AccNormal, AccNormal): return true;
						default: return false;
					}
				});

				//convert class fields to build fields and add them
				currentComponents=new Array<Field>();
				tempFields.iter(function(f){
					currentComponents.push(cf2f(f));
				});

				groupFields.set(name, currentComponents);

			}

			//call arguments for the group constructor for getter
			var constrArgs: Array<Expr>=[macro this];

			//for every component...
			currentComponents.iter(function(f){

				//add it to the set
				components.set(f.name, f);

				//add the field to the call args
				constrArgs.push(macro $i{f.name});

			});

			//create a getter for the group field
			var tp: TypePath=null;
			switch(type.toComplexType()){
				case TPath(p):
					tp=p;
				default:
			}

			fields.push({ //create a new group field
				name: makeVarName(name),
				pos: Context.currentPos(),
				access: [APublic],
				//kind: FVar(type.toComplexType(), null)
				kind: FProp("get", "null", type.toComplexType(), null)
			});

			fields.push({
				name: 'get_${makeVarName(name)}',
				pos: Context.currentPos(),
				access: [APrivate, AInline],
				kind: FFun({
					ret: type.toComplexType(),
					expr: {
						expr: EReturn({
							expr: ENew(tp, constrArgs), 
							pos: Context.currentPos()
						}),
						pos: Context.currentPos()
					},
					args: []
				})
			});

		});

		//add distinct components to the entity
		components.iter(function(comp){
			fields.push(comp);
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