package nrex.core;

class Entity{

	private static var currentId: Int=0;
	
	public var id(default, null): Int;

	public function new(){
		this.id=currentId++;
	}
}