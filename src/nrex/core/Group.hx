package nrex.core;

/**
 * Groups group together several components, required by systems
 */
@:autoBuild(nrex.core.Macro.buildGroup())
class Group{
	public var owner: Entity;

	public function new(owner: Entity){
		this.owner=owner;
	}
}