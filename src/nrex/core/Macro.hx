package nrex.core;

import haxe.ds.StringMap;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

using haxe.macro.MacroStringTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

using Lambda;
using StringTools;

using nrex.util.Extensions;

class Macro{

	/**
	 * Maps group to fields, that should be included in an entity that has the given group
	 * so that they can be calculated once per group
	 */
	private static var groupFields: StringMap<Array<Field>>=new StringMap<Array<Field>>();

	/**
	 * Number of last added entity
	 */
	private static var entNum: Int=0;

	/**
	 * Adds an entity to a game
	 */
	macro public static function addEntity(game: ExprOf<Game>, ent: ExprOf<Entity>){
		
		trace(game);
		trace(ent);

		var toAdd: Expr;

		switch(ent.expr){
			case EConst(_): //if a constant, don't do anything
				toAdd=ent;

			default: //otherwise, create a local variable
				toAdd={
					expr: EVars([{
						expr: ent,
						name: 'addedEntity$entNum',
						type: null
					}]),
					pos: Context.currentPos()
				};
				entNum++;
		}

		//get all groups of the entity
		var groups=Context.typeof(ent).getClass().meta.extract("has");
		groups.iter(function(m){
			trace(m.params);
		});

		return toAdd;
	}

	//TODO: @:unused and @:name metadata for systems
	/**
	 * Builds the game object:
	 * 		1)Adds instances of all subclasses of System as private fields
	 * 		2)Adds an update method
	 */
	macro public static function buildGame(): Array<Field>{
		var fields: Array<Field> = Context.getBuildFields();
		
		//get all systems
		var systemTypes = [];
		Context.getLocalClass().get().meta.extract(":systemLocation")[0].params.iter(function(path){
			systemTypes=systemTypes.concat(findSubClasses(path.getValue(), "", [], Context.getType("nrex.core.System").getClass()));
		});
		
		var sysPrios: Array<SysPrio> = new Array<SysPrio>();
		
		systemTypes.iter(function(t){ //for every system type...

			var sysName=makeVarName(t.name);
			var grType = t.superClass.params[0].toComplexType();
			var grTypeName = t.superClass.params[0].getClass().name;

			fields.push({ //add a system instance
				name: makeVarName(t.name),
				pos: Context.currentPos(),
				access: [APrivate],
				kind: FVar(TPath({ //pretty much a copy of TypeTools.toTypePath
					name: t.module.substring(t.module.lastIndexOf(".") + 1),
					pack: t.pack,
					sub: t.name,
					params: t.params.map(function(p){ return TPType(p.t.toComplexType()); })
				}), null)
			});

			//create a function to add necessary component
			var adder={
				args: [],
				expr: null,
				params: null,
				ret: Context.getType("Void").toComplexType()
			};
			
			adder.args.push({ //function argument
				name: "group",
				opt: false,
				type: grType
			});
			
			adder.expr={ //functon expression
				expr: ECall(
					macro $p{["this", sysName, "add"]},
					[macro $i{"group"}]
				),
				pos: Context.currentPos()
			}
			
			fields.push({ //push the function to the fields
				name: 'add$grTypeName',
				pos: Context.currentPos(),
				access: [APublic, AInline],
				kind: FFun(adder)
			});
			
			//get the priority of the system
			var sp={sys: t, prio: 0}
			if (t.meta.has(":priority")){
				sp.prio = t.meta.extract(":priority")[0].params[0].getValue();
			}
			sysPrios.push(sp);

		});
		
		//sort the systems by their priorities
		sysPrios.sort(function(a, b): Int{
			return a.prio - b.prio;
		});
		
		//find out, which systems use which methods
		var setupSys: Array<ClassType> = [];
		var updateSys: Array<ClassType> = [];
		var teardownSys: Array<ClassType> = [];
		
		sysPrios.iter(function(sp){
			sp.sys.fields.get().iter(function(f){
				
				if (f.name.equals("setup")){
					setupSys.push(sp.sys);
				}else if (f.name.equals("update")){
					updateSys.push(sp.sys);
				}else if (f.name.equals("teardown")){
					teardownSys.push(sp.sys);
				}
			});
		});
		
		//generate calls to appropriate methods of the systems
		var exprs: Array<Expr> = [];
		
		setupSys.iter(function(sys){
			exprs.push({
				expr: ECall(macro $p{["this", makeVarName(sys.name), "setup"]}, []),
				pos: Context.currentPos()
			});
		});
		
		updateSys.iter(function(sys){
			exprs.push({
				expr: ECall(macro $p{["this", makeVarName(sys.name), "updateAll"]}, []),
				pos: Context.currentPos()
			});
		});
		
		teardownSys.iter(function(sys){
			exprs.push({
				expr: ECall(macro $p{["this", makeVarName(sys.name), "teardown"]}, []),
				pos: Context.currentPos()
			});
		});
		
		//add the calls to overriden update method of the game
		fields.push({
			name: "update",
			pos: Context.currentPos(),
			access: [APublic, AOverride],
			kind: FFun({
				args: [],
				expr: macro $b{exprs},
				ret: null
			})
		});
		
		/*var sysCompoMap: Map<ClassType, Type> = new Map<ClassType, Type>();
		
		//get all components, that  the systems deal with
		systemTypes.iter(function(t){
			//sysCompoMap.set(t, t.superClass.params[0]); //take the first element of the params array, since systems only accept one component type each
		});
		trace(sysCompoMap);*/
		
		return fields;
	}
	
	macro public static function buildSystem(): Array<Field>{
		var fields: Array<Field> = Context.getBuildFields();
		
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
		/*var params=currentClass.meta.extract("has").flatMap(function(entry){
			return entry.params;
		});*/

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

		//do not remove the metadata, it will be needed for addition of entities to game
		//currentClass.meta.remove("has"); //remove metadata

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
	
	//TODO: use something like path2ClassPath: "nrex/core/Entity.hx" -> "nrex.core.Entity"
#if macro
	/**
	 * Recursively finds subclasses of a certain class in a given folder
	 * 
	 * @param	path				current path to files
	 * @param	classPath			current classPath
	 * @param	interResult			intermediate results
	 * @param	sup					superclass
	 * 
	 * @return						array of correct classTypes
	 */
	private static function findSubClasses(path: String, classPath: String, interResult: Array<ClassType>, sup: ClassType): Array<ClassType>{
		
		if (FileSystem.isDirectory(path)){ //if path is a directory
			FileSystem.readDirectory(path).iter(function(name: String){ //aply findSubClasses to its files recursively
				interResult=interResult.concat(findSubClasses(Path.join([path, name]), classPath.length==0 ? name : classPath+'.$name', [], sup));
			});
			
		}else{ //if path is a file
			if (path.endsWith(".hx")){
				Context.getModule(classPath.substring(0, classPath.length - 3)).iter(function(t){ //get the module
					
					switch(t){ //match with type instance(TInst)
						case TInst(ref, _):
							var ct = ref.get();
							if (ct.superClass != null){
								var curSup = ct.superClass.t.get();
								if (curSup.name.equals(sup.name) && curSup.pack.toString().equals(sup.pack.toString())){
									interResult.push(ct);
								}
							}
						default:
					}
				});
				//interResult=interResult.concat();
			}
		}
		
		return interResult;
		
	}
#end

#if macro
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
#end

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

/**
 * System-priority tuple for sorting
 */
typedef SysPrio = {
	var sys: ClassType;
	var prio: Int;
};