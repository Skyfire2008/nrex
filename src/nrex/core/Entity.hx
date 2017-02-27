package nrex.core;

@:autoBuild(nrex.core.Macro.buildEntity())
class Entity{

	private static var currentId: Int=0;
	
	public var id(default, null): Int;

	public function new(){
		this.id=currentId++;
	}

	public inline function equals(other: Entity): Bool{
		return this.id==other.id;
	}
}